page 57101 "AKSA Draft Document Subform"
{
    ApplicationArea = All;
    Caption = 'AKSA Draft Document Subform';
    PageType = ListPart;
    SourceTable = "AKSA Draft Document Line";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Document No."; Rec."Document No.")
                {
                    ToolTip = 'Specifies the value of the Document No. field.', Comment = '%';
                    Visible = false;
                }
                field("Line No."; Rec."Line No.")
                {
                    ToolTip = 'Specifies the value of the Line No. field.', Comment = '%';
                }
                field("Item No."; Rec."Item No.")
                {
                    ToolTip = 'Specifies the value of the Item No. field.', Comment = '%';

                    trigger OnAssistEdit()
                    var
                        AKSADraftDocLineItem: Record "AKSA Draft Doc. Line Item";
                        PageAKSADraftDocLineItems: Page "AKSA Draft Doc. Line Items";
                    begin
                        AKSADraftDocLineItem.FilterGroup(2);
                        AKSADraftDocLineItem.SetRange("Document No.", Rec."Document No.");
                        AKSADraftDocLineItem.SetRange("Line No.", Rec."Line No.");
                        AKSADraftDocLineItem.FilterGroup(0);

                        PageAKSADraftDocLineItems.LookupMode(true);
                        PageAKSADraftDocLineItems.SetTableView(AKSADraftDocLineItem);
                        if PageAKSADraftDocLineItems.RunModal() <> Action::LookupOK then
                            exit;

                        PageAKSADraftDocLineItems.GetRecord(AKSADraftDocLineItem);
                        Rec.Validate("Item No.", AKSADraftDocLineItem."Item No.");
                        Rec.Modify();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the value of the Description field.', Comment = '%';
                }
                field("Input Description"; Rec."Input Description")
                {
                    ToolTip = 'Specifies the value of the Input Description field.', Comment = '%';
                }
                field(Quantity; Rec.Quantity)
                {
                    ToolTip = 'Specifies the value of the Quantity field.', Comment = '%';
                }
                field(Reviewed; Rec.Reviewed)
                {
                    ToolTip = 'Specifies that the user has reviewed and accepted this AI-suggested line.';
                }
            }
        }
    }
}
