page 57102 "AKSA Open AI Setup"
{
    ApplicationArea = All;
    Caption = 'AKSA Open AI Setup';
    PageType = Card;
    SourceTable = "AKSA Open AI Setup";
    UsageCategory = Administration;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Open AI Model URL"; Rec."Open AI Model URL")
                {
                    ToolTip = 'Specifies the value of the Open AI Model URL field.', Comment = '%';
                }
                field("Open AI URL"; Rec."Open AI URL")
                {
                    ToolTip = 'Specifies the value of the Open AI URL field.', Comment = '%';
                }
                field("Open AI Model"; Rec."Open AI Model")
                {
                    ToolTip = 'Specifies the value of the Open AI Model field.', Comment = '%';
                    Lookup = false;
                    DrillDown = false;

                    trigger OnAssistEdit()
                    begin
                        SuggestListOfModels();
                    end;
                }
                field("Open AI Key"; Rec."Open AI Key")
                {
                    ToolTip = 'Specifies the value of the Open AI Api-Key field.', Comment = '%';
                    ExtendedDatatype = Masked;
                }
            }
            group("Item Catalogue")
            {
                Caption = 'Item Catalogue';

                field("Item Catalogue Batch Size"; Rec."Item Catalogue Batch Size")
                {
                    ToolTip = 'Specifies the value of the Item Catalogue Batch Size field.', Comment = '%';
                }
            }
            group("Temporary")
            {
                Caption = 'Temporary';

                field("Temp Blob"; Rec."Temp Blob".HasValue())
                {
                    ToolTip = 'Specifies the value of the Temp Blob field.', Comment = '%';

                    trigger OnAssistEdit()
                    var
                        AKSAAITextEditor: Page "AKSA AI Text Editor";
                    begin
                        Rec.CalcFields("Temp Blob");
                        AKSAAITextEditor.SetText(Rec.GetTempBlob());
                        if AKSAAITextEditor.RunModal() <> Action::OK then
                            exit;

                        Rec.SetTempBlob(AKSAAITextEditor.GetText());
                        Rec.Modify();
                    end;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(ExportItemCatalogue)
            {
                Caption = 'Export Item Catalogue';
                ToolTip = 'Export Item Catalogue';
                Image = Export;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                var
                    AKSAItemCatalogueMgt: Codeunit "AKSA Item Catalogue Mgt.";
                begin
                    Message(AKSAItemCatalogueMgt.GetItemCatalogue());
                end;
            }

            action(ItemEmbedding)
            {
                Caption = 'Call AI Search';
                ToolTip = 'Call AI Search';
                Image = Import;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                var
                    AKSAOpenAIManagement: Codeunit "AKSA Open AI Management";
                begin
                    AKSAOpenAIManagement.UploadItemCatalogueIntoAzureAISearch();
                    Message('gg');
                end;
            }
        }
    }

    local procedure SuggestListOfModels()
    var
        AKSAOpenAIModels: Record "AKSA Integer/Text Map";
        AKSAOpenAIManagementCU: Codeunit "AKSA Open AI Management";
        AKSAListOfValuesPage: Page "AKSA List Of Values";
    begin
        AKSAOpenAIManagementCU.GetOpenAIModels(AKSAOpenAIModels);

        AKSAListOfValuesPage.LookupMode := true;
        AKSAListOfValuesPage.Editable := false;
        AKSAListOfValuesPage.SetSourceRecord(AKSAOpenAIModels);
        if AKSAListOfValuesPage.RunModal() = Action::LookupOK then begin
            AKSAListOfValuesPage.GetRecord(AKSAOpenAIModels);
            Rec."Open AI Model" := AKSAOpenAIModels.Value;
        end;
    end;

    trigger OnOpenPage()
    begin
        if not Rec.FindFirst() then
            Rec.Insert();
    end;
}
