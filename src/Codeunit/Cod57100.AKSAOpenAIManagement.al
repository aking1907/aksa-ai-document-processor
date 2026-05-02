codeunit 57100 "AKSA Open AI Management"
{
    procedure GetOpenAIModels(var OpenAIModels: Record "AKSA Integer/Text Map")
    var
        AKSAOpenAISetup: Record "AKSA Open AI Setup";
        JsonArray: JsonArray;
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        HttpClient: HttpClient;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        ResponseText: Text;
        BearerToken: Text;
        i: Integer;
        BearerTokenLbl: Label 'Bearer %1', Comment = '%1 is the token';
    begin
        AKSAOpenAISetup.GetOrCreate();
        AKSAOpenAISetup.TestField("Open AI Model URL");
        AKSAOpenAISetup.TestField("Open AI Key");

        BearerToken := StrSubstNo(BearerTokenLbl, AKSAOpenAISetup."Open AI Key");

        HttpRequestMessage.SetRequestUri(AKSAOpenAISetup."Open AI Model URL");
        HttpRequestMessage.Method := 'GET';
        HttpClient.DefaultRequestHeaders.Add('Authorization', BearerToken);

        if not HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then
            Error('Unable to send the model list request.');

        HttpResponseMessage.Content.ReadAs(ResponseText);

        if not HttpResponseMessage.IsSuccessStatusCode() then
            Error('OpenAI model list request failed. Status code: %1. Reason: %2',
                HttpResponseMessage.HttpStatusCode(), HttpResponseMessage.ReasonPhrase());

        JsonObject.ReadFrom(ResponseText);
        if not JsonObject.Get('data', JsonToken) then
            exit;

        JsonArray := JsonToken.AsArray();
        for i := 0 to JsonArray.Count() - 1 do begin
            JsonArray.Get(i, JsonToken);
            JsonObject := JsonToken.AsObject();
            if JsonObject.Get('id', JsonToken) then begin
                OpenAIModels."Key" := i;
                OpenAIModels.Value := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(OpenAIModels.Value));
                OpenAIModels.Insert();
            end;
        end;
    end;

    procedure SendRequestToOpenAI(RequestText: Text): Text
    begin
        exit(SendPromptToAI(RequestText));
    end;

    procedure SendPromptToAI(PromptText: Text): Text
    var
        AKSAOpenAISetup: Record "AKSA Open AI Setup";
        AKSACommunicationLogMgt: Codeunit "AKSA AI Communication Log Mgt.";
        HttpClient: HttpClient;
        HttpContent: HttpContent;
        HttpHeaders: HttpHeaders;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        RequestBody: Text;
        ResponseText: Text;
        BearerToken: Text;
        BearerTokenLbl: Label 'Bearer %1', Comment = '%1 is the token';
    begin
        AKSAOpenAISetup.GetOrCreate();
        AKSAOpenAISetup.TestField("Open AI URL");
        AKSAOpenAISetup.TestField("Open AI Key");
        AKSAOpenAISetup.TestField("Open AI Model");

        BuildChatCompletionRequest(PromptText, RequestBody);
        BearerToken := StrSubstNo(BearerTokenLbl, AKSAOpenAISetup."Open AI Key");

        HttpContent.WriteFrom(RequestBody);
        HttpContent.GetHeaders(HttpHeaders);
        HttpHeaders.Clear();
        HttpHeaders.Add('Content-Type', 'application/json');

        HttpRequestMessage.Content(HttpContent);
        HttpRequestMessage.SetRequestUri(AKSAOpenAISetup."Open AI URL");
        HttpRequestMessage.Method := 'POST';
        HttpClient.DefaultRequestHeaders.Add('Authorization', BearerToken);

        if not HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then
            Error('Unable to send the AI request.');

        HttpResponseMessage.Content.ReadAs(ResponseText);
        AKSACommunicationLogMgt.Log('AI', 'Chat completion', RequestBody, ResponseText, HttpResponseMessage.HttpStatusCode());

        if not HttpResponseMessage.IsSuccessStatusCode() then
            Error('AI request failed. Status code: %1. Reason: %2',
                HttpResponseMessage.HttpStatusCode(), HttpResponseMessage.ReasonPhrase());

        exit(ParseChatCompletionResponse(ResponseText));
    end;

    procedure UploadItemCatalogueIntoAzureAISearch()
    var
        AKSAVectorSearchMgt: Codeunit "AKSA Vector Search Mgt.";
    begin
        AKSAVectorSearchMgt.UploadItemCatalogue();
    end;

    local procedure BuildChatCompletionRequest(PromptText: Text; var RequestBody: Text)
    var
        AKSAOpenAISetup: Record "AKSA Open AI Setup";
        BodyObject: JsonObject;
        MessageArray: JsonArray;
        MessageObject: JsonObject;
    begin
        AKSAOpenAISetup.GetOrCreate();

        MessageObject.Add('role', 'user');
        MessageObject.Add('content', PromptText);
        MessageArray.Add(MessageObject);

        BodyObject.Add('model', AKSAOpenAISetup."Open AI Model");
        BodyObject.Add('messages', MessageArray);
        BodyObject.Add('temperature', 0.2);
        BodyObject.Add('max_tokens', 4000);
        BodyObject.WriteTo(RequestBody);
    end;

    local procedure ParseChatCompletionResponse(ResponseText: Text): Text
    var
        ChoiceArray: JsonArray;
        JsonObject: JsonObject;
        JsonToken: JsonToken;
    begin
        JsonObject.ReadFrom(ResponseText);
        if not JsonObject.Get('choices', JsonToken) then
            exit(ResponseText);

        ChoiceArray := JsonToken.AsArray();
        if ChoiceArray.Count() = 0 then
            exit('');

        ChoiceArray.Get(0, JsonToken);
        JsonObject := JsonToken.AsObject();
        if not JsonObject.Get('message', JsonToken) then
            exit('');

        JsonObject := JsonToken.AsObject();
        if not JsonObject.Get('content', JsonToken) then
            exit('');

        exit(JsonToken.AsValue().AsText());
    end;
}
