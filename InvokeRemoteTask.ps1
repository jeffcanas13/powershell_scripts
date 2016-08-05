param (
    [string]$user = "MEMAdminCodeMove",
    [string]$remoteMachine = "",
    [string]$taskName = "",
    [string]$codeMove = "",
    [string]$jenkinsBuild = ""
)
$key = 'HKLM:\SOFTWARE\CSC\CodeMove\SecurityKeys'
$keyStr = (Get-ItemProperty -Path $key -Name $user).$user
$key = [System.Text.Encoding]::ASCII.GetBytes($keyStr)
$encrypted = "76492d1116743f0423413b16050a5345MgB8AEMAVAA3AEkATQBnADQAQgBXAE4AZwBvAGMATwBoAFEAUABqAHUAMwBoAFEAPQA9AHwAMwA2ADAAMABlAGMANQA5AGMAOABmAGYAMwBiADIANQA4AGEAYgA5ADQANgBlAGQAZAA3ADkAOQBkADYAYQBkADMAMQBjADAANABjADkAOQAzAGYAOQBmADgAZgAzAGMAYQAzAGEANQBkADQANwAwAGEANgBjADEAMAA4AGEAMAA=";
$pw = ConvertTo-SecureString -string $encrypted -Key $key
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $user,$pw;
$pp = $cred.GetNetworkCredential().Password;
$env = $taskName;
if ($taskName.StartsWith("CodeMove-")) {
    $env = $taskname.Substring(9);
}
$sqlIdx = $env.IndexOf("SQL");
$codeMoveCmd = "CodeMove.cmd";
if ($sqlIdx -ge 0) {
    $codeMoveCmd = "CodeMoveSQL.cmd";
}

#$cmd = ("SCHTASKS /Run /S " + $remoteMachine + " /U " + $user + " /P " + $pp + " /TN " + $taskName);
$cmd = ("psexec " + $remoteMachine + " -i -u " + $user + " -p " + $pp + " cmd.exe /C E:\CSC\CodeMove\" + $codeMoveCmd + " " + $env + " " + $codeMove + " " + $jenkinsBuild);
write-host Executing command: $cmd.Replace($pp, "********");
Invoke-Expression  $cmd
if ($lastExitCode -gt 0) {
    write-host "Error executing remote code move task with exit code: " $lastExitCode;
    EXIT $lastExitCode;
}
