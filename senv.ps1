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


# http://serverfault.com/questions/95431/in-a-powershell-script-how-can-i-check-if-im-running-with-administrator-privli
function Test-Administrator {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

# Modify Path http://blogs.technet.com/b/heyscriptingguy/archive/2011/07/23/use-powershell-to-modify-your-environmental-path.aspx
# SetEnvironmentVariable http://stackoverflow.com/questions/714877/setting-windows-powershell-path-variable
# http://wprogramming.wordpress.com/2011/07/18/appending-to-path-with-powershell/
function cleanAddPath([String]$cleanPattern, [String]$addPath) {
  Write-Host "cleanPattern '$cleanPattern'`r`naddPath '$addPath'"

  $isadmin=Test-Administrator
  # System and user registry keys: http://support.microsoft.com/kb/104011
  $systemPath=(Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).path
  Write-Host "systemPath='$systemPath'"
  $newSystemPath=( $systemPath.split(';') | where { $_ -notmatch "$cleanPattern" } ) -join ";"
  # '`r`n' http://stackoverflow.com/questions/1639291/how-do-i-add-a-newline-to-command-output-in-powershell
  if ( $systemPath -ne $newSystemPath -and $isadmin -eq $true ) {
    Write-Host "`r`nsystemPath    '$systemPath'`r`n`r`nnewSystemPath '$newSystemPath'"
    Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name "Path" -Value "$newSystemPath"
  }

  $pathAlreadyThere=$false
  $userPath=(Get-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Environment' -Name PATH).path
  Write-Host "userPath='$userPath'"
  # '-or' http://www.powershellpro.com/powershell-tutorial-introduction/powershell-tutorial-conditional-logic/
  $newUserPath=( $userPath.split(';') | where { $_ -notmatch "$cleanPattern" -or ( $_ -eq "$addPath" -and ($pathAlreadyThere=$true) -eq $true ) } ) -join ";"
  # ( $pathAlreadyThere -eq $false -and ($newSystemPath=$newSystemPath+";ddddddee") -eq $false)
  if( $pathAlreadyThere -eq $false ) {
    $newUserPath=$newUserPath+";"+$addPath
  }
  if ( $addPath -and $userPath -ne $newUserPath ) {
    Write-Host "userPath    '$userPath'`r`nnewuserPath '$newuserPath': pathAlreadyThere='$pathAlreadyThere'"
    Set-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Environment' -Name "Path" -Value "$newuserPath"
  }
  $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding($False)
  [System.IO.File]::WriteAllLines("$prgs\setpath.bat", "set PATH=$newSystemPath;$newUserPath", $Utf8NoBomEncoding)
  # invoke-expression "$prgs\setpath.bat"
}

# http://stackoverflow.com/questions/8588960/determine-if-current-powershell-process-is-32-bit-or-64-bit
# Is this a 64 bit process
function Test-Win64() {
    return [IntPtr]::size -eq 8
}

# http://stackoverflow.com/questions/571429/powershell-web-requests-and-proxies
$proxy = [System.Net.WebRequest]::GetSystemWebProxy()
$proxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
$downloader = new-object System.Net.WebClient
$downloader.proxy = $proxy

function installPrg([String]$aprgname, [String]$url, [String]$urlmatch, [String]$urlmatch_arc="", [String]$urlmatch_ver,
                    [String]$test, [String]$invoke, [switch][alias("z")]$unzip) {
  Write-Host "Install aprgname='$aprgname' from url='$url'`r`nurlmatch='$urlmatch', urlmatch_arc='$urlmatch_arc', urlmatch_ver='$urlmatch_ver'`r`ntest='$test', invoke='$invoke' and unzip='$unzip'"
  # Make sure c:\prgs\xxx exists for application 'xxx'
  $prgdir="$prgs\$aprgname"
  md2 "$prgdir" "$aprgname"
  # http://stackoverflow.com/questions/10550128/powershell-test-if-folder-empty
  # http://social.technet.microsoft.com/wiki/contents/articles/2286.understanding-booleans-in-powershell.aspx
  $mustupdate=-not (Test-Path "$prgdir\*")
  if(-not $mustupdate) {
    $afolder=Get-ChildItem  $prgdir | Where { $_.PSIsContainer -and $_ -match "$urlmatch_arc" } | sort CreationTime | select -l 1
    Write-Host "afolder='$afolder'" 
    if ( -not (Test-Path "$prgdir/$afolder/$test") ) {
      $mustupdate = $true
    }
  }
  Write-Host "mustupdate='$mustupdate'" 
  if( -not $update -and -not $mustupdate){ return "$prgdir\$afolder" }

  # http://stackoverflow.com/questions/2182666/powershell-2-0-try-catch-how-to-access-the-exception
  $result=$downloader.DownloadString($url)
  # http://www.systemcentercentral.com/powershell-quicktip-splitting-a-string-on-a-word-in-powershell-powershell-scsm-sysctr/
  $links = ( $result.split("`"") | where { $_ -match "$urlmatch" } ) # "
  Write-Host "links='$links'"
  if ( $urlmatch_arc -ne "" ) {
    $dwnUrl = ( $links -split " " | where { $_ -match "$urlmatch_arc" } ) # "
    Write-Host "dwnUrl1='$dwnUrl'"
  } else {
    $dwnUrl = $links
    Write-Host "dwnUrl2='$dwnUrl'"
  }
  $dwnUrl = ( $dwnUrl -split " "  )[0]
  Write-Host "dwnUrl3='$dwnUrl'"
  if ( $dwnUrl.StartsWith("/") ) {
    # http://stackoverflow.com/questions/14363214/get-domain-from-url-in-powershell
    $localpath = ([System.Uri]$url).LocalPath
    # http://blogs.technet.com/b/heyscriptingguy/archive/2011/09/21/two-simple-powershell-methods-to-remove-the-last-letter-of-a-string.aspx
    $domain = $url -replace "$localpath$"
    # Write-Host "lp='$url', localpath='$localpath', domain='$domain'"
    $dwnUrl = $domain + $dwnUrl
  }
  # http://stackoverflow.com/questions/4546567/get-last-element-of-pipeline-in-powershell
  $prgfile = $dwnUrl -split "/" | where { $_ -match "$urlmatch_ver" }
  $prgfile_dotindex = $prgfile.LastIndexOf('.')
  Write-Host "prgfile_dotindex='$prgfile_dotindex', " ( $prgfile_dotindex -gt 0 )
  $prgver = if ( $prgfile_dotindex -gt 0 ) { $prgfile.Substring(0,$prgfile_dotindex) } else { $prgfile }
  Write-Host "result='$dwnUrl': prgver='$prgver', prgfile='$prgfile'"

  if ( -not (Test-Path "$prgdir/$prgver/$test") ) {

    if(-not (Test-Path "$prgdir/$prgfile")) {
      if ( Test-Path "$Env:homedrive/$prgfile" ) {
        Write-Host "Copy '$prgfile' from '$Env:homedrive/$prgfile'"
        Copy-Item -Path "$Env:homedrive/$prgfile" -Destination "$prgdir/$prgfile"
      } else {
        Write-Host "Download '$prgfile' from '$dwnUrl'"
        $downloader.DownloadFile($dwnUrl, "$prgdir/$prgfile")
      }
    }

    if ( -not [string]::IsNullOrEmpty($invoke) ) {
      $invoke = $invoke -replace "@FILE@", "$prgdir\$prgfile"
      $invoke = $invoke -replace "@DEST@", "$prgdir\$prgver"
      Write-Host "$prgname: Invoke '$invoke'"
      invoke-expression "$invoke"
    }

    if ( $unzip ) {
      $shellApplication = new-object -com shell.application
      $zipPackage = $shellApplication.NameSpace("$prgdir\$prgfile")
      md2 "$prgdir\tmp" "tmp dir '$prgdir\tmp' for unzipping $prgfile"
      $destination = $shellApplication.NameSpace("$prgdir\tmp")
      Write-Host "prgdir/prgfile: '$prgdir\$prgfile' => unzipping..."
      # http://social.technet.microsoft.com/Forums/windowsserver/en-US/bb65afa5-3eff-4a5d-aabb-5d7f1bd3259f/powershell-script-extracting-a-zipped
      # http://www.howtogeek.com/tips/how-to-extract-zip-files-using-powershell/
      # http://serverfault.com/questions/18872/how-to-zip-unzip-files-in-powershell#201604
      # http://serverfault.com/questions/18872/how-to-zip-unzip-files-in-powershell#comment240131_201604
      $destination.Copyhere($zipPackage.items(), 0x14)
      $afolder=Get-ChildItem  "$prgdir\tmp" | Where { $_.PSIsContainer -and $_.Name -eq "$prgver" } | sort CreationTime | select -l 1
      Write-Host "zip afolder='$afolder', vs. prgver='$prgdir\tmp\$prgver'"
      if ( $afolder ) {
        Write-Host "Move '$prgdir\tmp\$prgver' up to '$prgdir\$prgver'"
        Move-Item "$prgdir\tmp\$prgver" "$prgdir"
        Write-Host "Deleting '$prgdir\tmp'"
        Remove-Item "$prgdir\tmp"
      } else {
        Write-Host "Renaming '$prgdir\tmp' to '$prgdir\$prgver'"
        Rename-Item -Path "$prgdir\tmp" -NewName "$prgdir\$prgver"
      }
    }
  }
  Write-Host "prgdir\prgver='$prgdir\$prgver'"
  return "$prgdir\$prgver"
}

invoke-expression 'doskey alias=doskey /macros'
invoke-expression 'doskey sc=$prgs\setpath.bat'

$peazip = {
# http://scriptinghell.blogspot.fr/2012/10/ternary-operator-support-in-powershell.html (second comment)
$peazip_urlmatch_arc = if ( Test-Win64 ) { "WIN64" } else { "WINDOWS" }
$peazipDir = installPrg -aprgname     "peazip"                   -url          "http://peazip.sourceforge.net/peazip-portable.html" `
                        -urlmatch     "zip/download"             -urlmatch_arc "$peazip_urlmatch_arc" `
                        -urlmatch_ver "$peazip_urlmatch_arc.zip" -test         "peazip.exe" `
                        -invoke       ""                         -unzip

cleanAddPath -cleanPattern "\\peazip" -addPath ""

invoke-expression 'doskey pzx=$peazipDir\res\7z\7z.exe x -aos -o"$2" -pdefault -sccUTF-8 `"`$1`"'
invoke-expression 'doskey pzc=$peazipDir\res\7z\7z.exe a -tzip -mm=Deflate -mmt=on -mx5 -w `"`$2`" `"`$1`"'
invoke-expression 'doskey 7z=$peazipDir\res\7z\7z.exe `$*'
}

$gow = {
#installPrg "Gow" "https://github.com/bmatzelle/gow/downloads" "gow/.*.exe" "" "Gow-" "bin" "@FILE@ /S /D=@DEST@"
$gow_dir   = installPrg -aprgname     "Gow"                      -url          "https://github.com/VonC/gow/releases" `
                        -urlmatch     "gow/releases/download/.*.zip"           -urlmatch_arc "" `
                        -urlmatch_ver "Gow.*.zip"                -test         "bin\gow.bat" `
                        -invoke       ""                         -unzip

cleanAddPath "\\Gow-" "$gow_dir\bin"
}
iex ('&$peazip')
# http://social.technet.microsoft.com/Forums/windowsserver/en-US/7fea96e4-1c42-48e0-bcb2-0ae23df5da2f/powershell-equivalent-of-goto
iex ('&$gow')