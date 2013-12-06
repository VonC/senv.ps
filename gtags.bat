@echo off
rem http://stackoverflow.com/questions/11331054/redirecting-command-output-to-variable-in-cmd-script
rem http://stackoverflow.com/questions/108439/how-do-i-get-the-result-of-a-command-in-a-variable-in-windows
git --git-dir=%prog%\git\git\.git log --date-order --tags --simplify-by-decoration --pretty="format:%%ai %%d" | grep tag > %prgs%\tmp\gtags

:end
if [%1]==[] goto print
type %prgs%\tmp\gtags | grep -n ": v.*%1" > %prgs%\tmp\gtags2
type %prgs%\tmp\gtags2
goto eof
:print
type %prgs%\tmp\gtags
:eof
