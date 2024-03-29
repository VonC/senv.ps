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
    $update = $false,
    [alias("d")]
    [switch]
    $updateDependencies = $false
)

$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding($False)

function addbin([String]$filename, [String]$command) {
  # Write-Host "WRITE to $filename the command $command"
  if ( Test-Path "$filename" ) {
    # Write-Host "Clear $filename"
    Clear-Content "$filename"
  }
  $acommand="@echo off`n"+$command
  [System.IO.File]::WriteAllLines("$filename", "$acommand", $Utf8NoBomEncoding)
}
function addenvs([String]$variable, [String]$value) {
  # http://www.pavleck.net/powershell-cookbook/ch07.html
  $envs=@{}
  # Write-Host "WRITE variable $variable the value '$value'"
  if( Test-Path "$prgs\envs.txt" ) {
    # http://stackoverflow.com/questions/4192072/how-to-process-a-file-in-powershell-line-by-line-as-a-stream
    $reader = [System.IO.File]::OpenText("$prgs\envs.txt")
    try {
      for(;;) {
        $line = $reader.ReadLine()
        if ($line -eq $null) { break }
        $line = $line.Trim()
        # http://www.regular-expressions.info/powershell.html
        if ( $line -match "set ([^`"]+)=([^`"]+)" ) {
          # Write-Host "Line '$line' match"
          $envs[$matches[1]]=$matches[2].Trim()
        }
      }
    }
    finally {
      $reader.Close()
    }
  }
  $envs[$variable]=$value.Trim()
  # http://stackoverflow.com/questions/5954503/powershell-hashtable-does-not-write-to-file-as-expected-receive-only-system-c
  Clear-Content "$prgs/envs.txt"
  # Make sure acontent is a String, not an Array
  # or it will add space at the start and end of each line!
  $acontent=""
  $envs.GetEnumerator() | Sort-Object Name | ForEach-Object {$acontent+=("`nset {0}={1}" -f $_.Name,$_.Value.Trim())}
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

# Write-Host "prgs '$prgs', prog '$prog'"

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

# http://andersrask.sharepointspace.com/Lists/Posts/Post.aspx?ID=5
# http://poshcode.org/3920 Get-WebFile 3.7, by Peter Kriegel, an upgrade to Joel Bennett´s wget script
Function Get-WebFile {
  [CmdletBinding(SupportsShouldProcess=$False)]
  param(
    [Parameter(Mandatory=$true)]
    [String]$url,
    [Parameter(Mandatory=$false)]
    [String]$fileName = $null,
    [Parameter(Mandatory=$false)]
    [String]$hostname = $null,
    [Parameter(Mandatory=$false)]
    [String]$referer = $null,
      [String]$ProxyAdress = $Null,
      [Int]$ProxyPort = 0,
      [String]$ProxyUserName = '',
      [String]$ProxyUserPassword = '',
      [String]$ProxyUserDomain = '',
      [String]$userAgent = 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Iron/29.0.1600.1 Chrome/29.0.1600.1 Safari/537.36',
    [switch]$Passthru,
    [switch]$quiet,
    [switch]$jdk
  )

  # http://stackoverflow.com/questions/9917875/power-shell-web-scraping-ssl-tsl-issue
  [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
  # http://stackoverflow.com/questions/10159066/print-debug-messages-to-console-from-a-powershell-function-that-returns
  # $DebugPreference = 'Continue'
  $req = [System.Net.HttpWebRequest]::Create($url);

  $webclient = new-object System.Net.WebClient

  If($ProxyAdress.length -eq 0){ # no Proxy is given by the User
    # check if a proxy is required
    If (!$webclient.Proxy.IsBypassed($url)) {
      $creds = [net.CredentialCache]::DefaultCredentials
      if ($creds -eq $null) {
        Write-Debug "Default credentials were null. Attempting backup method"
        $cred = get-credential
        $creds = $cred.GetNetworkCredential()
      }
      $proxyaddress = $webclient.Proxy.GetProxy($url).Authority
      Write-Verbose "Using this proxyserver: $proxyaddress"
      $proxy = New-Object System.Net.WebProxy($proxyaddress)
      $proxy.credentials = $creds
      $req.proxy = $proxy
    }
  }
  Else { # Proxy was given by the User
    If($ProxyPort -gt 0){
      $proxy = New-Object System.Net.WebProxy($ProxyAdress,$ProxyPort)
    }
    Else {
      $proxy = New-Object System.Net.WebProxy($ProxyAdress)
    }
    If($ProxyUserName.length -gt 0){
      # if username is given we create the credentials
      $creds = New-Object System.Net.NetworkCredential($ProxyUserName,$ProxyUserPassword,$ProxyUserDomain)
    }
    Else {
      # if no username is given try to get the default credentials
      $creds = [net.CredentialCache]::DefaultCredentials
    }
    if ($creds -eq $null) {
      # no credentials given or found so we as for it
      Write-Debug "Default credentials were null. Attempting backup method"
      $cred = get-credential
      $creds = $cred.GetNetworkCredential()
    }
    $proxy.credentials = $creds
    $req.proxy = $proxy
  }

  #http://stackoverflow.com/questions/518181/too-many-automatic-redirections-were-attempted-error-message-when-using-a-httpw
  $req.CookieContainer = New-Object System.Net.CookieContainer
  if ($userAgent -ne $null) {
    Write-Debug "Setting the UserAgent to `'$userAgent`'"
    $req.UserAgent = $userAgent
  }

  # http://stackoverflow.com/questions/16863455/how-to-do-wget-with-cookies-in-powershell
  $bindingFlags =
    [System.Reflection.BindingFlags]::NonPublic -bor
    [System.Reflection.BindingFlags]::Instance -bor
    [System.Reflection.BindingFlags]::InvokeMethod
  if ( -not [string]::IsNullOrEmpty($hostname) ) {
    # $downloader.Headers.Add("Host", $hostname)
    # http://stackoverflow.com/questions/3334860/an-example-of-using-the-from-and-data-keywords
    # http://stackoverflow.com/questions/359041/request-web-page-in-c-sharp-spoofing-the-host#7560279
    $req.Headers.GetType().InvokeMember("ChangeInternal", $bindingFlags, $null, $req.Headers, ("Host","$hostname"));
    Write-Debug "set Header Host to '$hostname'"
  }
  if ( -not [string]::IsNullOrEmpty($referer) ) {
    $req.Referer = $referer
    Write-Debug "set Header Referer to '$referer'"
  }
  # $sss=$req.Headers.ToString()
  # Write-Debug "req.Headers = '$sss'"

  if ( $jdk ) {
    $c1 = New-Object System.Net.Cookie("testSessionCookie", "Enabled", "/technetwork/java/javase/downloads", ".www.oracle.com")
    $c2 = New-Object System.Net.Cookie("oraclelicensejdk-6u31-oth-JPR", "accept-securebackup-cookie", "/", ".www.oracle.com")
    $c3 = New-Object System.Net.Cookie("gpw_e24", "http%3A%2F%2Fwww.oracle.com%2Ftechnetwork%2Fjava%2Fjavase%2Fdownloads%2Fjdk.html", "/", ".oracle.com")
    # http://www.howtoasp.net/web-forms-tutorials/how-to-create-cookie-in-asp-net/
    $c3.Expires = [DateTime]::Now.AddMinutes(1d);
    $cookies = New-Object System.Net.CookieCollection
    $cookies.Add($c1)
    $cookies.Add($c2)
    $cookies.Add($c3)
    $req.CookieContainer.Add($cookies)
  }

# exit 0

  # http://andersrask.sharepointspace.com/Lists/Posts/Post.aspx?ID=5
  Try {
    $res = $req.GetResponse();
    #$downloader.DownloadFile($dwnUrl, "$prgdir\$prgfile")
  }
  catch {
    Write-Warning "$($Error[0].Exception.ToString())"
    # http://stackoverflow.com/questions/9543818/error-handling-in-system-net-httpwebrequestgetresponse
    $ErrorMessage = $Error[0].Exception.ErrorRecord.Exception.Message;
    $Matched = ($ErrorMessage -match '[0-9]{3}')
    if ($Matched) {
      Write-Host -Object ('HTTP status code was {0} ({1})' -f $HttpStatusCode, $matches[0]);
    }
    else {
      Write-Host -Object $ErrorMessage;
    }

    $HttpWebResponse = $Error[0].Exception.InnerException.Response;
    $HttpWebResponse.GetResponseHeader("X-Detailed-Error");
  }

  if($res.StatusCode -ne 200) {
    $host.ui.WriteErrorLine("Unable to download '$prgfile' from '$dwnUrl', status '$res.StatusCode'")
    # Write-Error "Unable to download '$prgfile' from '$dwnUrl', status '$res.StatusCode'"
    return ""
  }

  $isDir = try{Test-Path -PathType "Container" $fileName}catch {$false}
  Write-Debug "FileName: '$fileName', isDir='$isDir'"
  if($fileName -and !(Split-Path $fileName)) {
    $fileName = Join-Path (Get-Location -PSProvider "FileSystem") $fileName
  }
  elseif((!$Passthru -and ($fileName -eq $null)) -or (($fileName -ne $null) -and ($isDir)))
  {
    [string]$fileName = ([regex]'(?i)filename=(.*)$').Match( $res.Headers["Content-Disposition"] ).Groups[1].Value
    $fileName = $fileName.trim("\/""'")
    if(!$fileName) {
      $fileName = $res.ResponseUri.Segments[-1]
      $fileName = $fileName.trim("\/")
      if(!$fileName) {
        $fileName = Read-Host "Please provide a file name"
      }
      $fileName = $fileName.trim("\/")
      if(!([IO.FileInfo]$fileName).Extension) {
        $fileName = $fileName + "." + $res.ContentType.Split(";")[0].Split("/")[1]
      }
    }
    $fileName = Join-Path $env:TEMP $fileName
  }
  if($Passthru) {
    $encoding = try { [System.Text.Encoding]::GetEncoding($res.CharacterSet ) } catch { $Utf8NoBomEncoding } # 'utf-8'
    [string]$output = ""
  }

  [int]$goal = $res.ContentLength
  $reader = $res.GetResponseStream()
  if($fileName) {
    $writer = new-object System.IO.FileStream $fileName, "Create"
  }
  [byte[]]$buffer = new-object byte[] 4096
  [int]$total = [int]$count = 0
  do
  {
    $count = $reader.Read($buffer, 0, $buffer.Length);
    if($fileName) {
     $writer.Write($buffer, 0, $count);
    }
    if($Passthru){
      $output += $encoding.GetString($buffer,0,$count)
    } elseif(!$quiet) {
      $total += $count
      if($goal -gt 0) {
        Write-Progress "Downloading $url" "Saving $total of $goal" -id 0 -percentComplete (($total/$goal)*100)
      } else {
        Write-Progress "Downloading $url" "Saving $total bytes..." -id 0
      }
    }
  } while ($count -gt 0)

  $reader.Close()
  if($fileName) {
    $writer.Flush()
    $writer.Close()
  }
  if($Passthru){
    $output
  }

  $res.Close();
  if($fileName) {
    ls $fileName
  }
  # Write-Debug "output='$output'"
}

function post([String]$install_folder,[String]$post) {
  if ( $post ) {
    # Write-Host "POST called for '$post'"
    $post = $post -replace "@install_folder", "$install_folder"
    invoke-expression "$post" -Debug
    # Write-Host "END POST called for '$post'"
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
    # Write-Host "prgdir\prgver1='$prgdir\$prgver'"
    # http://stackoverflow.com/a/14606292/6309: make sure to capture the result of the invoke command
    # or it will pollute the prgdir end result.
    $res = invoke-expression "$prgs\tmp\invoke.bat"
    # Write-Host "prgdir\prgver2='$prgdir\$prgver'"
    [System.IO.File]::WriteAllLines("$prgs\tmp\res.bat", "$prgdir\$prgver", $Utf8NoBomEncoding)
  }
}

function uncompress([String]$destination, [String]$archive, [String]$msgPrefix="", [String]$file="",[switch][alias("e")]$extract) {
  # http://social.technet.microsoft.com/Forums/scriptcenter/en-US/65186252-fcf7-4c6c-a11c-697ef0633018/escaping-the-escape-character-in-invokeexpression
  # http://social.technet.microsoft.com/Forums/windowsserver/en-US/cd08c144-7105-421d-bbce-ab27dcee0fb7/escaping-parameters-for-an-external-program-in-invokeexpression
  <#
    $exec = @'
             & "C:\Program Files\7-Zip\7z.exe" u -mx5 -tzip -r "$DestFileZip" "$DestFile"
           '@
  #>
  $argFile=""
  if ( -not [string]::IsNullOrEmpty($file) ) { $argFile=" -- $file" }
  $aMsgPrfix=""
  if ( -not [string]::IsNullOrEmpty($msgPrefix) ) { $aMsgPrfix = "${msgPrefix}: "}
  Write-Host "$aMsgPrefix'$archive'$argFile => 7z..."
  # http://stackoverflow.com/questions/8128276/invoke-expression-dropping-double-quote
  $extractCmd="x"
  if ( $extract ) { $extractCmd = "e"}
  Write-Host "$prgs\peazip\7z\7z.exe $extractCmd -aos -o`"$destination`" -pdefault -sccUTF-8 `"$archive`"$argFile"
  $7zexe = "$prgs\peazip\7z\7z.exe"
  $arg = " $extractCmd -aos `"-o$destination`" -pdefault -sccUTF-8 `"$archive`"$argFile"
  $cmdline = $7zexe, $arg -join ""
  # $cmdline
  $res=Invoke-Expression -command  "$cmdline "
  # $res=invoke-expression '$prgs\peazip\7z\7z.exe x  -aos -o"$prgdir\tmp" -pdefault -sccUTF-8 "$prgdir\$prgfile"'
  Write-Host "$aMsgPrefix'$archive'$argFile => 7z... DONE"
}

function installPrg([String]$aprgname, [String]$url, [String]$urlver="", [String]$urlmatch, [String]$urlmatch_arc="", [String]$urlmatch_ver,
                    [String]$test, [String]$invoke, [switch][alias("z")]$unzip, [String]$post,
                    [String]$url_replace="", [String]$ver_pattern="", [String]$referer="", [String]$hostname="", [switch][alias("v")]$ver_only,
                    [switch]$jdk) {
  Write-Host "Install/Update '$aprgname'"
  # Write-Host "Install aprgname='$aprgname' from url='$url'`r`nurlmatch='$urlmatch', urlmatch_arc='$urlmatch_arc', urlmatch_ver='$urlmatch_ver'`r`ntest='$test', invoke='$invoke' and unzip='$unzip'"
  # Make sure c:\prgs\xxx exists for application 'xxx'
  $prgdir="$prgs\$aprgname"
  md2 "$prgdir" "$aprgname"
  # http://stackoverflow.com/questions/10550128/powershell-test-if-folder-empty
  # http://social.technet.microsoft.com/wiki/contents/articles/2286.understanding-booleans-in-powershell.aspx
  $mustupdate=-not (Test-Path "$prgdir\*")
  if(-not $mustupdate) {
    # Write-Host "folder_pattern 00='$urlmatch_ver'"
    $folder_pattern=$urlmatch_ver -replace '\.(7z|7Z|zip|exe|msi).*',''
    $folder_pattern=$folder_pattern -replace " ", "_"
    $folder_pattern=$folder_pattern -replace "\\$", ""
    # Write-Host "folder_pattern 0 ='$folder_pattern'"
    if ( $ver_only ) {
      $folder_pattern=$folder_pattern -replace "^[^\(]*?\(", ""
      $folder_pattern=$folder_pattern -replace "\).*$", ""
    }
    if( $folder_pattern -eq ".*" ) { $folder_pattern="$aprgname_.+"}
    # Write-Host "folder_pattern 1 ='$folder_pattern'"
    $afolder=Get-ChildItem  $prgdir | Where { $_.PSIsContainer -and $_ -match "$folder_pattern" } | sort CreationTime | select -l 1
    # Write-Host "afolder='$afolder'"
    if ( -not [string]::IsNullOrEmpty($afolder) -and -not (Test-Path "$prgdir/$afolder/$test") ) {
      $mustupdate = $true
    }
    if ( [string]::IsNullOrEmpty($afolder) -and [string]::IsNullOrEmpty($test) ) {
      # Write-Host "filepattern='$folder_pattern.exe'"
      $anexe = Get-ChildItem  $prgdir | Where { -not $_.PSIsContainer -and $_ -match "$folder_pattern.exe" } | sort CreationTime | select -l 1
      # Write-Host "anexe='$anexe' :" + [string]::IsNullOrEmpty($anexe);
      $afolder = $anexe
      if ( [string]::IsNullOrEmpty($anexe) ) {
        $mustupdate = $true
      }
    }
    if ( [string]::IsNullOrEmpty($afolder) -and -not [string]::IsNullOrEmpty($test) ) {
      $mustupdate = $true
    }
  }
  # Write-Host "mustupdate='$mustupdate'"
  if( -not $update -and -not $mustupdate){
    # Write-Host "Calling POST"
    $rpost = post -install_folder "$prgdir\$afolder" -post $post ;
    # Write-Host "Return '$prgdir\$afolder'"
    return "$prgdir\$afolder"
  }
# exit 0
  $ver_number=""
  if ( [string]::IsNullOrEmpty($urlver) -eq $false ){
    $pagever=Get-WebFile -url $urlver -Passthru
    if ($pagever -match "$urlmatch_ver") {
      $ver_number=$matches[1]
      # Write-Host "ver_number='$ver_number', from urlver='$urlver'"
    }
  }
  $url = $url -replace "@VER@", $ver_number
  $urlmatch = $urlmatch -replace "@VER@", $ver_number

  # http://stackoverflow.com/questions/2182666/powershell-2-0-try-catch-how-to-access-the-exception
  # Write-Host "urlmatch='$urlmatch' for url '$url'"
  $result=$page=Get-WebFile -url $url -Passthru
  # http://www.systemcentercentral.com/powershell-quicktip-splitting-a-string-on-a-word-in-powershell-powershell-scsm-sysctr/
  $result = $result.split("`"") -join "^`""
  # Write-Host "urlmatch='$urlmatch' for url '$url': result='$result'"
  $links = ( $result.split("`"") | where { $_ -match "$urlmatch" }  )  # "
  # Write-Host "links='$links'"
  if ( $urlmatch_arc -ne "" ) {
    $dwnUrl = ( $links -split "^" | where { $_ -match "$urlmatch_arc" } ) # "
    # Write-Host "dwnUrl1='$dwnUrl'"
  } else {
    $dwnUrl = $links
    # Write-Host "dwnUrl2='$dwnUrl'"
  }
  # http://stackoverflow.com/questions/10928030/in-powershell-how-can-i-test-if-a-variable-holds-a-numeric-value
  if ( [string]::IsNullOrEmpty($dwnUrl) ) {
    $host.ui.WriteErrorLine("No url found for '$aprgname' in '$url', with urlmatch='$urlmatch'")
    return ""
  }
  if ( $dwnUrl.GetType().Name -eq "String" ) {
    $dwnUrl = ( $dwnUrl.split('^') )[0]
  } else {
    $dwnUrl = ((( $dwnUrl )[0]).split('^'))[0]
  }
  # Write-Host "dwnUrl3='$dwnUrl'"
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
  } elseif ( $dwnUrl.StartsWith("http://") ) {
    # nothing to change
  } elseif ( $dwnUrl.StartsWith("https://") ) {
    # nothing to change
  } else {
    $dwnUrl = $url + '/' + $dwnUrl
    $dwnUrl = $dwnUrl -replace "/\?[^/]+", ""
  }
  # Write-Host "dwnUrlpr='$dwnUrl'"

  $referer = $referer -replace "@dwnUrl@", "$dwnUrl"
  # Write-Host "referer='$referer'"

  if ( -not [string]::IsNullOrEmpty($url_replace) ) {
    $replaces = $url_replace.split(",")
    $replace_what = $replaces[0]
    $replace_with = $replaces[1]
    $dwnUrl = $dwnUrl -replace $replace_what, $replace_with
  }

  # Write-Host "dwnUrl === '$dwnUrl'; urlmatch_ver='$urlmatch_ver'"
  # http://stackoverflow.com/questions/4546567/get-last-element-of-pipeline-in-powershell
  $prgfile = $dwnUrl -split "/" | where { $_ -match "$urlmatch_ver" }
  # Write-Host "prgfile='$prgfile'; urlmatch_ver='$urlmatch_ver'"
  if ( [string]::IsNullOrEmpty($prgfile) ) {
    if ($page -match "$urlmatch_ver") {
      $prgver_space=$prgfile=$matches[1]
      # Write-Host "prgfile=$prgfile, prgver_space='$prgver_space'"
    } elseif ( [string]::IsNullOrEmpty($ver_number) -eq $false ){
      $prgver_space=$prgfile=$ver_number
      # Write-Host "prgfile=$prgfile, prgver_space='$prgver_space' from urlver='$urlver'"
    } else {
      $host.ui.WriteErrorLine("No version number found for '$aprgname' in '$url' or '$urlver', with urlmatch_ver='$urlmatch_ver'")
      return ""
    }
    # http://blogs.technet.com/b/ben_parker/archive/2011/07/28/how-can-i-tell-if-a-string-in-powershell-contains-a-number.aspx
    if ( $prgfile -match "^[0-9].*" ) {
      $prgver_space=$prgfile=$aprgname+ "_" + $prgfile
    }
    $anext=""
    # Write-Host "dwnUrl AA= $dwnUrl"
    if ( $dwnUrl -match "[/h][^/]+(\.[^/\?]*?)(\?.*)?$" ) {
      # Write-Host "prgfile 11=$prgfile" + $matches[1]
      $anext=$matches[1]
      $anext = $anext -replace "\?[^/]+", ""
      # Write-Host "prgfile 22=$prgfile" + $anext
      $prgfile+=$anext
    }
    if ($unzip -and $anext -ne ".zip" -and $anext -ne ".7z") { $prgfile+=".zip" }
    # Write-Host "matches: $prgfile for $urlmatch_ver and $dwnUrl"
  } else {
    # Write-Host "prgfile AA=$prgfile"
    $prgfile = $prgfile -replace "7[zZ]\?[^/]+", "7z"
    $prgfile = $prgfile -replace "[zZ][iI][pP]\?[^/]+", "zip"
    $prgfile_dotindex = $prgfile.LastIndexOf('.')
    # Write-Host "prgfile_dotindex='$prgfile_dotindex', " ( $prgfile_dotindex -gt 0 )
    $prgver_space = if ( $prgfile_dotindex -gt 0 ) { $prgfile.Substring(0,$prgfile_dotindex) } else { $prgfile }
    # Write-Host "prgfile=$prgfile, prgver_space='$prgver_space' ===="
  }

  $prgver = $prgver_space -replace "\s+:\s+", " "
  $prgver = $prgver -replace " ", "_"
  $prgver = $prgver -replace "(\(|\))", ""
  $prgfile = $prgfile -replace "\s+:\s+", " "
  $prgfile = $prgfile -replace " ", "_"
  $prgfile = $prgfile -replace "(\(|\))", ""

  if ( -not [string]::IsNullOrEmpty($ver_pattern) ) {
    $prgfile -match $ver_pattern
    $aver = $matches[1]
    $dwnUrl = $dwnUrl -replace "@VER@", $aver
  }
  # Write-Host "result='$dwnUrl': prgver='$prgver', prgfile='$prgfile': " + (Test-Path "$prgdir/$prgver/$test")
  # Write-Host "TestPath='$prgdir/$prgver/$test'"
# exit 0

  if ( -not (Test-Path "$prgdir/$prgver/$test") ) {

    if(-not (Test-Path "$prgdir/$prgfile")) {
      if ( Test-Path "$Env:homedrive/$prgfile" ) {
        Write-Host "Copy '$prgfile' from '$Env:homedrive/$prgfile'"
        Copy-Item -Path "$Env:homedrive/$prgfile" -Destination "$prgdir/$prgfile"
      } else {
        Write-Host "Download '$prgfile' from '$dwnUrl' ====> '$prgdir\$prgfile'"
        $referer = $referer -replace "@dwnUrl@", $dwnUrl
#exit 0
        # http://stackoverflow.com/questions/7808227/conditionally-specifying-switch-parameters-in-powershell
        $rgetwebfile = Get-WebFile -url $dwnUrl -filename "$prgdir/$prgfile" -hostname $hostname -referer $referer -jdk:$jdk
      }
    }
#exit 0
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
        $uncompress=uncompress -destination "$prgdir\tmp" -archive "$prgdir\$prgfile" -msgPrefix "prgdir/prgfile"
      }
      $files = Get-ChildItem  "$prgdir\tmp"
      $afolder=$files | Where { $_.PSIsContainer -and $_.Name -eq "$prgver_space" } | sort CreationTime | select -l 1
      Write-Host "zip afolder='$afolder', vs. prgver='$prgdir\tmp\$prgver': prgver_space='$prgver_space'"
      if ( -not $afolder ) {
        # http://stackoverflow.com/questions/11526285/how-to-count-objects-in-powershell
        $folders = $files | where-object { $_.PSIsContainer }
        $ftmp = $files | where-object { -not $_.PSIsContainer }
        # Write-Host "folders: '$folders', ftmp: '$ftmp'"
        if ( ($folders|measure).Count -eq 1 -and ($ftmp|measure).Count -eq 0 ) {
          $afolder = $folders | select -l 1
        }
      }
      if ( $afolder ) {
        Write-Host "Move '$prgdir\tmp\$afolder' up to '$prgdir\$prgver'"
        Move-Item "$prgdir\tmp\$afolder" "$prgdir"
        if ( $afolder -ne $prgver -and ("$prgdir\$afolder" -ne "$prgdir\$prgver")) {
          Rename-Item "$prgdir\$afolder" "$prgdir\$prgver"
        }
        Write-Host "Deleting '$prgdir\tmp'"
        Remove-Item "$prgdir\tmp"
      } else {
        Write-Host "Renaming '$prgdir\tmp' to '$prgdir\$prgver'"
        Rename-Item -Path "$prgdir\tmp" -NewName "$prgdir\$prgver"
      }
    }

    if ( $jdk ) {
      Write-Host "JDK loaded to '$prgdir/$prgfile' from '$dwnUrl'"
      $prglinuxfile = $prgfile -replace "-windows-", "-linux-"
      $prglinuxfile = $prglinuxfile -replace ".exe", ".tar.gz"
      $dwnlinuxUrl = $dwnUrl -replace "-windows-", "-linux-"
      $dwnlinuxUrl = $dwnlinuxUrl -replace ".exe", ".tar.gz"
      Write-Host "JDK loaded to '$prgdir/$prglinuxfile' from '$dwnlinuxUrl'"

      if(-not (Test-Path "$prgdir/$prglinuxfile")) {
        if ( Test-Path "$Env:homedrive/$prglinuxfile" ) {
          Write-Host "Copy '$prglinuxfile' from '$Env:homedrive/$prglinuxfile'"
          Copy-Item -Path "$Env:homedrive/$prglinuxfile" -Destination "$prgdir/$prglinuxfile"
        } else {
          Write-Host "Download '$prglinuxfile' from '$dwnlinuxUrl' ====> '$prgdir\$prglinuxfile'"
          # http://stackoverflow.com/questions/7808227/conditionally-specifying-switch-parameters-in-powershell
          $rgetwebfile = Get-WebFile -url $dwnlinuxUrl -filename "$prgdir/$prglinuxfile" -hostname $hostname -referer $referer -jdk:$jdk
        }
      }

      if(-not (Test-Path "$prgdir/$prgver/tools.zip")) {
        $uncompress=uncompress -destination "$prgdir\$prgver" -archive "$prgdir\$prgfile" -msgPrefix "prgdir/prgfile" -file "tools.zip"
      }

      $prglinuxfile2 = $prglinuxfile -replace ".gz", ""
      if(-not (Test-Path "$prgdir/$prglinuxfile2")) {
        $uncompress=uncompress -destination "$prgdir" -archive "$prgdir\$prglinuxfile" -msgPrefix "prgdir/prglinuxfile" -file "$prglinuxfile2"
      }

      $srcPath=Invoke-Expression -command  "$prgs\peazip\7z\7z.exe l -r $prgdir\$prglinuxfile2 -- src.zip "
      [string]$srcPath = ([regex]'(?i).*\s(\S+\\src.zip).*$').Match( $srcPath ).Groups[1].Value
      # Write-Host "srcPath='$srcPath'"

      if(-not (Test-Path "$prgdir/$prgver/src.zip")) {
        $uncompress=uncompress -destination "$prgdir\$prgver" -archive "$prgdir\$prglinuxfile2" -msgPrefix "prgdir/prglinuxfile2" -file "$srcPath" -extract
      }
      if(-not (Test-Path "$prgdir/$prgver/release")) {
        $uncompress=uncompress -destination "$prgdir\$prgver" -archive "$prgdir\$prgver\tools.zip" -msgPrefix "prgdir/prgver/tools"
      }
      # http://stackoverflow.com/questions/8677628/recursive-file-search-using-powershell
      $unpack = Get-ChildItem -Path "$prgdir\$prgver" -Filter "unpack*.exe" -Recurse  | Select-Object -First 1
      # Write-Host ("unpack '" + $unpack.Name + "' => '" + $unpack.FullName + "'")
      $unpack = $unpack.FullName
      $packs = Get-ChildItem -Path "$prgdir\$prgver" -Filter "*.pack" -Recurse
      # http://stackoverflow.com/questions/11568221/using-foreach-with-get-childitem-recurse
      foreach($pack in $packs){
        # Write-Host ("pack '" + $pack.Name + "' => '" + $pack.FullName + "'")
        $apack = $pack.FullName
        $nopack = $apack -replace ".pack", ".jar"
        if (-not (Test-Path "$nopack")) {
          Write-Host ("Unpack '$apack'")
          $srcPath=Invoke-Expression -command  "$unpack $apack $nopack"
        }
      }
    }

    $rinst = install -invoke $invoke -prgdir $prgdir -prgfile $prgfile -prgver $prgver

  }
  # Write-Host "prgdir\prgver='$prgdir\$prgver'"
  if ( -not [string]::IsNullOrEmpty($post) ) {
    $rpost = post -install_folder "$prgdir\$prgver" -post $post
  }
  return "$prgdir\$prgver"
}

invoke-expression 'doskey sc=%prgs%\setpath.bat ; doskey /exename=sc sc=%prgs%\setpath.bat ; doskey sc=%prgs%\setpath.bat'
invoke-expression 'doskey sp=%prgs%\setpath.bat ; doskey /exename=sp sp=%prgs%\setpath.bat'
invoke-expression 'doskey se=%prgs%\setpath.bat ; doskey /exename=se se=%prgs%\setpath.bat'
invoke-expression 'doskey cdd=cd %PROG% ; doskey /exename=cdd cdd=cd %PROG%'
invoke-expression 'doskey cds=cd %PRGS% ; doskey /exename=cds cds=cd %PRGS%'
invoke-expression 'doskey cdg=cd %PROG%\git\senv ; doskey /exename=cdg cdg=cd %PROG%\git\senv'
invoke-expression 'doskey cdgo=cd %PROG%\go\src ; doskey /exename=cdgo cdgo=cd %PROG%\go\src'


$peazip = {
# http://scriptinghell.blogspot.fr/2012/10/ternary-operator-support-in-powershell.html (second comment)
$peazip_urlmatch_arc = if ( Test-Win64 ) { "WIN64" } else { "WINDOWS" }
$peazipDir = installPrg -aprgname     "peazip"                   -url          "http://peazip.sourceforge.net/peazip-portable.html" `
                        -urlmatch     "zip/download"             -urlmatch_arc "$peazip_urlmatch_arc" `
                        -urlmatch_ver "$peazip_urlmatch_arc.zip" -test         "peazip.exe" `
                        -invoke       ""                         -unzip        -post "Copy-Item @install_folder\res\7z @install_folder\.. -Force -Recurse" `
						-url_replace  'sourceforge.net/projects/peazip/files/(.*?)/download,netcologne.dl.sourceforge.net/project/peazip/$1'

# http://superuser.com/questions/544520/how-can-i-copy-a-directory-overwriting-its-contents-if-it-exists-using-powershe

cleanAddPath -cleanPattern "\\peazip" -addPath ""

invoke-expression 'doskey pzx=$peazipDir\res\7z\7z.exe x -aos -o"$2" -pdefault -sccUTF-8 `"`$1`" ; doskey /exename=pzx pzx=$peazipDir\res\7z\7z.exe x -aos -o"$2" -pdefault -sccUTF-8 `"`$1`"'
invoke-expression 'doskey pzc=$peazipDir\res\7z\7z.exe a -tzip -mm=Deflate -mmt=on -mx5 -w `"`$2`" `"`$1`" ; doskey /exename=pzc pzc=$peazipDir\res\7z\7z.exe a -tzip -mm=Deflate -mmt=on -mx5 -w `"`$2`" `"`$1`"'
invoke-expression 'doskey 7z=$peazipDir\res\7z\7z.exe `$* ; doskey /exename=7z 7z=$peazipDir\res\7z\7z.exe `$*'
}

$global:gow_dir   = ""
$gow = {
$gow_dir   = installPrg -aprgname     "Gow"                      -url          "https://github.com/VonC/gow/releases" `
                        -urlmatch     "gow/releases/download/.*.zip"           -urlmatch_arc "" `
                        -urlmatch_ver "Gow.*.zip"                -test         "bin\gow.bat" `
                        -invoke       ""                         -unzip

cleanAddPath "\\Gow-" ""
# http://stackoverflow.com/questions/12535419/powershell-setting-a-global-variable-from-a-function-where-the-global-variable-n
Set-Variable -Name "gow_dir" -Value $gow_dir -Scope Global
invoke-expression 'doskey grep=$gow_dir\bin\grep.exe `$* ; doskey /exename=grep grep=$gow_dir\bin\grep.exe `$*'
}

$global:git_dir = ""
$git = {
$git_dir   = installPrg -aprgname     "git"                      -url          "https://github.com/git-for-windows/git/releases" `
                        -urlmatch     "git-for-windows/git/releases/download/.*.7z.exe"            -urlmatch_arc "" `
                        -urlver "https://github.com/git-for-windows/git/releases" `
                        -urlmatch_ver "Git-([^-]*?)-" -ver_only `
                                    -test         "git-cmd.exe" `
                        -invoke       ""                         -unzip
cleanAddPath "git" ""
invoke-expression 'doskey gl=git lg -20 ; doskey /exename=gl gl=git lg -20'
invoke-expression 'doskey gla=git lg -20 --all ; doskey /exename=gla gla=git lg -20 --all'
invoke-expression 'doskey glab=git lg -20 --all --branches ; doskey /exename=glab glab=git lg -20 --all --branches'
invoke-expression 'doskey glba=git lg -20 --branches --all ; doskey /exename=glba glba=git lg -20 --branches --all'
Set-Variable -Name "git_dir" -Value $git_dir -Scope Global
}

$npp = {
$npp_dir   = installPrg -aprgname     "npp"                      -url          "http://notepad-plus-plus.org/download/" `
                        -urlmatch     "npp.*.bin.zip"            -urlmatch_arc "" `
                        -urlmatch_ver "npp.*.bin.zip"            -test         "notepad++.exe" `
                        -invoke       ""                         -unzip
cleanAddPath "\\npp" ""
invoke-expression 'doskey npp=$npp_dir\notepad++.exe $* ; doskey /exename=npp npp=$npp_dir\notepad++.exe $*'
}

$python = {
$python_urlmatch_arc = if ( Test-Win64 ) { "amd64.msi" } else { "\d\.msi" }
# http://www.python.org/download/releases/2.4/msi/
# http://social.technet.microsoft.com/Forums/windowsserver/en-US/3729e9c2-cb1f-42f7-a4ee-91bc6b101d9a/invokeexpression-syntax-issues
$python_dir   = installPrg -aprgname     "python"                -url          "http://www.python.org/getit/" `
                        -urlmatch     "python-2.*.msi"           -urlmatch_arc "$python_urlmatch_arc" `
                        -urlmatch_ver "python-2.*$python_urlmatch_arc"            -test         "python.exe" `
                        -invoke       "C:\WINDOWS\system32\msiexec.exe /i @FILE@ /l @DEST@.log TARGETDIR=@DEST@ ADDLOCAL=DefaultFeature`,TclTk`,Documentation`,Tools`,Testsuite /qn"
cleanAddPath "\\python" ""
invoke-expression 'doskey python=$python_dir\python.exe $* ; doskey /exename=python python=$python_dir\python.exe $*'
}

$global:hg_dir = ""
$hg = {
$hg_urlmatch_arc = if ( Test-Win64 ) { "-x64.exe" } else { "\d\.exe" }
# http://www.jrsoftware.org/ishelp/index.php?topic=setupcmdline
$hg_dir   = installPrg -aprgname     "hg"                        -url          "http://mercurial.selenic.com/sources.js" `
                        -urlmatch     "Mercurial-.*.exe"         -urlmatch_arc "$hg_urlmatch_arc" `
                        -urlmatch_ver "Mercurial.*$hg_urlmatch_arc"            -test         "hg.exe" `
                        -invoke       "@FILE@ /LOG=@DEST@.log /DIR=@DEST@ /NOICONS /VERYSILENT"
cleanAddPath "\\Mercurial" ""
# Write-Host "hg_dir='$hg_dir'"
Set-Variable -Name "hg_dir" -Value $hg_dir -Scope Global
}

$bzr = {
# http://www.jrsoftware.org/ishelp/index.php?topic=setupcmdline: bazzar is dead! (since mid-2012)
$bzr_dir   = installPrg -aprgname     "bzr"                      -url          "http://wiki.bazaar.canonical.com/WindowsDownloads" `
                        -urlmatch     "bzr.*-setup.exe"          -urlmatch_arc "" `
                        -urlmatch_ver "bzr.*-setup.exe"          -test         "bzr.exe" `
                        -invoke       "@FILE@ /LOG=@DEST@.log /DIR=@DEST@ /NOICONS /VERYSILENT"
cleanAddPath "\\Bazaar" ""
# Write-Host "bzr_dir\bzr.exe='$bzr_dir\bzr.exe'"
invoke-expression 'doskey bzr= ; doskey /exename=bzr bzr='
addbin -filename "$prgs\bin\bzr.bat" -command "$bzr_dir\bzr.exe %*"
}

$global:go_dir   = ""
$go = {
$go_urlmatch_arc = if ( Test-Win64 ) { "-amd64.zip" } else { "-386.zip" }
$go_dir   = installPrg -aprgname     "go"                        -url          "https://code.google.com/p/go/downloads/list?can=2&q=windows+zip&sort=-uploaded&colspec=Filename+Summary+Uploaded+ReleaseDate+Size+DownloadCount" `
                        -urlmatch     "go.*$go_urlmatch_arc"     -urlmatch_arc "$go_urlmatch_arc" `
                        -urlmatch_ver "go.*$go_urlmatch_arc"     -test         "bin\go.exe" `
                        -unzip
cleanAddPath "\\go(?!w).*" ""
# Write-Host "go_dir\go.exe='$go_dir\go.exe'"
addenvs -variable "GOPATH" -value "%PROG%\go"
addenvs -variable "GOROOT" -value "$go_dir"
addbin -filename "$prgs\bin\go.bat" -command "$go_dir\bin\go.exe %*"
addbin -filename "$prgs\bin\godoc.bat" -command "$go_dir\bin\godoc.exe %*"
addbin -filename "$prgs\bin\gogofmt.bat" -command "$go_dir\bin\gofmt.exe %*"
invoke-expression 'doskey go= ; doskey /exename=go go='
invoke-expression 'doskey godoc= ; doskey /exename=godoc godoc='
invoke-expression 'doskey gofmt= ; doskey /exename=gofmt gofmt='
Set-Variable -Name "go_dir" -Value $go_dir -Scope Global
}

$sbt = {
$sbt_urlmatch_arc = if ( Test-Win64 ) { "x64.zip" } else { "\d\d\d\d.zip" }
$sbt_dir   = installPrg -aprgname     "sbt"                       -url          "http://www.sublimetext.com/3" `
                        -urlmatch     "Sublime.*$sbt_urlmatch_arc"    -urlmatch_arc "$sbt_urlmatch_arc" `
                        -invoke       "if not exist @DEST@\\..\\Data (move @DEST@\\Data @DEST@\\..) & if not exist @DEST@\\_Data (move @DEST@\\Data @DEST@\\_Data) && mklink /J @DEST@\\Data @DEST@\\..\Data" `
                        -urlmatch_ver "Sublime.*$sbt_urlmatch_arc"    -test         "sublime_text.exe" `
                        -unzip
cleanAddPath "\\Sublime.*" ""
invoke-expression 'doskey sbt=start "Sublime Text 3" "$sbt_dir\sublime_text.exe" $* ; doskey /exename=sbt sbt=start "Sublime Text 3" "$sbt_dir\sublime_text.exe" $*'

md2 "$sbt_dir\Data\Packages" "for Sublime text packages"
$gosublime="$sbt_dir\Data\Packages\GoSublime"
if ( -not ( Test-Path "$gosublime" ) ) {
  git clone https://github.com/DisposaBoy/GoSublime "$gosublime"
} elseif ($updateDependencies) {
  git --git-dir="$gosublime\.git" --work-tree="$gosublime" pull origin master
}

$powershell="$sbt_dir\Data\Packages\PowerShell"
if ( -not ( Test-Path "$powershell" ) ) {
  git clone https://github.com/SublimeText/PowerShell "$powershell"
} elseif ($updateDependencies) {
  git --git-dir="$powershell\.git" --work-tree="$powershell" pull origin master
}
md2 "$sbt_dir\Data\Packages\User" "for Sublime text user settings"

$goimports="$sbt_dir\Data\Packages\GoImports"
if ( -not ( Test-Path "$goimports" ) ) {
  git clone https://VonC@github.com/VonC/sublime_goimports "$goimports"
} elseif ($updateDependencies) {
  git --git-dir="$goimports\.git" --work-tree="$goimports" pull origin master
  invoke-expression 'cmd /C "set GOPATH=$sbt_dir\Data\Packages\GoImports&& go get github.com/bradfitz/goimports"'
}

}

$global:gpg_dir   = ""
$gpg = {
# http://www.gpg4win.org/doc/en/gpg4win-compendium_35.html
$gpg_dir   = installPrg -aprgname     "gpg"                      -url          "http://files.gpg4win.org/?C=M;O=D" `
                        -urlmatch     "gpg4win-vanilla-.*.exe(?!.sig)"  -urlmatch_arc "" `
                        -urlmatch_ver "gpg4win-vanilla-.*.exe(?!.sig)"  -test         "gpg2.exe" `
                        -invoke       "@FILE@ /S /D=@DEST@"
cleanAddPath "\\gpg" ""
# Write-Host "gpg_dir\gpg2.exe='$gpg_dir\gpg2.exe'"
if(-not (Test-Path "$gpg_dir\gpg.exe")) {
  Copy-Item -Path "$gpg_dir\gpg2.exe" -Destination "$gpg_dir\gpg.exe"
}
Set-Variable -Name "gpg_dir" -Value $gpg_dir -Scope Global
}

$procexp = {
$procexp_dir   = installPrg -aprgname     "procexp"              -url          "http://technet.microsoft.com/en-us/sysinternals/bb896653" `
                        -urlmatch     "ProcessExplorer.zip"      -urlmatch_arc "" `
                        -urlmatch_ver "(Process Explorer v\d+(\.\d+)?)" -test         "procexp.exe" `
                        -unzip
cleanAddPath "\\procexp" ""
# Write-Host "procexp_dir\procexp2.exe='$procexp_dir\procexp.exe'"
invoke-expression 'doskey pe=$procexp_dir\procexp.exe $* ; doskey /exename=pe pe=$procexp_dir\procexp.exe $*'
}

$mc = {
$mc_urlmatch_arc = if ( Test-Win64 ) { "_x64_.*.zip" } else { "_win32_.*.zip" }
$mc_dir   = installPrg -aprgname     "mc"                        -url "http://multicommander.com/downloads" `
                        -urlmatch     "MultiCommander.*.zip"     -urlmatch_arc "$mc_urlmatch_arc" `
                        -urlmatch_ver "MultiCommander.*.zip"     -test "MultiCommander.exe" `
                        -unzip
cleanAddPath "\\MultiCommander" ""
# Write-Host "mc_dir\mc2.exe='$mc_dir\MultiCommander.exe'"
invoke-expression 'doskey mc=$mc_dir\MultiCommander.exe $* ; doskey /exename=mc mc=$mc_dir\MultiCommander.exe $*'
}


$ag = {
$ag_dir   = installPrg -aprgname     "ag"                        -url          "http://sourceforge.net/projects/astrogrep/files/AstroGrep%20%28Win32%29/@VER@/" `
                        -urlmatch     "AstroGrep_v.*?/download"          -urlmatch_arc "" `
                        -urlver "http://astrogrep.sourceforge.net/download/" `
                        -urlmatch_ver "(AstroGrep v\d+(\.\d+\.\d+)?)" -test         "AstroGrep.exe" `
                        -unzip `
                        -url_replace  'sourceforge.net/projects/astrogrep/files/(.*?)/download,netcologne.dl.sourceforge.net/project/astrogrep/$1'
cleanAddPath "\\AstroGrep" ""
# Write-Host "ag_dir\AstroGrep.exe='$ag_dir\AstroGrep.exe'"
invoke-expression 'doskey ag=$ag_dir\AstroGrep.exe $* ; doskey /exename=ag ag=$ag_dir\AstroGrep.exe $*'
}


$perl = {
$perl_urlmatch_arc = if ( Test-Win64 ) { "-64bit-portable" } else { "-32bit-portable" }
$perl_dir   = installPrg -aprgname     "perl"                        -url          "http://strawberryperl.com/releases.html" `
                         -urlmatch     "/download/"  -urlmatch_arc "$perl_urlmatch_arc" `
                         -urlmatch_ver "$perl_urlmatch_arc.zip"       -test         "perl\bin\perl.exe" `
                         -unzip
cleanAddPath "\\.*perl" ""
# Write-Host "perl_dir\perl.exe='$perl_dir\perl\bin\perl.exe'"
invoke-expression 'doskey perl=$perl_dir\perl\bin\perl.exe $* ; doskey /exename=perl perl=$perl_dir\perl\bin\perl.exe $*'
}

$kitty = {
$kitty_dir   = installPrg -aprgname     "kitty"                        -url          "http://www.fosshub.com/KiTTY.html" `
                          -urlmatch     "download/kitty_portable.exe"  -urlmatch_arc "" `
                          -urlmatch_ver "(0\.\d+\.\d+\.\d+)"           -test         "kitty.exe" `
                          -invoke       "mkdir @DEST@ & copy @FILE@ @DEST@\\kitty.exe & mklink /J @DEST@\\Sessions @DEST@\\..\Sessions & mklink /J @DEST@\\kitty.ini @DEST@\\..\kitty.ini" `
                          -urlver       "http://www.9bis.net/kitty/check_update.php?version=0" `
                          -url_replace  "www.fosshub.com/download/kitty_portable.exe,mirror3.fosshub.com/programs/kitty_portable.exe" `
                          -ver_pattern "(0\.\d+\.\d+\.\d+)" -referer "http://www.fosshub.com/KiTTY.html"

cleanAddPath "\\.*kitty" ""
# Write-Host "kitty_dir\kitty.exe='$kitty_dir\kitty.exe'"
invoke-expression 'doskey kitty=$kitty_dir\kitty.exe $* ; doskey /exename=kitty kitty=$kitty_dir\kitty.exe $*'
}

$wintab = {
$wintab_dir   = installPrg -aprgname     "wintab"                        -url          "http://www.windowtabs.com/download/" `
                          -urlmatch     "/WindowTabs.exe"  -urlmatch_arc "" `
                          -urlmatch_ver "(\d+\.\d+\.\d+)"           -test         "WindowTabs.exe" `
                          -invoke       "mkdir @DEST@ & copy @FILE@ @DEST@\\WindowTabs.exe"

cleanAddPath "\\.*wintab" ""
# Write-Host "wintab_dir\WindowTabs.exe='$wintab_dir\WindowTabs.exe'"
invoke-expression 'doskey wintab=$wintab_dir\WindowTabs.exe $* ; doskey /exename=wintab wintab=$wintab_dir\WindowTabs.exe $*'
}

$greenshot = {
$greenshot_dir   = installPrg -aprgname     "greenshot"                        -url          "http://getgreenshot.org/version-history/" `
                          -urlmatch     "Greenshot-NO-INSTALLER-.*?.zip"  -urlmatch_arc "" `
                          -urlmatch_ver "(Greenshot-NO-INSTALLER-.*?).zip"           -test         "Greenshot.exe" `
                          -unzip `
                          -url_replace  'sourceforge.net/projects/greenshot/files/(.*?)/download,netcologne.dl.sourceforge.net/project/greenshot/$1'


cleanAddPath "\\.*greenshot" ""
# Write-Host "greenshot_dir\Greenshot.exe='$greenshot_dir\Greenshot.exe'"
invoke-expression 'doskey gs=$greenshot_dir\Greenshot.exe $* ; doskey /exename=gs gs=$greenshot_dir\Greenshot.exe $*'
}

$fastoneCapture = {
$fastoneCapture_dir   = installPrg -aprgname     "fastoneCapture"                        -url          "http://www.faststone.org/FSCapturerDownload.htm" `
                          -urlmatch     "www.faststonesoft.net/DN/FSCapture\d+?\.zip"  -urlmatch_arc "" `
                          -urlmatch_ver "(FSCapture\d+?)\.zip"           -test         "FSCapture.exe" `
                          -unzip

cleanAddPath "\\.*fastoneCapture" ""
# Write-Host "fastoneCapture_dir\FSCapture.exe='$fastoneCapture_dir\FSCapture.exe'"
invoke-expression 'doskey fsc=$fastoneCapture_dir\FSCapture.exe $* ; doskey /exename=fsc fsc=$fastoneCapture_dir\FSCapture.exe $*'
}

$zoomit = {
$zoomit_dir   = installPrg -aprgname     "zoomit"              -url          "http://technet.microsoft.com/en-us/sysinternals/bb897434" `
                        -urlmatch     "ZoomIt.zip"      -urlmatch_arc "" `
                        -urlmatch_ver "(ZoomIt v\d+(\.\d+)?)" -test         "zoomit.exe" `
                        -unzip
cleanAddPath "\\zoomit" ""
# Write-Host "zoomit_dir\zoomit2.exe='$zoomit_dir\zoomit.exe'"
invoke-expression 'doskey zi=$zoomit_dir\zoomit.exe $* ; doskey /exename=zi zi=$zoomit_dir\zoomit.exe $*'
}


$filezilla = {
$filezilla_dir   = installPrg -aprgname     "filezilla"              -url          "https://filezilla-project.org/download.php?show_all=1" `
                        -urlmatch     "FileZilla_.*?win32.zip"      -urlmatch_arc "" `
                        -urlmatch_ver "(FileZilla_\d.\d.\d)" -test         "filezilla.exe" `
                        -unzip `
                        -url_replace  'sourceforge.net/projects/filezilla/files/(.*?)/download,netcologne.dl.sourceforge.net/project/filezilla/$1'
cleanAddPath "\\filezilla" ""
# Write-Host "filezilla_dir\filezilla2.exe='$filezilla_dir\filezilla.exe'"
invoke-expression 'doskey fz=$filezilla_dir\filezilla.exe $* ; doskey /exename=fz fz=$filezilla_dir\filezilla.exe $*'
}


$autoit = {
$autoit_dir   = installPrg -aprgname     "autoit"              -url          "http://www.autoitscript.com/site/autoit/downloads/index.php" `
                        -urlmatch     "autoit-v3.zip"      -urlmatch_arc "" `
                        -urlmatch_ver "(autoit v\d+\.\d+\.\d+\.\d+)" -test         "AutoIt3.exe" `
                        -unzip `
                        -referer "http://www.autoitscript.com/site/autoit/downloads" -hostname "www.autoitscript.com" `
                        -url_replace  'cgi-bin/getfile.pl.,files/'
cleanAddPath "\\autoit" ""
# Write-Host "autoit_dir\AutoIt3.exe='$autoit_dir\AutoIt3.exe'"
invoke-expression 'doskey autoit=$autoit_dir\AutoIt3.exe $* ; doskey /exename=autoit autoit=$autoit_dir\AutoIt3.exe $*'
}

$iron = {
$iron_dir   = installPrg -aprgname     "iron"              -url          "http://www.srware.net/forum/viewtopic.php?f=18&t=6987" `
                        -urlmatch     "IronPortable.zip"      -urlmatch_arc "" `
                        -urlver "http://www.srware.net/forum/viewforum.php?f=18" `
                        -urlmatch_ver "topictitle..New Iron-Version: (\d+\.\d+\.\d+\.\d+) Stable for Windows" -ver_only -test         "IronPortable.exe" `
                        -unzip
cleanAddPath "\\iron" ""
# Write-Host "iron_dir\iron3.exe='$iron_dir\IronPortable.exe'"
invoke-expression 'doskey iron=$iron_dir\IronPortable.exe $* ; doskey /exename=iron iron=$iron_dir\IronPortable.exe $*'
}

$firefox = {
$firefox_dir   = installPrg -aprgname     "firefox"              -url          "http://www.firefox-usb.com/" `
                        -urlmatch     "/download/FirefoxPortable.*?.zip"      -urlmatch_arc "" `
                        -urlmatch_ver "(FirefoxPortable.*?).zip" -test         "FireFoxPortable.exe" `
                        -unzip -referer "http://www.firefox-usb.com/" -hostname "www.firefox-usb.com" `
                        -invoke       "move @DEST@\\Data @DEST@\\Data.ori & mklink /J @DEST@\\Data @DEST@\\..\Data" `

cleanAddPath "\\firefox" ""
# Write-Host "firefox_dir\FireFoxPortable.exe='$firefox_dir\FireFoxPortable.exe'"
invoke-expression 'doskey firefox=$firefox_dir\FireFoxPortable.exe $* ; doskey /exename=firefox firefox=$firefox_dir\FireFoxPortable.exe $*'
}

$kdiff3 = {
# http://scriptinghell.blogspot.fr/2012/10/ternary-operator-support-in-powershell.html (second comment)
$kdiff3_urlmatch_arc = if ( Test-Win64 ) { "64bit" } else { "32bit" }
$kdiff3Dir = installPrg -aprgname     "kdiff3"                   -url          "http://sourceforge.net/projects/kdiff3/files/kdiff3/@VER@/" `
                        -urlmatch     "Setup_.*?/download"             -urlmatch_arc "$kdiff3_urlmatch_arc" `
                        -urlver "http://kdiff3.sourceforge.net/" `
                        -urlmatch_ver "Current version: (.*) \(" -ver_only -test         "kdiff3.exe" `
                        -invoke       "@FILE@ /S /D=@DEST@" `
                        -url_replace  'sourceforge.net/projects/kdiff3/files/(.*?)/download,netcologne.dl.sourceforge.net/project/kdiff3/$1'
# http://superuser.com/questions/544520/how-can-i-copy-a-directory-overwriting-its-contents-if-it-exists-using-powershe

cleanAddPath -cleanPattern "\\kdiff3" -addPath ""

invoke-expression 'doskey kdiff3=$kdiff3Dir\kdiff3.exe `$* ; doskey /exename=kdiff3 kdiff3=$kdiff3Dir\kdiff3.exe `$*'
}

$paint = {
$paint_dir   = installPrg -aprgname     "paint"              -url          "http://www.rw-designer.com/image-editor" `
                        -urlmatch     "RWPaint.zip"      -urlmatch_arc "" `
                        -urlmatch_ver "/([^/]*)/RWPaint.zip" -ver_only `
                        -unzip -test         "RWPaint.exe"
cleanAddPath "\\paint" ""
# Write-Host "paint_dir\paint3.exe='$paint_dir\paintPortable.exe'"
invoke-expression 'doskey paint=$paint_dir\RWPaint.exe $* ; doskey /exename=paint paint=$paint_dir\RWPaint.exe $*'
}

$svn = {
# http://www.svn.org/download/releases/2.4/msi/
# http://social.technet.microsoft.com/Forums/windowsserver/en-US/3729e9c2-cb1f-42f7-a4ee-91bc6b101d9a/invokeexpression-syntax-issues
$svn_dir   = installPrg -aprgname     "svn"                -url          "http://www.visualsvn.com/downloads/" `
                        -urlmatch     "Apache-Subversion-.*?.zip"          `
                        -urlmatch_ver "Apache-Subversion-.*?.zip"            -test         "bin\svn.exe" `
                        -unzip
cleanAddPath "\\svn" ""
invoke-expression 'doskey svn=$svn_dir\bin\svn.exe $* ; doskey /exename=svn svn=$svn_dir\bin\svn.exe $*'
}

$wiztree = {
$wiztree_dir   = installPrg -aprgname     "wiztree"                -url          "http://antibody-software.com/web/software/software/wiztree-finds-the-files-and-folders-using-the-most-disk-space-on-your-hard-drive/" `
                        -urlmatch     "wiztree_.*?portable.zip"          `
                        -urlmatch_ver "wiztree_.*?portable.zip"            -test         "WizTree.exe" `
                        -unzip
cleanAddPath "\\wiztree" ""
invoke-expression 'doskey wiztree=$wiztree_dir\WizTree.exe $* ; doskey /exename=wiztree wiztree=$wiztree_dir\WizTree.exe $*'
}

$ss = {
$ss_dir   = installPrg -aprgname     "ss"                -url          "http://www.uderzo.it/main_products/space_sniffer/download.html" `
                        -urlmatch     "spacesniffer_.*?.zip"          `
                        -urlmatch_ver "spacesniffer_.*?.zip"            -test         "SpaceSniffer.exe" `
                        -url_replace  'download.html/files,files' `
                        -unzip
cleanAddPath "\\ss" ""
invoke-expression 'doskey ss=$ss_dir\SpaceSniffer.exe $* ; doskey /exename=ss ss=$ss_dir\SpaceSniffer.exe $*'
}

$liteide = {
$liteide_dir   = installPrg -aprgname     "liteide"                      -url          "https://code.google.com/p/golangide/downloads/list?can=2&q=windows&colspec=Filename+Summary+Uploaded+ReleaseDate+Size+DownloadCount" `
                        -urlmatch     "golangide.googlecode.com/files/liteidex.*.windows.7z"            -urlmatch_arc "" `
                        -urlmatch_ver "windows.*.7z"            -test         "bin\liteide.exe" `
                        -unzip
cleanAddPath "liteide" ""
invoke-expression 'doskey goide=$liteide_dir\bin\liteide.exe $* ; doskey /exename=goide goide=$liteide_dir\bin\liteide.exe $*'
}

$gvim = {
$gvim_dir   = installPrg -aprgname     "gvim"                     -url          "http://ftp.vim.org/pub/vim/pc/?C=M;O=D" `
                        -urlmatch     "gvim[\d_]+.zip"             `
                        -urlmatch_ver "gvim[\d_]+.zip"            -test         "gvim.exe" `
                        -post "Get-ChildItem @install_folder\vim*\* -Recurse | Move-Item -Destination @install_folder" `
                        -unzip
cleanAddPath "gvim" ""
invoke-expression 'doskey gvim=$gvim_dir\gvim.exe $* ; doskey /exename=gvim gvim=$gvim_dir\gvim.exe $*'
invoke-expression 'doskey vim=$gvim_dir\gvim.exe $* ; doskey /exename=vim vim=$gvim_dir\gvim.exe $*'
invoke-expression 'doskey vi=$gvim_dir\gvim.exe $* ; doskey /exename=vi vi=$gvim_dir\gvim.exe $*'
}

$dexpot = {
$dexpot_dir   = installPrg -aprgname     "dexpot"                     -url          "http://dexpot.de/index.php?id=download" `
                        -urlmatch     "download/dexpot_[\d]+_portable[\dr_]+.zip"             `
                        -urlmatch_ver "(dexpot_[\d]+_portable[\dr_]+).zip"            -test         "dexpot.exe" `
                        -url_replace  'index.php.id=download/,' `
                        -unzip
cleanAddPath "dexpot" ""
invoke-expression 'doskey dexpot=$dexpot_dir\dexpot.exe $* ; doskey /exename=dexpot dexpot=$dexpot_dir\dexpot.exe $*'
}

$freeplane = {
$freeplane_dir   = installPrg -aprgname     "freeplane"                        -url          "http://sourceforge.net/projects/freeplane/files/freeplane%20stable/" `
                        -urlmatch     "stable/freeplane_bin-.*?zip/download"           `
                        -urlmatch_ver "stable/(freeplane_bin-.*?).zip/download" -ver_only -test         "freeplane.exe" `
                        -unzip `
                        -url_replace  'sourceforge.net/projects/freeplane/files/(.*?)/download,netcologne.dl.sourceforge.net/project/freeplane/$1'
cleanAddPath "\\freeplane" ""
# Write-Host "freeplane_dir\AstroGrep.exe='$freeplane_dir\AstroGrep.exe'"
invoke-expression 'doskey fp=$freeplane_dir\freeplane.exe $* ; doskey /exename=fp fp=$freeplane_dir\freeplane.exe $*'
}

$node = {
$node_urlmatch_arc = if ( Test-Win64 ) { "x64" } else { "x86" }
$node_urlmatch_arc2 = if ( Test-Win64 ) { "x64" } else { "" }
$node_dir   = installPrg -aprgname     "node"                        -url          "http://nodejs.org/download/" `
                        -urlmatch     "http://nodejs.org/dist/v[^/]+/?$node_urlmatch_arc2/node.exe"           `
                        -urlmatch_ver "(node-v[^-]+-$node_urlmatch_arc).msi"
cleanAddPath "\\node" ""
# Write-Host "node_dir.exe='$node_dir'"
addbin -filename "$prgs\bin\node.bat" -command "$node_dir %*"
}

$npm = {
$npm_dir   = installPrg -aprgname     "npm"                     -url          "http://nodejs.org/dist/npm/" `
                        -urlmatch     "npm-@VER@.zip"             `
                        -urlver "https://github.com/isaacs/npm/releases" `
                        -urlmatch_ver 'tag/v([^"]*?)"' -ver_only `
                                    -test         "npm.cmd" `
                        -unzip
cleanAddPath "npm" ""
invoke-expression 'doskey npm=$npm_dir\npm.cmd $* ; doskey /exename=npm npm=$npm_dir\npm.cmd $*'
}

$global:ruby_dir = ""
$ruby = {
$ruby_urlmatch_arc = if ( Test-Win64 ) { "x64" } else { "i386" }
$ruby_dir   = installPrg -aprgname     "ruby"                        -url          "http://rubyinstaller.org/downloads/" `
                        -urlmatch     "http://dl.bintray.com/oneclick/rubyinstaller/ruby-(.*?)-$ruby_urlmatch_arc-mingw32.7z"           `
                        -urlmatch_ver "(ruby-.*?-$ruby_urlmatch_arc-mingw32)" `
                        -unzip -test "bin\ruby.exe"
cleanAddPath "\\ruby" ""
# Write-Host "ruby_dir.exe='$ruby_dir'"
Set-Variable -Name "ruby_dir" -Value $ruby_dir -Scope Global
}


$ads = {
$ads_urlmatch_arc = if ( Test-Win64 ) { "x86_64-" } else { "x86-" }
$ads_dir   = installPrg -aprgname     "ads"                     -url          "http://directory.apache.org/studio/download/download-windows.html" `
                        -urlmatch     "ApacheDirectoryStudio-win32-$ads_urlmatch_arc(.*?).exe"             `
                        -urlmatch_ver "(ApacheDirectoryStudio-win32-$ads_urlmatch_arc-?.*?)" `
                        -test         "Apache Directory Studio.exe" `
                        -invoke       "@FILE@ /S /D=@DEST@"
cleanAddPath "ads" ""
invoke-expression 'doskey ads=$ads_dir\Apache~1.exe $* ; doskey /exename=ads ads=$ads_dir\Apache~1.exe $*'
}

$ontop = {
$ontop_dir   = installPrg -aprgname     "ontop"                     -url          "http://ontopreplica.codeplex.com/" `
                        -urlmatch     "http://ontopreplica.codeplex.com/downloads/get/.*"             `
                        -urlver "http://ontopreplica.codeplex.com/" `
                        -urlmatch_ver 'Release (\d+\.\d+)' -ver_only `
                                    -test         "OnTopReplica.exe" `
                        -unzip `
                        -url_replace  'ontopreplica.codeplex.com.*,www.klopfenstein.net/download.aspx?file=ontopreplica%2fontopreplica-executable.zip'
cleanAddPath "ontop" ""
invoke-expression 'doskey ontop=$ontop_dir\OnTopReplica.exe $* ; doskey /exename=ontop ontop=$ontop_dir\OnTopReplica.exe $*'
}

$global:jdk_dir = ""
$jdk = {
$jdk_urlmatch_arc = if ( Test-Win64 ) { "x64" } else { "i586" }
$jdk_dir   = installPrg -aprgname     "jdk"                     -url          "http://www.oracle.com/technetwork/java/javase/downloads/jdk7-downloads-1880260.html" `
                        -urlmatch     "http://download.oracle.com/otn-pub/java/jdk/.*/jdk-.*?-windows-$jdk_urlmatch_arc.exe"             `
                        -urlver "http://www.oracle.com/technetwork/java/javase/downloads/jdk7-downloads-1880260.html" `
                        -urlmatch_ver "(jdk-\du\d+-windows-$jdk_urlmatch_arc).exe" `
                                    -test         "bin\java.exe" `
                                    -hostname "download.oracle.com" `
                        -jdk `
                        -url_replace  'jdkreplica.codeplex.com.*,www.klopfenstein.net/download.aspx?file=jdkreplica%2fjdkreplica-executable.zip'
cleanAddPath "jdk" ""
# Write-Host "jdk_dir='$jdk_dir'"
Set-Variable -Name "jdk_dir" -Value $jdk_dir -Scope Global
}

function post-all-install() {
  cleanAddPath "" "$prgs\bin"
  cleanAddPath "" "$prog\bin"
  cleanAddPath "" "$gpg_dir"
  cleanAddPath "" "$git_dir\bin"
  cleanAddPath "" "$hg_dir"
  cleanAddPath "" "$gow_dir\bin"
  cleanAddPath "" "%PROG%\go\bin"
  cleanAddPath "" "$prgs\node"
  cleanAddPath "" "$ruby_dir\bin"
  cleanAddPath "" "$jdk_dir\bin"

  md2 "$prog\tmp" "temp directory"
  addenvs -variable "TMP" -value "%PROG%\tmp"
  addenvs -variable "TEMP" -value "%PROG%\tmp"
  addenvs -variable "JAVA_HOME" -value "$jdk_dir"
  $path=get-content "$prgs/path.txt"
  $sp="set PATH=$path"
  $sp=$sp+"`nset term=msys"

  #http://stackoverflow.com/questions/15041857/powershell-keep-text-formatting-when-reading-in-a-file
  $envs=(Get-Content "$prgs/envs.txt") -join "`n"
  # Write-Host "envs='$envs'"
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

  invoke-expression 'doskey h=doskey /history ; doskey /exename=h h=doskey /history'
  invoke-expression 'doskey l=ls -alr ; doskey /exename=l l=ls -alrt'
}

# http://social.technet.microsoft.com/Forums/windowsserver/en-US/7fea96e4-1c42-48e0-bcb2-0ae23df5da2f/powershell-equivalent-of-goto
<#
 iex ('&$jdk')
 post-all-install
exit 0
#>

 iex ('&$peazip')
 iex ('&$gow')
 iex ('&$git')
 iex ('&$npp')
 iex ('&$python')
 iex ('&$hg')
 iex ('&$bzr')
 iex ('&$sbt')
 iex ('&$go')
 iex ('&$gpg')
 iex ('&$procexp')
 iex ('&$mc')
 iex ('&$ag')
 iex ('&$perl')
 iex ('&$kitty')
 iex ('&$wintab')
 iex ('&$greenshot')
 iex ('&$fastoneCapture')
 iex ('&$zoomit')
 iex ('&$filezilla')
 iex ('&$autoit')
 iex ('&$iron')
 iex ('&$firefox')
 iex ('&$kdiff3')
 iex ('&$paint')
 iex ('&$svn')
 iex ('&$wiztree')
 iex ('&$ss')
 iex ('&$liteide')
 iex ('&$gvim')
 iex ('&$dexpot')
 iex ('&$freeplane')
 iex ('&$node')
 iex ('&$npm')
 iex ('&$ruby')
 iex ('&$ads')
 iex ('&$ontop')
 iex ('&$jdk')
 post-all-install
