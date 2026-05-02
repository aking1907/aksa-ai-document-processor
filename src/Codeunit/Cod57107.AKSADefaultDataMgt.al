codeunit 57107 "AKSA Default Data Mgt."
{
    procedure EnsureDefaultData()
    begin
        EnsureSetup();
        EnsureDefaultPromptTemplate();
    end;

    procedure EnsureDefaultPromptTemplate()
    var
        AKSAOpenAISetup: Record "AKSA Open AI Setup";
        AKSAAIPromptTemplateHeader: Record "AKSA AI Prompt Template Header";
        TemplateNo: Code[20];
    begin
        AKSAOpenAISetup.GetOrCreate();
        TemplateNo := AKSAOpenAISetup."Default Prompt Template No.";

        if not AKSAAIPromptTemplateHeader.Get(TemplateNo) then begin
            AKSAAIPromptTemplateHeader.Init();
            AKSAAIPromptTemplateHeader."No." := TemplateNo;
            AKSAAIPromptTemplateHeader.Name := 'Document to Quote';
            AKSAAIPromptTemplateHeader.Description := 'Default human-reviewed document-to-quote workflow.';
            AKSAAIPromptTemplateHeader.Insert(true);
        end;

        InsertPromptLine(
            TemplateNo,
            10000,
            Enum::"AKSA AI Request Type"::Prompt,
            'Instructions',
            'Match the incoming quote request to the supplied Business Central item catalogue. Use only item numbers that exist in the catalogue. Return only valid JSON in this exact shape: {"data":[{"dsc":"source line description","qty":1,"items":[{"no":"item number"}]}]}. Keep one output record per requested line. Leave items empty when no confident match exists. The user will review every suggestion before quote creation.');
        InsertPromptLine(TemplateNo, 20000, Enum::"AKSA AI Request Type"::ItemCatalogue, 'Item catalogue', '');
        InsertPromptLine(TemplateNo, 30000, Enum::"AKSA AI Request Type"::DocumentData, 'Document data', '');
    end;

    local procedure EnsureSetup()
    var
        AKSAOpenAISetup: Record "AKSA Open AI Setup";
    begin
        AKSAOpenAISetup.GetOrCreate();
    end;

    local procedure InsertPromptLine(TemplateNo: Code[20]; LineNo: Integer; AIRequestType: Enum "AKSA AI Request Type"; PromptDescription: Text[250]; PromptText: Text[2048])
    var
        AKSAAIPromptTemplateLine: Record "AKSA AI Prompt Template Line";
    begin
        if AKSAAIPromptTemplateLine.Get(TemplateNo, LineNo) then
            exit;

        AKSAAIPromptTemplateLine.Init();
        AKSAAIPromptTemplateLine."Document No." := TemplateNo;
        AKSAAIPromptTemplateLine."Line No." := LineNo;
        AKSAAIPromptTemplateLine.Active := true;
        AKSAAIPromptTemplateLine."AI Request Type" := AIRequestType;
        AKSAAIPromptTemplateLine."Prompt Desc." := PromptDescription;
        AKSAAIPromptTemplateLine."AI Prompt" := PromptText;
        AKSAAIPromptTemplateLine.Insert(true);
    end;
}
