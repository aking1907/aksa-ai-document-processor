page 57105 "AKSA AI Prompt Templates"
{
    ApplicationArea = All;
    Caption = 'AKSA AI Prompt Templates';
    PageType = List;
    SourceTable = "AKSA AI Prompt Template Header";
    UsageCategory = Administration;
    Editable = false;
    CardPageId = "AKSA AI Prompt Template Card";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("No."; Rec."No.")
                {
                    ToolTip = 'Specifies the value of the No. field.', Comment = '%';
                }
                field(Name; Rec.Name)
                {
                    ToolTip = 'Specifies the value of the Name field.', Comment = '%';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the value of the Description field.', Comment = '%';
                }
            }
        }
    }
}
