@echo off

@powershell -NoProfile -ExecutionPolicy unrestricted -Command "& \"%prog%\git\senv\senv.ps1\"" %*
call %PRGS%\setpath.bat

copy "%prog%\git\senv\senv.bat" "%prgs%\bin" >NUL
copy "%prog%\git\senv\alias.bat" "%prgs%\bin" >NUL
copy "%prog%\git\senv\h.bat" "%prgs%\bin" >NUL
copy "%prog%\git\senv\l.bat" "%prgs%\bin" >NUL
copy "%prog%\git\senv\kp*.bat" "%prgs%\bin" >NUL
copy "%prog%\git\senv\gtags.bat" "%prgs%\bin" >NUL

if exist "%~dp0aliases.bat" call "%~dp0aliases.bat"