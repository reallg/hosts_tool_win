@echo off
set HostsSource="http://your_raw_hosts_file"

if defined converted goto :converted

set ConverterPath=%temp%\HostsTool_CodeConverter.vbs
set ConverterOutput=%temp%\HostsTool_GBK.bat

echo inputpath="%~0" >%ConverterPath%
echo outputpath="%ConverterOutput%" >>%ConverterPath%
echo set stm2=createobject("ADODB.Stream") >>%ConverterPath%
echo stm2.Charset ="utf-8" >>%ConverterPath%
echo stm2.Open >>%ConverterPath%
echo stm2.LoadFromFile inputpath >>%ConverterPath%
echo readfile = stm2.ReadText >>%ConverterPath%
echo stm2.Close >>%ConverterPath%
echo Set Stm1 =CreateObject("ADODB.Stream") >>%ConverterPath%
echo Stm1.Type = 2 >>%ConverterPath%
echo Stm1.Open >>%ConverterPath%
echo Stm1.Charset ="GBK" >>%ConverterPath%
echo Stm1.Position = Stm1.Size >>%ConverterPath%
echo Stm1.WriteText "set converted=y" ^& vbcrlf >>%ConverterPath%
echo Stm1.WriteText readfile >>%ConverterPath%
echo Stm1.SaveToFile outputpath,2 >>%ConverterPath%
echo Stm1.Close >>%ConverterPath%
%ConverterPath% && %ConverterOutput%
goto :eof

:converted

cls
%1 %2
ver|find " 5.">nul &&goto :st
echo Granting Admin permissions...
mshta vbscript:createobject("shell.application").shellexecute("%~s0","goto :st","","runas",1)(window.close)&goto :eof
:st

cls

@REM HostsGet Version0.4
cd /d %~dp0

set LogFilePath=%temp%\HostsTool_log.txt
set DLScriptPath=%temp%\downloadhosts.vbs
set DLPath=%windir%\system32\drivers\etc\hosts_downloaded
set BackupDir=%windir%\system32\drivers\etc
set HostsPath=%windir%\system32\drivers\etc\hosts

set LogToFile=^>^>%LogFilePath% 2^>^&1
set EchoAndLog=call :echoandlog
echo. %LogToFile%
echo ==========[%date% %time%]========== %LogToFile%
echo Log Path:
echo %LogFilePath%
echo.

echo iLocal=LCase("%DLPath%") > %DLScriptPath% ||(
 call :error downloadhosts.vbs Create / Write file.
)
echo iRemote=LCase(%HostsSource%) >> %DLScriptPath%
echo Set xPost=createObject("Microsoft.XMLHTTP") 'Set Post = CreateObject("Msxml2.XMLHTTP") >> %DLScriptPath%
echo xPost.Open "GET",iRemote,0 >> %DLScriptPath%
echo xPost.Send() >> %DLScriptPath%
echo set sGet=createObject("ADODB.Stream") >> %DLScriptPath%
echo sGet.Mode=3 >> %DLScriptPath%
echo sGet.Type=1 >> %DLScriptPath%
echo sGet.Open() >> %DLScriptPath%
echo sGet.Write xPost.ResponseBody >> %DLScriptPath%
echo sGet.SaveToFile iLocal,2 >> %DLScriptPath%

%EchoAndLog% Downloading hosts from remote source...
if exist %DLPath% del %DLPath% /s /q %LogToFile%
%DLScriptPath% || call :error  hosts file download failed.
del %DLScriptPath% /s /q %LogToFile%
if not exist %DLPath% call :error  hosts file download failed.
%EchoAndLog% Done download hosts file.
echo.

if exist %HostsPath% (
    call :backuphosts
) else (
    %EchoAndLog% Origin hosts file is not exsit, skip backup
)
%EchoAndLog% Replacing hosts...
move %DLPath% %HostsPath% %LogToFile% || call :error hosts replace failed.
%EchoAndLog% hosts file is replaced successfully.
echo.

%EchoAndLog% Flushing DNS cache...
ipconfig /flushdns %LogToFile% || call :error DNS flush failed.
%EchoAndLog% DNS is flushed.
echo.
%EchoAndLog% [Done!]
echo.

goto :end

:backuphosts
%EchoAndLog% Backup hosts...
set "bakfilename=hosts_%date%_%time:~0,8%.bak"
set bakfilename=%bakfilename:/=-%
set bakfilename=%bakfilename:\=-%
set bakfilename=%bakfilename::=-%
set bakfilename=%bakfilename: =_%
copy %HostsPath% %BackupDir%\%bakfilename% %LogToFile% || call :error hosts backup failed.
%EchoAndLog% Origin hosts file is backup to %BackupDir%\%bakfilename%.
echo.
goto :eof

:error
echo ======================
%EchoAndLog% Error%*
start %LogFilePath%
goto :end

:echoandlog
echo %*
echo %* %LogToFile%
goto :eof

:end
echo Press any key to exit.
pause >nul
exit