
Function CreateDir{
[cmdletBinding()]
Param(
        [parameter(Mandatory = $True)]
        [string] $DirectoryToCreate,
        [string] $ComputerName)


Invoke-Command -ComputerName $ComputerName -ScriptBlock{
param ($IDirectoryCreate)
Write-Output $WriteL
if ( -not(Test-Path -LiteralPath $IDirectoryCreate)){
    
    try{
        New-Item -Path $IDirectoryCreate -ItemType Directory -ErrorAction Stop | Out-Null
        }
    catch{
            #Write-Log -Message Error was: $_ -Severity Error    
        #    Write-Error -Message "Unable to Create Directory '$IDirectoryCreate'. Error was: $_" -path $ELogFile -Error
            }
            Write-Output "Successfully created directory '$IDirectoryCreate'."
           # Write-Log -Message "Successfully created directory '$DirectoryToCreate'." -path $ELogFile -Severity Information
}else {
        write-output "Directory $DirectoryToCreate Already Existed"
        return 
      #  Write-Log -Message "Directory $DirectoryToCreate Already Existed" -path $ELogFile -Severity Information
        }
       }-ArgumentList (,$DirectoryToCreate)} 

#$ELogFile = "D:\SQLDBA\SQLInstallLog\ErrorLog.log"

#CreateDir -DirectoryToCreate  "D:\SQLDBA\SQLInstallLog\"
#CreateDir -DirectoryToCreate "D:\SQLDBA\Logs" 
#CreateDir -DirectoryToCreate "D:\SQLDBA\Perflogs" 
#CreateDir -DirectoryToCreate "D:\SQLDBA\ScheduledTasks" 

##CreateDir -DirectoryToCreate "D:\HammerDbBenchmark\" -ComputerName SQL02 

