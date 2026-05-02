codeunit 57102 "AKSA AI Document Processor"
{
    procedure ProcessDraftDocument(var AKSADraftDocumentHeader: Record "AKSA Draft Document Header")
    var
        AKSAOpenAIManagement: Codeunit "AKSA Open AI Management";
        PromptText: Text;
        ResponseText: Text;
    begin
        ValidateDraftDocument(AKSADraftDocumentHeader);

        PromptText := BuildPrompt(AKSADraftDocumentHeader);
        ResponseText := AKSAOpenAIManagement.SendPromptToAI(PromptText);

        AKSADraftDocumentHeader.SetAIResponseText(ResponseText);
        PopulateDraftLines(AKSADraftDocumentHeader, ResponseText);
        AKSADraftDocumentHeader.MarkAISuggested();
    end;

    local procedure ValidateDraftDocument(var AKSADraftDocumentHeader: Record "AKSA Draft Document Header")
    begin
        AKSADraftDocumentHeader.TestField("No.");
        AKSADraftDocumentHeader.TestField("AI Prompt Template No.");
        if AKSADraftDocumentHeader.Status = AKSADraftDocumentHeader.Status::Converted then
            Error('Converted draft documents cannot be processed again.');

        AKSADraftDocumentHeader.CalcFields("Document Data");
        if not AKSADraftDocumentHeader."Document Data".HasValue() then
            Error('Document Data is empty.');
    end;

    local procedure BuildPrompt(var AKSADraftDocumentHeader: Record "AKSA Draft Document Header"): Text
    var
        AKSAAIPromptTemplateLine: Record "AKSA AI Prompt Template Line";
        CatalogueText: Text;
        PromptText: Text;
    begin
        AKSAAIPromptTemplateLine.SetRange("Document No.", AKSADraftDocumentHeader."AI Prompt Template No.");
        AKSAAIPromptTemplateLine.SetRange(Active, true);
        if not AKSAAIPromptTemplateLine.FindSet() then
            Error('AI Prompt Template lines were not found.');

        repeat
            case AKSAAIPromptTemplateLine."AI Request Type" of
                Enum::"AKSA AI Request Type"::Prompt:
                    AppendPromptSection(PromptText, AKSAAIPromptTemplateLine."Prompt Desc.", AKSAAIPromptTemplateLine."AI Prompt");
                Enum::"AKSA AI Request Type"::ItemCatalogue:
                    begin
                        if CatalogueText = '' then
                            CatalogueText := GetCatalogueContext(AKSADraftDocumentHeader);
                        AppendPromptSection(PromptText, 'Item catalogue', CatalogueText);
                    end;
                Enum::"AKSA AI Request Type"::DocumentData:
                    AppendPromptSection(PromptText, 'Document data', AKSADraftDocumentHeader.GetDocumentDataText());
                else
                    Error('Unexpected AI Request Type: %1', AKSAAIPromptTemplateLine."AI Request Type");
            end;
        until AKSAAIPromptTemplateLine.Next() = 0;

        exit(PromptText);
    end;

    local procedure GetCatalogueContext(var AKSADraftDocumentHeader: Record "AKSA Draft Document Header"): Text
    var
        AKSAOpenAISetup: Record "AKSA Open AI Setup";
        AKSAItemCatalogueMgt: Codeunit "AKSA Item Catalogue Mgt.";
        AKSAVectorSearchMgt: Codeunit "AKSA Vector Search Mgt.";
        ItemCount: Integer;
    begin
        AKSAOpenAISetup.GetOrCreate();
        AKSAOpenAISetup.SetDefaultValues();

        ItemCount := AKSAItemCatalogueMgt.GetItemCount();
        if ItemCount <= AKSAOpenAISetup."Catalogue Size Threshold" then begin
            SetProcessingPattern(AKSADraftDocumentHeader, 'Medium catalogue');
            exit(AKSAItemCatalogueMgt.GetItemCatalogue());
        end;

        SetProcessingPattern(AKSADraftDocumentHeader, 'Large catalogue');
        exit(AKSAVectorSearchMgt.GetRelevantItemCatalogue(AKSADraftDocumentHeader.GetDocumentDataText()));
    end;

    local procedure AppendPromptSection(var PromptText: Text; SectionName: Text; SectionValue: Text)
    begin
        if SectionValue = '' then
            exit;

        if PromptText <> '' then
            PromptText += '\';

        if SectionName <> '' then
            PromptText += StrSubstNo('## %1\', SectionName);

        PromptText += SectionValue;
    end;

    local procedure SetProcessingPattern(var AKSADraftDocumentHeader: Record "AKSA Draft Document Header"; ProcessingPattern: Text[30])
    begin
        AKSADraftDocumentHeader."Processing Pattern" := ProcessingPattern;
        AKSADraftDocumentHeader.Modify();
    end;

    local procedure PopulateDraftLines(var AKSADraftDocumentHeader: Record "AKSA Draft Document Header"; ResponseText: Text)
    var
        AKSADraftDocumentLine: Record "AKSA Draft Document Line";
        DataArray: JsonArray;
        LineObject: JsonObject;
        ResponseObject: JsonObject;
        JsonToken: JsonToken;
        JsonText: Text;
        i: Integer;
        LineNo: Integer;
    begin
        JsonText := NormalizeJsonResponse(ResponseText);
        ResponseObject.ReadFrom(JsonText);

        if not ResponseObject.Get('data', JsonToken) then
            Error('AI response does not contain a data array.');

        DataArray := JsonToken.AsArray();

        AKSADraftDocumentLine.SetRange("Document No.", AKSADraftDocumentHeader."No.");
        if not AKSADraftDocumentLine.IsEmpty() then
            AKSADraftDocumentLine.DeleteAll(true);

        LineNo := 10000;
        for i := 0 to DataArray.Count() - 1 do begin
            DataArray.Get(i, JsonToken);
            LineObject := JsonToken.AsObject();
            InsertDraftLine(AKSADraftDocumentHeader, LineObject, LineNo);
            LineNo += 10000;
        end;
    end;

    local procedure InsertDraftLine(var AKSADraftDocumentHeader: Record "AKSA Draft Document Header"; LineObject: JsonObject; LineNo: Integer)
    var
        AKSADraftDocumentLine: Record "AKSA Draft Document Line";
    begin
        AKSADraftDocumentLine.Init();
        AKSADraftDocumentLine."Document No." := AKSADraftDocumentHeader."No.";
        AKSADraftDocumentLine."Line No." := LineNo;
        AKSADraftDocumentLine."Input Description" := CopyStr(GetFirstText(LineObject, 'dsc', 'description'), 1, MaxStrLen(AKSADraftDocumentLine."Input Description"));
        AKSADraftDocumentLine.Quantity := GetDecimal(LineObject, 'qty', 'quantity');
        AKSADraftDocumentLine.Insert(true);

        InsertSuggestedItems(AKSADraftDocumentLine, LineObject);
    end;

    local procedure InsertSuggestedItems(var AKSADraftDocumentLine: Record "AKSA Draft Document Line"; LineObject: JsonObject)
    var
        ItemArray: JsonArray;
        ItemObject: JsonObject;
        JsonToken: JsonToken;
        i: Integer;
    begin
        if LineObject.Get('items', JsonToken) then begin
            ItemArray := JsonToken.AsArray();
            for i := 0 to ItemArray.Count() - 1 do begin
                ItemArray.Get(i, JsonToken);
                ItemObject := JsonToken.AsObject();
                InsertSuggestedItem(AKSADraftDocumentLine, GetFirstText(ItemObject, 'no', 'itemNo'));
            end;
            exit;
        end;

        InsertSuggestedItem(AKSADraftDocumentLine, GetFirstText(LineObject, 'no', 'itemNo'));
    end;

    local procedure InsertSuggestedItem(var AKSADraftDocumentLine: Record "AKSA Draft Document Line"; ItemNo: Text)
    var
        AKSADraftDocLineItem: Record "AKSA Draft Doc. Line Item";
        Item: Record Item;
    begin
        if ItemNo = '' then
            exit;

        if not Item.Get(CopyStr(ItemNo, 1, MaxStrLen(Item."No."))) then
            exit;

        if AKSADraftDocLineItem.Get(AKSADraftDocumentLine."Document No.", AKSADraftDocumentLine."Line No.", Item."No.") then
            exit;

        AKSADraftDocLineItem.Init();
        AKSADraftDocLineItem."Document No." := AKSADraftDocumentLine."Document No.";
        AKSADraftDocLineItem."Line No." := AKSADraftDocumentLine."Line No.";
        AKSADraftDocLineItem.Validate("Item No.", Item."No.");
        AKSADraftDocLineItem.Insert(true);

        if AKSADraftDocumentLine."Item No." = '' then begin
            AKSADraftDocumentLine.Validate("Item No.", Item."No.");
            AKSADraftDocumentLine.Modify(true);
        end;
    end;

    local procedure NormalizeJsonResponse(ResponseText: Text): Text
    var
        EndPosition: Integer;
        StartPosition: Integer;
    begin
        ResponseText := ResponseText.Replace('```json', '');
        ResponseText := ResponseText.Replace('```JSON', '');
        ResponseText := ResponseText.Replace('```', '');
        ResponseText := ResponseText.Trim();

        StartPosition := StrPos(ResponseText, '{');
        EndPosition := FindLastCharacter(ResponseText, '}');
        if (StartPosition > 0) and (EndPosition >= StartPosition) then
            ResponseText := CopyStr(ResponseText, StartPosition, EndPosition - StartPosition + 1);

        exit(ResponseText);
    end;

    local procedure FindLastCharacter(InputText: Text; Character: Text[1]): Integer
    var
        i: Integer;
    begin
        for i := StrLen(InputText) downto 1 do
            if CopyStr(InputText, i, 1) = Character then
                exit(i);

        exit(0);
    end;

    local procedure GetFirstText(JsonObject: JsonObject; FirstFieldName: Text; SecondFieldName: Text): Text
    var
        JsonToken: JsonToken;
    begin
        if JsonObject.Get(FirstFieldName, JsonToken) then
            exit(JsonToken.AsValue().AsText());

        if JsonObject.Get(SecondFieldName, JsonToken) then
            exit(JsonToken.AsValue().AsText());

        exit('');
    end;

    local procedure GetDecimal(JsonObject: JsonObject; FirstFieldName: Text; SecondFieldName: Text): Decimal
    var
        JsonToken: JsonToken;
    begin
        if JsonObject.Get(FirstFieldName, JsonToken) then
            exit(EvaluateDecimal(JsonToken));

        if JsonObject.Get(SecondFieldName, JsonToken) then
            exit(EvaluateDecimal(JsonToken));

        exit(0);
    end;

    local procedure EvaluateDecimal(JsonToken: JsonToken): Decimal
    var
        DecimalValue: Decimal;
    begin
        if Evaluate(DecimalValue, JsonToken.AsValue().AsText()) then
            exit(DecimalValue);

        exit(0);
    end;
}
