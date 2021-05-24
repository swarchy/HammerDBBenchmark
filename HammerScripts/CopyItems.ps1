Function CopyItems{
[cmdletBinding()]
Param(
        [parameter(Mandatory = $True)]
        [string] $FileToCheck,
        [string] $NewPath)

if (Test-Path $FileToCheck -PathType leaf) 
{
    Copy-Item -Path $FileToCheck -Destination $NewPath -ErrorAction stop
    "$FileToCheck moved to $NewPath"
}
}

##CopyItems -FileToCheck "\\Share\OLA-2020H2\LCCDBA_StartCollection.bat" -NewPath "D:\SQLDBA\ScheduledTasks"
