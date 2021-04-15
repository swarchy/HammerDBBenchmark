. "$PSScriptRoot\CreateLogFolders.ps1" 
. "$PSScriptRoot\WriteLog.ps1" 
. "$PSScriptRoot\CopyItems.ps1" 


# Settings 
$LogTime = Get-Date -Format "MMMM-dd_HH-mm-ss"
$ELogFile = "$Destination\"+$LogTime+"_HammerDBSetupLog.txt"
$Fileshare = '\\DESKTOP-J7VOGRI\Images\HammerDBJob'
$Destination = "D:\HammerDbBenchmark\"
$SQLInstance = "SQL02"


if (Get-Module -ListAvailable -Name DbaTools) {
    
 }
else {
    Write-Host "Module does not exist, Attempting to install DBA TOOLS" -ForegroundColor Yellow
    Try
    {
        Find-Module -Name DbaTools -ErrorAction Stop | Install-Module -ErrorAction Stop
    }
    Catch 
    {
        $ErrorMessage = $_.Exception.Message
        write-host "You need to Install DBATools before continuing" -ForegroundColor yellow
     
        Exit
    }

}

try {
    CreateDir -DirectoryToCreate $Destination
}
catch {
    Write-Log -Message "Error was: $_" -Severity Error 
    throw}

try{
Copy-Item -Path "$Fileshare\HammerScripts\*" -Destination $Destination}
catch {
    Write-Log -Message "Error whilst copying Hammer scripts from $Fileshare\HammerScripts\ to $Destination : $_" -Severity Error    
    throw
}


try{
if (Test-Path "$Destination\HammerMedia\" -PathType leaf) 
{ 
Copy-Item -Path "$Fileshare\HammerMedia\*" -Destination $Destination -Recurse  }}
catch {
    Write-Log -Message "Error whilst copying HammerDb executables from $Fileshare\HammerMedia\ to $Destination :  $_" -Severity Error    
    throw
}


try{
Invoke-DbaQuery -File "$fileshare\HammerScripts\CreateHammerDBBenchmarkJob.sql" -SqlInstance $SQLInstance
}
catch {
    Write-Log -Message "Error whilst setting up HammerDB Agent Job: $_" -Severity Error    
    throw
}

try{
Invoke-DbaQuery -File "$fileshare\HammerScripts\CreateHammerDBLogImportJob.sql" -SqlInstance $SQLInstance
}
catch {
    Write-Log -Message "Error whilst setting up HammerDB Import Agent Job: $_" -Severity Error    
    throw
}