# C:\prgs>@powershell -NoProfile -ExecutionPolicy unrestricted -Command "iex ((new-object net.webclient).DownloadString('%userprofile%/prog/senv.ps1'))"
# C:\prgs>@powershell -NoProfile -ExecutionPolicy unrestricted -Command "iex ((new-object net.webclient).DownloadString('%homedrive%/prog/senv.ps1'))"
# C:\prgs>@powershell -NoProfile -ExecutionPolicy unrestricted -Command "iex ((new-object net.webclient).DownloadString('http://gist.github.com/VonC/5995144/raw/e0d69ae979556cd302c86934afaf686b1a39c1c7/senv.ps1'))"

$prgsInstallVariableName="prgs"
$prgsDefaultPath="C:\prgs"
$prgsPath = [Environment]::GetEnvironmentVariable($prgsInstallVariableName, [System.EnvironmentVariableTarget]::User)
if ($prgsPath -eq $null) {
  # http://technet.microsoft.com/en-us/library/ff730964.aspx
  Write-Host "%PRGS% (for installing programming tools) isn't defined."
  # http://social.technet.microsoft.com/Forums/exchange/en-US/3fc59659-c9fe-41e3-9d02-fc41e3bc63f4/asking-for-input-in-powershell
  $prgs = Read-Host "Please enter %PRGS% path (default [$prgsDefaultPath])"
  $prgs = $prgs.Trim()
  if ($prgs -eq "") {
    $prgs=$prgsDefaultPath
  }
} else {
  $prgs=$prgsPath
}
# http://technet.microsoft.com/en-us/library/ff730955.aspx
if ( ! (Test-Path "$prgs") ) {
  # http://stackoverflow.com/questions/16906170/powershell-create-directory-if-it-does-not-exist
  New-Item -ItemType Directory -Force -Path $prgs > $null
  if ( ! (Test-Path "$prgs") ) {
    Write-Host "No right to create '$prgs' for %PRGS%"
    Exit
  }
}
if ($prgsPath -eq $null) {
  [Environment]::SetEnvironmentVariable($prgsInstallVariableName, $prgs, "User")
}
Write-Host "User environment variable %PRGS% set to '$prgs'"
$progInstallVariableName="prog"
$progDefaultPath="$Env:userprofile\prog"
$progPath = [Environment]::GetEnvironmentVariable($progInstallVariableName, [System.EnvironmentVariableTarget]::User)
if ($progPath -eq $null) {
  Write-Host "%PROG% (for programming data) isn't defined."
  $prog = (Read-Host "Please enter %PRGS% path (default [$progDefaultPath])").Trim()
  if ($prog -eq "") { $prog=$progDefaultPath }
} 
else { $prog=$progPath }
if ( ! (Test-Path "$prog") ) {
  New-Item -ItemType Directory -Force -Path $prog > $null
  if ( ! (Test-Path "$prog") ) {
    Write-Host "No right to create '$prog' for %PROG%"
    Exit
  }
}
if ($progPath -eq $null) {
  [Environment]::SetEnvironmentVariable($progInstallVariableName, $prog, "User")
}
Write-Host "User environment variable %PROG% set to '$prog'"

$gowVer="Gow-0.7.0"
$gowExe="$gowVer.exe"
$gowFile="$prgs\$gowExe"
$gowDir="$prgs\$gowVer"
$gowUrl="https://github.com/downloads/bmatzelle/gow/$gowExe"

# http://stackoverflow.com/questions/571429/powershell-web-requests-and-proxies
$proxy = [System.Net.WebRequest]::GetSystemWebProxy()
$proxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
$downloader = new-object System.Net.WebClient
$downloader.proxy = $proxy


if ( ! (Test-Path "$gowDir\bin") ) {
  Write-Host "Must install '$gowVer' in $gowDir"
  if ( ! (Test-Path "$gowExe") ) {
    Write-Host "Downloading  $gowUrl to $gowExe"
    if ( Test-Path "$Env:homedrive/$gowExe" ) {
      Copy-Item -Path "$Env:homedrive/$gowExe" -Destination "gowFile"
    } else {
      $downloader.DownloadFile($gowUrl, $gowFile)
    }
  }
  # http://unattended.sourceforge.net/installers.php
  invoke-expression "$gowFile /S /D=c:\prgs\$gowVer"
}

function cleanAddPath([String]$cleanPattern, [String]$addPath) {
  Write-Host "cleanPattern '$cleanPattern'`r`naddPath '$addPath'"
  # System and user registry keys: http://support.microsoft.com/kb/104011
  $systemPath=(Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).path
  $newSystemPath=( $systemPath.split(';') | where { $_ -notmatch "$cleanPattern" } ) -join ";"
  # '`r`n' http://stackoverflow.com/questions/1639291/how-do-i-add-a-newline-to-command-output-in-powershell
  Write-Host "systemPath    '$systemPath'`r`nnewSystemPath '$newSystemPath'"

  $userPath=(Get-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Environment' -Name PATH).path
  # '-or' http://www.powershellpro.com/powershell-tutorial-introduction/powershell-tutorial-conditional-logic/
  $newUserPath=( $userPath.split(';') | where { $_ -notmatch "$cleanPattern" -or $_ -eq "$addPath" } ) -join ";"
  Write-Host "userPath    '$userPath'`r`nnewuserPath '$newuserPath'"
}

# http://weblogs.asp.net/soever/archive/2006/11/29/powershell-calling-a-function-with-parameters.aspx
cleanAddPath "\\Gow-" "$gowDir\bin"


# http://technet.microsoft.com/en-us/library/ff730964.aspx
# http://blogs.technet.com/b/heyscriptingguy/archive/2011/07/23/use-powershell-to-modify-your-environmental-path.aspx
# http://stackoverflow.com/questions/714877/setting-windows-powershell-path-variable
# http://wprogramming.wordpress.com/2011/07/18/appending-to-path-with-powershell/

<#
PS Env:\> $a=(Get-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Environment' -Name PATH).path.split(';')
PS Env:\> $b=$a | where { $_ -notmatch "\\H" }
PS Env:\> $b -join ";"

PS Env:\> ( (Get-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Environment' -Name PATH).path.split(';') | where { $_ -notmatch "\\H" } ) -join ";"
#>