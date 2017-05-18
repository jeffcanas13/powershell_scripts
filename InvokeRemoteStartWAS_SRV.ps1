$server ='170.30.11.242'
$profile = 'SREDEVSRV'
$appserver= 'server1'
$outputLog = 'Jenkins_Deployment_Logs\remoteWAS'
$wsadminPath = 'E:/Program Files/IBM/WebSphere/AppServer/bin'
$wsadminUsername= 'jenkins'
$wsadminPassword = ''

function Status($logFile)
{
	$stats = "FAILED"
	$content = Get-Content $logFile
	while ($stats -eq "FAILED")
	{
		if ($content -match "stopped" -and $content -match "cannot be reached")
		{
			$stats = "STOPPED"
		}
		elseif ($content -match "is STOPPING")
		{
			$stats = "STOPPING"
		}
		elseif ($content -match "is STARTING")
		{
			$stats = "STARTING"
		}
		elseif ($content -match "is STARTED")
		{
			$stats = "STARTED"
		}
		elseif ($content -match "Exception" -or $content -match "Error")
		{
			$stats = "There's an error or an exception. See serverStatus.log for details..."
		}
		else
		{
			$stats = "FAILED"
			Write-Host "Logging of application serverStatus.log might still be ongoing..."
			Write-Host "Waiting until logs completed"
			sleep -m 50
			$content = Get-Content $logFile
		}
	}

	return $stats
}

function CheckErrorStopStart($logFile, $StopStart)
{
	$stats = "FAILED"
	$content = Get-Content $logFile
	while ($stats -eq "FAILED")
	{
		if ($content -match "Server $appserver open for e-business")
		{
			$stats = "Server $appserver open for e-business"
		}
		elseif ($content -match "Server $appserver stop completed")
		{
			$stats = "Server $appserver stop completed"
		}
		elseif ($content -match "Error" -or $content -match "Exception")
		{
			$stats = "There's an error or an exception. See " + $StopStart + "Server.log for details..."
		}
		else
		{
			$stats = "FAILED"
			Write-Host "Logging of application server $StopStart might still be ongoing..."
			Write-Host "Waiting until logs completed"
			sleep -m 50
			$content = Get-Content $logFile
		}
	}
	return $stats
}

function StopServer()
{
	$processId = (Invoke-WmiMethod -Path "Win32_Process" -ComputerName $server -Name Create -ArgumentList "cmd /c `"$wsadminPath\stopServer.bat`" $appserver -profileName $profile > $('E:\' + $outputLog + '_' + $profile +'_stop.txt')" -ErrorAction Stop).processId
	while ((Get-WmiObject -class "win32_process" -Filter "ProcessID=$processId" -ComputerName $server) -ne $null)
	{
		Write-Host -NoNewline "."
		sleep -m 50
	}
	Write-Host ""
	$fileName = $("\\$server\e$\" + $outputLog + "_" + $profile + "_stop.txt")
	CheckErrorStopStart -logFile $fileName -StopStart 'stop' 
}

function StartServer()
{
	$processId = (Invoke-WmiMethod -Path "Win32_Process" -ComputerName $server -Name Create -ArgumentList "cmd /c `"$wsadminPath\startServer.bat`" $appserver -profileName $profile > $('E:\' + $outputLog + '_' + $profile + '_start.txt')" -ErrorAction Stop).processId
	while ((Get-WmiObject -class "win32_process" -Filter "ProcessID=$processId" -ComputerName $server) -ne $null)
	{
		Write-Host -NoNewline "."
		sleep -m 50
	}
	Write-Host ""
	$fileName = $("\\$server\e$\" + $outputLog + "_" + $profile + "_start.txt")
	CheckErrorStopStart -logFile $fileName -StopStart 'start'
}

function ExecuteServerStatus()
{
	$processId = (Invoke-WmiMethod -Path "Win32_Process" -ComputerName $server -Name Create -ArgumentList "cmd /c `"$wsadminPath\serverStatus.bat`" $appserver -profileName $profile > $('E:\' + $outputLog + '_' + $profile + '_status.txt')" -ErrorAction Stop).processId
	while ((Get-WmiObject -class "win32_process" -Filter "ProcessID=$processId" -ComputerName $server) -ne $null)
	{
		Write-Host -NoNewline "."
		sleep -m 1
	}
	$statusLogFile = $("\\$server\e$\" + $outputLog + "_" + $profile + "_status.txt")
	return $statusLogFile
}

#MAIN

try
{
	Write-Host "Configuring the Jenkins_Deployment_Logs directory"
	(New-Item \\$server\e$\Jenkins_Deployment_Logs -itemtype directory) 2> $null
	Write-Host "Done"
}
catch
{
	Write-Host "`nDirectory already exists`n"
}

try
{
	Write-Host "`n***STOP SERVER execution started . . .`n"
	Write-Host "`nVerifying $appserver Status . . .`n"
	$results = ExecuteServerStatus
	$checkStatus = Status -logFile $results
	Write-Host "`nSTATUS: $checkStatus`n"
	if ($checkStatus -eq 'STOPPED')
	{
		Write-Host "Application Server already STOPPED - Skipping server stop"
	}
	else
	{
		Write-Host "`nSTOPPING $appserver`n"
		StopServer
		Write-Host "`nExecution of StopServer for $appserver ended but might still be running`n"
		Write-Host "`nVerifying $appserver Status . . .`n"
		sleep -s 10
		$results = ExecuteServerStatus
		$checkStatus = Status -logFile $results
        Write-Host "`nSTATUS: $checkStatus`n"
		while ($checkStatus -eq 'STOPPING' -or $checkStatus -eq 'STARTED')
		{
			$results = ExecuteServerStatus
			$checkStatus = Status -logFile $results
			Write-Host "`nSTATUS: $checkStatus`n"
			#add sleep here
			sleep -s 5
		}
		if ($checkStatus -eq 'STOPPED')
		{
			Write-Host "`nSuccessfully stopped $appserver !!!`n"
		}
	}
}
catch
{
	$ErrorMessage = $_.Exception.Message
	Write-Host "`nSTOPPING $appserver FAILED: $ErrorMessage`n"
}

try
{
	Write-Host "`n***START SERVER execution started . . .`n"
	Write-Host "`nVerifying $appserver Status . . .`n"
	$results = ExecuteServerStatus
	$checkStatus = Status -logFile $results
	Write-Host "`nSTATUS: $checkStatus`n"	
	if ($checkStatus -eq 'STARTED')
	{
		Write-Host "`nApplication Server already STARTED - Skipping server start`n"
	}
	else
	{
		Write-Host "`nSTARTING $appserver`n"
		StartServer
		Write-Host "`nExecution of StartServer for $appserver ended but might still be running`n"
		Write-Host "`nVerifying $appserver Status . . .`n"
		sleep -s 10
		$results = ExecuteServerStatus
		$checkStatus = Status -logFile $results
		Write-Host "`nSTATUS: $checkStatus`n"
		while ($checkStatus -eq 'STARTING' -or $checkStatus -eq 'STOPPED')
		{
			$results = ExecuteServerStatus
			$checkStatus = Status -logFile $results
			Write-Host "`nSTATUS: $checkStatus`n"
			#add sleep here
			sleep -s 5
		}

		if ($checkStatus -eq 'STARTED')
		{
			Write-Host "`nSuccessfully started $appserver !!!`n"
		}
	}
}
catch
{
	$ErrorMessage = $_.Exception.Message
	Write-Host "`nSTARTING $appserver FAILED: $ErrorMessage`n"
}
