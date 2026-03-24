page 57107 "AKSA AI Prompt Template Lines"
{
    ApplicationArea = All;
    Caption = 'AKSA AI Prompt Template Lines';
    PageType = ListPart;
    SourceTable = "AKSA AI Prompt Template Line";

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
                field(Active; Rec.Active)
                {
                    ToolTip = 'Specifies the value of the Active field.', Comment = '%';
                }
                field("AI Request Type"; Rec."AI Request Type")
                {
                    ToolTip = 'Specifies the value of the AI Request Type field.', Comment = '%';
                }
                field("Prompt Desc."; Rec."Prompt Desc.")
                {
                    ToolTip = 'Specifies the value of the Prompt Desc. field.', Comment = '%';
                }
                field("AI Prompt"; Rec."AI Prompt")
                {
                    ToolTip = 'Specifies the value of the AI Prompt field.', Comment = '%';
                    trigger OnAssistEdit()
                    var
                        AKSAAITextEditor: Page "AKSA AI Text Editor";
                    begin
                        AKSAAITextEditor.SetText(Rec."AI Prompt");
                        if AKSAAITextEditor.RunModal() = Action::OK then
                            Rec."AI Prompt" := AKSAAITextEditor.GetText();
                    end;
                }
            }
        }
    }
}
