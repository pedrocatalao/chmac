:: chmac 0.2.a (c) 2003 radix
:: radix@ironik.org
:: ==========================

@echo off

:: clearance of temp files and setting environment to local
:: ========================================================
echo chmac 0.2.a (c) 2003 radix > 1.tmp
del *.tmp > nul
setlocal

:: checking for args to go to non-interactive mode
:: ===============================================
if "%1" == "" goto interactive
for /L %%i in (1,1,10) do if "%1" == "%%i" goto setdev
goto interactive
:setdev
set chmacnidev=%1
if NOT "%2" == "" set chmacnimac=%2

:: gathering data about network devices - names and mac addresses
:: ==============================================================
:interactive
ipconfig /all | %windir%\system32\find.exe "Description" > 1.tmp
ipconfig /all | %windir%\system32\find.exe "Physical Address" > 2.tmp
for /F "tokens=2 delims=:" %%i in (1.tmp) do @echo %%i >> devices.tmp
for /F "tokens=2 delims=:" %%i in (2.tmp) do @echo %%i >> macs.tmp
type devices.tmp | %windir%\system32\find.exe /N " " > 1.tmp
type macs.tmp | %windir%\system32\find.exe /N " " > 2.tmp
type 1.tmp > devices.tmp
type 2.tmp > macs.tmp
for /F "tokens=1,2* delims=[] " %%i in (devices.tmp) do set chmacdev%%i=[%%i]%%j

:: help and listing args
:: =====================
if "%1" == "/?" goto help
if "%1" == "/h" goto help
if "%1" == "/H" goto help
if "%1" == "-h" goto help
if "%1" == "-H" goto help
if "%1" == "--help" goto help
if "%1" == "-l" goto list
if "%1" == "-L" goto list
if "%1" == "/l" goto list
if "%1" == "/L" goto list
if "%1" == "--list" goto list


:: starting interface showing avaliable devices and prompting user to choose one
:: =============================================================================
if NOT "%chmacnidev%" == "" goto niinterfc1
echo.
echo chmac 0.2.a (c) 2003 radix
echo.
echo List of avaliable devices:
echo.
for /F "tokens=1,2,3* delims=[] " %%i in (devices.tmp) do @echo   --^> [dev%%i] - %%j %%k %%l
echo.
echo.
set /P chmacdevnum="Which one do you want to change the MAC address? [1]: "
:: the previous line memorizes the position on the list of the chosen device 
if "%chmacdevnum%" == "" set chmacdevnum=1
goto step1end
:niinterfc1
echo.
echo chmac 0.2.a (c) 2003 radix
echo.
set chmacdevnum=%chmacnidev%
:step1end

:: isolating the chosen device name in a variable to search it on registry
:: =======================================================================
set chmacdevusetmp=chmacdev%chmacdevnum%
set %chmacdevusetmp% > 1.tmp
for /F "tokens=2 delims==" %%i IN (1.tmp) DO echo %%i > 2.tmp
for /F "tokens=2,3 delims=] " %%i IN (2.tmp) DO set chmacdevuse=%%i %%j

:: finding the entry where the device config is stored
:: ===================================================
start /wait REGEDIT /E chmac.reg "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Class"
type chmac.reg | %windir%\system32\find.exe /N "%chmacdevuse%" > 1.tmp
type chmac.reg | %windir%\system32\find.exe /N "{4D36E972-E325-11CE-BFC1-08002bE10318}" >> 1.tmp
%windir%\system32\sort.exe /O 2.tmp 1.tmp
type 2.tmp | %windir%\system32\find.exe /N "[" > 1.tmp
type 1.tmp | %windir%\system32\find.exe "%chmacdevuse%" > 2.tmp
FOR /F "tokens=1 delims=[]" %%i in (2.tmp) do set chmacline=%%i
del 2.tmp
FOR /F "tokens=3 delims=[]" %%i in (1.tmp) do echo [%%i] >> 2.tmp
echo chmac by radix > 1.tmp
type 2.tmp >> 1.tmp
type 1.tmp | %windir%\system32\find.exe /N "[" > 2.tmp
type 2.tmp | %windir%\system32\find.exe "[%chmacline%]" > 1.tmp

