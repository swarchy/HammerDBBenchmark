Function ImportHammerLogs {
    [cmdletBinding()]
    Param(
        [parameter(Mandatory = $True)]
        [string] $BaseFolder,
        [string] $HammerLogsFolder,
        [string] $WriteOp,
        [parameter(Mandatory = $False)]
        [string] $LogSQLInstance,
        [parameter(Mandatory = $False)]
        [string] $LogDatabase,
        [parameter(Mandatory = $False)]
        [string] $LogTable)


    ##Load scripts from same folder
    ## https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/use-psscriptroot-to-load-resources
    . "$BaseFolder\CreateLogFolders.ps1" 
    . "$BaseFolder\WriteLog.ps1" 
    . "$BaseFolder\MoveItems.ps1" 



    $LogTime = Get-Date -Format "MMMM-dd_HH-mm-ss"
    $ELogFile = "$BaseFolder\HammerLog\" + $LogTime + "_HammerDBImportLog.txt"
    $serverName = $env:computername
    $LogFolder = "$HammerLogsFolder\"
    $HammerDBResults = "$BaseFolder\HammerResults\HammerDBResults.csv"
    $ErrorActionPreference = "stop"
    $ProcessedFolder = "$BaseFolder\HammerProcessed"

    $BaseFolder = "D:\HammerDbBenchmark"
    try {
        CreateLogDirs -DirectoryToCreate "$BaseFolder\HammerLog" 
        CreateLogDirs -DirectoryToCreate "$BaseFolder\HammerResults" 
        CreateLogDirs -DirectoryToCreate "$BaseFolder\HammerProcessed" 
    }
    catch {
        Write-Log -Message "Error was: $_" -Severity Error 
        throw   
    
    }

    if ($WriteOp -ne "csv") {
        ##Check if DBATools Module is installed, this is required for creating SQL Agent jobs 
        if (Get-Module -ListAvailable -Name DbaTools) {
    
        }
        else {
            Write-Host "Module does not exist, Attempting to install DBA TOOLS" -ForegroundColor Yellow
            Try {
                Find-Module -Name DbaTools -ErrorAction Stop | Install-Module -ErrorAction Stop
            }
            Catch {
                $ErrorMessage = $_.Exception.Message
                write-host "You need to Install DBATools before continuing" -ForegroundColor yellow
                Write-Log -Message "Error was: $_" -Severity Error 
                Exit
            }

        }
    }
    try {
        # Create consolidated HammerDB results file if it doesn't exist
        if (-Not (Test-Path $HammerDBResults)) {
            Set-Content -Path $HammerDBResults "Hostname,EndTime,Users,TPM,NOPM,FileName"
        }
    }
    catch {
        Write-Log -Message "Error was: $_" -Severity Error    
        throw
    }

    # Adds freindly name to log files and converts to txt format
    try {
        if (Test-Path $LogFolder ) {

        
            Get-ChildItem  $LogFolder -Filter hammerdb_*.log  | ForEach { Rename-Item -Path $_.FullName -NewName "$($_.DirectoryName)\$serverName$("_HammerDb_")$($_.LastWriteTime.toString("ddMMyyyyHHmmss"))$(".txt")" }

            # Defines how to filter which txt files to look through
            $Filter = $serverName + "_HammerDb_"

            # Gets the txt log files 
            $files = Get-ChildItem $LogFolder -filter *.txt   | Where-Object { $_.FullName -Like "*$filter*" }  
 
            # Starts loop through each txt log file 
            foreach ($file in $files) {

                $ResultsLine = Get-Content $file.FullName | Select-String -Pattern "Test complete" -AllMatches -Context 0, 4
                $NumTests = $ResultsLine.count

                foreach ($line in $ResultsLine) {
                    $Timestamp = ""
                    $NumUsers = ""
                    $TPM = ""
                    $NOPM = ""

                    $found = $line -match "@ 1 @ (?<content>.*) "
                    if ($found) {	
                        $Timestamp = $matches['content']
                    }

                    $found = $line -match ":(?<content>.*) Active Virtual Users"
                    if ($found) {	
                        $NumUsers = $matches['content']
                    }

                    $found = $line -match "from (?<content>.*) SQL"
                    if ($found) {	
                        $TPM = $matches['content']
                    }

                    $found = $line -match "System achieved (?<content>.*) NOPM"
                    if ($found) {	
                        $NOPM = $matches['content']
                    }

        


                }
                [string]$WriteTime = $file.LastWriteTime.ToString('dd/MM/yyyy HH:mm:ss')
                [string]$FullName = $File.FullName

                $SQL = [PSCustomObject]@{
                    HostName = $ServerName
                    EndTime  = $WriteTime
                    Users    = $NumUsers
                    Tpm      = $TPM
                    Nopm     = $NOPM
                    FileName = $FullName
                }

 
                switch ( $WriteOp ) {
                    "sql" { Write-DbaDbTableData -SqlInstance $LogSQLInstance -Database $LogDatabase -InputObject $SQL -Table $LogTable -EnableException -AutoCreateTable }
                    "csv" {
                        Add-Content -Path $HammerDBResults "$ServerName,$WriteTime,$NumUsers,$TPM,$NOPM,$FullName" -ErrorAction Stop
                        MoveItems -FileToCheck $file.FullName -NewPath $ProcessedFolder 
                    }
                    "both" {
                        Write-DbaDbTableData -SqlInstance $LogSQLInstance -Database $LogDatabase -InputObject $SQL -Table $LogTable -EnableException -AutoCreateTable
                        MoveItems -FileToCheck $file.FullName -NewPath $ProcessedFolder 
                    }
                }

                

                


            }
            $Count = $files.Count
            Write-Log -Message "Processed $Count log files" -Severity "Information"

      
        }
        else {
            # Write-Host "$hostname : cannot read $HammerDBLog"
            ##Add-Content -Path $HammerDBRunlog "$hostname : cannot read $HammerDBLog"
            write-host "cannot read file"
        }
    }
    catch {
        Write-Log -Message "Error was: $_" -Severity Error    
        throw
    }

}

ImportHammerLogs -BaseFolder "D:\HammerDbBenchmark" -HammerLogsFolder "C:\Users\SVC_SQLA\AppData\Local\Temp" -WriteOp "csv" -LogSQLInstance "sql02" -LogDatabase "HammerResults" -LogTable "SQL02_HammerBenchmarkRlt"
