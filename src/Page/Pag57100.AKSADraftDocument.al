page 57100 "AKSA Draft Document"
{
    ApplicationArea = All;
    Caption = 'AKSA Draft Document';
    PageType = Card;
    SourceTable = "AKSA Draft Document Header";

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Document No."; Rec."No.")
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
                field("Excel Desc. Column No."; Rec."Excel Desc. Column No.")
                {
                    ToolTip = 'Specifies the value of the Excel Desc. Column No. field.', Comment = '%';
                }
                field("Excel Quantity Column No."; Rec."Excel Quantity Column No.")
                {
                    ToolTip = 'Specifies the value of the Excel Quantity Column No. field.', Comment = '%';
                }
                field("Document Data"; Rec."Document Data".HasValue)
                {
                    ToolTip = 'Specifies the value of the Document Data field.', Comment = '%';
                    DrillDown = false;

                    trigger OnAssistEdit()
                    begin
                        Message(Rec.GetDocumentDataText());
                    end;
                }
                field("AI Response"; Rec."AI Response".HasValue)
                {
                    ToolTip = 'Specifies the value of the AI Response field.', Comment = '%';
                    DrillDown = false;

                    trigger OnAssistEdit()
                    begin
                        Message(Rec.GetAIResponseText());
                    end;
                }
            }
            part(AKDraftDocumentSubform; "AKSA Draft Document Subform")
            {
                ApplicationArea = All;
                UpdatePropagation = Both;
                SubPageLink = "Document No." = field("No.");
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(ProcessWithAI)
            {
                ApplicationArea = All;
                Caption = 'Process with AI';
                Promoted = true;
                PromotedCategory = Process;
                Image = Document;

                trigger OnAction()
                var
                    OpenAIModels: Record "AKSA Integer/Text Map";
                    AKOpenAIManagement: Codeunit "AKSA Open AI Management";
                    AKSAItemCatalogueMgt: Codeunit "AKSA Item Catalogue Mgt.";
                    AKSAExcelToJsonReport: Report "AKSA Excel To Json";
                // Prompt1Lbl: Label 'I will send an Item Catalogue in JSON structure. It will be marked as catalogname:item. Then I will send you a data structure in json format. You will need to try to recognize the item from item catalogue by the free text in data structure. If you are able to recognize the item, you will need to return the item no., description, quantity and uom. If you are not able to recognize the item, you will need to return the item no. empty, but description, quantyty and uom try to recognize from free data structure.The result must be in json format.';
                // Prompt2Lbl: Label 'There is item catalogue: %1';
                // Prompt3Lbl: Label 'There is free data: %1';
                // Prompt4Lbl: Label 'Give me results in json format:{\"data\":[{\"dsc\":\"%1\",\"no\":\"%2\",\"qty\":\"%3\",\"uom\":\"%4\"}]} where %1 is item no from item catalogue if recognized, empty if not. %2 is description from free data structure, it should be combination of data with max length 250. %3 is quantity if recognized from free structure or empty if not. %4 is uom if recognized from free structure or empty if not. Total count of records must be equal to count of records from the free data structure.';
                begin
                    Rec.ProcessWithAI();
                    // Message(AKOpenAIManagement.SendRequestToOpenAI(Prompt1Lbl));
                    // Message(AKOpenAIManagement.SendRequestToOpenAI(StrSubstNo(Prompt2Lbl, AKSAItemCatalogueMgt.GetItemCatalogue())));

                    // AKSAExcelToJsonReport.SetParams(Rec."Excel Desc. Column No.", Rec."Excel Quantity Column No.");
                    // AKSAExcelToJsonReport.RunModal();
                    // Message(AKOpenAIManagement.SendRequestToOpenAI(StrSubstNo(Prompt3Lbl, AKSAExcelToJsonReport.GetDataText())));
                    // Message(AKOpenAIManagement.SendRequestToOpenAI(Prompt4Lbl));
                end;
            }

            // action(InitItemCatalogue)
            // {
            //     ApplicationArea = All;
            //     Caption = 'Init Item Catalogue';
            //     Promoted = true;
            //     PromotedCategory = Process;
            //     Image = Item;

            //     trigger OnAction()
            //     var
            //         AKSAItemCatalogueMgt: Codeunit "AKSA Item Catalogue Mgt.";
            //     begin
            //         Message(AKSAItemCatalogueMgt.GetItemCatalogue());
            //     end;
            // }

            action(ImportFromExcel)
            {
                ApplicationArea = All;
                Caption = 'Import From Excel';
                Promoted = true;
                PromotedCategory = Process;
                Image = Document;

                trigger OnAction()
                var
                    AKSAExcelToJsonReport: Report "AKSA Excel To Json";
                begin
                    AKSAExcelToJsonReport.SetParams(Rec."Excel Desc. Column No.", Rec."Excel Quantity Column No.");
                    AKSAExcelToJsonReport.RunModal();
                    Rec.SetDocumentDataText(AKSAExcelToJsonReport.GetDataText());
                    Rec.CalcFields("Document Data");
                    if not Rec."Document Data".HasValue then
                        Error('No data to import!');

                    Message('Document Data has been imported.');
                end;
            }

            action(EvaluateToQuote)
            {
                ApplicationArea = All;
                Caption = 'Evaluate to Quote';
                Promoted = true;
                PromotedCategory = Process;
                Image = Quote;

                trigger OnAction()
                begin
                    Message('Evaluate to Quote');
                end;
            }
        }
    }


}
