# http://stackoverflow.com/questions/9735449/how-to-verify-whether-the-share-has-write-access
function Test-Write {
    [CmdletBinding()]
    param (
        [parameter()] [ValidateScript({[IO.Directory]::Exists($_.FullName)})]
        [IO.DirectoryInfo] $Path
    )
    try {
        $testPath = Join-Path $Path ([IO.Path]::GetRandomFileName())
        [IO.File]::Create($testPath, 1, 'DeleteOnClose') > $null
        # Or...
        <# New-Item -Path $testPath -ItemType File -ErrorAction Stop > $null #>
        return $true
    } catch {
        return $false
    } finally {
        Remove-Item $testPath -ErrorAction SilentlyContinue
    }
}

Write-Host "Testing User environment variable %PRGS%"
$prgsInstallVariableName="prgs"
$prgsDefaultPath="C:\prgs"
$prgsPath = [Environment]::GetEnvironmentVariable($prgsInstallVariableName, [System.EnvironmentVariableTarget]::User)
if ($prgsPath -eq $null) {
  # http://technet.microsoft.com/en-us/library/ff730964.aspx
  Write-Host "%PRGS% (for installing programming tools) isn't defined."
  # http://social.technet.microsoft.com/Forums/exchange/en-US/3fc59659-c9fe-41e3-9d02-fc41e3bc63f4/asking-for-input-in-powershell
  $prgsPath = Read-Host "Please enter %PRGS% path (default [C:\prgs])"
  $prgsPath = $prgsPath.Trim()
  if ($prgsPath -eq "") {
    $prgsPath="C:\prgs"
    # http://technet.microsoft.com/en-us/library/ff730955.aspx
    if ( ! (Test-Path "$prgsPath") ) {
      # http://stackoverflow.com/questions/16906170/powershell-create-directory-if-it-does-not-exist
      New-Item -ItemType Directory -Force -Path $prgsPath
      if ( ! (Test-Path "$prgsPath") ) {
        Write-Host "No right to create '$prgsPath'"
        Exit
      }
     }
   }
   # http://technet.microsoft.com/en-us/library/ff730951.aspx
   # $prgsPathACL = Get-ACL $prgsPath 
   # http://technet.microsoft.com/en-us/library/ff730964.aspx
   # [Environment]::SetEnvironmentVariable("prgsInstallVariableName", "Test value.", "User")
   Write-Host "prgsPathACL='$prgsPathACL'"
   Exit
}
Write-Host "Testing User environment variable %PROG%"

