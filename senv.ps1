$prgsInstallVariableName="prgs"
$prgsDefaultPath="C:\prgs"
$prgsPath = [Environment]::GetEnvironmentVariable($prgsInstallVariableName, [System.EnvironmentVariableTarget]::User)
if ($prgsPath -eq $null) {
  # http://technet.microsoft.com/en-us/library/ff730964.aspx
  Write-Host "%PRGS% (for installing programming tools) isn't defined."
  # http://social.technet.microsoft.com/Forums/exchange/en-US/3fc59659-c9fe-41e3-9d02-fc41e3bc63f4/asking-for-input-in-powershell
  $prgs = Read-Host "Please enter %PRGS% path (default [C:\prgs])"
  $prgs = $prgs.Trim()
  if ($prgs -eq "") {
    $prgs="C:\prgs"
  }
} else {
  $prgs=$prgsPath
}
# http://technet.microsoft.com/en-us/library/ff730955.aspx
if ( ! (Test-Path "$prgs") ) {
  # http://stackoverflow.com/questions/16906170/powershell-create-directory-if-it-does-not-exist
  New-Item -ItemType Directory -Force -Path $prgs > $null
  if ( ! (Test-Path "$prgs") ) {
    Write-Host "No right to create '$prgs'"
    Exit
  }
}
if ($prgsPath -eq $null) {
  [Environment]::SetEnvironmentVariable($prgsInstallVariableName, $prgs, "User")
}
Write-Host "User environment variable %PRGS% set to '$prgs'"

Write-Host "Testing User environment variable %PROG%"

