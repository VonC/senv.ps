
# C:\prgs>@powershell -NoProfile -ExecutionPolicy unrestricted -Command "iex ((new-object net.webclient).DownloadString('%userprofile%/prog/senv.ps1'))"
# C:\prgs>@powershell -NoProfile -ExecutionPolicy unrestricted -Command "iex ((new-object net.webclient).DownloadString('%homedrive%/prog/senv.ps1'))"
# C:\prgs>@powershell -NoProfile -ExecutionPolicy unrestricted -Command "iex ((new-object net.webclient).DownloadString('http://gist.github.com/VonC/5995144/raw/e0d69ae979556cd302c86934afaf686b1a39c1c7/senv.ps1'))"

# http://technet.microsoft.com/en-us/library/ff730955.aspx
function md2([String]$apath, [String]$afor) {
  if ( ! (Test-Path "$apath") ) {
    # http://stackoverflow.com/questions/16906170/powershell-create-directory-if-it-does-not-exist
    New-Item -ItemType Directory -Force -Path $apath > $null
    if ( ! (Test-Path "$apath") ) {
      Write-Host "No right to create '$apath' for $afor"
      Exit
    }
  }
}
$prgsInstallVariableName="prgs"
$prgsDefaultPath="C:\prgs"
# GetEnvironmentVariable SetEnvironmentVariable http://technet.microsoft.com/en-us/library/ff730964.aspx
$prgsPath = [Environment]::GetEnvironmentVariable($prgsInstallVariableName, [System.EnvironmentVariableTarget]::User)
if ($prgsPath -eq $null) {
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
md2 "$prgs" "PRGS"
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
md2 "$prog" "%PROG%"
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

# http://serverfault.com/questions/95431/in-a-powershell-script-how-can-i-check-if-im-running-with-administrator-privli
function Test-Administrator {  
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

# http://stackoverflow.com/questions/8588960/determine-if-current-powershell-process-is-32-bit-or-64-bit
# Is this a Wow64 powershell host
function Test-Wow64() {
    return (Test-Win32) -and (test-path env:\PROCESSOR_ARCHITEW6432)
}

# Is this a 64 bit process
function Test-Win64() {
    return [IntPtr]::size -eq 8
}

# Is this a 32 bit process
function Test-Win32() {
    return [IntPtr]::size -eq 4
}

# Modify Path http://blogs.technet.com/b/heyscriptingguy/archive/2011/07/23/use-powershell-to-modify-your-environmental-path.aspx
# SetEnvironmentVariable http://stackoverflow.com/questions/714877/setting-windows-powershell-path-variable
# http://wprogramming.wordpress.com/2011/07/18/appending-to-path-with-powershell/
function cleanAddPath([String]$cleanPattern, [String]$addPath) {
  $isadmin=Test-Administrator
  Write-Host "cleanPattern '$cleanPattern'`r`naddPath '$addPath'"
  # System and user registry keys: http://support.microsoft.com/kb/104011
  $systemPath=(Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).path
  $newSystemPath=( $systemPath.split(';') | where { $_ -notmatch "$cleanPattern" } ) -join ";"
  # '`r`n' http://stackoverflow.com/questions/1639291/how-do-i-add-a-newline-to-command-output-in-powershell
  if ( $systemPath -ne $newSystemPath -and $isadmin -eq $true ) {
    Write-Host "`r`nsystemPath    '$systemPath'`r`n`r`nnewSystemPath '$newSystemPath'"
    Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name "Path" -Value "$newSystemPath"
  }
  
  $pathAlreadyThere=$false
  $userPath=(Get-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Environment' -Name PATH).path
  # '-or' http://www.powershellpro.com/powershell-tutorial-introduction/powershell-tutorial-conditional-logic/
  $newUserPath=( $userPath.split(';') | where { $_ -notmatch "$cleanPattern" -or ( $_ -eq "$addPath" -and ($pathAlreadyThere=$true) -eq $true ) } ) -join ";"
  # ( $pathAlreadyThere -eq $false -and ($newSystemPath=$newSystemPath+";ddddddee") -eq $false)
  if( $pathAlreadyThere -eq $false ) {
    $newUserPath=$newUserPath+";"+$addPath
  }
  if ( $userPath -ne $newUserPath ) {
    Write-Host "userPath    '$userPath'`r`nnewuserPath '$newuserPath': pathAlreadyThere='$pathAlreadyThere'"
    Set-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Environment' -Name "Path" -Value "$newuserPath"
  }

}

# http://weblogs.asp.net/soever/archive/2006/11/29/powershell-calling-a-function-with-parameters.aspx
cleanAddPath "\\Gow-" "$gowDir\bin"

$peazip="$prgs\peazip"
md2 "$peazip" "peazip"
# http://stackoverflow.com/questions/2182666/powershell-2-0-try-catch-how-to-access-the-exception
$url="http://peazip.sourceforge.net/peazip-portable.html"
$result=$downloader.DownloadString($url) 
# http://www.systemcentercentral.com/powershell-quicktip-splitting-a-string-on-a-word-in-powershell-powershell-scsm-sysctr/
$links = ( $result.split("`"") | where { $_ -match "zip/download" } ) # "
Write-Host "links='$links'" 
if ( Test-Win64 ) {
$peazipUrl = ( $links -split " " | where { $_ -match "WIN64" } ) # "
} else {
 $peazipUrl = ( $links -split " " | where { $_ -match "WINDOWS" } ) # "
}
Write-Host "result='$peazipUrl'" 

$peazipArc= $peazipUrl -split "/" | where { $_ -match "portable" } 
$peazipFile = "$peazip\$peazipArc"
$peazipDir = $peazipFile.TrimEnd(".zip")

Write-Host "peazipArc='$peazipArc', peazipFile='$peazipFile', peazipDir='$peazipDir', peazipUrl='$peazipUrl'" 
if ( ! (Test-Path "$peazipFile") ) {
    Write-Host "Downloading  $peazipUrl to $peazipFile"
    if ( Test-Path "$Env:homedrive/$peazipArc" ) {
      Copy-Item -Path "$Env:homedrive/$peazipArc" -Destination "peazipFile"
    } else {
      $downloader.DownloadFile($peazipUrl, $peazipFile)
    }
}