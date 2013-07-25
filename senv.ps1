# C:\prgs>@powershell -NoProfile -ExecutionPolicy unrestricted -Command "(New-Object System.Net.WebClient).DownloadFile('%userprofile%/prog/senv.ps1','c:/temp/senv.ps1') ; & c:/temp/senv.ps1 -u"
# C:\prgs>@powershell -NoProfile -ExecutionPolicy unrestricted -Command "(New-Object System.Net.WebClient).DownloadFile('%homedrive%/prog/senv.ps1','c:/temp/senv.ps1') ; & c:/temp/senv.ps1 -u"
# C:\prgs>@powershell -NoProfile -ExecutionPolicy unrestricted -Command "(New-Object System.Net.WebClient).DownloadFile('http://gist.github.com/VonC/5995144/raw/senv.ps1','c:/temp/senv.ps1') ; & c:/temp/senv.ps1 -u"
# http://technet.microsoft.com/en-us/library/ee176949.aspx : Running Windows PowerShell Scripts

# http://stackoverflow.com/questions/2157554/how-to-handle-command-line-arguments-in-powershell
param(
    [alias("u")]
    [switch]
    $update = $false
)
Write-Host "update=$update, Num Args:" $args.Length;
foreach ($arg in $args)
{
  Write-Host "Arg: $arg";
}
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
function mdEnvPath([String]$aVariableName, [String]$afor, [String]$aDefaultPath)
{
  # GetEnvironmentVariable SetEnvironmentVariable http://technet.microsoft.com/en-us/library/ff730964.aspx
  $aPath = [Environment]::GetEnvironmentVariable($aVariableName, [System.EnvironmentVariableTarget]::User)
  if ($aPath -eq $null) {
    Write-Host "%$aVariableName% ($afor) isn't defined."
    # http://social.technet.microsoft.com/Forums/exchange/en-US/3fc59659-c9fe-41e3-9d02-fc41e3bc63f4/asking-for-input-in-powershell
    $actualPath = Read-Host "Please enter %$aVariableName% path (default [$aDefaultPath])"
    $actualPath = $actualPath.Trim()
    if ($actualPath -eq "") {
      $actualPath=$aDefaultPath
    }
  } else {
    $actualPath=$aPath
  }
  md2 "$actualPath" "$aVariableName"
  if ($aPath -eq $null) {
    [Environment]::SetEnvironmentVariable($aVariableName, $actualPath, "User")
  }
  Write-Host "User environment variable %$aVariableName% set to '$actualPath'"
  return $actualPath
}

$prgsInstallVariableName="prgs"
$prgsDefaultPath="C:\prgs"
$prgs=mdEnvPath "$prgsInstallVariableName" "for installing programming tools" "$prgsDefaultPath"

$progInstallVariableName="prog"
$progDefaultPath="$Env:userprofile\prog"
$prog=mdEnvPath "$progInstallVariableName" "for programming data" "$progDefaultPath"

Write-Host "prgs '$prgs', prog '$prog'"

# http://stackoverflow.com/questions/571429/powershell-web-requests-and-proxies
$proxy = [System.Net.WebRequest]::GetSystemWebProxy()
$proxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
$downloader = new-object System.Net.WebClient
$downloader.proxy = $proxy