:: writing the new regfile to append later
:: =======================================
echo Windows Registry Editor Version 5.00 > chmacnew.reg
echo. >> chmacnew.reg
for /F "tokens=2 delims=[]" %%i in (1.tmp) do echo [%%i] >> chmacnew.reg
:: the previous line removes the line number [n] in the start of the string
echo. >> chmacnew.reg

:: informative output about current device name and mac address
:: ============================================================
type macs.tmp | %windir%\system32\find.exe "[%chmacdevnum%]" > 1.tmp
for /F "tokens=2 delims=[]" %%i in (1.tmp) do set chmacdevmac=%%i
echo.
echo.
echo Changing MAC Address for dev%chmacdevnum%:
for /F "tokens=1,2,3* delims=[] " %%i in (devices.tmp) do @echo %%j %%k %%l | %windir%\system32\find.exe "%chmacdevuse%"
echo.
echo Current MAC address:%chmacdevmac%
if "%chmacnimac%" == "/r" goto restoremac
if "%chmacnimac%" == "/R" goto restoremac
if "%chmacnimac%" == "-R" goto restoremac
if "%chmacnimac%" == "-r" goto restoremac
if "%chmacnimac%" == "--restore" goto restoremac
if NOT "%chmacnimac%" == "" goto niinterfc2
set /P chmacnewmac=Type the new address (leave blank to restore original): 
if "%chmacnewmac%" == "" goto restoremac
goto step2end
:niinterfc2
set chmacnewmac=%chmacnimac%
:step2end

:: parse and finish the registry entry to append
:: =============================================
for /F "tokens=1,2,3,4,5,6 delims=:-" %%i in ('echo %chmacnewmac%') do echo "NetworkAddress"="%%i%%j%%k%%l%%m%%n" >> chmacnew.reg
goto changemac
:restoremac
echo "NetworkAddress"=- >> chmacnew.reg
:changemac

:: append the regfile with the new mac entry
:: =========================================
start /wait REGEDIT /S chmacnew.reg

:: final message
:: =============
if "%chmacnewmac%" == "" goto sayrestored
echo.
echo MAC changed to %chmacnewmac%
goto saychanged
:sayrestored
echo.
echo Original MAC restored
:saychanged
echo Disable and re-enable dev%chmacdevnum% for changes to take effect.
echo.
goto progend

:: help and listing information
:: ============================
:help
echo.
echo chmac 0.2.a (c) 2003 radix
echo.
echo Changes and restores network interface cards MAC addresses.
echo.
echo CHMAC [dev_num ^| -h ^| -l] [new_mac ^| -r]
echo.
echo   dev_num          Device Number,  you can check the devices list using the 
echo                    -l option and then use the number of the device you want
echo                    on this field.
echo   new_mac          New MAC address the specified device will get associated
echo                    to.  The MAC  address is  given  as 6 hexadecimal  bytes
echo                    separated by hyphens as shown in the example.
echo   -h --help        Show this help information.
echo   -l --list        List avaliable devices.
echo   -r --restore     Restores the hardware's original MAC.
echo.
echo Example:
echo   ^> chmac 1 00-11-22-33-44-55   Changes device 1 MAC to 00-11-22-33-44-55.
echo   ^> chmac 2                     Asks for the MAC to assign to device 2.
echo   ^> chmac 3 -r                  Restores device 3 original MAC.
echo   ^> chmac -l                    List avaliable devices.  
echo.
echo.
goto progend
:list
echo.
echo chmac 0.2.a (c) 2003 radix
echo.
echo List of avaliable devices:
echo.
for /F "tokens=1,2,3* delims=[] " %%i in (devices.tmp) do @echo   [dev%%i] - %%j %%k %%l
echo.
echo.

:: end local environment and delete temp files
:: ===========================================
:progend
endlocal
echo chmac 0.2.a (c) 2003 radix > 1.tmp
echo chmac 0.2.a (c) 2003 radix > 1.reg
del *.tmp
del *.reg

