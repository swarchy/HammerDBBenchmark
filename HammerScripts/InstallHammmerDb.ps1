Function InstallHammerDb{
[cmdletBinding()]
Param(
        [parameter(Mandatory = $True)]
        [string] $SourceDir,
        [string] $HamMedia,
        [string] $SQLInstance,
        [string] $ELogFileDir,
        [string] $Destination)


#. "$PSScriptRoot\CreateLogFolders.ps1" 
#. "$PSScriptRoot\WriteLog.ps1" 
#. "$PSScriptRoot\CopyItems.ps1" 

#$SourceDir= "D:\Temp\HammerScripts"

. "$SourceDir\CreateLogFolders.ps1" 
. "$SourceDir\WriteLog.ps1" 
. "$SourceDir\CopyItems.ps1" 


# Settings 
#$SQLInstance = "SQL02"
$LogTime = Get-Date -Format "MMMM-dd_HH-mm-ss"
$ELogFile = $ELogFileDir+$LogTime+"_HammerDBSetupLog_"+$SQLInstance+".txt"
##$Fileshare = '\\DESKTOP-J7VOGRI\Images\HammerDBJob'
$Fileshare = $SourceDir
            

#$Destination = "D:\HammerDbBenchmark"


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
    Write-Error -Message "Error whilst creating driectory $Destination on $SQLInstance see error log within $ELogFile"
    Write-Log -Message "Error was: $_" -Severity Error 
    throw}
    Write-Log -Message "Message captured was $CreateInstallFolder" -Severity Information

try{
Copy-Item -Path "$Fileshare\*" -Destination $Destination -ToSession $Session}
catch {
    Write-Error -Message "Error whilst copying Hammer scripts from $Fileshare\HammerScripts\ to $Destination see error log within $ELogFile"        
    Write-Log -Message "Error whilst copying Hammer scripts from $Fileshare\HammerScripts\ to $Destination : $_" -Severity Error    
    throw
}
Write-Log -Message "Copied Files from $Fileshare\HammerScripts\ to $Destination" -Severity Information

try{
#if (Test-Path "$Destination" -PathType leaf) 
#{ 
Copy-Item -Path "$HamMedia\*" -Destination $Destination -Recurse  -ToSession $Session }#}
catch {
    Write-Error -Message "Error whilst copying HammerDb executables from $HamMedia\ to $Destination see error log within $ELogFile"
    Write-Log -Message "Error whilst copying HammerDb executables from $HamMedia\ to $Destination :  $_" -Severity Error    
    throw
}
Write-Log -Message "Copied Files from $HamMedia\ to $Destination" -Severity Information


try{
Invoke-DbaQuery -File "$fileshare\CreateHammerDBBenchmarkJob.sql" -SqlInstance $SQLInstance -EnableException
}
catch {
    Write-Error -Message "Error whilst setting up HammerDB Benchmark Agent Job: $_ see error log within $ELogFile" 
    Write-Log -Message "Error whilst setting up HammerDB Benchmark Agent Job running script CreateHammerDBBenchmarkJob.sql: $_" -Severity Error    
    throw
}
Write-Log -Message "successfully executed $fileshare\CreateHammerDBBenchmarkJob.sql on $SQLInstance" -Severity Information

try{
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

InstallHammerDb -SourceDir "D:\Temp\HammerScripts" -HamMedia "\\DESKTOP-J7VOGRI\Images\HammerDBJob\HammerMedia" -SQLInstance "SQL02" -ELogFileDir "\\sql01\HammerRemoteLogs\" -Destination "D:\HammerDbBenchmark"