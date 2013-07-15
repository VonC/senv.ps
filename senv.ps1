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
  Write-Host "Must install '$prog' for %PROG%"
  if ( ! (Test-Path "$gowExe") ) {
    Write-Host "Downloading  $gowUrl to $gowExe"
    $downloader.DownloadFile($gowUrl, $gowFile)
  }
  # http://unattended.sourceforge.net/installers.php
  $gowFile /S /D=c:\prgs\$gowVer
}
