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
            group("AI Model")
            {
                Caption = 'AI Model';

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
            group("Document Intelligence")
            {
                Caption = 'Document Intelligence';

                field("Document Intelligence URL"; Rec."Document Intelligence URL")
                {
                    ToolTip = 'Specifies the Azure AI Document Intelligence endpoint used to extract document data.';
                }
                field("Document Intelligence Key"; Rec."Document Intelligence Key")
                {
                    ToolTip = 'Specifies the Azure AI Document Intelligence key.';
                    ExtendedDatatype = Masked;
                }
            }
            group("Item Catalogue")
            {
                Caption = 'Item Catalogue';

                field("Default Prompt Template No."; Rec."Default Prompt Template No.")
                {
                    ToolTip = 'Specifies the default AI prompt template assigned to new draft documents.';
                }
                field("Catalogue Size Threshold"; Rec."Catalogue Size Threshold")
                {
                    ToolTip = 'Specifies the item count threshold used to switch from full catalogue prompting to vector retrieval.';
                }
                field("Item Catalogue Batch Size"; Rec."Item Catalogue Batch Size")
                {
                    ToolTip = 'Specifies the value of the Item Catalogue Batch Size field.', Comment = '%';
                }
            }
            group("Vector Search")
            {
                Caption = 'Vector Search';

                field("Azure AI Search URL"; Rec."Azure AI Search URL")
                {
                    ToolTip = 'Specifies the Azure AI Search service URL.';
                }
                field("Azure AI Search Index Name"; Rec."Azure AI Search Index Name")
                {
                    ToolTip = 'Specifies the Azure AI Search index that stores item catalogue data.';
                }
                field("Azure AI Search Api Version"; Rec."Azure AI Search Api Version")
                {
                    ToolTip = 'Specifies the Azure AI Search REST API version.';
                }
                field("Azure AI Search Key"; Rec."Azure AI Search Key")
                {
                    ToolTip = 'Specifies the Azure AI Search API key.';
                    ExtendedDatatype = Masked;
                }
                field("Vector Result Count"; Rec."Vector Result Count")
                {
                    ToolTip = 'Specifies how many catalogue items are retrieved for large catalogue processing.';
                }
            }
            group("Embeddings")
            {
                Caption = 'Embeddings';

                field("Open AI Embedding URL"; Rec."Open AI Embedding URL")
                {
                    ToolTip = 'Specifies the endpoint used to create item embeddings.';
                }
                field("Open AI Embedding Model"; Rec."Open AI Embedding Model")
                {
                    ToolTip = 'Specifies the embedding model when the endpoint requires it.';
                }
                field("Open AI Embedding Key"; Rec."Open AI Embedding Key")
                {
                    ToolTip = 'Specifies the embedding API key. If blank, the Open AI Api-Key is used.';
                    ExtendedDatatype = Masked;
                }
            }
            group("Temporary")
            {
                Caption = 'Temporary';

                field("Temp Blob"; Rec."Temp Blob".HasValue())
                {
                    Caption = 'Temp Blob';
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
                Caption = 'Upload Item Catalogue';
                ToolTip = 'Uploads the item catalogue to Azure AI Search.';
                Image = Import;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                var
                    AKSAOpenAIManagement: Codeunit "AKSA Open AI Management";
                begin
                    AKSAOpenAIManagement.UploadItemCatalogueIntoAzureAISearch();
                    Message('The item catalogue has been uploaded to Azure AI Search.');
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
            Rec."Open AI Model" := CopyStr(AKSAOpenAIModels.Value, 1, MaxStrLen(Rec."Open AI Model"));
        end;
    end;

    trigger OnOpenPage()
    var
        AKSADefaultDataMgt: Codeunit "AKSA Default Data Mgt.";
    begin
        Rec.GetOrCreate();
        AKSADefaultDataMgt.EnsureDefaultPromptTemplate();
    end;
}
