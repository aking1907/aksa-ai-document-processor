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
        field(9; "Catalogue Size Threshold"; Integer)
        {
            Caption = 'Catalogue Size Threshold';
            InitValue = 1000;
            MinValue = 1;
        }
        field(10; "Document Intelligence URL"; Text[250])
        {
            Caption = 'Document Intelligence URL';
        }
        field(11; "Document Intelligence Key"; Text[1024])
        {
            Caption = 'Document Intelligence Key';
        }
        field(12; "Azure AI Search URL"; Text[250])
        {
            Caption = 'Azure AI Search URL';
        }
        field(13; "Azure AI Search Key"; Text[1024])
        {
            Caption = 'Azure AI Search Key';
        }
        field(14; "Azure AI Search Index Name"; Text[100])
        {
            Caption = 'Azure AI Search Index Name';
        }
        field(15; "Azure AI Search Api Version"; Text[20])
        {
            Caption = 'Azure AI Search Api Version';
            InitValue = '2024-07-01';
        }
        field(16; "Vector Result Count"; Integer)
        {
            Caption = 'Vector Result Count';
            InitValue = 25;
            MinValue = 1;
        }
        field(17; "Open AI Embedding URL"; Text[250])
        {
            Caption = 'Open AI Embedding URL';
        }
        field(18; "Open AI Embedding Key"; Text[1024])
        {
            Caption = 'Open AI Embedding Key';
        }
        field(19; "Open AI Embedding Model"; Text[50])
        {
            Caption = 'Open AI Embedding Model';
        }
        field(20; "Default Prompt Template No."; Code[20])
        {
            Caption = 'Default Prompt Template No.';
            TableRelation = "AKSA AI Prompt Template Header";
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

    procedure SetDefaultValues()
    begin
        if Rec."Catalogue Size Threshold" = 0 then
            Rec."Catalogue Size Threshold" := 1000;

        if Rec."Vector Result Count" = 0 then
            Rec."Vector Result Count" := 25;

        if Rec."Azure AI Search Api Version" = '' then
            Rec."Azure AI Search Api Version" := '2024-07-01';

        if Rec."Default Prompt Template No." = '' then
            Rec."Default Prompt Template No." := GetDefaultPromptTemplateNo();
    end;

    procedure GetOrCreate()
    begin
        if not Rec.Get() then begin
            Rec.Init();
            Rec.SetDefaultValues();
            Rec.Insert(true);
            exit;
        end;

        Rec.SetDefaultValues();
        Rec.Modify(true);
    end;

    procedure GetDefaultPromptTemplateNo(): Code[20]
    begin
        exit('DEFAULT');
    end;
}
