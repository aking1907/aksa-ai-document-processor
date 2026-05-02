codeunit 57101 "AKSA Item Catalogue Mgt."
{
    procedure GetItemCount(): Integer
    var
        Item: Record Item;
    begin
        exit(Item.Count());
    end;

    procedure GetItemCatalogue(): Text
    var
        Item: Record Item;
    begin
        exit(BuildPromptCatalogue(Item, 0, 0));
    end;

    procedure GetPartOfItemCatalogue(IndexNo: Integer): Text
    var
        AKSAOpenAISetup: Record "AKSA Open AI Setup";
        Item: Record Item;
        BatchSize: Integer;
    begin
        AKSAOpenAISetup.GetOrCreate();
        AKSAOpenAISetup.SetDefaultValues();

        BatchSize := AKSAOpenAISetup."Item Catalogue Batch Size";
        if BatchSize = 0 then
            BatchSize := Item.Count();

        exit(BuildPromptCatalogue(Item, IndexNo, BatchSize));
    end;

    procedure GetCatalogueForSearchUpload(): Text
    var
        Item: Record Item;
    begin
        exit(BuildSearchUploadPayload(Item));
    end;

    procedure UpdateItemEmbedding(var Item: Record Item)
    var
        AKSAVectorSearchMgt: Codeunit "AKSA Vector Search Mgt.";
    begin
        AKSAVectorSearchMgt.UpdateItemEmbeddings(Item);
    end;

    local procedure BuildPromptCatalogue(var Item: Record Item; SkipCount: Integer; MaxCount: Integer): Text
    var
        CatalogueObject: JsonObject;
        ItemArray: JsonArray;
        CatalogueText: Text;
        AddedCount: Integer;
        CurrentIndex: Integer;
    begin
        CurrentIndex := 0;

        if Item.FindSet() then
            repeat
                if CurrentIndex >= SkipCount then begin
                    AddPromptItem(ItemArray, Item);
                    AddedCount += 1;
                end;

                CurrentIndex += 1;
            until (Item.Next() = 0) or ((MaxCount > 0) and (AddedCount >= MaxCount));

        CatalogueObject.Add('catalogname', 'item');
        CatalogueObject.Add('data', ItemArray);
        CatalogueObject.WriteTo(CatalogueText);
        exit(CatalogueText);
    end;

    local procedure BuildSearchUploadPayload(var Item: Record Item): Text
    var
        PayloadObject: JsonObject;
        ItemArray: JsonArray;
        PayloadText: Text;
    begin
        if Item.FindSet() then
            repeat
                AddSearchUploadItem(ItemArray, Item);
            until Item.Next() = 0;

        PayloadObject.Add('value', ItemArray);
        PayloadObject.WriteTo(PayloadText);
        exit(PayloadText);
    end;

    local procedure AddPromptItem(var ItemArray: JsonArray; var Item: Record Item)
    var
        ItemObject: JsonObject;
    begin
        Item.CalcFields(Inventory);

        ItemObject.Add('no', Item."No.");
        ItemObject.Add('dsc', CleanText(Item.Description));
        ItemObject.Add('uom', Item."Base Unit of Measure");
        ItemObject.Add('inventory', Item.Inventory);
        ItemArray.Add(ItemObject);
    end;

    local procedure AddSearchUploadItem(var ItemArray: JsonArray; var Item: Record Item)
    var
        EmbeddingArray: JsonArray;
        ItemObject: JsonObject;
        EmbeddingText: Text;
    begin
        ItemObject.Add('@search.action', 'upload');
        ItemObject.Add('no', Item."No.");
        ItemObject.Add('dsc', CleanText(Item.Description));
        ItemObject.Add('uom', Item."Base Unit of Measure");

        EmbeddingText := Item.AKSAGetObjectEmbeddingData();
        if EmbeddingText <> '' then begin
            EmbeddingArray.ReadFrom(EmbeddingText);
            ItemObject.Add('dsc_v', EmbeddingArray);
        end;

        ItemArray.Add(ItemObject);
    end;

    local procedure CleanText(InputText: Text): Text
    begin
        exit(DelChr(InputText.Trim(), '=', '"'));
    end;
}
