@echo off
SETLOCAL ENABLEDELAYEDEXPANSION
set PATH=%SYSTEMROOT%\System32;%SYSTEMROOT%;%SYSTEMROOT%\System32\Wbem;%prgs%\gpg\latest\pub;%SYSTEMROOT%\System32\WindowsPowerShell\v1.0
call "%prgs%\bin\kpag.bat"
if not exist %prgs%\tmp\t.asc (
	echo "test" | gpg -ea -r %1 --yes -o "%prgs%\tmp\t.asc"
)
gpg -d "%prgs%\tmp\t.asc"
