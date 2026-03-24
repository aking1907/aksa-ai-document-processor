pageextension 57100 "AKSA Item List" extends "Item List"
{
    actions
    {
        addafter("BOM Level")
        {
            action(AKSAIndexItems)
            {
                ApplicationArea = All;
                Caption = 'AKSA Embedding';
                Image = Description;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Show Embedding for AI search.';
                trigger OnAction()

                begin
                    if not Rec."AKSA Indexed" then
                        Message('No Embedding data found!');

                    Rec.CalcFields("AKSA Object Embedding Data");
                    if Rec."AKSA Object Embedding Data".HasValue then
                        Message('Embedding: %1', Rec.AKSAGetObjectEmbeddingData())
                    else
                        Message('No Embedding data found!');
                end;
            }
            action(AKSAUpdateEmbeddingByFilter)
            {
                ApplicationArea = All;
                Caption = 'AKSA Update Embedding by Filter';
                Image = EditLines;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Update Embedding data for items based on filter.';
                trigger OnAction()
                var
                    Item: Record Item;
                    AKSAItemCatalogueMgt: Codeunit "AKSA Item Catalogue Mgt.";
                begin
                    CurrPage.SetSelectionFilter(Item);
                    AKSAItemCatalogueMgt.UpdateItemEmbedding(Item);
                    Message('Embedding data update process completed.');
                end;
            }
        }


    }
}
