@echo off

@powershell -NoProfile -ExecutionPolicy unrestricted -Command "& \"%prog%\git\senv\senv.ps1\"" %*
call %PRGS%\setpath.bat

copy "%prog%\git\senv\senv.bat" "%prgs%\bin" >NUL
copy "%prog%\git\senv\alias.bat" "%prgs%\bin" >NUL
copy "%prog%\git\senv\h.bat" "%prgs%\bin" >NUL
copy "%prog%\git\senv\l.bat" "%prgs%\bin" >NUL
copy "%prog%\git\senv\kp*.bat" "%prgs%\bin" >NUL
copy "%prog%\git\senv\rag.bat" "%prgs%\bin" >NUL
copy "%prog%\git\senv\gtags.bat" "%prgs%\bin" >NUL

if not exist "%prgs%\bin\aliases.bat" copy "%prog%\git\senv\aliases.bat" "%prgs%\bin" >NUL
if not exist "%prgs%\bin\goupdate.bat" copy "%prog%\git\senv\goupdate.bat" "%prgs%\bin" >NUL

if not exist "%HOME%\.gitconfig" copy "%prog%\git\senv\.gitconfig" "%HOME%" >NUL

if exist "%~dp0aliases.bat" call "%~dp0aliases.bat"

copy "%prog%\git\senv\gt*.bat" "%prgs%\bin" >NUL
copy "%prog%\git\senv\gc.bat" "%prgs%\bin" >NUL
copy "%prog%\git\senv\gocov.bat" "%prgs%\bin" >NUL
copy "%prog%\git\senv\g.bat" "%prgs%\bin" >NUL
