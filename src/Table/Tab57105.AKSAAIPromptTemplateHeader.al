table 57105 "AKSA AI Prompt Template Header"
{
    Caption = 'AKSA AI Prompt Templ. Header';
    DataClassification = CustomerContent;
    LookupPageId = "AKSA AI Prompt Templates";
    DrillDownPageId = "AKSA AI Prompt Templates";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(3; Description; Text[250])
        {
            Caption = 'Description';
        }
    }
    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
    }
}
