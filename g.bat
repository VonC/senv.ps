@echo off
rem http://stackoverflow.com/questions/1291941/batch-files-number-of-command-line-arguments
set argC=0
for %%x in (%*) do Set /A argC+=1
rem echo %argC%
if %argC%==0 goto end
if %argC%==1 goto have_1
if %argC%==2 goto have_2
goto end
:have_1
grep -nrHI %1 *
goto end
:have_2
grep -nrHI %1 * | grep %2
:end
