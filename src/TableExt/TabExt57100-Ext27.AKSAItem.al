tableextension 57100 "AKSA Item" extends Item //27
{
    fields
    {
        field(57100; "AKSA Object Embedding Data"; Blob)
        {
            Caption = 'AKSA Object Embedding Data';
            DataClassification = CustomerContent;
        }
        field(57101; "AKSA Indexed"; Boolean)
        {
            Caption = 'AKSA Indexed';
            DataClassification = CustomerContent;
        }
    }

    procedure AKSASetObjectEmbeddingData(InputText: Text)
    var
        OutStream: OutStream;
    begin
        Rec."AKSA Object Embedding Data".CreateOutStream(OutStream);
        OutStream.WriteText(InputText);
    end;

    procedure AKSAGetObjectEmbeddingData(): Text
    var
        InStream: InStream;
        ResultText: Text;
    begin
        Rec.CalcFields("AKSA Object Embedding Data");
        if not Rec."AKSA Object Embedding Data".HasValue() then
            exit('');

        Rec."AKSA Object Embedding Data".CreateInStream(InStream);
        InStream.ReadText(ResultText);
        exit(ResultText);
    end;

}
