$server ='170.30.11.242'
$profile = 'SREDEVSRV'
$appserver= 'server1'
$wsadminPath = 'E:/Program Files/IBM/WebSphere/AppServer/bin'
$wsadminUsername= ''
$wsadminPassword = ''


$processId = (Invoke-WmiMethod -Path "Win32_Process" -ComputerName $server -Name Create -ArgumentList "cmd /c `"E:\Program Files\IBM\WebSphere\AppServer\profiles\SREDEVSRV\bin\startServer.bat`" server1 -profileName SREDEVSRV > E:\remoteWAS_DEVSRV_Start.txt" -ErrorAction Stop).processId
            
#New-Item -Path "E:\remoteWASCopy.txt" -ItemType File -ErrorAction SilentlyContinue > $null
#$timeoutCounter = 0
#$timeoutvalue = 10000


while ((Get-WmiObject -class "win32_process" -Filter "ProcessID=$processId" -ComputerName $server) -ne $null )
{
 Write-Host -NoNewline "."
 sleep -m 50
# $timeoutCounter++
}
Write-Host ""
#if ($timeoutCounter -ge $timeoutvalue)
#{
# Write-Host "Timeout has been reached while waiting for script to complete"
#}
#else
#{
 Write-Host "Start Action is Complete"
#}
#Copy-Item -Path "\\$server\e$\remoteWAS.txt" -Destination "E:\remoteWASCopy.txt" -Force -ErrorAction Stop > $null
