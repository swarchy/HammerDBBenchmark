Function CopyItems{
[cmdletBinding()]
Param(
        [parameter(Mandatory = $True)]
        [string] $FileToCheck,
        [string] $NewPath)

if (Test-Path $FileToCheck -PathType leaf) 
{
    Copy-Item -Path $FileToCheck -Destination $NewPath 
    "$FileToCheck moved to $NewPath"
}
}

##CopyItems -FileToCheck "\\DESKTOP-J7VOGRI\Share\OLA-2020H2\LCCDBA_StartCollection.bat" -NewPath "D:\SQLDBA\ScheduledTasks"