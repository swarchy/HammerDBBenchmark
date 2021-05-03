##Check if DBATools Module is installed, this is required if you choose to write results to
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