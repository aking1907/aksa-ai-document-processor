page 57103 "AKSA List Of Values"
{
    ApplicationArea = All;
    Caption = 'AKSA List Of Values';
    PageType = List;
    SourceTable = "AKSA Integer/Text Map";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                Caption = 'General';

                field("Key"; Rec."Key")
                {
                    ToolTip = 'Specifies the value of the Key field.', Comment = '%';
                }
                field(Value; Rec."Value")
                {
                    ToolTip = 'Specifies the value of the Value field.', Comment = '%';
                }
            }
        }
    }

    procedure SetSourceRecord(var AKSAIntegerTextMap: Record "AKSA Integer/Text Map")
    begin
        Rec.Reset();
        if not Rec.IsEmpty then
            Rec.DeleteAll();

        if AKSAIntegerTextMap.FindSet() then
            repeat
                Rec := AKSAIntegerTextMap;
                Rec.Insert();
            until AKSAIntegerTextMap.Next() = 0;

        if Rec.FindFirst() then;
    end;
}
