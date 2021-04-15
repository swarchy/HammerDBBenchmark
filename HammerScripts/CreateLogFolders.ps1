
Function CreateDir{
[cmdletBinding()]
Param(
        [parameter(Mandatory = $True)]
        [string] $DirectoryToCreate)

if ( -not(Test-Path -LiteralPath $DirectoryToCreate)){
    
    try{
        New-Item -Path $DirectoryToCreate -ItemType Directory -ErrorAction Stop | Out-Null
        }
    catch{
            Write-Log -Message Error was: $_ -Severity Error    
            Write-Error -Message "Unable to Create Directory '$DirectoryToCreate'. Error was: $_" -path $ELogFile -Error
            }
            "Successfully created directory '$DirectoryToCreate'."
            Write-Log -Message "Successfully created directory '$DirectoryToCreate'." -path $ELogFile -Severity Information
}else {
        
        Write-Log -Message "Directory $DirectoryToCreate Already Existed" -path $ELogFile -Severity Information
        }
       }

#$ELogFile = "D:\SQLDBA\SQLInstallLog\ErrorLog.log"

#CreateDir -DirectoryToCreate  "D:\SQLDBA\SQLInstallLog\"
#CreateDir -DirectoryToCreate "D:\SQLDBA\Logs" 
#CreateDir -DirectoryToCreate "D:\SQLDBA\Perflogs" 
#CreateDir -DirectoryToCreate "D:\SQLDBA\ScheduledTasks" 
