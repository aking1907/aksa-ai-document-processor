table 57107 "AKSA Open AI Communication Log"
{
    Caption = 'AKSA Open AI Communication Log';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; Type; Text[20])
        {
            Caption = 'Type';
        }
        field(3; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(4; "Request Body"; Blob)
        {
            Caption = 'Request Body';
        }
        field(5; "Response Body"; Blob)
        {
            Caption = 'Response Body';
        }
    }
    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}
