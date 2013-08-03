# C:\prgs>@powershell -NoProfile -ExecutionPolicy unrestricted -Command "(New-Object System.Net.WebClient).DownloadFile('%userprofile%/prog/senv.ps1','c:/temp/senv.ps1') ; & c:/temp/senv.ps1 -u"
# C:\prgs>@powershell -NoProfile -ExecutionPolicy unrestricted -Command "(New-Object System.Net.WebClient).DownloadFile('%homedrive%/prog/senv.ps1','c:/temp/senv.ps1') ; & c:/temp/senv.ps1 -u"
# C:\prgs>@powershell -NoProfile -ExecutionPolicy unrestricted -Command "(New-Object System.Net.WebClient).DownloadFile('http://gist.github.com/VonC/5995144/raw/senv.ps1','c:/temp/senv.ps1') ; & c:/temp/senv.ps1 -u"
# C:\prgs>@powershell -NoProfile -ExecutionPolicy unrestricted -Command "(New-Object System.Net.WebClient).DownloadFile('%userprofile%/prog/git/5995144/senv.ps1','c:/prgs/senv.ps1'); & c:/prgs/senv.ps1 -u"
# C:\Users\aUser\prog\git\5995144>@powershell -NoProfile -ExecutionPolicy unrestricted -Command "& %prog%\git\5995144\senv.ps1"
# http://technet.microsoft.com/en-us/library/ee176949.aspx : Running Windows PowerShell Scripts

# http://stackoverflow.com/questions/2157554/how-to-handle-command-line-arguments-in-powershell
param(
    [alias("u")]
    [switch]
    $update = $false
)

$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding($False)

