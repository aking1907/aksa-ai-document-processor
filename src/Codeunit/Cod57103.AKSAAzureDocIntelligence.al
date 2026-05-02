codeunit 57103 "AKSA Azure Doc Intelligence"
{
    procedure UploadAndExtractToDraft(var AKSADraftDocumentHeader: Record "AKSA Draft Document Header")
    var
        FileInStream: InStream;
        FileName: Text;
        ExtractedData: Text;
        UploadDocumentMsg: Label 'Upload document';
    begin
        if not UploadIntoStream(UploadDocumentMsg, '', 'Documents (*.pdf;*.png;*.jpg;*.jpeg)|*.pdf;*.png;*.jpg;*.jpeg|All Files (*.*)|*.*', FileName, FileInStream) then
            exit;

        ExtractedData := ExtractDocument(FileInStream);

        AKSADraftDocumentHeader."Source File Name" := CopyStr(FileName, 1, MaxStrLen(AKSADraftDocumentHeader."Source File Name"));
        AKSADraftDocumentHeader.SetDocumentDataText(ExtractedData);
    end;

    procedure ExtractDocument(DocumentInStream: InStream): Text
    var
        AKSAOpenAISetup: Record "AKSA Open AI Setup";
        AKSACommunicationLogMgt: Codeunit "AKSA AI Communication Log Mgt.";
        HttpClient: HttpClient;
        HttpContent: HttpContent;
        HttpHeaders: HttpHeaders;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        OperationLocation: Text;
        ResponseText: Text;
    begin
        AKSAOpenAISetup.GetOrCreate();
        AKSAOpenAISetup.TestField("Document Intelligence URL");
        AKSAOpenAISetup.TestField("Document Intelligence Key");

        HttpContent.WriteFrom(DocumentInStream);
        HttpContent.GetHeaders(HttpHeaders);
        HttpHeaders.Clear();
        HttpHeaders.Add('Content-Type', 'application/octet-stream');

        HttpRequestMessage.Content(HttpContent);
        HttpRequestMessage.SetRequestUri(AKSAOpenAISetup."Document Intelligence URL");
        HttpRequestMessage.Method := 'POST';
        HttpClient.DefaultRequestHeaders.Add('Ocp-Apim-Subscription-Key', AKSAOpenAISetup."Document Intelligence Key");

        if not HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then
            Error('Unable to send the document extraction request.');

        HttpResponseMessage.Content.ReadAs(ResponseText);
        AKSACommunicationLogMgt.Log('OCR', 'Azure AI Document Intelligence submit', '', ResponseText, HttpResponseMessage.HttpStatusCode());

        if not HttpResponseMessage.IsSuccessStatusCode() then
            Error('Document extraction failed. Status code: %1. Reason: %2',
                HttpResponseMessage.HttpStatusCode(), HttpResponseMessage.ReasonPhrase());

        if HttpResponseMessage.HttpStatusCode() = 202 then begin
            OperationLocation := GetResponseHeader(HttpResponseMessage, 'Operation-Location');
            if OperationLocation = '' then
                Error('Document Intelligence accepted the document but did not return an Operation-Location header.');

            exit(PollDocumentAnalysis(AKSAOpenAISetup, OperationLocation));
        end;

        exit(ResponseText);
    end;

    local procedure PollDocumentAnalysis(AKSAOpenAISetup: Record "AKSA Open AI Setup"; OperationLocation: Text): Text
    var
        AKSACommunicationLogMgt: Codeunit "AKSA AI Communication Log Mgt.";
        HttpClient: HttpClient;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        ResponseText: Text;
        StatusText: Text;
        AttemptNo: Integer;
    begin
        HttpClient.DefaultRequestHeaders.Add('Ocp-Apim-Subscription-Key', AKSAOpenAISetup."Document Intelligence Key");

        repeat
            AttemptNo += 1;
            Sleep(1000);

            Clear(HttpRequestMessage);
            Clear(HttpResponseMessage);
            HttpRequestMessage.SetRequestUri(OperationLocation);
            HttpRequestMessage.Method := 'GET';

            if not HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then
                Error('Unable to poll the document extraction result.');

            HttpResponseMessage.Content.ReadAs(ResponseText);
            AKSACommunicationLogMgt.Log('OCR', 'Azure AI Document Intelligence poll', '', ResponseText, HttpResponseMessage.HttpStatusCode());

            if not HttpResponseMessage.IsSuccessStatusCode() then
                Error('Document extraction polling failed. Status code: %1. Reason: %2',
                    HttpResponseMessage.HttpStatusCode(), HttpResponseMessage.ReasonPhrase());

            StatusText := LowerCase(GetJsonText(ResponseText, 'status'));
            case StatusText of
                'succeeded':
                    exit(ResponseText);
                'failed':
                    Error('Document extraction failed. Response: %1', ResponseText);
            end;
        until AttemptNo >= 30;

        Error('Document extraction did not finish within the polling timeout.');
    end;

    local procedure GetResponseHeader(HttpResponseMessage: HttpResponseMessage; HeaderName: Text): Text
    var
        HeaderValues: List of [Text];
        HttpHeaders: HttpHeaders;
        HeaderValue: Text;
    begin
        HttpHeaders := HttpResponseMessage.Headers();
        if not HttpHeaders.GetValues(HeaderName, HeaderValues) then
            exit('');

        if HeaderValues.Count() = 0 then
            exit('');

        HeaderValues.Get(1, HeaderValue);
        exit(HeaderValue);
    end;

    local procedure GetJsonText(ResponseText: Text; FieldName: Text): Text
    var
        JsonObject: JsonObject;
        JsonToken: JsonToken;
    begin
        if ResponseText = '' then
            exit('');

        JsonObject.ReadFrom(ResponseText);
        if JsonObject.Get(FieldName, JsonToken) then
            exit(JsonToken.AsValue().AsText());

        exit('');
    end;
}
