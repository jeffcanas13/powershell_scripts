$server = '170.30.11.242'
$profile = 'SREQATSRV'
$wsadminPath = 'E:/Program Files/IBM/WebSphere/AppServer/bin'
$appName='sreqatsrv'
$outputLog = 'Jenkins_Deployment_Logs\remoteWAS'

Write-Host "Script execution started"
try
{
	Write-Host "Configuring the " + $outputLog + " directory."
	(New-Item \\$server\e$\Jenkins_Deployment_Logs -itemtype directory) 2> $null
	Write-Host "Creating " + $outputLog + ". "
}
catch
{
	Write-Host "`nDirectory already exists`n"
}


try
{
	$processId = (Invoke-WmiMethod -Path "Win32_Process" -ComputerName $server -Name Create -ArgumentList "cmd /c `"$wsadminPath\wsadmin.bat`" -profileName $profile  -lang jython -f e:/CSC/ISSUtils/ClassLoader.py $appName > $('E:\' + $outputLog + '_' + $profile + '_ClassLoader.txt')"  -ErrorAction Stop).processId
	while ((Get-WmiObject -class "win32_process" -Filter "ProcessID=$processId" -ComputerName $server) -ne $null)
	{
		Write-Host -NoNewline "."
 		sleep -m 50
	}
}
catch
{
	Write-Host "Problem encountered!"
}
Write-Host " "
