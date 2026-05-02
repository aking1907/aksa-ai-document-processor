codeunit 57108 "AKSA Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        AKSADefaultDataMgt: Codeunit "AKSA Default Data Mgt.";
    begin
        AKSADefaultDataMgt.EnsureDefaultData();
    end;
}
