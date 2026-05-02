codeunit 57105 "AKSA Quote Mgt."
{
    procedure CreateQuoteFromDraft(var AKSADraftDocumentHeader: Record "AKSA Draft Document Header"): Code[20]
    var
        QuoteNo: Code[20];
    begin
        AKSADraftDocumentHeader.TestField(Status, AKSADraftDocumentHeader.Status::Approved);

        case AKSADraftDocumentHeader.Type of
            Enum::"AKSA Draft Document Type"::Sales:
                QuoteNo := CreateSalesQuote(AKSADraftDocumentHeader);
            Enum::"AKSA Draft Document Type"::Purchase:
                QuoteNo := CreatePurchaseQuote(AKSADraftDocumentHeader);
            Enum::"AKSA Draft Document Type"::Service:
                QuoteNo := CreateServiceQuote(AKSADraftDocumentHeader);
            else
                Error('Unsupported draft document type: %1', AKSADraftDocumentHeader.Type);
        end;

        AKSADraftDocumentHeader.MarkConverted(QuoteNo);
        exit(QuoteNo);
    end;

    local procedure CreateSalesQuote(var AKSADraftDocumentHeader: Record "AKSA Draft Document Header"): Code[20]
    var
        AKSADraftDocumentLine: Record "AKSA Draft Document Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        EnsureDraftLinesReady(AKSADraftDocumentHeader);
        AKSADraftDocumentHeader.TestField("Customer No.");

        SalesHeader.Init();
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Quote);
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", AKSADraftDocumentHeader."Customer No.");
        SalesHeader.Modify(true);

        AKSADraftDocumentLine.SetRange("Document No.", AKSADraftDocumentHeader."No.");
        AKSADraftDocumentLine.FindSet();
        repeat
            AKSADraftDocumentLine.TestField("Item No.");

            SalesLine.Init();
            SalesLine."Document Type" := SalesHeader."Document Type";
            SalesLine."Document No." := SalesHeader."No.";
            SalesLine."Line No." := AKSADraftDocumentLine."Line No.";
            SalesLine.Insert(true);
            SalesLine.Validate(Type, SalesLine.Type::Item);
            SalesLine.Validate("No.", AKSADraftDocumentLine."Item No.");
            SalesLine.Validate(Quantity, AKSADraftDocumentLine.Quantity);
            SalesLine.Modify(true);
        until AKSADraftDocumentLine.Next() = 0;

        exit(SalesHeader."No.");
    end;

    local procedure CreatePurchaseQuote(var AKSADraftDocumentHeader: Record "AKSA Draft Document Header"): Code[20]
    var
        AKSADraftDocumentLine: Record "AKSA Draft Document Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        EnsureDraftLinesReady(AKSADraftDocumentHeader);
        AKSADraftDocumentHeader.TestField("Vendor No.");

        PurchaseHeader.Init();
        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::Quote);
        PurchaseHeader.Insert(true);
        PurchaseHeader.Validate("Buy-from Vendor No.", AKSADraftDocumentHeader."Vendor No.");
        PurchaseHeader.Modify(true);

        AKSADraftDocumentLine.SetRange("Document No.", AKSADraftDocumentHeader."No.");
        AKSADraftDocumentLine.FindSet();
        repeat
            AKSADraftDocumentLine.TestField("Item No.");

            PurchaseLine.Init();
            PurchaseLine."Document Type" := PurchaseHeader."Document Type";
            PurchaseLine."Document No." := PurchaseHeader."No.";
            PurchaseLine."Line No." := AKSADraftDocumentLine."Line No.";
            PurchaseLine.Insert(true);
            PurchaseLine.Validate(Type, PurchaseLine.Type::Item);
            PurchaseLine.Validate("No.", AKSADraftDocumentLine."Item No.");
            PurchaseLine.Validate(Quantity, AKSADraftDocumentLine.Quantity);
            PurchaseLine.Modify(true);
        until AKSADraftDocumentLine.Next() = 0;

        exit(PurchaseHeader."No.");
    end;

    local procedure CreateServiceQuote(var AKSADraftDocumentHeader: Record "AKSA Draft Document Header"): Code[20]
    var
        AKSADraftDocumentLine: Record "AKSA Draft Document Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        EnsureDraftLinesReady(AKSADraftDocumentHeader);
        AKSADraftDocumentHeader.TestField("Customer No.");

        ServiceHeader.Init();
        ServiceHeader.Validate("Document Type", ServiceHeader."Document Type"::Quote);
        ServiceHeader.Insert(true);
        ServiceHeader.Validate("Customer No.", AKSADraftDocumentHeader."Customer No.");
        ServiceHeader.Modify(true);

        AKSADraftDocumentLine.SetRange("Document No.", AKSADraftDocumentHeader."No.");
        AKSADraftDocumentLine.FindSet();
        repeat
            AKSADraftDocumentLine.TestField("Item No.");

            ServiceLine.Init();
            ServiceLine."Document Type" := ServiceHeader."Document Type";
            ServiceLine."Document No." := ServiceHeader."No.";
            ServiceLine."Line No." := AKSADraftDocumentLine."Line No.";
            ServiceLine.Insert(true);
            ServiceLine.Validate(Type, ServiceLine.Type::Item);
            ServiceLine.Validate("No.", AKSADraftDocumentLine."Item No.");
            ServiceLine.Validate(Quantity, AKSADraftDocumentLine.Quantity);
            ServiceLine.Modify(true);
        until AKSADraftDocumentLine.Next() = 0;

        exit(ServiceHeader."No.");
    end;

    local procedure EnsureDraftLinesReady(var AKSADraftDocumentHeader: Record "AKSA Draft Document Header")
    var
        AKSADraftDocumentLine: Record "AKSA Draft Document Line";
    begin
        AKSADraftDocumentHeader.TestField("No.");
        AKSADraftDocumentHeader.TestField(Status, AKSADraftDocumentHeader.Status::Approved);

        AKSADraftDocumentLine.SetRange("Document No.", AKSADraftDocumentHeader."No.");
        if AKSADraftDocumentLine.IsEmpty() then
            Error('The draft document has no lines to convert.');
    end;
}
