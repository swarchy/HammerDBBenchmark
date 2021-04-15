#. "$PSScriptRoot\CreateLogFolders.ps1" 
#. "$PSScriptRoot\WriteLog.ps1" 
#. "$PSScriptRoot\CopyItems.ps1" 

$LocalScripts= "D:\Temp\HammerScripts"

. "$LocalScripts\CreateLogFolders.ps1" 
. "$LocalScripts\WriteLog.ps1" 
. "$LocalScripts\CopyItems.ps1" 

$writeL= "$LocalScripts\WriteLog.ps1" 


# Settings 
$SQLInstance = "SQL02"
$LogTime = Get-Date -Format "MMMM-dd_HH-mm-ss"
$ELogFile = "\\sql01\HammerRemoteLogs\"+$LogTime+"_HammerDBSetupLog_"+$SQLInstance+".txt"
##$Fileshare = '\\DESKTOP-J7VOGRI\Images\HammerDBJob'
$Fileshare = $LocalScripts
            

$Destination = "D:\HammerDbBenchmark"


$Session = New-PSSession -ComputerName $SQLInstance 

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
   $CreateInstallFolder= CreateDir -DirectoryToCreate $Destination -ComputerName $SQLInstance
}
catch {
    Write-Log -Message "Error was: $_" -Severity Error 
    throw}
    Write-Log -Message "Message captured was $CreateInstallFolder" -Severity Information

try{
Copy-Item -Path "$Fileshare\*" -Destination $Destination -ToSession $Session}
catch {
    Write-Log -Message "Error whilst copying Hammer scripts from $Fileshare\HammerScripts\ to $Destination : $_" -Severity Error    
    throw
}
Write-Log -Message "Copied Files from $Fileshare\HammerScripts\ to $Destination" -Severity Information

try{
if (Test-Path "$Destination" -PathType leaf) 
{ 
Copy-Item -Path "$Fileshare\HammerMedia\*" -Destination $Destination -Recurse  -ToSession $Session }}
catch {
    Write-Log -Message "Error whilst copying HammerDb executables from $Fileshare\HammerMedia\ to $Destination :  $_" -Severity Error    
    throw
}
Write-Log -Message "Copied Files from $Fileshare\HammerMedia\ to $Destination" -Severity Information


try{
Invoke-DbaQuery -File "$fileshare\CreateHammerDBBenchmarkJob.sql" -SqlInstance $SQLInstance
}
catch {
    Write-Log -Message "Error whilst setting up HammerDB Agent Job: $_" -Severity Error    
    throw
}
Write-Log -Message "successfully executed $fileshare\CreateHammerDBBenchmarkJob.sql on $SQLInstance" -Severity Information

try{
Invoke-DbaQuery -File "$fileshare\CreateHammerDBLogImportJob.sql" -SqlInstance $SQLInstance
}
catch {
    Write-Log -Message "Error whilst setting up HammerDB Import Agent Job: $_" -Severity Error    
    throw
}
Write-Log -Message "successfully executed $fileshare\CreateHammerDBLogImportJob.sql on $SQLInstance" -Severity Information

