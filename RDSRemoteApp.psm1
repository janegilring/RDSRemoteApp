Import-Module RemoteDesktopServices

function New-RDSRemoteApp {
<#
.SYNOPSIS
Creates a new RemoteApp on Windows Server 2008 R2 RDS server the function is executed on.
.DESCRIPTION
Creates a new RemoteApp using the supplied parameters.
.PARAMETER Alias
Alias for the new RemoteApp. Accepts ValueFromPipeline and ValueFromPipelineByPropertyName.
.PARAMETER Applicationpath
Path to the executable file for for the new RemoteApp. This file must exist before creating the new RemoteApp.
Accepts ValueFromPipeline and ValueFromPipelineByPropertyName.
.PARAMETER Displayname
Displayname for the new RemoteApp. This is the application name the users will see. Accepts ValueFromPipeline and ValueFromPipelineByPropertyName.
.PARAMETER ShowinRDWebAccess
True or false. Determines if the RemoteApp should be visible in RD Web Access. Defaults to true if the parameter is omitted. Accepts ValueFromPipeline and ValueFromPipelineByPropertyName.
.PARAMETER UserAssignment
User Assignment for the new RemoteApp, determines which users have access to the new RemoteApp. If this parameter is omitted, all authenticated users have access.
The format must be username@DomainNetBIOSName, e.g. JohnDoe@CONTOSO and "Domain Users@CONTOSO". Separate entries by comma if more than one.
Accepts ValueFromPipeline and ValueFromPipelineByPropertyName.
.PARAMETER CommandlineSetting
0 = Do not allow command-line arguments, 1 = Allow any command-line arguments (not recommended), 2 = Always use the following command-line arguments
.PARAMETER CommandlineArguments
Command-line  argument to be used when starting the new RemoteApp
.EXAMPLE
New-RDSRemoteApp -Alias Notepad -Applicationpath "%windir%\system32\notepad.exe" -Displayname Notepad -ShowinRDWebAccess $false -UserAssignment sales@CONTOSO,hr@CONTOSO
.EXAMPLE
New-RDSRemoteApp -Alias Calc -Applicationpath "%windir%\system32\calc.exe" -Displayname Calculator -CommandLineArgumentMode 2 -CommandlineArguments '/MyCustomParameter'
.NOTES
AUTHOR:    Jan Egil Ring
BLOG:      http://blog.powershell.no
LASTEDIT:  30.06.2010 
#>

[CmdletBinding()]
    param (
        [parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string]$Alias,
         
        [parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string]$Applicationpath,
        [parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string]$Displayname,
        [parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [boolean]$ShowinRDWebAccess = $true,
        [parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        $UserAssignment,
        [parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [int]$CommandlineSetting,
        [parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        $CommandlineArguments
         
    )

#Create the new RemoteApp
if (Test-Path RDS:\RemoteApp\RemoteAppPrograms\$Alias) {
Write-Warning "The application $alias already exist!";return}
else {
New-Item -path RDS:\RemoteApp\RemoteAppPrograms -Name $Alias -applicationpath $Applicationpath | Out-Null
if (Test-Path RDS:\RemoteApp\RemoteAppPrograms\$Alias) {
Write-Host "The application $alias was succesfully created" -ForegroundColor yellow
}
}

#Configure RD Web Access visibility
if ($ShowinRDWebAccess){
Set-Item -path RDS:\RemoteApp\RemoteAppPrograms\$Alias\ShowInWebAccess -Value 1
}
else
{
Set-Item -path RDS:\RemoteApp\RemoteAppPrograms\$Alias\ShowInWebAccess -Value 0
}

#Configure Displayname
if ($Displayname) {
Set-Item -path RDS:\RemoteApp\RemoteAppPrograms\$Alias\DisplayName -Value $Displayname
}

#Configure UserAssignment
if (($UserAssignment -and $UserAssignment.Length -gt 0) -or ($UserAssignment.UserAssignment -and $UserAssignment.UserAssignment.Length -gt 0)) {

if ($UserAssignment.UserAssignment){
$UserAssignment = $UserAssignment.UserAssignment.Split(",")
}

foreach ($item in $UserAssignment){
$item.UserAssignment
New-Item -path RDS:\RemoteApp\RemoteAppPrograms\$Alias\UserAssignment  -Name $item | Out-Null
}
}

#Configure CommandLineSetting
if ($CommandlineSetting -ne $null -and $CommandlineSetting -ne 2) {
Set-Item -path RDS:\RemoteApp\RemoteAppPrograms\$Alias\CommandLineSetting -Value $CommandlineSetting -Force
}

#Configure CommandLineArguments
if ($CommandlineArguments -and ($CommandlineSetting -eq 2)) {
if ($CommandlineArguments.RequiredCommandline) {
$CommandlineArguments = $CommandlineArguments.RequiredCommandline
}
Set-Item -path RDS:\RemoteApp\RemoteAppPrograms\$Alias\CommandLineSetting -Value $CommandlineSetting -RequiredCommandLine $CommandlineArguments -Force
}

}


function Import-RDSRemoteApps {
<#
.SYNOPSIS
Imports all RDS RemoteApps from the provided CSV-file to the Windows Server 2008 R2 RDS server the function is executed on.
.DESCRIPTION
Imports all RDS RemoteApps from the provided CSV-file to the Windows Server 2008 R2 RDS server the function is executed on,
using the function New-RDSRemoteApp. One mandatory parameter: Path
.PARAMETER path
Path to the CSV-file to be imported
.EXAMPLE
Import-RDSRemoteApps -Path C:\temp\RemoteApps.csv
Imports all RemoteApps from the specified CSV-file.
.NOTES
AUTHOR:    Jan Egil Ring
BLOG:      http://blog.powershell.no
LASTEDIT:  30.06.2010
#>

[CmdletBinding()]
    param (
        [parameter(Mandatory=$true)]
        [string]$Path
    )

foreach ($app in (Import-Csv $path)){
$app | New-RDSRemoteApp
}


}

function Export-RDSRemoteApps {
<#
.SYNOPSIS
Exports all RDS RemoteApps from the Windows Server 2008 R2 RDS server the function is executed on.
.DESCRIPTION
Exports all RDS RemoteApps from the Windows Server 2008 R2 RDS server the function is executed on to a CSV-file.
One mandatory parameter: Path
.PARAMETER path
Path to the CSV-file to be exported
.EXAMPLE
Export-RDSRemoteApps -Path C:\temp\RemoteApps.csv
Exports all RemoteApps to the specified CSV-file.
.NOTES
AUTHOR:    Jan Egil Ring
BLOG:      http://blog.powershell.no
LASTEDIT:  30.06.2010
#>

[CmdletBinding()]
    param (
        [parameter(Mandatory=$true)]
        [string]$Path
    )
BEGIN {
$collection = @()
$RemoteApps = Get-ChildItem -path RDS:\RemoteApp\RemoteAppPrograms
}

PROCESS {

 foreach ($app in $RemoteApps) {
 $exportobject = "" | Select-Object Alias,Displayname,Applicationpath,UserAssignment,CommandLineSetting,RequiredCommandLine
 $exportobject.Alias = $app.Name
 $exportobject.Displayname = (Get-ChildItem -path RDS:\RemoteApp\RemoteAppPrograms\$app\DisplayName).CurrentValue
 $exportobject.Applicationpath = (Get-ChildItem -path RDS:\RemoteApp\RemoteAppPrograms\$app\Path).CurrentValue
 $exportobject.CommandLineSetting = (Get-ChildItem -path RDS:\RemoteApp\RemoteAppPrograms\$app\CommandLineSetting).CurrentValue
 $RequiredCommandLineValue = (Get-ChildItem -path RDS:\RemoteApp\RemoteAppPrograms\$app\RequiredCommandLine).CurrentValue
 if ($RequiredCommandLineValue){
 $exportobject.RequiredCommandLine = $RequiredCommandLineValue
 }
 
 $UAarray = @()
 $UA = Get-ChildItem -Path RDS:\RemoteApp\RemoteAppPrograms\$app\UserAssignment
 foreach ($u in $UA) {
 $UAarray += $u.name
 $exportobject.UserAssignment = [system.string]::Join(",",$UAarray)
 
 }
 
 $collection += $exportobject
 }

}

END {
if (-not (Test-Path $path)) {
New-Item -ItemType file -Path $path | Out-Null
}
$collection | Export-Csv -Path $path -NoTypeInformation
}

}

function Remove-RDSRemoteApp {
<#
.SYNOPSIS
Removes the specified RemoteApp from the Windows Server 2008 R2 RDS server the function is executed on.
.DESCRIPTION
 Removes the specified RemoteApp from the Windows Server 2008 R2 RDS server the function is executed on. One mandatory parameter: Alias
.PARAMETER Alias
The alias of the application to be removed
.EXAMPLE
Remove-RDSRemoteApp -Alias Calc
Removes the Calc RemoteApp.
.EXAMPLE
Get-RDSRemoteApp | Foreach-Object {Remove-RDSRemoteApp $_.Alias}
Removes all RemoteApps.
.NOTES
AUTHOR:    Jan Egil Ring
BLOG:      http://blog.powershell.no
LASTEDIT:  30.06.2010
#>

[CmdletBinding()]
    param (
        [parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string]$Alias
    )

#Remove the specified RemoteApp
if (-not (Test-Path RDS:\RemoteApp\RemoteAppPrograms\$Alias)) {
Write-Warning "The application $alias doesn`t exist!";return}
else {
Remove-Item -path RDS:\RemoteApp\RemoteAppPrograms\$Alias -Recurse -Force -Confirm:$false | Out-Null
if (-not (Test-Path RDS:\RemoteApp\RemoteAppPrograms\$Alias)) {
Write-Host "The application $alias was successfully removed" -ForegroundColor yellow
}
}

}

function Get-RDSRemoteApp {
<#
.SYNOPSIS
Retrieves info about the specified RemoteApp from the Windows Server 2008 R2 RDS server the function is executed on.
.DESCRIPTION
 Retrieves info about specified RemoteApp from the Windows Server 2008 R2 RDS server the function is executed on. One optional parameter: Alias
 If Alias is omitted, all RemoteApps are returned.
.PARAMETER Alias
The alias of the application to be retirived
.EXAMPLE
Get-RDSRemoteApp -Alias Calc
.NOTES
AUTHOR:    Jan Egil Ring
BLOG:      http://blog.powershell.no
LASTEDIT:  30.06.2010
#>

[CmdletBinding()]
    param (
        [parameter(Mandatory=$false)]
        [string]$Alias
    )

if ($Alias) {
if (-not (Test-Path RDS:\RemoteApp\RemoteAppPrograms\$Alias)) 
{
Write-Warning "The application $alias doesn`t exist!";return
}
Get-Item -path RDS:\RemoteApp\RemoteAppPrograms\$Alias | Select-Object @{"Name"="Displayname";"Expression"={(Get-Item -path "RDS:\RemoteApp\RemoteAppPrograms\$Alias\DisplayName").CurrentValue}},@{"Name"="Alias";"Expression"={$Alias}},@{"Name"="Path";"Expression"={(Get-Item -path "RDS:\RemoteApp\RemoteAppPrograms\$Alias\Path").CurrentValue}}
}
else
{
foreach ($RemoteApp in (Get-ChildItem -path RDS:\RemoteApp\RemoteAppPrograms)) {
$RemoteApp | Select-Object @{"Name"="Displayname";"Expression"={(Get-Item -path "RDS:\RemoteApp\RemoteAppPrograms\$RemoteApp\DisplayName").CurrentValue}},@{"Name"="Alias";"Expression"={($RemoteApp).Name}},@{"Name"="Path";"Expression"={(Get-Item -path "RDS:\RemoteApp\RemoteAppPrograms\$RemoteApp\Path").CurrentValue}}
}
}
}