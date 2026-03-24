codeunit 57100 "AKSA Open AI Management"
{
    procedure GetOpenAIModels(var OpenAIModels: Record "AKSA Integer/Text Map")
    var
        AKSAOpenAISetup: Record "AKSA Open AI Setup";
        JsonObject: JsonObject;
        JsonObjectChild: JsonObject;
        JsonArray: JsonArray;
        JsonToken: JsonToken;
        JsonTokenChild: JsonToken;
        HttpHeaders: HttpHeaders;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        HttpClient: HttpClient;
        HttpContent: HttpContent;
        ModelURL: Text[250];
        ResponseText: Text;
        BearerToken: Text;
        i: Integer;
        BearerTokenLbl: Label 'Bearer %1', Comment = '%1 is the token';
    begin
        AKSAOpenAISetup.Get();
        // ModelURL := 'https://api.openai.com/v1/models';
        ModelURL := AKSAOpenAISetup."Open AI Model URL";

        BearerToken := StrSubstNo(BearerTokenLbl, AKSAOpenAISetup."Open AI Key");

        HttpContent.GetHeaders(HttpHeaders);

        HttpHeaders.Clear();
        HttpRequestMessage.Content(HttpContent);
        HttpHeaders.Add('Content-Type', 'application/json');

        HttpRequestMessage.SetRequestUri(ModelURL);
        HttpRequestMessage.Method := 'GET';

        HttpClient.DefaultRequestHeaders.Add('Authorization', BearerToken);
        HttpClient.Send(HttpRequestMessage, HttpResponseMessage);

        if not HttpResponseMessage.IsSuccessStatusCode then
            Error(HttpResponseMessage.ReasonPhrase);

        HttpResponseMessage.Content.ReadAs(ResponseText);
        // Message(ResponseText);

        JsonObject.ReadFrom(ResponseText);
        JsonObject.Get('data', JsonToken);
        JsonArray := JsonToken.AsArray();

        i := 0;
        foreach JsonToken in JsonArray do begin
            JsonObject := JsonToken.AsObject();

            OpenAIModels."Key" := i;
            if JsonObject.Get('id', JsonTokenChild) then begin
                OpenAIModels.Value := JsonTokenChild.AsValue().AsText();
                OpenAIModels.Insert();

                i += 1;
            end;
        end;
    end;

    procedure SendRequestToOpenAI(RequestText: Text): Text;
    var
        AKSAOpenAISetup: Record "AKSA Open AI Setup";
        JsonObject: JsonObject;
        JsonObjectChild: JsonObject;
        JsonArray: JsonArray;
        JsonToken: JsonToken;
        JsonTokenChild: JsonToken;
        HttpHeaders: HttpHeaders;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        HttpClient: HttpClient;
        HttpContent: HttpContent;
        ModelURL: Text[250];
        ResponseText: Text;
        BearerToken: Text;
        i: Integer;
        BearerTokenLbl: Label 'Bearer %1', Comment = '%1 is the token';
    begin
        AKSAOpenAISetup.Get();
        ModelURL := AKSAOpenAISetup."Open AI URL";
        BearerToken := StrSubstNo(BearerTokenLbl, AKSAOpenAISetup."Open AI Key");

        RequestText := StrSubstNo('{"model": "%1","messages":[{"role": "user","content": "%2"}], "max_tokens": 100, "temperature": 0.5}', AKSAOpenAISetup."Open AI Model", RequestText);
        // JsonObject.ReadFrom(RequestText);
        // JsonObject.WriteTo(RequestText);

        HttpContent.WriteFrom(RequestText);
        HttpContent.GetHeaders(HttpHeaders);
        // Message('%1\%2\%3\', ModelURL, BearerToken, RequestText);
        HttpHeaders.Clear();
        HttpHeaders.Add('Content-Type', 'application/json');

        HttpRequestMessage.Content(HttpContent);
        HttpRequestMessage.SetRequestUri(ModelURL);
        HttpRequestMessage.Method := 'POST';

        HttpClient.DefaultRequestHeaders.Add('Authorization', BearerToken);
        HttpClient.Send(HttpRequestMessage, HttpResponseMessage);

        if not HttpResponseMessage.IsSuccessStatusCode then
            Error('Http Status Code:%1\Reason Phrase: %2', HttpResponseMessage.HttpStatusCode, HttpResponseMessage.ReasonPhrase);

        HttpResponseMessage.Content.ReadAs(ResponseText);
        JsonObject.ReadFrom(ResponseText);

        if JsonObject.Get('choices', JsonToken) then begin
            JsonArray := JsonToken.AsArray();
            JsonArray.Get(0, JsonToken);
            JsonObject := JsonToken.AsObject();

            JsonObject.Get('message', JsonToken);
            JsonObject := JsonToken.AsObject();
            JsonObject.Get('content', JsonToken);
        end;

        // Message(JsonToken.AsValue().AsText());
        exit(JsonToken.AsValue().AsText());
    end;


    procedure GetOpenAIResponse(prompt: Text): Text
    var
        AKSAOpenAISetup: Record "AKSA Open AI Setup";
        HttpClient: HttpClient;
        HttpResponse: HttpResponseMessage;
        content: HttpContent;
        httpHeaders: HttpHeaders;
        OpenAIEndpoint: Text;
        ResponseString: Text;
        APIKey: Text;
        JsonResponse: JsonObject;
        JsonObject: JsonObject;
        JsonToken: JsonToken;
    begin
        AKSAOpenAISetup.Get();
        OpenAIEndpoint := 'https://api.openai.com/v1/chat/completions'; // Endpoint for OpenAI API
        APIKey := AKSAOpenAISetup."Open AI Key"; //'YOUR_OPENAI_API_KEY'; // Your OpenAI API key

        // Create the body of the request
        JsonObject.Add('model', 'text-davinci-003'); // Specify the model you'd like to use
        JsonObject.Add('prompt', prompt);
        JsonObject.Add('max_tokens', 100); // Adjust token length as needed
        JsonObject.Add('temperature', 0.5);

        // Convert the JSON object to a string content
        JsonResponse.WriteTo(ResponseString);

        content.WriteFrom(ResponseString);
        content.GetHeaders(httpHeaders);
        httpHeaders.Clear();
        httpHeaders.Add('Content-Type', 'application/json');

        // Set the Authorization header with your API key
        HttpClient.DefaultRequestHeaders().Add('Authorization', 'Bearer ' + APIKey);

        // Make the API POST request
        if not HttpClient.Post(OpenAIEndpoint, content, HttpResponse) then begin
            Error('Error calling OpenAI API: %1', HttpResponse.HttpStatusCode());
        end;

        // Check the response status
        if HttpResponse.IsSuccessStatusCode() then begin
            HttpResponse.Content().ReadAs(ResponseString);
            JsonResponse.ReadFrom(ResponseString);
            // if JsonResponse.Get('choices', JsonToken) then
            //     JsonToken.AsArray().Get(0).AsObject().Get('text', ResponseString);
        end else begin
            Error('Failed to get a successful response from OpenAI API: %1', HttpResponse.HttpStatusCode());
        end;

        exit(ResponseString);
    end;

    local procedure SetChatGPTBody(Input: Text; NewModel: Boolean; var ContentText: Text)
    var
        AKSAOpenAISetup: Record "AKSA Open AI Setup";
        ChatGPTBody: JsonObject;
        ChatGPTBodyArray: JsonArray;
    begin
        AKSAOpenAISetup.Get();
        if NewModel then begin
            ChatGPTBody.Add('model', AKSAOpenAISetup."Open AI Model");
            ChatGPTBody.Add('messages', GetChatGPTMessageArray(Input));
        end else begin
            // ChatGPTBody.Add('model', AKSAOpenAISetup."Open AI Model"));
            // ChatGPTBody.Add('prompt', Input);
            // ChatGPTBody.Add('max_tokens', '10');
            // ChatGPTBody.Add('temperature','0.5');
            // ChatGPTBody.Add('top_p', OpenAISetup."Top P");
            // ChatGPTBody.Add('presence_penalty', OpenAISetup."Presence Penalty");
            // ChatGPTBody.Add('frequency_penalty', OpenAISetup."Frequency Penalty");
            // ChatGPTBody.Add('best_of', OpenAISetup."Best of");
        end;
        ChatGPTBody.WriteTo(ContentText);
    end;

    local procedure GetChatGPTMessageArray(Input: Text) InputArray: JsonArray
    var
        InputJsonObject: JsonObject;
    begin
        InputJsonObject.Add('role', 'system');
        InputJsonObject.Add('content', Input);
        InputArray.Add(InputJsonObject);
    end;


    local procedure ParseChatGPTResponseText(OutputString: Text; NewModel: Boolean): Text
    var
        JsonObjectResponse: JsonObject;
        JsonTokenResponse: JsonToken;
        JsonArrayResponse: JsonArray;
    begin
        JsonObjectResponse.ReadFrom(OutputString);
        if JsonObjectResponse.Get('choices', JsonTokenResponse) then begin
            JsonArrayResponse := JsonTokenResponse.AsArray();
            JsonArrayResponse.Get(0, JsonTokenResponse);
            JsonObjectResponse := JsonTokenResponse.AsObject();
            if NewModel then begin
                JsonObjectResponse.Get('message', JsonTokenResponse);
                JsonObjectResponse := JsonTokenResponse.AsObject();
                JsonObjectResponse.Get('content', JsonTokenResponse);
            end else
                JsonObjectResponse.Get('text', JsonTokenResponse);
            exit(JsonTokenResponse.AsValue().AsText());
        end;
    end;

    procedure ProcessWithOpenAI(var AKSADraftDocumentHeader: Record "AKSA Draft Document Header")
    var
        AKSAAIPromptTemplateLine: Record "AKSA AI Prompt Template Line";
        AKSADraftDocumentLine: Record "AKSA Draft Document Line";
        AKSADraftDocLineItem: Record "AKSA Draft Doc. Line Item";
        Item: Record Item;
        AKSAItemCatalogueMgt: Codeunit "AKSA Item Catalogue Mgt.";
        JsonObject: JsonObject;
        ChildJsonObject: JsonObject;
        JsonArray: JsonArray;
        ChildJsonArray: JsonArray;
        JsonToken: JsonToken;
        i: Integer;
        j: Integer;
        RequestText: Text;
    // AKOpenAIManagement: Codeunit "AKSA Open AI Management";
    // AKSAItemCatalogueMgt: Codeunit "AKSA Item Catalogue Mgt.";
    // AKSAExcelToJsonReport: Report "AKSA Excel To Json";
    // Prompt1Lbl: Label 'I will send an Item Catalogue in JSON structure. It will be marked as catalogname:item. Then I will send you a data structure in json format. You will need to try to recognize the item from item catalogue by the free text in data structure. If you are able to recognize the item, you will need to return the item no., description, quantity and uom. If you are not able to recognize the item, you will need to return the item no. empty, but description, quantyty and uom try to recognize from free data structure.The result must be in json format.';
    // Prompt2Lbl: Label 'There is item catalogue: %1';
    // Prompt3Lbl: Label 'There is free data: %1';
    // Prompt4Lbl: Label 'Give me results in json format:{\"data\":[{\"dsc\":\"%1\",\"no\":\"%2\",\"qty\":\"%3\",\"uom\":\"%4\"}]} where %1 is item no from item catalogue if recognized, empty if not. %2 is description from free data structure, it should be combination of data with max length 250. %3 is quantity if recognized from free structure or empty if not. %4 is uom if recognized from free structure or empty if not. Total count of records must be equal to count of records from the free data structure.';
    begin
        AKSADraftDocumentHeader.TestField("AI Prompt Template No.");
        AKSADraftDocumentHeader.CalcFields("Document Data");
        if not AKSADraftDocumentHeader."Document Data".HasValue then
            Error('Document Data is empty.');

        AKSAAIPromptTemplateLine.SetRange("Document No.", AKSADraftDocumentHeader."AI Prompt Template No.");
        AKSAAIPromptTemplateLine.SetRange(Active, true);
        if not AKSAAIPromptTemplateLine.FindSet() then
            Error('AI Prompt Template lines were not found.');

        repeat
            case AKSAAIPromptTemplateLine."AI Request Type" of
                Enum::"AKSA AI Request Type"::Prompt:
                    RequestText += AKSAAIPromptTemplateLine."AI Prompt";
                // Message(SendRequestToOpenAI(AKSAAIPromptTemplateLine."AI Prompt"));
                Enum::"AKSA AI Request Type"::ItemCatalogue:
                    RequestText += AKSAItemCatalogueMgt.GetItemCatalogue();
                // SendItemCatalogueToOpenAI();
                Enum::"AKSA AI Request Type"::DocumentData:
                    RequestText += AKSADraftDocumentHeader.GetDocumentDataText();
                // SendRequestToOpenAI(AKSADraftDocumentHeader.GetDocumentDataText());
                else
                    Error('Unexpected AI Request Type: %1', AKSAAIPromptTemplateLine."AI Request Type");
            end;
        until AKSAAIPromptTemplateLine.Next() = 0;

        Message(RequestText);
        // AKSADraftDocumentHeader.SetAIResponseText(GetOpenAIResponse());

        // JsonObject.ReadFrom(AKSADraftDocumentHeader.GetAIResponseText());

        // AKSADraftDocumentLine.SetRange("Document No.", AKSADraftDocumentHeader."No.");
        // if not AKSADraftDocumentLine.IsEmpty then
        //     AKSADraftDocumentLine.DeleteAll(true);

        // JsonObject.Get('data', JsonToken);
        // JsonArray := JsonToken.AsArray();
        // for i := 0 to JsonArray.Count - 1 do begin
        //     JsonArray.Get(i, JsonToken);

        //     AKSADraftDocumentLine.Init();
        //     AKSADraftDocumentLine."Line No." := i * 10000;
        //     AKSADraftDocumentLine."Document No." := AKSADraftDocumentHeader."No.";

        //     //dsc
        //     JsonObject := JsonToken.AsObject();
        //     JsonObject.Get('dsc', JsonToken);
        //     AKSADraftDocumentLine."Input Description" := JsonToken.AsValue().AsText();

        //     //qty
        //     JsonObject.Get('qty', JsonToken);
        //     AKSADraftDocumentLine.Quantity := JsonToken.AsValue().AsDecimal();

        //     //items
        //     JsonObject.Get('items', JsonToken);
        //     ChildJsonArray := JsonToken.AsArray();
        //     for j := 0 to ChildJsonArray.Count - 1 do begin
        //         ChildJsonArray.Get(j, JsonToken);
        //         ChildJsonObject := JsonToken.AsObject();
        //         ChildJsonObject.Get('no', JsonToken);

        //         AKSADraftDocLineItem."Line No." := AKSADraftDocumentLine."Line No.";
        //         AKSADraftDocLineItem."Document No." := AKSADraftDocumentLine."Document No.";
        //         if Item.Get(JsonToken.AsValue().AsText()) then begin
        //             AKSADraftDocLineItem.Validate("Item No.", Item."No.");
        //             AKSADraftDocLineItem.Insert();

        //             if AKSADraftDocumentLine."Item No." = '' then
        //                 AKSADraftDocumentLine.Validate("Item No.", Item."No.");
        //         end;
        //     end;

        //     AKSADraftDocumentLine.Insert();
        // end;
        // Message(AKOpenAIManagement.SendRequestToOpenAI(Prompt1Lbl));
        // Message(AKOpenAIManagement.SendRequestToOpenAI(StrSubstNo(Prompt2Lbl, AKSAItemCatalogueMgt.GetItemCatalogue())));

        // AKSAExcelToJsonReport.SetParams(Rec."Excel Desc. Column No.", Rec."Excel Quantity Column No.");
        // AKSAExcelToJsonReport.RunModal();
        // Message(AKOpenAIManagement.SendRequestToOpenAI(StrSubstNo(Prompt3Lbl, AKSAExcelToJsonReport.GetDataText())));
        // Message(AKOpenAIManagement.SendRequestToOpenAI(Prompt4Lbl));
    end;

    procedure SendItemCatalogueToOpenAI()
    var
        AKSAOpenAISetup: Record "AKSA Open AI Setup";
        AKSAItemCatalogueMgt: Codeunit "AKSA Item Catalogue Mgt.";
        Item: Record Item;
        IndexNo: Integer;
        BatchNo: Integer;
        i: Integer;
    begin
        AKSAOpenAISetup.Get();

        if AKSAOpenAISetup."Item Catalogue Batch Size" = 0 then
            SendRequestToOpenAI(AKSAItemCatalogueMgt.GetItemCatalogue())
        else begin
            BatchNo := Item.Count div AKSAOpenAISetup."Item Catalogue Batch Size";
            for i := 1 to BatchNo do begin
                SendRequestToOpenAI(StrSubstNo('Part %1:%2', i, AKSAItemCatalogueMgt.GetPartOfItemCatalogue(IndexNo)));
                IndexNo := IndexNo + AKSAOpenAISetup."Item Catalogue Batch Size";
            end;
        end;
    end;

    procedure GetOpenAIResponse(): Text
    var
        ResponseText: Text;
    begin
        ResponseText := '{"data":[{"dsc":"Shampoo - 32 oz.","items":[{"no":"000565"},{"no":"000559"},{"no":"000575"},{"no":"000577"},{"no":"000579"},{"no":"000574"}],"qty":100.0},{"dsc":"Shampoo - 12 oz.","items":[{"no":"000713"},{"no":"000753"},{"no":"0002552"},{"no":"0004009"},{"no":"0005290"}],"qty":60.0},{"dsc":"Deep Moist. Shampoo - 27.05 oz.","items":[{"no":"024022"},{"no":"MNT54200"}],"qty":60.0},{"dsc":"Micellar Shampoo - 11.2 oz.","items":[{"no":"MNT54220"}],"qty":90.0},{"dsc":"Deep Moist. Conditioner - 27.05 oz","items":[{"no":"024023"},{"no":"MNT54201"}],"qty":60.0},{"dsc":"Anti-Dandruff 2 in 1 Shampoo/Conditioner","items":[{"no":"MNT54441"}],"qty":60.0},{"dsc":"Herbal Gro Conditioner - 27.05 oz.","items":[{"no":"MNT54203"}],"qty":80.0}]}';
        exit(ResponseText);
    end;

    procedure GetEmbeddingData(RequestBody: Text) ResponseText: Text
    var
        HttpClient: HttpClient;
        HttpContent: HttpContent;
        HttpHeaders: HttpHeaders;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        URL: Text;
        APIKey: Text;
        EmbeddingModel: Text;
        APIVersion: Text;
    begin
        // Initialize variables
        ResponseText := '';
        URL := 'https://itemsearchai.openai.azure.com/openai/deployments/%1/embeddings?api-version=%2';
        APIKey := '';
        EmbeddingModel := 'text-embedding-ada-002';
        APIVersion := '2023-05-15';

        // Format the URL with the model and API version
        URL := StrSubstNo(URL, EmbeddingModel, APIVersion);

        // Set up the HTTP request
        HttpRequestMessage.Method := 'POST';
        HttpRequestMessage.SetRequestUri(URL);

        // Set up the request body
        HttpContent.WriteFrom(RequestBody);

        // Get and configure headers
        HttpContent.GetHeaders(HttpHeaders);
        HttpHeaders.Clear(); // Clear default headers
        HttpHeaders.Add('Content-Type', 'application/json');
        HttpHeaders.Add('api-key', APIKey);

        // Assign content to the request
        HttpRequestMessage.Content(HttpContent);

        // Send the request
        HttpClient.Send(HttpRequestMessage, HttpResponseMessage);

        // Check for success
        if not HttpResponseMessage.IsSuccessStatusCode then
            Error('HTTP request failed with status code %1: %2',
                HttpResponseMessage.HttpStatusCode,
                HttpResponseMessage.ReasonPhrase);

        // Read the response
        HttpResponseMessage.Content.ReadAs(ResponseText);
    end;

    procedure UploadItemCatalogueIntoAzureAISearch()
    var
        AKSAItemCatalogueMgt: Codeunit "AKSA Item Catalogue Mgt.";
        HttpClient: HttpClient;
        HttpContent: HttpContent;
        HttpHeaders: HttpHeaders;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        URL: Text;
        APIKey: Text;
        EmbeddingModel: Text;
        APIVersion: Text;
        TextItemCatalogue: Text;
    begin
        // Initialize variables
        TextItemCatalogue := AKSAItemCatalogueMgt.GetItemCatalogue();

        URL := 'https://codegamesjems-search.search.windows.net/indexes/item_search/docs/index?api-version=%1';
        APIKey := '';
        APIVersion := '2024-07-01';

        // Format the URL with the model and API version
        URL := StrSubstNo(URL, APIVersion);

        // Set up the HTTP request
        HttpRequestMessage.Method := 'POST';
        HttpRequestMessage.SetRequestUri(URL);

        // Set up the request body
        HttpContent.WriteFrom(TextItemCatalogue);

        // Get and configure headers
        HttpContent.GetHeaders(HttpHeaders);
        HttpHeaders.Clear(); // Clear default headers
        HttpHeaders.Add('Content-Type', 'application/json');
        HttpHeaders.Add('api-key', APIKey);

        // Assign content to the request
        HttpRequestMessage.Content(HttpContent);

        // Send the request
        HttpClient.Send(HttpRequestMessage, HttpResponseMessage);

        // Check for success
        if not HttpResponseMessage.IsSuccessStatusCode then
            Error('HTTP request failed with status code %1: %2',
                HttpResponseMessage.HttpStatusCode,
                HttpResponseMessage.ReasonPhrase);

    end;

}
