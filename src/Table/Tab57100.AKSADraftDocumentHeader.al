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

            trigger OnValidate()
            begin
                ResetApproval();
                Rec.Status := Rec.Status::Open;
            end;
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
        field(9; "Source File Name"; Text[250])
        {
            Caption = 'Source File Name';
        }
        field(10; "Processing Pattern"; Text[30])
        {
            Caption = 'Processing Pattern';
            Editable = false;
        }
        field(11; Status; Enum "AKSA Draft Document Status")
        {
            Caption = 'Status';
            Editable = false;
        }
        field(12; "Approved By"; Code[50])
        {
            Caption = 'Approved By';
            Editable = false;
        }
        field(13; "Approved At"; DateTime)
        {
            Caption = 'Approved At';
            Editable = false;
        }
        field(14; "Quote No."; Code[20])
        {
            Caption = 'Quote No.';
            Editable = false;
        }
        field(15; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;

            trigger OnValidate()
            var
                Customer: Record Customer;
            begin
                if Customer.Get(Rec."Customer No.") then
                    Rec."Contact Name" := Customer.Name;

                ResetApproval();
                Rec.Status := Rec.Status::Open;
            end;
        }
        field(16; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;

            trigger OnValidate()
            var
                Vendor: Record Vendor;
            begin
                if Vendor.Get(Rec."Vendor No.") then
                    Rec."Contact Name" := Vendor.Name;

                ResetApproval();
                Rec.Status := Rec.Status::Open;
            end;
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
        if not Rec."Document Data".HasValue() then
            exit('');

        Rec."Document Data".CreateInStream(InStream);
        InStream.ReadText(TextResponse);
    end;

    procedure SetDocumentDataText(InputText: Text)
    var
        OutStream: OutStream;
    begin
        Rec."Document Data".CreateOutStream(OutStream);
        OutStream.WriteText(InputText);
        ResetApproval();
        Rec.Modify();
    end;

    procedure GetAIResponseText() TextResponse: Text
    var
        InStream: InStream;
    begin
        Rec.CalcFields("AI Response");
        if not Rec."AI Response".HasValue() then
            exit('');

        Rec."AI Response".CreateInStream(InStream);
        InStream.ReadText(TextResponse);
    end;

    procedure SetAIResponseText(InputText: Text)
    var
        OutStream: OutStream;
    begin
        Rec."AI Response".CreateOutStream(OutStream);
        OutStream.WriteText(InputText);
        Rec.Modify();
    end;

    procedure ProcessWithAI()
    var
        AKSAAIDocumentProcessor: Codeunit "AKSA AI Document Processor";
    begin
        AKSAAIDocumentProcessor.ProcessDraftDocument(Rec);
    end;

    procedure ApproveDraft()
    begin
        EnsureLinesReviewed();

        Rec.Status := Rec.Status::Approved;
        Rec."Approved By" := CopyStr(UserId(), 1, MaxStrLen(Rec."Approved By"));
        Rec."Approved At" := CurrentDateTime();
        Rec.Modify(true);
    end;

    procedure ReopenDraft()
    begin
        if Rec.Status = Rec.Status::Converted then
            Error('Converted draft documents cannot be reopened.');

        ResetApproval();
        Rec.Status := Rec.Status::Open;
        Rec.Modify(true);
    end;

    procedure MarkAISuggested()
    begin
        ResetApproval();
        Rec.Status := Rec.Status::"AI Suggested";
        Rec.Modify(true);
    end;

    procedure MarkConverted(QuoteNo: Code[20])
    begin
        Rec.Status := Rec.Status::Converted;
        Rec."Quote No." := QuoteNo;
        Rec.Modify(true);
    end;

    local procedure EnsureLinesReviewed()
    var
        AKSADraftDocumentLine: Record "AKSA Draft Document Line";
    begin
        Rec.TestField("No.");
        EnsureQuoteAccountSelected();

        AKSADraftDocumentLine.SetRange("Document No.", Rec."No.");
        if not AKSADraftDocumentLine.FindSet() then
            Error('The draft document has no lines to approve.');

        repeat
            AKSADraftDocumentLine.TestField("Item No.");
            if AKSADraftDocumentLine.Quantity <= 0 then
                Error('Quantity must be greater than zero on line %1.', AKSADraftDocumentLine."Line No.");

            if not AKSADraftDocumentLine.Reviewed then
                Error('Line %1 must be reviewed before the draft can be approved.', AKSADraftDocumentLine."Line No.");
        until AKSADraftDocumentLine.Next() = 0;
    end;

    local procedure EnsureQuoteAccountSelected()
    begin
        case Rec.Type of
            Rec.Type::Sales,
            Rec.Type::Service:
                Rec.TestField("Customer No.");
            Rec.Type::Purchase:
                Rec.TestField("Vendor No.");
        end;
    end;

    local procedure ResetApproval()
    begin
        if Rec.Status = Rec.Status::Converted then
            Error('Converted draft documents cannot be changed.');

        Clear(Rec."Approved By");
        Clear(Rec."Approved At");
        Clear(Rec."Quote No.");
    end;

    trigger OnInsert()
    var
        AKSAOpenAISetup: Record "AKSA Open AI Setup";
        AKSADefaultDataMgt: Codeunit "AKSA Default Data Mgt.";
    begin
        if Rec."AI Prompt Template No." = '' then begin
            AKSADefaultDataMgt.EnsureDefaultPromptTemplate();
            AKSAOpenAISetup.GetOrCreate();
            Rec."AI Prompt Template No." := AKSAOpenAISetup."Default Prompt Template No.";
        end;
    end;
}
