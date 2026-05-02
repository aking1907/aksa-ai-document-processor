table 57101 "AKSA Draft Document Line"
{
    Caption = 'AKSA Draft Document Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "AKSA Draft Document Header";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = "Item";

            trigger OnValidate()
            var
                Item: Record Item;
            begin
                Rec.Description := '';
                if Item.Get(Rec."Item No.") then
                    Rec.Description := Item.Description;

                Rec.Reviewed := false;
            end;
        }
        field(4; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(5; "Input Description"; Text[500])
        {
            Caption = 'Input Description';
        }
        field(6; Quantity; Decimal)
        {
            Caption = 'Quantity';

            trigger OnValidate()
            begin
                Rec.Reviewed := false;
            end;
        }
        field(7; Reviewed; Boolean)
        {
            Caption = 'Reviewed';
        }
    }
    keys
    {
        key(PK; "Document No.", "Line No.")
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    var
        AKSADraftDocLineItem: Record "AKSA Draft Doc. Line Item";
    begin
        EnsureDraftCanChange();

        AKSADraftDocLineItem.SetRange("Document No.", Rec."Document No.");
        AKSADraftDocLineItem.SetRange("Line No.", Rec."Line No.");
        if AKSADraftDocLineItem.FindSet() then
            AKSADraftDocLineItem.DeleteAll();
    end;

    trigger OnModify()
    begin
        EnsureDraftCanChange();
    end;

    local procedure EnsureDraftCanChange()
    var
        AKSADraftDocumentHeader: Record "AKSA Draft Document Header";
    begin
        if Rec."Document No." = '' then
            exit;

        if not AKSADraftDocumentHeader.Get(Rec."Document No.") then
            exit;

        if AKSADraftDocumentHeader.Status = AKSADraftDocumentHeader.Status::Converted then
            Error('Converted draft documents cannot be changed.');

        if AKSADraftDocumentHeader.Status = AKSADraftDocumentHeader.Status::Approved then
            AKSADraftDocumentHeader.MarkAISuggested();
    end;
}