function installPrg([String]$aprgname, [String]$url, [String]$urlmatch, [String]$urlmatchArc="", [String]$test) {
  # Make sure c:\prgs\xxx exists for application 'xxx'
  $prgdir="$prgs\$aprgname"
  md2 "$prgdir" "$aprgname"
  # http://stackoverflow.com/questions/10550128/powershell-test-if-folder-empty
  # http://social.technet.microsoft.com/wiki/contents/articles/2286.understanding-booleans-in-powershell.aspx
  $mustupdate=-not (Test-Path "$prgdir\*")
  if(-not $mustupdate) {
    $afolder=Get-ChildItem  $prgdir | Where { $_.PSIsContainer } | sort CreationTime  | select -l 1
    Write-Host "afolder='$afolder'" 
    if ( -not (Test-Path "$prgdir/$afolder/$test") ) {
      $mustupdate = $true
    }
  }
  Write-Host "mustupdate='$mustupdate'" 
  if($update -or $mustupdate){
    # http://stackoverflow.com/questions/2182666/powershell-2-0-try-catch-how-to-access-the-exception
    $result=$downloader.DownloadString($url) 
    # http://www.systemcentercentral.com/powershell-quicktip-splitting-a-string-on-a-word-in-powershell-powershell-scsm-sysctr/
    $links = ( $result.split("`"") | where { $_ -match "$urlmatch" } ) # "
    Write-Host "links='$links'" 
    if ( $urlmatchArc -ne "" ) {
      $dwnUrl = ( $links -split " " | where { $_ -match "$urlmatchArc" } ) # "
    } else {
      $dwnUrl = $links
    }
    $dwnUrl = $dwnUrl[0]
    if ( $dwnUrl.StartsWith("/") ) {
      # http://stackoverflow.com/questions/14363214/get-domain-from-url-in-powershell
      $localpath = ([System.Uri]$url).LocalPath
      # http://blogs.technet.com/b/heyscriptingguy/archive/2011/09/21/two-simple-powershell-methods-to-remove-the-last-letter-of-a-string.aspx
      $domain = $url -replace "$localpath$"
      # Write-Host "lp='$url', localpath='$localpath', domain='$domain'"
      $dwnUrl = $domain + $dwnUrl
    }
    # http://stackoverflow.com/questions/4546567/get-last-element-of-pipeline-in-powershell
    $prgfile = $dwnUrl.Split('/') | Select-Object -Last 1
    $prgver = $prgfile.Substring(0,$prgfile.LastIndexOf('.'))
    Write-Host "result='$dwnUrl': prgver='$prgver', prgfile='$prgfile'" 
  }
  if(-not (Test-Path "$prgdir/$prgfile")) {
    if ( Test-Path "$Env:homedrive/$prgfile" ) {
      Write-Host "Copy '$prgfile' from '$Env:homedrive/$prgfile'" 
      Copy-Item -Path "$Env:homedrive/$prgfile" -Destination "$prgdir/$prgfile"
    } else {
      Write-Host "Download '$prgfile' from '$dwnUrl'" 
      $downloader.DownloadFile($dwnUrl, "$prgdir/$prgfile")
    }
  }
}

installPrg "Gow" "https://github.com/bmatzelle/gow/downloads" "gow/.*.exe" "" "bin"

exit 0

# https://github.com/bmatzelle/gow/downloads
$gowVer="Gow-0.7.0"
$gowExe="$gowVer.exe"
$gowFile="$prgs\$gowExe"
$gowDir="$prgs\$gowVer"
$gowUrl="https://github.com/downloads/bmatzelle/gow/$gowExe"



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

$peazipArc  = $peazipUrl -split "/" | where { $_ -match "portable" } 
# http://technet.microsoft.com/en-us/library/ee692804.aspx The String’s the Thing
$peazipVer  = $peazipArc.TrimEnd(".zip")
$peazipFile = "$peazip\$peazipArc"
$peazipDir  = "$peazip\$peazipVer"

Write-Host "peazipArc='$peazipArc', peazipFile='$peazipFile', peazipDir='$peazipDir', peazipUrl='$peazipUrl'" 
if ( ! (Test-Path "$peazipFile") ) {
  Write-Host "Downloading  $peazipUrl to $peazipFile"
  if ( Test-Path "$Env:homedrive/$peazipArc" ) {
    Copy-Item -Path "$Env:homedrive/$peazipArc" -Destination "peazipFile"
  } else {
    $downloader.DownloadFile($peazipUrl, $peazipFile)
  }
}
if ( ! (Test-Path "$peazipDir\peazip.exe") ) {
  $arcHasDir = (unzip -l $peazipFile) -split "`r`n" | where { $_ -match " 0  .*$peazipVer/" }
  Write-Host "arcHasDir='$arcHasDir'" 
  # http://techibee.com/powershell/check-if-a-string-is-null-or-empty-using-powershell/1889 : Check if a string is NULL or EMPTY using PowerShell
  if ( [string]::IsNullOrEmpty($arcHasDir) ) {
    md2 "$peazipDir" "peazip extract folder"
    unzip "$peazipFile" -d "$peazipDir"
  } else {
    unzip "$peazipFile" -d "$peazip"
  }
}
invoke-expression 'doskey pzx=$peazipDir\res\7z\7z.exe x -aos -o"$2" -pdefault -sccUTF-8 `"`$1`"'
invoke-expression 'doskey pzc=$peazipDir\res\7z\7z.exe a -tzip -mm=Deflate -mmt=on -mx5 -w `"`$2`" `"`$1`"'
invoke-expression 'doskey 7z=$peazipDir\res\7z\7z.exe `$*'
invoke-expression 'doskey alias=doskey /macros'