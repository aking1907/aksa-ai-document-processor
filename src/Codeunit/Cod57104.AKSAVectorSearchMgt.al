codeunit 57104 "AKSA Vector Search Mgt."
{
    procedure GetRelevantItemCatalogue(DocumentData: Text): Text
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
    begin
        AKSAOpenAISetup.GetOrCreate();
        AKSAOpenAISetup.SetDefaultValues();
        ValidateSearchSetup(AKSAOpenAISetup);

        BuildSearchRequest(DocumentData, AKSAOpenAISetup."Vector Result Count", RequestBody);

        HttpContent.WriteFrom(RequestBody);
        HttpContent.GetHeaders(HttpHeaders);
        HttpHeaders.Clear();
        HttpHeaders.Add('Content-Type', 'application/json');

        HttpRequestMessage.Content(HttpContent);
        HttpRequestMessage.SetRequestUri(GetSearchUrl(AKSAOpenAISetup, true));
        HttpRequestMessage.Method := 'POST';
        HttpClient.DefaultRequestHeaders.Add('api-key', AKSAOpenAISetup."Azure AI Search Key");

        if not HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then
            Error('Unable to send the Azure AI Search request.');

        HttpResponseMessage.Content.ReadAs(ResponseText);
        AKSACommunicationLogMgt.Log('Search', 'Retrieve relevant catalogue items', RequestBody, ResponseText, HttpResponseMessage.HttpStatusCode());

        if not HttpResponseMessage.IsSuccessStatusCode() then
            Error('Azure AI Search request failed. Status code: %1. Reason: %2',
                HttpResponseMessage.HttpStatusCode(), HttpResponseMessage.ReasonPhrase());

        exit(ConvertSearchResultsToCatalogue(ResponseText));
    end;

    procedure UploadItemCatalogue()
    var
        AKSAOpenAISetup: Record "AKSA Open AI Setup";
        AKSAItemCatalogueMgt: Codeunit "AKSA Item Catalogue Mgt.";
        AKSACommunicationLogMgt: Codeunit "AKSA AI Communication Log Mgt.";
        HttpClient: HttpClient;
        HttpContent: HttpContent;
        HttpHeaders: HttpHeaders;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        RequestBody: Text;
        ResponseText: Text;
    begin
        AKSAOpenAISetup.GetOrCreate();
        AKSAOpenAISetup.SetDefaultValues();
        ValidateSearchSetup(AKSAOpenAISetup);

        RequestBody := AKSAItemCatalogueMgt.GetCatalogueForSearchUpload();

        HttpContent.WriteFrom(RequestBody);
        HttpContent.GetHeaders(HttpHeaders);
        HttpHeaders.Clear();
        HttpHeaders.Add('Content-Type', 'application/json');

        HttpRequestMessage.Content(HttpContent);
        HttpRequestMessage.SetRequestUri(GetSearchUrl(AKSAOpenAISetup, false));
        HttpRequestMessage.Method := 'POST';
        HttpClient.DefaultRequestHeaders.Add('api-key', AKSAOpenAISetup."Azure AI Search Key");

        if not HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then
            Error('Unable to upload the item catalogue to Azure AI Search.');

        HttpResponseMessage.Content.ReadAs(ResponseText);
        AKSACommunicationLogMgt.Log('Search', 'Upload item catalogue', RequestBody, ResponseText, HttpResponseMessage.HttpStatusCode());

        if not HttpResponseMessage.IsSuccessStatusCode() then
            Error('Azure AI Search upload failed. Status code: %1. Reason: %2',
                HttpResponseMessage.HttpStatusCode(), HttpResponseMessage.ReasonPhrase());
    end;

    procedure UpdateItemEmbeddings(var Item: Record Item)
    var
        AKSAOpenAISetup: Record "AKSA Open AI Setup";
        AKSACommunicationLogMgt: Codeunit "AKSA AI Communication Log Mgt.";
        EmbeddingArray: JsonArray;
        ItemNos: List of [Code[20]];
        ResponseArray: JsonArray;
        ResponseObject: JsonObject;
        DataObject: JsonObject;
        JsonToken: JsonToken;
        HttpClient: HttpClient;
        HttpContent: HttpContent;
        HttpHeaders: HttpHeaders;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        CurrentItemNo: Code[20];
        EmbeddingText: Text;
        RequestBody: Text;
        ResponseText: Text;
        i: Integer;
    begin
        AKSAOpenAISetup.GetOrCreate();
        AKSAOpenAISetup.TestField("Open AI Embedding URL");

        if Item.GetFilters() = '' then
            Item.SetRange("AKSA Indexed", false);

        BuildEmbeddingRequest(Item, ItemNos, RequestBody);
        if ItemNos.Count() = 0 then
            exit;

        HttpContent.WriteFrom(RequestBody);
        HttpContent.GetHeaders(HttpHeaders);
        HttpHeaders.Clear();
        HttpHeaders.Add('Content-Type', 'application/json');

        HttpRequestMessage.Content(HttpContent);
        HttpRequestMessage.SetRequestUri(AKSAOpenAISetup."Open AI Embedding URL");
        HttpRequestMessage.Method := 'POST';
        AddEmbeddingAuthentication(HttpClient, AKSAOpenAISetup);

        if not HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then
            Error('Unable to send the embedding request.');

        HttpResponseMessage.Content.ReadAs(ResponseText);
        AKSACommunicationLogMgt.Log('AI', 'Create item embeddings', RequestBody, ResponseText, HttpResponseMessage.HttpStatusCode());

        if not HttpResponseMessage.IsSuccessStatusCode() then
            Error('Embedding request failed. Status code: %1. Reason: %2',
                HttpResponseMessage.HttpStatusCode(), HttpResponseMessage.ReasonPhrase());

        ResponseObject.ReadFrom(ResponseText);
        if not ResponseObject.Get('data', JsonToken) then
            Error('Embedding response does not contain a data array.');

        ResponseArray := JsonToken.AsArray();
        for i := 0 to ResponseArray.Count() - 1 do begin
            ResponseArray.Get(i, JsonToken);
            DataObject := JsonToken.AsObject();
            if DataObject.Get('embedding', JsonToken) then begin
                EmbeddingArray := JsonToken.AsArray();
                EmbeddingArray.WriteTo(EmbeddingText);
                ItemNos.Get(i + 1, CurrentItemNo);
                if Item.Get(CurrentItemNo) then begin
                    Item.AKSASetObjectEmbeddingData(EmbeddingText);
                    Item."AKSA Indexed" := true;
                    Item.Modify();
                end;
            end;
        end;
    end;

    local procedure BuildSearchRequest(DocumentData: Text; TopCount: Integer; var RequestBody: Text)
    var
        EmbeddingArray: JsonArray;
        RequestObject: JsonObject;
        VectorQueriesArray: JsonArray;
        VectorQueryObject: JsonObject;
    begin
        EmbeddingArray := CreateEmbeddingVector(DocumentData, 'Create document embedding for vector search');

        VectorQueryObject.Add('kind', 'vector');
        VectorQueryObject.Add('vector', EmbeddingArray);
        VectorQueryObject.Add('fields', 'dsc_v');
        VectorQueryObject.Add('k', TopCount);
        VectorQueriesArray.Add(VectorQueryObject);

        RequestObject.Add('vectorQueries', VectorQueriesArray);
        RequestObject.Add('top', TopCount);
        RequestObject.Add('select', 'no,dsc,uom');
        RequestObject.WriteTo(RequestBody);
    end;

    local procedure CreateEmbeddingVector(InputText: Text; LogDescription: Text[250]): JsonArray
    var
        AKSAOpenAISetup: Record "AKSA Open AI Setup";
        AKSACommunicationLogMgt: Codeunit "AKSA AI Communication Log Mgt.";
        DataObject: JsonObject;
        HttpClient: HttpClient;
        HttpContent: HttpContent;
        HttpHeaders: HttpHeaders;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        JsonToken: JsonToken;
        RequestBody: Text;
        ResponseArray: JsonArray;
        ResponseObject: JsonObject;
        ResponseText: Text;
    begin
        AKSAOpenAISetup.GetOrCreate();
        AKSAOpenAISetup.TestField("Open AI Embedding URL");

        BuildSingleEmbeddingRequest(InputText, RequestBody);

        HttpContent.WriteFrom(RequestBody);
        HttpContent.GetHeaders(HttpHeaders);
        HttpHeaders.Clear();
        HttpHeaders.Add('Content-Type', 'application/json');

        HttpRequestMessage.Content(HttpContent);
        HttpRequestMessage.SetRequestUri(AKSAOpenAISetup."Open AI Embedding URL");
        HttpRequestMessage.Method := 'POST';
        AddEmbeddingAuthentication(HttpClient, AKSAOpenAISetup);

        if not HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then
            Error('Unable to send the embedding request.');

        HttpResponseMessage.Content.ReadAs(ResponseText);
        AKSACommunicationLogMgt.Log('AI', LogDescription, RequestBody, ResponseText, HttpResponseMessage.HttpStatusCode());

        if not HttpResponseMessage.IsSuccessStatusCode() then
            Error('Embedding request failed. Status code: %1. Reason: %2',
                HttpResponseMessage.HttpStatusCode(), HttpResponseMessage.ReasonPhrase());

        ResponseObject.ReadFrom(ResponseText);
        if not ResponseObject.Get('data', JsonToken) then
            Error('Embedding response does not contain a data array.');

        ResponseArray := JsonToken.AsArray();
        if ResponseArray.Count() = 0 then
            Error('Embedding response does not contain any embeddings.');

        ResponseArray.Get(0, JsonToken);
        DataObject := JsonToken.AsObject();
        if not DataObject.Get('embedding', JsonToken) then
            Error('Embedding response does not contain an embedding vector.');

        exit(JsonToken.AsArray());
    end;

    local procedure BuildSingleEmbeddingRequest(InputText: Text; var RequestBody: Text)
    var
        AKSAOpenAISetup: Record "AKSA Open AI Setup";
        InputArray: JsonArray;
        RequestObject: JsonObject;
    begin
        AKSAOpenAISetup.GetOrCreate();

        InputArray.Add(CopyStr(InputText, 1, 8000));
        RequestObject.Add('input', InputArray);
        if AKSAOpenAISetup."Open AI Embedding Model" <> '' then
            RequestObject.Add('model', AKSAOpenAISetup."Open AI Embedding Model");

        RequestObject.WriteTo(RequestBody);
    end;

    local procedure BuildEmbeddingRequest(var Item: Record Item; var ItemNos: List of [Code[20]]; var RequestBody: Text)
    var
        AKSAOpenAISetup: Record "AKSA Open AI Setup";
        InputArray: JsonArray;
        RequestObject: JsonObject;
    begin
        AKSAOpenAISetup.GetOrCreate();

        if Item.FindSet() then
            repeat
                if Item.Description <> '' then begin
                    ItemNos.Add(Item."No.");
                    InputArray.Add(Item.Description);
                end;
            until Item.Next() = 0;

        RequestObject.Add('input', InputArray);
        if AKSAOpenAISetup."Open AI Embedding Model" <> '' then
            RequestObject.Add('model', AKSAOpenAISetup."Open AI Embedding Model");

        RequestObject.WriteTo(RequestBody);
    end;

    local procedure ConvertSearchResultsToCatalogue(ResponseText: Text): Text
    var
        CatalogueArray: JsonArray;
        ResultArray: JsonArray;
        CatalogueObject: JsonObject;
        ResultObject: JsonObject;
        ItemObject: JsonObject;
        JsonToken: JsonToken;
        CatalogueText: Text;
        i: Integer;
    begin
        ResultObject.ReadFrom(ResponseText);
        if not ResultObject.Get('value', JsonToken) then
            Error('Azure AI Search response does not contain a value array.');

        ResultArray := JsonToken.AsArray();
        for i := 0 to ResultArray.Count() - 1 do begin
            ResultArray.Get(i, JsonToken);
            ResultObject := JsonToken.AsObject();

            Clear(ItemObject);
            ItemObject.Add('no', GetJsonText(ResultObject, 'no'));
            ItemObject.Add('dsc', GetJsonText(ResultObject, 'dsc'));
            ItemObject.Add('uom', GetJsonText(ResultObject, 'uom'));
            CatalogueArray.Add(ItemObject);
        end;

        CatalogueObject.Add('catalogname', 'item');
        CatalogueObject.Add('data', CatalogueArray);
        CatalogueObject.WriteTo(CatalogueText);
        exit(CatalogueText);
    end;

    local procedure GetJsonText(JsonObject: JsonObject; FieldName: Text): Text
    var
        JsonToken: JsonToken;
    begin
        if JsonObject.Get(FieldName, JsonToken) then
            exit(JsonToken.AsValue().AsText());

        exit('');
    end;

    local procedure GetSearchUrl(AKSAOpenAISetup: Record "AKSA Open AI Setup"; SearchRequest: Boolean): Text
    var
        BaseUrl: Text;
        IndexRequestUrlLbl: Label '%1/indexes/%2/docs/index?api-version=%3', Comment = '%1 is the Azure AI Search URL, %2 is the index name, %3 is the API version.';
        SearchRequestUrlLbl: Label '%1/indexes/%2/docs/search?api-version=%3', Comment = '%1 is the Azure AI Search URL, %2 is the index name, %3 is the API version.';
    begin
        BaseUrl := RemoveTrailingSlash(AKSAOpenAISetup."Azure AI Search URL");

        if SearchRequest then
            exit(StrSubstNo(SearchRequestUrlLbl,
                BaseUrl, AKSAOpenAISetup."Azure AI Search Index Name", AKSAOpenAISetup."Azure AI Search Api Version"));

        exit(StrSubstNo(IndexRequestUrlLbl,
            BaseUrl, AKSAOpenAISetup."Azure AI Search Index Name", AKSAOpenAISetup."Azure AI Search Api Version"));
    end;

    local procedure RemoveTrailingSlash(InputText: Text): Text
    begin
        if (InputText <> '') and (CopyStr(InputText, StrLen(InputText), 1) = '/') then
            exit(CopyStr(InputText, 1, StrLen(InputText) - 1));

        exit(InputText);
    end;

    local procedure ValidateSearchSetup(AKSAOpenAISetup: Record "AKSA Open AI Setup")
    begin
        AKSAOpenAISetup.TestField("Azure AI Search URL");
        AKSAOpenAISetup.TestField("Azure AI Search Key");
        AKSAOpenAISetup.TestField("Azure AI Search Index Name");
        AKSAOpenAISetup.TestField("Azure AI Search Api Version");
    end;

    local procedure AddEmbeddingAuthentication(var HttpClient: HttpClient; AKSAOpenAISetup: Record "AKSA Open AI Setup")
    var
        ApiKey: Text;
        BearerTokenLbl: Label 'Bearer %1', Comment = '%1 is the token';
    begin
        ApiKey := AKSAOpenAISetup."Open AI Embedding Key";
        if ApiKey = '' then
            ApiKey := AKSAOpenAISetup."Open AI Key";

        if ApiKey = '' then
            AKSAOpenAISetup.TestField("Open AI Embedding Key");

        HttpClient.DefaultRequestHeaders.Add('Authorization', StrSubstNo(BearerTokenLbl, ApiKey));
        HttpClient.DefaultRequestHeaders.Add('api-key', ApiKey);
    end;
}
