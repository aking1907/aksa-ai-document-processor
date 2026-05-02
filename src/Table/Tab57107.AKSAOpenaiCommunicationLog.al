table 57107 "AKSA Open AI Communication Log"
{
    Caption = 'AKSA Open AI Communication Log';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
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
        field(6; "Created At"; DateTime)
        {
            Caption = 'Created At';
        }
        field(7; "Status Code"; Integer)
        {
            Caption = 'Status Code';
        }
    }
    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }

    procedure GetRequestBodyText() RequestBodyText: Text
    var
        InStream: InStream;
    begin
        Rec.CalcFields("Request Body");
        if not Rec."Request Body".HasValue() then
            exit('');

        Rec."Request Body".CreateInStream(InStream);
        InStream.ReadText(RequestBodyText);
    end;

    procedure GetResponseBodyText() ResponseBodyText: Text
    var
        InStream: InStream;
    begin
        Rec.CalcFields("Response Body");
        if not Rec."Response Body".HasValue() then
            exit('');

        Rec."Response Body".CreateInStream(InStream);
        InStream.ReadText(ResponseBodyText);
    end;
}
