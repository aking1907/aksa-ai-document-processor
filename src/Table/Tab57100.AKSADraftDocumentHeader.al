table 57100 "AKSA Draft Document Header"
{
    Caption = 'AKSA Draft Document Header';
    DataClassification = CustomerContent;
    DrillDownPageId = "AKSA Draft Document List";
    LookupPageId = "AKSA Draft Document List";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(2; Type; Enum "AKSA Draft Document Type")
        {
            Caption = 'Type';
        }
        field(3; "Contact Name"; Text[100])
        {
            Caption = 'Contact Name';
        }
        field(4; "Excel Desc. Column No."; Integer)
        {
            Caption = 'Excel Desc. Column No.';
            MinValue = 0;
            MaxValue = 100;
        }
        field(5; "Excel Quantity Column No."; Integer)
        {
            Caption = 'Excel Quantity Column No.';
            MinValue = 0;
            MaxValue = 100;
        }
        field(6; "AI Prompt Template No."; Code[20])
        {
            TableRelation = "AKSA AI Prompt Template Header";
            Caption = 'AI Prompt Template No.';
        }
        field(7; "Document Data"; Blob)
        {
            Caption = 'Document Data';
        }
        field(8; "AI Response"; Blob)
        {
            Caption = 'AI Response';
        }
    }
    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
    }

    procedure GetDocumentDataText() TextResponse: Text;
    var
        InStream: InStream;
    begin
        Rec.CalcFields("Document Data");
        Rec."Document Data".CreateInStream(InStream);
        InStream.Read(TextResponse);
    end;

    procedure SetDocumentDataText(InputText: Text)
    var
        OutStream: OutStream;
    begin
        Rec."Document Data".CreateOutStream(OutStream);
        OutStream.Write(InputText);
        Rec.Modify();
    end;

    procedure GetAIResponseText() TextResponse: Text
    var
        InStream: InStream;
    begin
        Rec.CalcFields("AI Response");
        Rec."AI Response".CreateInStream(InStream);
        InStream.Read(TextResponse);
    end;

    procedure SetAIResponseText(InputText: Text)
    var
        OutStream: OutStream;
    begin
        Rec."AI Response".CreateOutStream(OutStream);
        OutStream.Write(InputText);
        Rec.Modify();
    end;

    procedure ProcessWithAI()
    var
        AKSAOpenAIManagement: Codeunit "AKSA Open AI Management";
    begin
        AKSAOpenAIManagement.ProcessWithOpenAI(Rec);
    end;
}
