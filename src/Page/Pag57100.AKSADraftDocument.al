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
                field("Customer No."; Rec."Customer No.")
                {
                    ToolTip = 'Specifies the customer used when creating Sales or Service Quotes.';
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ToolTip = 'Specifies the vendor used when creating Purchase Quotes.';
                }
                field(Type; Rec."Type")
                {
                    ToolTip = 'Specifies the value of the Type field.', Comment = '%';
                }
                field("AI Prompt Template No."; Rec."AI Prompt Template No.")
                {
                    ToolTip = 'Specifies the value of the AI Prompt Template No. field.', Comment = '%';
                }
                field("Source File Name"; Rec."Source File Name")
                {
                    ToolTip = 'Specifies the name of the uploaded source document.';
                }
                field("Processing Pattern"; Rec."Processing Pattern")
                {
                    ToolTip = 'Specifies whether the document was processed with the medium or large catalogue pattern.';
                }
                field(Status; Rec.Status)
                {
                    ToolTip = 'Specifies the draft review status.';
                }
                field("Approved By"; Rec."Approved By")
                {
                    ToolTip = 'Specifies the user that approved the draft document.';
                }
                field("Approved At"; Rec."Approved At")
                {
                    ToolTip = 'Specifies when the draft document was approved.';
                }
                field("Quote No."; Rec."Quote No.")
                {
                    ToolTip = 'Specifies the quote created from this draft document.';
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
                    Caption = 'Document Data';
                    ToolTip = 'Specifies the value of the Document Data field.', Comment = '%';
                    DrillDown = false;

                    trigger OnAssistEdit()
                    begin
                        Message(Rec.GetDocumentDataText());
                    end;
                }
                field("AI Response"; Rec."AI Response".HasValue)
                {
                    Caption = 'AI Response';
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
                ToolTip = 'Processes the extracted document data with AI and populates suggested draft lines.';
                Promoted = true;
                PromotedCategory = Process;
                Image = Document;

                trigger OnAction()
                begin
                    Rec.ProcessWithAI();
                    CurrPage.Update(false);
                    Message('AI processing completed. Review the suggested lines before creating a quote.');
                end;
            }

            action(ImportFromExcel)
            {
                ApplicationArea = All;
                Caption = 'Import From Excel';
                ToolTip = 'Imports customer request lines from an Excel workbook into the draft document data.';
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

            action(ExtractDocumentData)
            {
                ApplicationArea = All;
                Caption = 'Extract Document Data';
                ToolTip = 'Uploads a PDF or image to Azure AI Document Intelligence and stores the extracted data.';
                Promoted = true;
                PromotedCategory = Process;
                Image = Import;

                trigger OnAction()
                var
                    AKSAAzureDocIntelligence: Codeunit "AKSA Azure Doc Intelligence";
                begin
                    AKSAAzureDocIntelligence.UploadAndExtractToDraft(Rec);
                    CurrPage.Update(false);
                    Message('Document Data has been extracted.');
                end;
            }

            action(EvaluateToQuote)
            {
                ApplicationArea = All;
                Caption = 'Create Quote';
                ToolTip = 'Creates the final quote document from an approved draft.';
                Promoted = true;
                PromotedCategory = Process;
                Image = Quote;

                trigger OnAction()
                var
                    AKSAQuoteMgt: Codeunit "AKSA Quote Mgt.";
                    QuoteNo: Code[20];
                begin
                    QuoteNo := AKSAQuoteMgt.CreateQuoteFromDraft(Rec);
                    Message('%1 Quote %2 has been created.', Rec.Type, QuoteNo);
                end;
            }
            action(ApproveDraft)
            {
                ApplicationArea = All;
                Caption = 'Approve Draft';
                ToolTip = 'Approves the reviewed draft document lines for quote creation.';
                Promoted = true;
                PromotedCategory = Process;
                Image = Approve;

                trigger OnAction()
                begin
                    Rec.ApproveDraft();
                    CurrPage.Update(false);
                    Message('Draft document %1 has been approved for quote creation.', Rec."No.");
                end;
            }
            action(ReopenDraft)
            {
                ApplicationArea = All;
                Caption = 'Reopen Draft';
                ToolTip = 'Reopens the draft document for additional review or corrections.';
                Promoted = true;
                PromotedCategory = Process;
                Image = ReOpen;

                trigger OnAction()
                begin
                    Rec.ReopenDraft();
                    CurrPage.Update(false);
                end;
            }
        }
    }


}
