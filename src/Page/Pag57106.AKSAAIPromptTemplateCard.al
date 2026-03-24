page 57106 "AKSA AI Prompt Template Card"
{
    ApplicationArea = All;
    Caption = 'AKSA AI Prompt Template Card';
    PageType = Card;
    SourceTable = "AKSA AI Prompt Template Header";

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

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
                    MultiLine = true;
                }
            }
            part(AKSAAIPromptTemplateLines; "AKSA AI Prompt Template Lines")
            {
                ApplicationArea = All;
                UpdatePropagation = Both;
                SubPageLink = "Document No." = field("No.");
            }
        }
    }
}
