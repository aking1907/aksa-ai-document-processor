page 57109 "AKSA AI Text Editor"
{
    Caption = 'AKSA AI Text Editor';
    PageType = StandardDialog;
    ApplicationArea = All;

    layout
    {
        area(content)
        {
            group(EntityTextGroup)
            {
                ShowCaption = false;
                field(EntityTextContent; EntityTextContent)
                {
                    MultiLine = true;
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the EntityTextContent field.';
                    ShowCaption = false;
                    StyleExpr = false;
                }
            }
        }
    }

    procedure SetText(InputText: Text)
    begin
        EntityTextContent := InputText;
    end;

    procedure GetText(): Text
    begin
        exit(EntityTextContent);
    end;

    var
        EntityTextContent: Text;
}