codeunit 57106 "AKSA AI Communication Log Mgt."
{
    procedure Log(LogType: Text[20]; Description: Text[250]; RequestBody: Text; ResponseBody: Text; StatusCode: Integer)
    var
        AKSAOpenAICommunicationLog: Record "AKSA Open AI Communication Log";
        OutStream: OutStream;
    begin
        AKSAOpenAICommunicationLog.Init();
        AKSAOpenAICommunicationLog.Type := LogType;
        AKSAOpenAICommunicationLog.Description := Description;
        AKSAOpenAICommunicationLog."Created At" := CurrentDateTime();
        AKSAOpenAICommunicationLog."Status Code" := StatusCode;

        AKSAOpenAICommunicationLog."Request Body".CreateOutStream(OutStream);
        OutStream.WriteText(RequestBody);

        Clear(OutStream);
        AKSAOpenAICommunicationLog."Response Body".CreateOutStream(OutStream);
        OutStream.WriteText(ResponseBody);

        AKSAOpenAICommunicationLog.Insert(true);
    end;
}
