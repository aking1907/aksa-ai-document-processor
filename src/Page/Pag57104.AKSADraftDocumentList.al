page 57104 "AKSA Draft Document List"
{
    ApplicationArea = All;
    Caption = 'AKSA Draft Document List';
    PageType = List;
    SourceTable = "AKSA Draft Document Header";
    UsageCategory = Lists;
    CardPageId = "AKSA Draft Document";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("No."; Rec."No.")
                {
                    ToolTip = 'Specifies the value of the Document No. field.', Comment = '%';
                }
                field("Contact Name"; Rec."Contact Name")
                {
                    ToolTip = 'Specifies the value of the Contact Name field.', Comment = '%';
                }
                field(Type; Rec."Type")
                {
                    ToolTip = 'Specifies the value of the Type field.', Comment = '%';
                }
                field("AI Prompt Template No."; Rec."AI Prompt Template No.")
                {
                    ToolTip = 'Specifies the value of the AI Prompt Template No. field.', Comment = '%';
                }
                field(SystemCreatedBy; GetUserNameFromSecurityId(Rec.SystemCreatedBy))
                {
                    Caption = 'Created By';
                    ToolTip = 'Specifies the value of the SystemCreatedBy field.', Comment = '%';
                }
                field(SystemCreatedAt; Rec.SystemCreatedAt)
                {
                    ToolTip = 'Specifies the value of the SystemCreatedAt field.', Comment = '%';
                }
            }
        }
    }

    local procedure GetUserNameFromSecurityId(UserSecurityID: Guid): Code[50]
    var
        User: Record User;
    begin
        User.Get(UserSecurityID);
        exit(User."User Name");
    end;
}
