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
        AKSADraftDocLineItem.SetRange("Document No.", Rec."Document No.");
        AKSADraftDocLineItem.SetRange("Line No.", Rec."Line No.");
        if AKSADraftDocLineItem.FindSet() then
            AKSADraftDocLineItem.DeleteAll();
    end;
}
