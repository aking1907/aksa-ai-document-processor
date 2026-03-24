table 57108 "AKSA Draft Doc. Line Item"
{
    Caption = 'AKSA Draft Doc. Line Item';
    DataClassification = CustomerContent;
    LookupPageId = "AKSA Draft Doc. Line Items";
    DrillDownPageId = "AKSA Draft Doc. Line Items";

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
        field(5; Inventory; Decimal)
        {
            CalcFormula = sum("Item Ledger Entry".Quantity where("Item No." = field("Item No.")));
            Caption = 'Inventory';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
    }
    keys
    {
        key(PK; "Document No.", "Line No.", "Item No.")
        {
            Clustered = true;
        }
    }
}
