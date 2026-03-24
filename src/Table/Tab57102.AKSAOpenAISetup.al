table 57102 "AKSA Open AI Setup"
{
    Caption = 'AKSA Open AI Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[10])
        {
            Caption = 'No.';
        }
        field(2; "Open AI Key"; Text[1024])
        {
            Caption = 'Open AI Api-Key';
        }
        field(5; "Open AI URL"; Text[100])
        {
            Caption = 'Open AI URL';
        }
        field(6; "Open AI Model URL"; Text[100])
        {
            Caption = 'Open AI Model URL';
        }
        field(7; "Open AI Model"; Text[20])
        {
            Caption = 'Open AI Model';
        }
        field(8; "Item Catalogue Batch Size"; Integer)
        {
            Caption = 'Item Catalogue Batch Size';
        }
        field(77777; "Temp Blob"; Blob)
        {
            Caption = 'Temp Blob';
        }

    }
    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
    }

    procedure SetTempBlob(InputText: Text)
    var
        OutStream: OutStream;
    begin
        Rec."Temp Blob".CreateOutStream(OutStream);
        OutStream.WriteText(InputText);
    end;

    procedure GetTempBlob(): Text
    var
        InStream: InStream;
        ResultText: Text;
    begin
        if not Rec."Temp Blob".HasValue() then
            exit('');

        Rec."Temp Blob".CreateInStream(InStream);
        InStream.ReadText(ResultText);
        exit(ResultText);
    end;
}
