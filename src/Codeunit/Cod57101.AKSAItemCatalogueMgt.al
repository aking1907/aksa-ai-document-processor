codeunit 57101 "AKSA Item Catalogue Mgt."
{
    procedure GetItemCatalogue(): Text
    var
        Item: Record Item;
        Base64Convert: Codeunit "Base64 Convert";
        JsonObject: JsonObject;
        JsonArray: JsonArray;
        DscvJsonArray: JsonArray;
        DataObject: JsonObject;
        TextCatalogue: Text;
        Baase64Text: Text;
        i: Integer;
    begin
        if Item.FindSet() then
            repeat
                i += 1;
                Item.CalcFields(Inventory);
                Clear(DataObject);
                DataObject.Add('@search.action', 'upload');
                DataObject.Add('no', Item."No.");
                DataObject.Add('dsc', DelChr(Item.Description.Trim(), '=', '"'));

                // clear(DscvJsonArray);
                // DscvJsonArray.Add(DataObject);
                // DscvJsonArray.WriteTo(TextCatalogue);

                clear(DscvJsonArray);
                TextCatalogue := Item.AKSAGetObjectEmbeddingData();

                if TextCatalogue = '' then
                    continue;

                DscvJsonArray.ReadFrom(TextCatalogue);
                DataObject.Add('dsc_v', DscvJsonArray);
                // DataObject.Add('uom', Item."Base Unit of Measure");
                // DataObject.Add('qty', Item.Inventory);

                JsonArray.Add(DataObject);
            until (Item.Next() = 0) or (i = 100);

        // JsonObject.Add('catalogname', 'item');
        JsonObject.Add('value', JsonArray);

        JsonObject.WriteTo(TextCatalogue);
        TextCatalogue := TextCatalogue.Replace('"', '''');
        // Baase64Text := Base64Convert.ToBase64(TextCatalogue);
        exit(TextCatalogue);
        // Message(TextCatalogue);
    end;

    procedure GetPartOfItemCatalogue(IndexNo: Integer): Text
    var
        Item: Record Item;
        AKSAOpenAISetup: Record "AKSA Open AI Setup";
        Base64Convert: Codeunit "Base64 Convert";
        JsonObject: JsonObject;
        JsonArray: JsonArray;
        DataObject: JsonObject;
        TextCatalogue: Text;
        Baase64Text: Text;
        i: Integer;
        BatchSize: Integer;
    begin
        AKSAOpenAISetup.Get();
        BatchSize := AKSAOpenAISetup."Item Catalogue Batch Size";
        if BatchSize = 0 then
            BatchSize := Item.Count;


        if Item.FindSet() then
            repeat
                i += 1;
                Item.CalcFields(Inventory);
                Clear(DataObject);
                DataObject.Add('no', Item."No.");
                DataObject.Add('dsc', DelChr(Item.Description.Trim(), '=', '"'));
                // DataObject.Add('uom', Item."Base Unit of Measure");
                // DataObject.Add('qty', Item.Inventory);

                if i >= IndexNo then
                    JsonArray.Add(DataObject);

            until (Item.Next() = 0) or (i = IndexNo + BatchSize);

        JsonObject.Add('catalogname', 'item');
        JsonObject.Add('data', JsonArray);

        JsonObject.WriteTo(TextCatalogue);
        TextCatalogue := TextCatalogue.Replace('"', '''');
        // Baase64Text := Base64Convert.ToBase64(TextCatalogue);
        exit(TextCatalogue);
        // Message(TextCatalogue);
    end;

    procedure TEST_ProcessItemEmbeddingDataResponse(ListOfItems: List of [Text]; ResponseText: Text)
    var
        AKSAOpenAISetup: Record "AKSA Open AI Setup";
        JsonObject: JsonObject;
        JsonArray: JsonArray;
        DataObject: JsonObject;
        EmbeddingJsonArray: JsonArray;
        Item: Record Item;
        No: Text;
        Embedding: Text;
        i: Integer;
    begin
        AKSAOpenAISetup.Get();

        AKSAOpenAISetup.CalcFields("Temp Blob");
        ResponseText := AKSAOpenAISetup.GetTempBlob();
        Clear(ListOfItems);
        ListOfItems.Add('1000');
        ListOfItems.Add('1001');
        JsonObject.ReadFrom(ResponseText);
        JsonArray := JsonObject.GetArray('data');

        for i := 0 to JsonArray.Count() - 1 do begin
            DataObject := JsonArray.GetObject(i);

            EmbeddingJsonArray := DataObject.GetArray('embedding');
            Embedding := Format(EmbeddingJsonArray);

            No := '';
            ListOfItems.Get(i + 1, No);
            Item.Get(No);
            Item.AKSASetObjectEmbeddingData(Embedding);
            Item."AKSA Indexed" := true;
            Item.Modify();
        end;
    end;

    procedure UpdateItemEmbedding(var Item: Record Item)
    var

        AKSAOpenAISetup: Record "AKSA Open AI Setup";
        AKSAOpenAIManagement: Codeunit "AKSA Open AI Management";
        JsonObject: JsonObject;
        JsonArray: JsonArray;
        DataObject: JsonObject;
        EmbeddingJsonArray: JsonArray;
        ResponseText: Text;
        No: Text;
        Embedding: Text;
        i: Integer;
        ListOfItems: List of [Text];
        RequestBody: Text;
    begin
        AKSAOpenAISetup.Get();

        if Item.GetFilters() = '' then
            Item.SetRange("AKSA Indexed", false);

        if Item.FindSet() then
            repeat
                if Item.Description <> '' then begin
                    ListOfItems.Add(Item."No.");
                    RequestBody += StrSubstNo(',"%1"', Item.Description);
                end;
            until Item.Next() = 0;

        if ListOfItems.Count() = 0 then
            exit;

        RequestBody := DelChr(RequestBody, '<>', ',');
        RequestBody := StrSubstNo('{"input":[%1]}', RequestBody);
        ResponseText := AKSAOpenAIManagement.GetEmbeddingData(RequestBody);

        JsonObject.ReadFrom(ResponseText);
        JsonArray := JsonObject.GetArray('data');

        for i := 0 to JsonArray.Count() - 1 do begin
            DataObject := JsonArray.GetObject(i);

            EmbeddingJsonArray := DataObject.GetArray('embedding');
            Embedding := Format(EmbeddingJsonArray);

            No := '';
            ListOfItems.Get(i + 1, No);
            Item.Get(No);
            Item.AKSASetObjectEmbeddingData(Embedding);
            Item."AKSA Indexed" := true;
            Item.Modify();
        end;
    end;



}
