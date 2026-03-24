table 57106 "AKSA AI Prompt Template Line"
{
    Caption = 'AKSA AI Prompt Templ. Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "AI Prompt"; Text[2048])
        {
            Caption = 'AI Prompt';
        }
        field(4; "Prompt Desc."; Text[250])
        {
            Caption = 'Prompt Desc.';
        }
        field(5; Active; Boolean)
        {
            Caption = 'Active';
            InitValue = true;
        }
        field(6; "AI Request Type"; Enum "AKSA AI Request Type")
        {
            Caption = 'AI Request Type';
        }
    }
    keys
    {
        key(PK; "Document No.", "Line No.")
        {
            Clustered = true;
        }
    }
}
