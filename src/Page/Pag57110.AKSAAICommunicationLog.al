page 57110 "AKSA AI Communication Log"
{
    ApplicationArea = All;
    Caption = 'AKSA AI Communication Log';
    Editable = false;
    PageType = List;
    SourceTable = "AKSA Open AI Communication Log";
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ToolTip = 'Specifies the log entry number.';
                }
                field(Type; Rec.Type)
                {
                    ToolTip = 'Specifies the integration type.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the integration step that was logged.';
                }
                field("Status Code"; Rec."Status Code")
                {
                    ToolTip = 'Specifies the HTTP status code returned by the external service.';
                }
                field("Created At"; Rec."Created At")
                {
                    ToolTip = 'Specifies when the integration step was logged.';
                }
                field("Request Body"; Rec."Request Body".HasValue())
                {
                    Caption = 'Request Body';
                    ToolTip = 'Specifies whether the request body was logged.';

                    trigger OnAssistEdit()
                    var
                        AKSAAITextEditor: Page "AKSA AI Text Editor";
                    begin
                        AKSAAITextEditor.SetText(Rec.GetRequestBodyText());
                        AKSAAITextEditor.RunModal();
                    end;
                }
                field("Response Body"; Rec."Response Body".HasValue())
                {
                    Caption = 'Response Body';
                    ToolTip = 'Specifies whether the response body was logged.';

                    trigger OnAssistEdit()
                    var
                        AKSAAITextEditor: Page "AKSA AI Text Editor";
                    begin
                        AKSAAITextEditor.SetText(Rec.GetResponseBodyText());
                        AKSAAITextEditor.RunModal();
                    end;
                }
            }
        }
    }
}
