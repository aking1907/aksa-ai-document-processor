report 57100 "AKSA Excel To Json"
{
    ApplicationArea = All;
    Caption = 'AKSA Excel To Json';
    ProcessingOnly = true;
    // DefaultLayout = RDLC;
    // UsageCategory = Administration;

    dataset
    {
        dataitem(IntegerRecord; "Integer")
        {
            DataItemTableView = sorting(number);
            trigger OnPreDataItem()
            begin
                IntegerRecord.SetRange(Number, 1);

                IntegerRecord.SetRange(Number, 1, TotalRowsCount + 1);
            end;

            trigger OnAfterGetRecord()
            begin
                ProcessRecord(Number);
            end;

            trigger OnPostDataItem()
            begin
                RecordToJson();
            end;
        }
    }
    requestpage
    {
        layout
        {
            area(content)
            {
                field(ServerFileName; ExcelServerFileName)
                {
                    ApplicationArea = All;
                    Caption = 'File Name';
                    ToolTip = 'Specifies the File Name field.';

                    trigger OnAssistEdit()
                    begin
                        if not UploadIntoStream(UploadExcelMsg, '', 'Excel Files (*.xlsx)|*.xlsx', FromServerFileName, InStream) then
                            exit;

                        if FromServerFileName <> '' then
                            ExcelServerFileName := FileManagement.GetFileName(FromServerFileName)
                        else
                            Error(FileDoesNotExistErr);
                    end;

                }
                field(SheetName; ExcelSheetName)
                {
                    ApplicationArea = All;
                    Caption = 'Sheet Name';
                    ToolTip = 'Specifies the Sheet Name field.';

                    trigger OnAssistEdit()
                    begin
                        ExcelSheetName := TempExcelBuffer.SelectSheetsNameStream(InStream);
                        if ExcelSheetName = '' then
                            Error('Sheet name is required.');
                    end;

                }
            }
        }
        actions
        {
            area(processing)
            {
            }
        }
    }

    var

        AKSAFreeData: Record "AKSA Free Data";
        TempExcelBuffer: Record "Excel Buffer" temporary;
        FileManagement: Codeunit "File Management";
        GlobalJsonObject: JsonObject;
        GlobalStartColumnsIndex: Integer;
        GlobalEndColumnsIndex: Integer;
        GlobalDescriptionColumnNo: Integer;
        GlobalQuantityColumnNo: Integer;
        TotalRowsCount: Integer;
        ErrorMessage: Text;
        ExcelSheetName: Text;
        ExcelServerFileName: Text;
        FromServerFileName: Text;
        InStream: InStream;
        UploadExcelMsg: Label 'Import File';
        FileDoesNotExistErr: Label 'File does not exist!';

    trigger OnPreReport()
    begin

        ErrorMessage := TempExcelBuffer.OpenBookStream(InStream, ExcelSheetName);
        if ErrorMessage <> '' then
            Error(ErrorMessage);

        TempExcelBuffer.ReadSheet();

        TempExcelBuffer.FindFirst();
        TempExcelBuffer.SetFilter("Row No.", '<>1');
        TempExcelBuffer.SetRange("Column No.", TempExcelBuffer."Column No.");
        TotalRowsCount := TempExcelBuffer.Count;
        TempExcelBuffer.Reset();
    end;

    procedure SetParams(ExcelDescriptionColumnNo: Integer; ExcelQuantityColumnNo: Integer)
    begin
        if ExcelDescriptionColumnNo > 0 then
            GlobalDescriptionColumnNo := ExcelDescriptionColumnNo + 10;

        if ExcelQuantityColumnNo > 0 then
            GlobalQuantityColumnNo := ExcelQuantityColumnNo + 10;
    end;

    local procedure GetFieldValue(RowNo: Integer; ColumnNo: Integer): Text[250]
    begin
        if TempExcelBuffer.Get(RowNo, ColumnNo) then
            exit(DelChr(TempExcelBuffer."Cell Value as Text", '=', ','));

        exit('');
    end;


    local procedure ProcessRecord(RowNo: Integer)
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        TextVar: Text[250];
        i: Integer;
        j: Integer;
        isEmptyLine: Boolean;
        NextEntryNo: Integer;
    begin
        TextVar := '';
        isEmptyLine := true;
        RecordRef.Open(Database::"AKSA Free Data");

        for i := 1 to 50 do begin
            j := i + 10;
            FieldRef := RecordRef.Field(j);
            TextVar := GetFieldValue(RowNo, i);
            if TextVar <> '' then begin
                isEmptyLine := false;
                FieldRef.Value := TextVar;

                if (GlobalStartColumnsIndex = 0) or (GlobalStartColumnsIndex > j) then
                    GlobalStartColumnsIndex := j;

                if GlobalEndColumnsIndex < j then
                    GlobalEndColumnsIndex := j;
            end;
        end;

        if not isEmptyLine then begin
            Clear(AKSAFreeData);
            AKSAFreeData.Init();
            NextEntryNo := 1;
            if AKSAFreeData.FindLast() then
                NextEntryNo := AKSAFreeData."Entry No." + 1;

            RecordRef.SetTable(AKSAFreeData);
            AKSAFreeData."Entry No." := NextEntryNo;
            AKSAFreeData.Insert(true);
        end;
    end;

    local procedure RecordToJson()
    var
        TypeHelper: Codeunit "Type Helper";
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        ExcelQty: Decimal;
        ExcelDesc: Text[250];
        ExcelQtyText: Text[250];
        i: Integer;
        JsonArray: JsonArray;
        JsonObject: JsonObject;
        Variant: Variant;
    begin
        RecordRef.Open(Database::"AKSA Free Data");
        if GlobalStartColumnsIndex = 0 then
            exit;

        if (GlobalDescriptionColumnNo > 0) and (GlobalQuantityColumnNo > 0) then begin
            if AKSAFreeData.FindSet() then
                repeat
                    Clear(ExcelDesc);
                    Clear(ExcelQtyText);
                    Clear(ExcelQty);
                    RecordRef.GetTable(AKSAFreeData);

                    for i := GlobalStartColumnsIndex to GlobalEndColumnsIndex do begin
                        FieldRef := RecordRef.Field(i);

                        if i = GlobalDescriptionColumnNo then
                            ExcelDesc := CopyStr(Format(FieldRef.Value), 1, MaxStrLen(ExcelDesc));

                        if i = GlobalQuantityColumnNo then begin
                            ExcelQtyText := CopyStr(Format(FieldRef.Value), 1, MaxStrLen(ExcelQtyText));
                            Variant := ExcelQty;
                            TypeHelper.Evaluate(Variant, ExcelQtyText, '', '');
                            ExcelQty := Variant;
                        end;
                    end;

                    if (ExcelDesc <> '') and (ExcelQty > 0) then begin
                        JsonObject.Add('dsc', ExcelDesc);
                        JsonObject.Add('qty', ExcelQty);
                        JsonArray.Add(JsonObject);
                    end;
                    Clear(JsonObject);
                until AKSAFreeData.Next() = 0;
        end else
            if AKSAFreeData.FindSet() then
                repeat
                    RecordRef.GetTable(AKSAFreeData);
                    for i := GlobalStartColumnsIndex to GlobalEndColumnsIndex do begin
                        FieldRef := RecordRef.Field(i);
                        JsonObject.Add(LowerCase(FieldRef.Name), CopyStr(Format(FieldRef.Value), 1, 250));
                    end;

                    JsonArray.Add(JsonObject);
                    Clear(JsonObject);
                until AKSAFreeData.Next() = 0;

        if JsonArray.Count > 0 then
            GlobalJsonObject.Add('data', JsonArray);
    end;

    procedure GetDataJson(): JsonObject
    begin
        exit(GlobalJsonObject);
    end;

    procedure GetDataText(): Text
    var
        TextVar: Text;
    begin
        GlobalJsonObject.WriteTo(TextVar);
        exit(TextVar);
    end;
}
