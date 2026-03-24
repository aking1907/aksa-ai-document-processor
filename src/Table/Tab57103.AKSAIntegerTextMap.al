table 57103 "AKSA Integer/Text Map"
{
    Caption = 'AKSA Integer/Text Map';
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; "Key"; Integer)
        {
            Caption = 'Key';
        }
        field(2; Value; Text[250])
        {
            Caption = 'Value';
        }
    }
    keys
    {
        key(PK; "Key")
        {
            Clustered = true;
        }
    }
}
