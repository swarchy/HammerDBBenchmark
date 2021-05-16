Function InstallHammerDb {
    [cmdletBinding()]
    Param(
        [parameter(Mandatory = $True)]
        [string] $SourceDir,
        [string] $HamMedia,
        [string] $SQLInstance,
        [string] $ELogFileDir,
        [string] $Destination)
    
    
    
    . "$SourceDir\CreateLogFolders.ps1" 
    . "$SourceDir\WriteLog.ps1" 
    . "$SourceDir\CopyItems.ps1" 
    
    
    # Settings 
    $LogTime = Get-Date -Format "MMMM-dd_HH-mm-ss"
    $ELogFile = $ELogFileDir + $LogTime + "_HammerDBSetupLog_" + $SQLInstance + ".txt"
    $RoboLog = $ELogFileDir + $LogTime + "_RoboCopyDBSetupLog_" + $SQLInstance + ".txt"
    $Fileshare = $SourceDir
    
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
               
    ##Uses PSSession to create connection to remote server 
    $Session = New-PSSession -ComputerName $SQLInstance 
    
    ##Creates the setup log directory on localhost where script being executed 
    try {
        $SetupDir = $SourceDir -replace "HammerScripts", ""
        $SetupDir = $SetupDir + "\SetupLogs"
        $CreateInstallFolder = CreateDir -DirectoryToCreate $SetupDir -ComputerName .
    }
    catch {
        Write-Error -Message "Error whilst creating driectory $SetupDir on LocalMachine see error log within $ELogFile"
        Write-Log -Message "Error was: $_" -Severity Error 
    }
    Write-Log -Message "Message captured was $_" -Severity Information
    
    ##Create the directory in which the HammerDB exeuctable media files need to be placed 
    try {
        $HamDir = $SourceDir -replace "HammerScripts", ""
        $HamDir = $HamDir + "HammerMedia"
        $CreateInstallFolder = CreateDir -DirectoryToCreate $HamDir -ComputerName .
    }
    catch {
        Write-Error -Message "Error whilst creating driectory $HamDir on Local see error log within $ELogFile"
        Write-Log -Message "Error was: $_" -Severity Error 
    }
    Write-Log -Message "Message captured was $_" -Severity Information
    
    ##Tests if the HammerDB Media folder has the required setup executables present, if the folder is empty you are advised to download 
    try {
        If ((Get-ChildItem -Force $HamDir) -eq $Null) {
            echo "The media folder is empty please download the latest version of HammerDb and save it to $HamDir then rerun"
            throw 
            exit
        }
    }
    catch {
        Write-Error -Message "The media folder is empty please download the latest version of HammerDb and save it to $HamDir then rerun"
        Write-Log -Message "The media folder is empty please download the latest version of HammerDb and save it to $HamDir then rerun" -Severity Error 
        throw
        exit
    }
    
    
    ##Creates the HammerDB installation folder on the remote machine
    try {
        $CreateInstallFolder = CreateDir -DirectoryToCreate $Destination -ComputerName $SQLInstance
    }
    catch {
        Write-Error -Message "Error whilst creating driectory $Destination on $SQLInstance see error log within $ELogFile"
        Write-Log -Message "Error was: $_" -Severity Error 
        throw
    }
    Write-Log -Message "Message captured was $CreateInstallFolder" -Severity Information
    
    ##Copies the HammerDB setup\import scripts from the local machine to the target machine
    try {
        Copy-Item -Path "$Fileshare\*" -Destination $Destination -ToSession $Session -Force -ErrorAction stop
    }
    catch {
        Write-Error -Message "Error whilst copying Hammer scripts from $Fileshare\HammerScripts\ to $Destination see error log within $ELogFile"        
        Write-Log -Message " $_" -Severity Error    
        throw
    }
    Write-Log -Message "Copied Files from $Fileshare\HammerScripts\ to $Destination" -Severity Information
    
    ##Copies the HammerDB installation Media from local machine to target machine 
    try { 
        #Copy-Item -Path "$HamMedia\*" -Destination "$Destination\HammerMedia" -Recurse -ToSession $Session -ErrorAction stop}
        $Destination = "\\" + $SQLInstance + "\" + $Destination.Replace(":\", "$\")
        Robocopy "$HamMedia\" "$Destination\HammerMedia" /E	/IS /Log:$RoboLog
    }
    catch {
        Write-Error -Message "Error whilst copying HammerDb executables from $HamMedia\ to $Destination see error log within $ELogFile"
        Write-Log -Message "Error whilst copying HammerDb executables from $HamMedia\ to $Destination :  $_" -Severity Error    
        throw
    }
    Write-Log -Message "Copied Files from $HamMedia\ to $Destination" -Severity Information
    
    ##Uses DBATools Invoke-DbaQuery to create SQL agent benchmark job on target machine  
    try {
        Invoke-DbaQuery -File "$fileshare\CreateHammerDBBenchmarkJob.sql" -SqlInstance $SQLInstance -EnableException
    }
    catch {
        Write-Error -Message "Error whilst setting up HammerDB Benchmark Agent Job: $_ see error log within $ELogFile" 
        Write-Log -Message "Error whilst setting up HammerDB Benchmark Agent Job running script CreateHammerDBBenchmarkJob.sql: $_" -Severity Error    
        throw
    }
    Write-Log -Message "successfully executed $fileshare\CreateHammerDBBenchmarkJob.sql on $SQLInstance" -Severity Information
    
    ##Uses DBATools Invoke-DbaQuery to create SQL agent import job on target machine 
    try {
        Invoke-DbaQuery -File "$fileshare\CreateHammerDBLogImportJob.sql" -SqlInstance $SQLInstance -EnableException
    }
    catch {
        Write-Error -Message "Error whilst setting up HammerDB Import Agent Job: $_ see error log within $ELogFile"
        Write-Log -Message "Error whilst setting up HammerDB Import Agent Job running sript CreateHammerDBLogImportJob.sql: $_" -Severity Error
        throw
        
    }
    Write-Log -Message "successfully executed $fileshare\CreateHammerDBLogImportJob.sql on $SQLInstance" -Severity Information
    write-output "Hammer DB Install completed check logfile within $ELogFile for more info `n open in notepad with command: Notepad $ELogFile"
}
    
##Determines the location where the script is saved and being run from. This will be where your media is downloaded to and setup logs will be saved.
$Root = $MyInvocation.MyCommand.Path -replace "\\HammerScripts\\InstallHammmerDb.ps1", ""
##Command to call the function and start the install
InstallHammerDb -SourceDir "$Root\HammerScripts" -HamMedia "$Root\HammerMedia\HammerDB-4.1-Win\HammerDB-4.1" -SQLInstance "SQL02" -ELogFileDir "$Root\SetupLogs\" -Destination "D:\HammerDbBenchmark"    