function addbin([String]$filename, [String]$command) {
  Write-Host "WRITE to $filename the command $command"
  if ( Test-Path "$filename" ) {
    Write-Host "Clear $filename"
    Clear-Content "$filename"
  }
  $acommand="@echo off`n"+$command
  [System.IO.File]::WriteAllLines("$filename", "$acommand", $Utf8NoBomEncoding)
}
function addenvs([String]$variable, [String]$value) {
  # http://www.pavleck.net/powershell-cookbook/ch07.html
  $envs=@{}
  Write-Host "WRITE variable $variable the value $value"
  if( Test-Path "$prgs\envs.txt" ) {
    # http://stackoverflow.com/questions/4192072/how-to-process-a-file-in-powershell-line-by-line-as-a-stream
    $reader = [System.IO.File]::OpenText("$prgs\envs.txt")
    try {
      for(;;) {
        $line = $reader.ReadLine()
        if ($line -eq $null) { break }
        # http://www.regular-expressions.info/powershell.html
        if ( $line -match "set ([^`"]+)=([^`"]+)" ) {
          Write-Host "Line '$line' match"
          $envs[$matches[1]] = $matches[2]
        }
      }
    }
    finally {
      $reader.Close()
    }
  }
  $envs[$variable] = $value
  # http://stackoverflow.com/questions/5954503/powershell-hashtable-does-not-write-to-file-as-expected-receive-only-system-c
  Clear-Content "$prgs/envs.txt"
  $acontent=($envs.GetEnumerator() | Sort-Object Name | ForEach-Object { "`nset {0}={1}" -f $_.Name,$_.Value })
  [System.IO.File]::WriteAllLines("$prgs\envs.txt", "$acontent", $Utf8NoBomEncoding)
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

md2 "$prgs\bin" "prgs bin"
md2 "$prog\bin" "prog bin"

Write-Host "prgs '$prgs', prog '$prog'"

# Modify Path http://blogs.technet.com/b/heyscriptingguy/archive/2011/07/23/use-powershell-to-modify-your-environmental-path.aspx
# SetEnvironmentVariable http://stackoverflow.com/questions/714877/setting-windows-powershell-path-variable
# http://wprogramming.wordpress.com/2011/07/18/appending-to-path-with-powershell/
function cleanAddPath([String]$cleanPattern, [String]$addPath) {
  # '`r`n' http://stackoverflow.com/questions/1639291/how-do-i-add-a-newline-to-command-output-in-powershell
  # Write-Host "cleanPattern '$cleanPattern'`r`naddPath '$addPath'"
  # System and user registry keys: http://support.microsoft.com/kb/104011
  $path = $Env:PATH
  if ( (Test-Path "$prgs\path.txt") ) { $path = get-content "$prgs\path.txt" }
  $newPath=$path
  $pathAlreadyThere=$false
  # '-or' http://www.powershellpro.com/powershell-tutorial-introduction/powershell-tutorial-conditional-logic/
  $newPath=( $newPath.split(';') | where { 
    ( ( [string]::IsNullOrEmpty($cleanPattern) -or $_ -notmatch "$cleanPattern" ) -and ( [string]::IsNullOrEmpty($addPath) -or $_ -ne "$addPath"  -or ( $_ -eq "$addPath" -and ($pathAlreadyThere=$true) -eq $true ) ) )
    # Write-Host "....... " + $_ + ": IsNullOrEmpty(cleanPattern)=" + ( [string]::IsNullOrEmpty($cleanPattern) -or $_ -notmatch "$cleanPattern" ) + ", or:" + ( [string]::IsNullOrEmpty($addPath) -or ( $_ -eq "$addPath" -and ($pathAlreadyThere=$true) -eq $true ) ) +", pathAlreadyThere='$pathAlreadyThere' ==> " + ( ( [string]::IsNullOrEmpty($cleanPattern) -or $_ -notmatch "$cleanPattern" ) -or ( [string]::IsNullOrEmpty($addPath) -or ( $_ -eq "$addPath" -and ($pathAlreadyThere=$true) -eq $true ) ) )
  } ) -join ";"
  # Write-Host "pathAlreadyThere=$pathAlreadyThere"
  if(  -not [string]::IsNullOrEmpty($addPath) -and $pathAlreadyThere -eq $false ) {
    # Write-Host "add addPath '$addPath' to newPath='$newPath'"
    $newPath=$newPath+";"+$addPath
  }
  # http://blogs.technet.com/b/heyscriptingguy/archive/2011/03/21/use-powershell-to-replace-text-in-strings.aspx
  $newPath = $newPath -replace ";;", ";"
  # Write-Host "---> path '$path'`r`n===> newPath '$newPath'"
  [System.IO.File]::WriteAllLines("$prgs\path.txt", "$newPath", $Utf8NoBomEncoding)
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

function post([String]$install_folder,[String]$post) {
  if ( $post ) {
    Write-Host "POST called for '$post'"
    $post = $post -replace "@install_folder", "$install_folder"
    invoke-expression "$post" -Debug
    Write-Host "END POST called for '$post'"
  }
}

function install( [String]$invoke, [String]$prgdir, [String]$prgfile, [String]$prgver) {
  if ( -not [string]::IsNullOrEmpty($invoke) ) {
    $invoke = $invoke -replace "@FILE@", "$prgdir\$prgfile"
    $invoke = $invoke -replace "@DEST@", "$prgdir\$prgver"
    md2 "$prgs\tmp" "temp directory"
    Write-Host "${aprgname}: Invoke '$invoke'"
    # http://stackoverflow.com/questions/3592851/executing-a-command-stored-in-a-variable-from-powershell
    $sp="set TEMP=`"$prgs\tmp`""
    $sp=$sp+"`nset TMP=`"$prgs\tmp`""
    $sp=$sp+"`n$invoke"
    [System.IO.File]::WriteAllLines("$prgs\tmp\invoke.bat", "$sp", $Utf8NoBomEncoding)
    Write-Host "prgdir\prgver1='$prgdir\$prgver'"
    # http://stackoverflow.com/a/14606292/6309: make sure to capture the result of the invoke command
    # or it will pollute the prgdir end result.
    $res = invoke-expression "$prgs\tmp\invoke.bat"
    Write-Host "prgdir\prgver2='$prgdir\$prgver'"
    [System.IO.File]::WriteAllLines("$prgs\tmp\res.bat", "$prgdir\$prgver", $Utf8NoBomEncoding)
  }
}

function installPrg([String]$aprgname, [String]$url, [String]$urlmatch, [String]$urlmatch_arc="", [String]$urlmatch_ver,
                    [String]$test, [String]$invoke, [switch][alias("z")]$unzip, [String]$post) {
  Write-Host "Install aprgname='$aprgname' from url='$url'`r`nurlmatch='$urlmatch', urlmatch_arc='$urlmatch_arc', urlmatch_ver='$urlmatch_ver'`r`ntest='$test', invoke='$invoke' and unzip='$unzip'"
  # Make sure c:\prgs\xxx exists for application 'xxx'
  $prgdir="$prgs\$aprgname"
  md2 "$prgdir" "$aprgname"
  # http://stackoverflow.com/questions/10550128/powershell-test-if-folder-empty
  # http://social.technet.microsoft.com/wiki/contents/articles/2286.understanding-booleans-in-powershell.aspx
  $mustupdate=-not (Test-Path "$prgdir\*")
  if(-not $mustupdate) {
    $folder_pattern=$urlmatch_ver -replace '\.(7z|7Z|zip|exe|msi)$',''
	Write-Host "folder_pattern='$folder_pattern'"
    $afolder=Get-ChildItem  $prgdir | Where { $_.PSIsContainer -and $_ -match "$folder_pattern" } | sort CreationTime | select -l 1
    Write-Host "afolder='$afolder'" 
    if ( -not (Test-Path "$prgdir/$afolder/$test") ) {
      $mustupdate = $true
    }
  }
  Write-Host "mustupdate='$mustupdate'" 
  if( -not $update -and -not $mustupdate){ Write-Host "Calling POST" ; post -install_folder "$prgdir\$afolder" -post $post ; return "$prgdir\$afolder" }

  # http://stackoverflow.com/questions/2182666/powershell-2-0-try-catch-how-to-access-the-exception
  $result=$downloader.DownloadString($url)
  # http://www.systemcentercentral.com/powershell-quicktip-splitting-a-string-on-a-word-in-powershell-powershell-scsm-sysctr/
  $result = $result.split("`"") -join "^`""
  $links = ( $result.split("`"") | where { $_ -match "$urlmatch" }  )  # "
  Write-Host "links='$links'"
  if ( $urlmatch_arc -ne "" ) {
    $dwnUrl = ( $links -split "^" | where { $_ -match "$urlmatch_arc" } ) # "
    Write-Host "dwnUrl1='$dwnUrl'"
  } else {
    $dwnUrl = $links
    Write-Host "dwnUrl2='$dwnUrl'"
  }
  $dwnUrl = ( $dwnUrl.split('^')  )[0]
  Write-Host "dwnUrl3='$dwnUrl'"
  if ( $dwnUrl.StartsWith("//") ) {
    $dwnUrl = ([System.Uri]$url).Scheme + ":" + $dwnUrl
  }
  elseif ( $dwnUrl.StartsWith("/") ) {
    # http://stackoverflow.com/questions/14363214/get-domain-from-url-in-powershell
    $localpath = ([System.Uri]$url).LocalPath
    # http://blogs.technet.com/b/heyscriptingguy/archive/2011/09/21/two-simple-powershell-methods-to-remove-the-last-letter-of-a-string.aspx
    $domain = $url -replace "$localpath$"
    # Write-Host "lp='$url', localpath='$localpath', domain='$domain'"
    $dwnUrl = $domain + $dwnUrl
  }
  # Write-Host "dwnUrl === '$dwnUrl'; urlmatch_ver='$urlmatch_ver'"
  # http://stackoverflow.com/questions/4546567/get-last-element-of-pipeline-in-powershell
  $prgfile = $dwnUrl -split "/" | where { $_ -match "$urlmatch_ver" }
  $prgfile_dotindex = $prgfile.LastIndexOf('.')
  Write-Host "prgfile_dotindex='$prgfile_dotindex', " ( $prgfile_dotindex -gt 0 )
  $prgver_space = if ( $prgfile_dotindex -gt 0 ) { $prgfile.Substring(0,$prgfile_dotindex) } else { $prgfile }
  $prgver = $prgver_space -replace " ", "_"
  $prgfile = $prgfile -replace " ", "_"
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
    
    install -invoke $invoke -prgdir $prgdir -prgfile $prgfile -prgver $prgver

    if ( $unzip ) {
      if ( $prgfile.EndsWith(".zip") ) {
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
      }
      elseif ( $prgfile.EndsWith(".7z") ) {
        Write-Host "prgdir/prgfile: '$prgdir\$prgfile' => 7z..."
		# http://social.technet.microsoft.com/Forums/scriptcenter/en-US/65186252-fcf7-4c6c-a11c-697ef0633018/escaping-the-escape-character-in-invokeexpression
		# http://social.technet.microsoft.com/Forums/windowsserver/en-US/cd08c144-7105-421d-bbce-ab27dcee0fb7/escaping-parameters-for-an-external-program-in-invokeexpression
		<#
		$exec = @'
                   & "C:\Program Files\7-Zip\7z.exe" u -mx5 -tzip -r "$DestFileZip" "$DestFile"
                '@
		#>
        $res=invoke-expression "$prgs\peazip\7z\7z.exe x  -aos -o`"$prgdir\tmp```" -pdefault -sccUTF-8 ```"$prgdir\$prgfile```""
        Write-Host "prgdir/prgfile: '$prgdir\$prgfile' => 7z... DONE"
      }
      $afolder=Get-ChildItem  "$prgdir\tmp" | Where { $_.PSIsContainer -and $_.Name -eq "$prgver_space" } | sort CreationTime | select -l 1
      Write-Host "zip afolder='$afolder', vs. prgver='$prgdir\tmp\$prgver'"
      if ( $afolder ) {
        Write-Host "Move '$prgdir\tmp\$prgver' up to '$prgdir\$prgver'"
        Move-Item "$prgdir\tmp\$prgver_space" "$prgdir"
        Rename-Item "$prgdir\$prgver_space" "$prgdir\$prgver"
        Write-Host "Deleting '$prgdir\tmp'"
        Remove-Item "$prgdir\tmp"
      } else {
        Write-Host "Renaming '$prgdir\tmp' to '$prgdir\$prgver'"
        Rename-Item -Path "$prgdir\tmp" -NewName "$prgdir\$prgver"
      }
    }
  }
  Write-Host "prgdir\prgver='$prgdir\$prgver'"
  if ( -not [string]::IsNullOrEmpty($post) ) {
    post -install_folder "$prgdir\$prgver" -post $post
  }
  return "$prgdir\$prgver"
}

invoke-expression 'doskey alias=doskey /macros'
invoke-expression 'doskey h=doskey /history'
invoke-expression 'doskey sc=$prgs\setpath.bat'
invoke-expression 'doskey sp=$prgs\setpath.bat'
invoke-expression 'doskey se=$prgs\setpath.bat'
invoke-expression 'doskey cdd=cd %PROG%'
invoke-expression 'doskey cds=cd %PRGS%'
invoke-expression 'doskey cdg=cd %PROG%\git\5995144'


$peazip = {
# http://scriptinghell.blogspot.fr/2012/10/ternary-operator-support-in-powershell.html (second comment)
$peazip_urlmatch_arc = if ( Test-Win64 ) { "WIN64" } else { "WINDOWS" }
$peazipDir = installPrg -aprgname     "peazip"                   -url          "http://peazip.sourceforge.net/peazip-portable.html" `
                        -urlmatch     "zip/download"             -urlmatch_arc "$peazip_urlmatch_arc" `
                        -urlmatch_ver "$peazip_urlmatch_arc.zip" -test         "peazip.exe" `
                        -invoke       ""                         -unzip        -post "Copy-Item @install_folder\res\7z @install_folder\.. -Force -Recurse"
# http://superuser.com/questions/544520/how-can-i-copy-a-directory-overwriting-its-contents-if-it-exists-using-powershe

cleanAddPath -cleanPattern "\\peazip" -addPath ""

invoke-expression 'doskey pzx=$peazipDir\res\7z\7z.exe x -aos -o"$2" -pdefault -sccUTF-8 `"`$1`"'
invoke-expression 'doskey pzc=$peazipDir\res\7z\7z.exe a -tzip -mm=Deflate -mmt=on -mx5 -w `"`$2`" `"`$1`"'
invoke-expression 'doskey 7z=$peazipDir\res\7z\7z.exe `$*'
}

$gow = {
$gow_dir   = installPrg -aprgname     "Gow"                      -url          "https://github.com/VonC/gow/releases" `
                        -urlmatch     "gow/releases/download/.*.zip"           -urlmatch_arc "" `
                        -urlmatch_ver "Gow.*.zip"                -test         "bin\gow.bat" `
                        -invoke       ""                         -unzip

cleanAddPath "\\Gow-" "$gow_dir\bin"
}

$git = {
$git_dir   = installPrg -aprgname     "git"                      -url          "https://code.google.com/p/msysgit/downloads/list?can=2&q=portable&colspec=Filename+Summary+Uploaded+ReleaseDate+Size+DownloadCount" `
                        -urlmatch     "msysgit.googlecode.com/files/Portable.*.7z"            -urlmatch_arc "" `
                        -urlmatch_ver "Portable.*.7z"            -test         "git-cmd.bat" `
                        -invoke       ""                         -unzip
cleanAddPath "git" "$git_dir\bin"
invoke-expression 'doskey gl=git lg -20'
invoke-expression 'doskey gla=git lg -20 --all'
invoke-expression 'doskey glab=git lg -20 --all --branches'
invoke-expression 'doskey glba=git lg -20 --branches --all'
}

$npp = {
$npp_dir   = installPrg -aprgname     "npp"                      -url          "http://notepad-plus-plus.org/download/" `
                        -urlmatch     "npp.*.bin.zip"            -urlmatch_arc "" `
                        -urlmatch_ver "npp.*.bin.zip"            -test         "notepad++.exe" `
                        -invoke       ""                         -unzip
cleanAddPath "\\npp" ""
invoke-expression 'doskey npp=$npp_dir\notepad++.exe $*'
}

$python = {
$python_urlmatch_arc = if ( Test-Win64 ) { "amd64.msi" } else { "\d\.msi" }
# http://www.python.org/download/releases/2.4/msi/
# http://social.technet.microsoft.com/Forums/windowsserver/en-US/3729e9c2-cb1f-42f7-a4ee-91bc6b101d9a/invokeexpression-syntax-issues
$python_dir   = installPrg -aprgname     "python"                -url          "http://www.python.org/getit/" `
                        -urlmatch     "python-2.*.msi"           -urlmatch_arc "$python_urlmatch_arc" `
                        -urlmatch_ver "python-2.*$python_urlmatch_arc"            -test         "python.exe" `
                        -invoke       "C:\WINDOWS\system32\msiexec.exe /i @FILE@ /l @DEST@.log TARGETDIR=@DEST@ ADDLOCAL=DefaultFeature``,TclTk``,Documentation``,Tools``,Testsuite /qn"
cleanAddPath "\\python" ""
invoke-expression 'doskey python=$python_dir\python.exe $*'
}

$hg = {
$hg_urlmatch_arc = if ( Test-Win64 ) { "-x64.exe" } else { "\d\.exe" }
# http://www.jrsoftware.org/ishelp/index.php?topic=setupcmdline
$hg_dir   = installPrg -aprgname     "hg"                        -url          "http://mercurial.selenic.com/sources.js" `
                        -urlmatch     "Mercurial-.*.exe"         -urlmatch_arc "$hg_urlmatch_arc" `
                        -urlmatch_ver "Mercurial.*$hg_urlmatch_arc"            -test         "hg.exe" `
                        -invoke       "@FILE@ /LOG=@DEST@.log /DIR=@DEST@ /NOICONS /VERYSILENT"
cleanAddPath "\\Mercurial" ""
Write-Host "hg_dir'$hg_dir'"
addbin -filename "$prgs\bin\hg.bat" -command "$hg_dir\hg.exe %*"
invoke-expression 'doskey hg='
}

$bzr = {
# http://www.jrsoftware.org/ishelp/index.php?topic=setupcmdline: bazzar is dead! (since mid-2012)
$bzr_dir   = installPrg -aprgname     "bzr"                      -url          "http://wiki.bazaar.canonical.com/WindowsDownloads" `
                        -urlmatch     "bzr.*-setup.exe"          -urlmatch_arc "" `
                        -urlmatch_ver "bzr.*-setup.exe"          -test         "bzr.exe" `
                        -invoke       "@FILE@ /LOG=@DEST@.log /DIR=@DEST@ /NOICONS /VERYSILENT"
cleanAddPath "\\Bazaar" ""
Write-Host "bzr_dir\bzr.exe='$bzr_dir\bzr.exe'"
invoke-expression 'doskey bzr=$bzr_dir\bzr.exe $*'
}

$go = {
$go_urlmatch_arc = if ( Test-Win64 ) { "-amd64.zip" } else { "-386.zip" }
$go_dir   = installPrg -aprgname     "go"                        -url          "https://code.google.com/p/go/downloads/list?can=2&q=windows+zip&sort=-uploaded&colspec=Filename+Summary+Uploaded+ReleaseDate+Size+DownloadCount" `
                        -urlmatch     "go.*$go_urlmatch_arc"     -urlmatch_arc "$go_urlmatch_arc" `
                        -urlmatch_ver "go.*$go_urlmatch_arc"     -test         "go\bin\go.exe" `
                        -unzip
cleanAddPath "\\go.*" ""
Write-Host "go_dir\go.exe='$go_dir\go.exe'"
addenvs -variable "GOPATH" -value "%PROG%\go"
addenvs -variable "GOROOT" -value "$go_dir\go"
addbin -filename "$prgs\bin\go.bat" -command "$go_dir\go\bin\go.exe %*"
addbin -filename "$prgs\bin\godoc.bat" -command "$go_dir\go\bin\godoc.exe %*"
addbin -filename "$prgs\bin\gogofmt.bat" -command "$go_dir\go\bin\gofmt.exe %*"
invoke-expression 'doskey go='
invoke-expression 'doskey godoc='
invoke-expression 'doskey gofmt='
}

$sbt = {
$sbt_urlmatch_arc = if ( Test-Win64 ) { "x64.zip" } else { "\d\d\d\d.zip" }
$sbt_dir   = installPrg -aprgname     "sbt"                       -url          "http://www.sublimetext.com/3" `
                        -urlmatch     "Sublime.*$sbt_urlmatch_arc"    -urlmatch_arc "$sbt_urlmatch_arc" `
                        -urlmatch_ver "Sublime.*$sbt_urlmatch_arc"    -test         "sublime_text.exe" `
                        -unzip
cleanAddPath "\\Sublime.*" ""
invoke-expression 'doskey sbt=start "Sublime Text 3" "$sbt_dir\sublime_text.exe" $*'

md2 "$sbt_dir\Data\Packages" "for Sublime text packages"
$gosublime="$sbt_dir\Data\Packages\GoSublime"
if ( -not ( Test-Path "$gosublime" ) ) {
  git clone https://github.com/DisposaBoy/GoSublime "$gosublime"
} else {
  git --git-dir="$gosublime\.git" --work-tree="$gosublime" pull origin master
}

md2 "$sbt_dir\Data\Packages\User" "for Sublime text user settings"
$GoSublime_sublime_settings = @"
{
  "env": { "GOPATH": "$PROG/go;$GS_GOPATH",
           "GOROOT": "$PRGS/go/go1.1.1.windows-amd64/go"
         },
}
"@
if ( -not ( Test-Path "$sbt_dir\Data\Packages\User\GoSublime.sublime-settings" ) ) {
  Add-Content -value $GoSublime_sublime_settings -path "$sbt_dir\Data\Packages\User\GoSublime.sublime-settings"
}

$powershell="$sbt_dir\Data\Packages\PowerShell"
if ( -not ( Test-Path "$powershell" ) ) {
  git clone https://github.com/SublimeText/PowerShell "$powershell"
} else {
  git --git-dir="$powershell\.git" --work-tree="$powershell" pull origin master
}

}

$gpg = {
# http://www.jrsoftware.org/ishelp/index.php?topic=setupcmdline: bazzar is dead! (since mid-2012)
$gpg_dir   = installPrg -aprgname     "gpg"                      -url          "http://files.gpg4win.org/Beta/?C=M;O=D" `
                        -urlmatch     "gpg4win-vanilla-.*.exe$"  -urlmatch_arc "" `
                        -urlmatch_ver "gpg4win-vanilla-.*.exe$"  -test         "gpg2.exe" `
                        -invoke       "@FILE@ /LOG=@DEST@.log /DIR=@DEST@ /NOICONS /VERYSILENT"
cleanAddPath "\\gpg" ""
Write-Host "gpg_dir\gpg2.exe='$gpg_dir\bzr.exe'"
invoke-expression 'doskey gpg=$gpg_dir\gpg2.exe $*'
invoke-expression 'doskey gpg2=$gpg_dir\gpg2.exe $*'
}



cleanAddPath "" "$prgs\bin"
cleanAddPath "" "$prog\bin"

# iex ('&$bzr')
# Exit 0
# http://social.technet.microsoft.com/Forums/windowsserver/en-US/7fea96e4-1c42-48e0-bcb2-0ae23df5da2f/powershell-equivalent-of-goto
<#
 iex ('&$peazip')
 iex ('&$gow')
 iex ('&$git')
 iex ('&$npp')
 iex ('&$python')
 iex ('&$hg')
 iex ('&$hg')
 iex ('&$bzr')
 iex ('&$sbt')
#>

 iex ('&$go')
# iex ('&$gpg')

$path=get-content "$prgs/path.txt"
$sp="set PATH=$path"
$sp=$sp+"`nset term=msys"

#http://stackoverflow.com/questions/15041857/powershell-keep-text-formatting-when-reading-in-a-file
$envs=(Get-Content "$prgs/envs.txt") -join "`n"
Write-Host "envs='$envs'"
$sp=$sp+"`n$envs"

$homep=$env:HOME
if ( [string]::IsNullOrEmpty($homep) ) {
  $homep="$Env:HOMEDRIVE$Env:HOMEPATH"
  if ( "$Env:HOMEDRIVE" -ne "C:" ) {
    $homep = "$Env:HOMEDRIVE"
  }
}
$sp=$sp+"`nset HOME=$homep"
$sp=$sp+"`nif exist `"%HOME%\.proxy.bat`" call `"%HOME%\.proxy.bat`""

[System.IO.File]::WriteAllLines("$prgs\setpath.bat", "$sp", $Utf8NoBomEncoding)