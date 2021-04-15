##Load scripts from same folder
## https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/use-psscriptroot-to-load-resources
. "$PSScriptRoot\CreateLogFolders.ps1" 
. "$PSScriptRoot\WriteLog.ps1" 
. "$PSScriptRoot\MoveItems.ps1" 



# Settings 
$LogTime = Get-Date -Format "MMMM-dd_HH-mm-ss"
##$LogSQLInstance = "SQL01" 
##$LogDatabase = "SwarchDBA"
##$LogTable = "dbo.HammerDbResults"
$ELogFile = "D:\HammerDbBenchmark\HammerLog\"+$LogTime+"_HammerDBImportLog.txt"
$serverName = $env:computername
$LogFolder = "C:\temp\"
$HammerDBResults = "D:\HammerDbBenchmark\HammerResults\HammerDBResults.csv"
$ErrorActionPreference = "stop"
$ProcessedFolder = "D:\HammerDbBenchmark\HammerProcessed"


try {
    CreateDir -DirectoryToCreate "D:\HammerDbBenchmark\HammerLog"
    CreateDir -DirectoryToCreate "D:\HammerDbBenchmark\HammerResults" 
    CreateDir -DirectoryToCreate "D:\HammerDbBenchmark\HammerProcessed" 
}
catch {
    Write-Log -Message "Error was: $_" -Severity Error 
    throw   
    
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

                    $found = $line -match "System achieved (?<content>.*) SQL Server"
                    if ($found) {	
                        $TPM = $matches['content']
                    }

                    $found = $line -match "at (?<content>.*) NOPM"
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

 
                #Can uncomment below line if you want data to be imported into a SQL database instead of csv format
                ##   Write-DbaDbTableData -SqlInstance $LogSQLInstance -Database $LogDatabase -InputObject $SQL -Table $LogTable -EnableException -AutoCreateTable

                Add-Content -Path $HammerDBResults "$ServerName,$WriteTime,$NumUsers,$TPM,$NOPM,$FullName" -ErrorAction Stop
                MoveItems -FileToCheck $file.FullName -NewPath $ProcessedFolder 
               
                



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




