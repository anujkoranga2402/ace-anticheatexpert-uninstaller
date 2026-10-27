@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion
TITLE AntiCheatExpert manual uninstaller

REM ============================================================
REM  AntiCheatExpert manual uninstaller
REM
REM  Run as administrator. A menu at the start lets you pick:
REM    1  Dry run                  lists what it finds, changes nothing
REM    2  Full auto                removes everything it finds, no questions
REM    3  Prompt on each component asks Y/N before every single item
REM
REM  What this script can touch, and nothing else, ever:
REM    1. Services whose name starts with "AntiCheatExpert"
REM    2. Kernel services whose name starts with "ACE-"
REM    3. The two AntiCheatExpert folders, ProgramFiles and ProgramData
REM    4. Four AntiCheatExpert registry keys, see the :remove_regkey calls
REM    5. Files named ACE-*.sys inside System32\drivers, by exact name
REM  There are no wildcard deletes. The name checks are re-done in code
REM  right before every delete, in every mode, including full auto.
REM ============================================================

REM ---------- Admin check ----------
NET.EXE SESSION >NUL 2>&1
IF ERRORLEVEL 1 GOTO not_admin

REM ---------- Environment ----------
IF NOT DEFINED TEMP SET "TEMP=%SystemRoot%\Temp"
IF NOT EXIST "%TEMP%\" GOTO no_temp

SET "SystemPath=%SystemRoot%\System32"
SET "REGVIEW="
IF DEFINED PROCESSOR_ARCHITEW6432 (
    SET "SystemPath=%SystemRoot%\Sysnative"
    SET "REGVIEW=/reg:64"
)

SET "PF=%ProgramW6432%"
IF NOT DEFINED PF SET "PF=%ProgramFiles%"

SET "TMP_ALL=%TEMP%\ace_list_all.txt"
SET "TMP_USER=%TEMP%\ace_list_user.txt"
SET "TMP_KERN=%TEMP%\ace_list_kern.txt"
SET "TMP_FILES=%TEMP%\ace_list_files.txt"
SET "TMP_REPORT=%TEMP%\ace_report.txt"

GOTO menu


REM ============================================================
REM  MENU
REM ============================================================
:menu
CLS
ECHO ======================================================================
ECHO        Simple AntiCheatExpert (ACE) Uninstaller (October 2026)
ECHO ======================================================================
ECHO.
ECHO   Close all games and game launchers before you continue.
ECHO.
ECHO   [1] Scan Mode (RECOMMENDED FIRST)
ECHO       Search and list all ACE installations on this PC which are
ECHO       worthy for removal. Scan only. Nothing is actually deleted.
ECHO       If no components are found, ACE doesn't exist on this PC.
ECHO.
ECHO   [2] Full Auto Mode
ECHO       Removes everything related to AntiCheatExpert which is found
ECHO       without asking for confirmation. Use at own risk.
ECHO       WARNING: This is faster, but risks unintentional removals.
ECHO       Components *SHOULD* still match the strict ACE name patterns
ECHO       to be removed, but you won't be prompted for confirmation.
ECHO.
ECHO   [3] Confirm before Delete Mode
ECHO       Shows each component and path, then asks for Yes or No (Y/N)
ECHO       from the user before deleting it. Helps stop wrong deletion.
ECHO       This works better because you get to review each item, but it
ECHO       may be slower. Safest method in case of future ACE updates.
ECHO.
ECHO   [Q] Quit
ECHO.
CHOICE /C 123Q /N /M "Select an option [1/2/3/Q]: "
SET "sel=!ERRORLEVEL!"
IF "!sel!"=="4" EXIT /B 0
IF "!sel!"=="3" (
    SET "MODE=3"
    SET "MODE_NAME=CONFIRM BEFORE DELETE"
    GOTO run
)
IF "!sel!"=="2" GOTO menu_auto
SET "MODE=1"
SET "MODE_NAME=SCAN ONLY"
GOTO run

:menu_auto
ECHO.
ECHO   You selected FULL AUTO.
ECHO   Everything found will be stopped, deleted and removed with no
ECHO   questions asked. Option 3 lets you review each item instead.
ECHO.
CHOICE /C YN /N /M "  Are you sure you want to run in full auto mode? [Y/N]: "
IF ERRORLEVEL 2 GOTO menu
SET "MODE=2"
SET "MODE_NAME=FULL AUTO"
GOTO run


REM ============================================================
REM  RUN
REM ============================================================
:run
CLS
SET /A C_FOUND=0
SET /A C_DONE=0
SET /A C_SKIP=0
SET /A C_FAIL=0
SET /A C_PEND=0
SET "REBOOT="

DEL /Q "%TMP_ALL%" "%TMP_USER%" "%TMP_KERN%" "%TMP_FILES%" "%TMP_REPORT%" >NUL 2>&1

ECHO ============================================================
ECHO   Mode: !MODE_NAME!
ECHO ============================================================
ECHO.

REM ---------- Scan services once ----------
ECHO Scanning Windows services...
sc.exe query type= all state= all bufsize= 65536 > "%TMP_ALL%" 2>&1
FINDSTR /B /C:"SERVICE_NAME:" "%TMP_ALL%" >NUL 2>&1
IF ERRORLEVEL 1 GOTO enum_fail
FINDSTR /B /I /C:"SERVICE_NAME: AntiCheatExpert" "%TMP_ALL%" > "%TMP_USER%"
FINDSTR /B /I /C:"SERVICE_NAME: ACE-" "%TMP_ALL%" > "%TMP_KERN%"

REM ---------- Pass 1: user-mode services ----------
ECHO.
ECHO Looking for AntiCheatExpert services...
FOR /F "usebackq tokens=1,* delims=:" %%A IN ("%TMP_USER%") DO (
    SET "svcname=%%B"
    SET "svcname=!svcname:~1!"
    CALL :process_service "!svcname!" USER
)

REM ---------- Pass 2: kernel services ----------
ECHO.
ECHO Looking for ACE- kernel services...
FOR /F "usebackq tokens=1,* delims=:" %%A IN ("%TMP_KERN%") DO (
    SET "svcname=%%B"
    SET "svcname=!svcname:~1!"
    CALL :process_service "!svcname!" KERN
)

REM ---------- Folders ----------
ECHO.
ECHO Looking for AntiCheatExpert folders...
CALL :remove_folder "%PF%\AntiCheatExpert"
CALL :remove_folder "%ProgramData%\AntiCheatExpert"

REM ---------- Registry ----------
ECHO.
ECHO Looking for AntiCheatExpert registry keys...
CALL :remove_regkey "HKCU\SOFTWARE\AppDataLow\AntiCheatExpert"
CALL :remove_regkey "HKU\.DEFAULT\SOFTWARE\AppDataLow\AntiCheatExpert"
CALL :remove_regkey "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\AntiCheatExpert"
CALL :remove_regkey "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\AntiCheatExpert"

REM ---------- Driver files ----------
ECHO.
ECHO Looking for ACE-*.sys driver files...
DIR /B /A-D "%SystemPath%\drivers\ACE-*.sys" > "%TMP_FILES%" 2>NUL
FOR /F "usebackq delims=" %%F IN ("%TMP_FILES%") DO CALL :remove_driver_file "%%F"

GOTO summary


REM ============================================================
REM  SUMMARY AND GUIDANCE
REM ============================================================
:summary
ECHO.
ECHO ============================================================
ECHO   SUMMARY   Mode: !MODE_NAME!
ECHO ============================================================
IF EXIST "%TMP_REPORT%" TYPE "%TMP_REPORT%"
ECHO.
ECHO   Items found   : !C_FOUND!
IF NOT "%MODE%"=="1" ECHO   Removed       : !C_DONE!
IF NOT "%MODE%"=="1" ECHO   Needs restart : !C_PEND!
IF NOT "%MODE%"=="1" ECHO   Skipped       : !C_SKIP!
IF NOT "%MODE%"=="1" ECHO   Failed        : !C_FAIL!
ECHO.

IF "!C_FOUND!"=="0" GOTO sum_nothing
IF "%MODE%"=="1" GOTO sum_dry
IF DEFINED REBOOT CALL :guide_restart
IF NOT "!C_FAIL!"=="0" CALL :guide_failed
IF NOT "!C_SKIP!"=="0" CALL :guide_skipped
IF DEFINED REBOOT GOTO sum_end
IF NOT "!C_FAIL!"=="0" GOTO sum_end
IF NOT "!C_SKIP!"=="0" GOTO sum_end
ECHO   All found components were removed. To double check, run this script
ECHO   again and pick option 1, SCAN MODE. It should report nothing found.
GOTO sum_end

:sum_nothing
ECHO   No AntiCheatExpert components were found. Nothing to do.
GOTO sum_end

:sum_dry
ECHO   Scanning finished. Nothing was changed.
ECHO   To remove the items above, run this script again and pick 
ECHO   option 2 or 3 to delete them.
GOTO sum_end

:sum_end
DEL /Q "%TMP_ALL%" "%TMP_USER%" "%TMP_KERN%" "%TMP_FILES%" "%TMP_REPORT%" >NUL 2>&1
ECHO.
PAUSE
EXIT /B 0


:guide_restart
ECHO ------------------------------------------------------------
ECHO   RESTART REQUIRED
ECHO ------------------------------------------------------------
ECHO   Some components are still in use by Windows, so they could not be
ECHO   removed yet. Windows will finish removing some of them on restart.
ECHO.
ECHO   What to do:
ECHO     1. Save your work and close all games and launchers.
ECHO     2. Use Start, Power, RESTART. Do not use Shut down, because
ECHO        Windows Fast Startup can keep the old driver loaded.
ECHO     3. After the restart, right-click this script and choose
ECHO        Run as administrator, then pick option 1, SCAN MODE.
ECHO     4. If the Scan Mode lists anything, run again with option 3.
ECHO     5. If an item is still stuck after a second restart, start
ECHO        Windows in Safe Mode and run this script from there.
ECHO.
EXIT /B 0

:guide_failed
ECHO ------------------------------------------------------------
ECHO   SOME ITEMS FAILED
ECHO ------------------------------------------------------------
ECHO   Items marked FAILED above could not be removed. Common causes:
ECHO     - A game or launcher that uses AntiCheatExpert is still running.
ECHO       Close it, or end it in Task Manager.
ECHO     - Antivirus or another program is locking the files.
ECHO     - The script was not started as administrator.
ECHO   Fix the cause, restart Windows if unsure, then run this script again.
ECHO.
EXIT /B 0

:guide_skipped
ECHO ------------------------------------------------------------
ECHO   SOME ITEMS WERE SKIPPED
ECHO ------------------------------------------------------------
ECHO   Items marked SKIPPED were left untouched. Run this script again and
ECHO   pick option 3 if you want to handle them. A driver file is skipped
ECHO   while its service is still registered. Remove the service first.
ECHO.
EXIT /B 0


REM ============================================================
REM  ERROR EXITS
REM ============================================================
:not_admin
ECHO You need to run this as administrator. Right-click the script and choose "Run as administrator".
PAUSE
EXIT /B 1

:no_temp
ECHO Cannot find a usable temp folder, so the script cannot continue safely.
PAUSE
EXIT /B 1

:enum_fail
ECHO.
ECHO Could not read the list of Windows services, so nothing was changed.
ECHO Make sure you are running as administrator and try again. If this keeps
ECHO happening, restart Windows and run the script again.
DEL /Q "%TMP_ALL%" "%TMP_USER%" "%TMP_KERN%" >NUL 2>&1
PAUSE
EXIT /B 1


REM ============================================================
REM  :confirm  "question text, no parentheses"
REM  Returns errorlevel 0 for yes and 1 for no.
REM  In full auto mode it answers yes automatically.
REM ============================================================
:confirm
IF "%MODE%"=="2" (
    ECHO   [AUTO] %~1 Yes
    EXIT /B 0
)
CHOICE /C YN /N /M "  %~1 [Y/N]: "
IF ERRORLEVEL 2 EXIT /B 1
EXIT /B 0


REM ============================================================
REM  :process_service  "name"  USER or KERN
REM ============================================================
:process_service
SET "svc=%~1"
SET "kind=%~2"
SET "stopfail="

REM Safety: re-check the name prefix before doing anything.
SET "ok="
IF /I "%kind%"=="USER" IF /I "!svc:~0,15!"=="AntiCheatExpert" SET "ok=1"
IF /I "%kind%"=="KERN" IF /I "!svc:~0,4!"=="ACE-" SET "ok=1"
IF NOT DEFINED ok EXIT /B 0

SET /A C_FOUND+=1

SET "state="
FOR /F "tokens=3 delims=: " %%S IN ('sc.exe query "%svc%" 2^>NUL ^| findstr /C:"STATE"') DO SET "state=%%S"
SET "binpath="
FOR /F "tokens=1,* delims=:" %%X IN ('sc.exe qc "%svc%" 2^>NUL ^| findstr /C:"BINARY_PATH_NAME"') DO SET "binpath=%%Y"
IF DEFINED binpath SET "binpath=!binpath:~1!"

ECHO ------------------------------------------------------------
ECHO Found %kind% service : !svc!
ECHO   State       : !state!
ECHO   Binary path : !binpath!

IF "%MODE%"=="1" (
    ECHO   [SCAN MODE] This service would be stopped and deleted.
    >>"%TMP_REPORT%" ECHO WOULD REMOVE  service !svc!
    EXIT /B 0
)

CALL :confirm "Stop and delete this service?"
IF ERRORLEVEL 1 (
    ECHO   Skipped. Nothing was changed.
    SET /A C_SKIP+=1
    >>"%TMP_REPORT%" ECHO SKIPPED       service !svc!
    EXIT /B 0
)

ECHO   Stopping service...
sc.exe stop "%svc%" >NUL 2>&1
SET "rc=!ERRORLEVEL!"
IF "!rc!"=="1060" GOTO ps_gone
IF "!rc!"=="1062" GOTO ps_stopped
IF "!rc!"=="1052" GOTO ps_notstoppable
IF "!rc!"=="5" GOTO ps_denied
SET /A tries=0

:ps_wait
sc.exe query "%svc%" 2>&1 | find /I "STOPPED" >NUL && GOTO ps_stopped
sc.exe query "%svc%" >NUL 2>&1
IF ERRORLEVEL 1060 GOTO ps_stopped
SET /A tries+=1
IF !tries! GEQ 30 GOTO ps_notstopped
timeout /t 2 /nobreak >NUL
GOTO ps_wait

:ps_notstopped
ECHO   The service did not stop within 60 seconds. A game or launcher may
ECHO   still be using it. It will be marked for deletion and removed after
ECHO   you restart Windows.
SET "stopfail=1"
GOTO ps_delete

:ps_notstoppable
ECHO   Windows will not let this service be stopped while it is running.
ECHO   This is normal for kernel drivers. It will be marked for deletion and
ECHO   removed after you restart Windows.
SET "stopfail=1"
GOTO ps_delete

:ps_denied
ECHO   Access denied while stopping the service. Make sure the script is
ECHO   running as administrator.
SET /A C_FAIL+=1
>>"%TMP_REPORT%" ECHO FAILED        service !svc! - access denied
EXIT /B 0

:ps_stopped
ECHO   Service is stopped.

:ps_delete
ECHO   Deleting service registration...
sc.exe delete "%svc%" >NUL 2>&1
SET "rc=!ERRORLEVEL!"
IF "!rc!"=="0" GOTO ps_deleted
IF "!rc!"=="1072" GOTO ps_marked
IF "!rc!"=="1060" GOTO ps_gone
ECHO   sc delete failed with code !rc!.
SET /A C_FAIL+=1
>>"%TMP_REPORT%" ECHO FAILED        service !svc! - sc delete code !rc!
EXIT /B 0

:ps_deleted
IF DEFINED stopfail GOTO ps_marked
ECHO   Service deleted.
SET /A C_DONE+=1
>>"%TMP_REPORT%" ECHO REMOVED       service !svc!
EXIT /B 0

:ps_marked
ECHO   Service is marked for deletion and will disappear after a restart.
SET "REBOOT=1"
SET /A C_PEND+=1
>>"%TMP_REPORT%" ECHO NEEDS RESTART service !svc!
EXIT /B 0

:ps_gone
ECHO   Service no longer exists. Nothing more to do.
SET /A C_DONE+=1
>>"%TMP_REPORT%" ECHO REMOVED       service !svc!
EXIT /B 0


REM ============================================================
REM  :remove_folder  "full path"
REM  Only proceeds if the last path component is exactly AntiCheatExpert
REM  and the path has a drive letter.
REM ============================================================
:remove_folder
SET "dir=%~1"
IF NOT DEFINED dir EXIT /B 0
SET "dname="
SET "ddrive="
FOR %%I IN ("%~1") DO (
    SET "dname=%%~nxI"
    SET "ddrive=%%~dI"
)
IF NOT DEFINED ddrive EXIT /B 0
IF /I NOT "!dname!"=="AntiCheatExpert" EXIT /B 0
IF NOT EXIST "!dir!\" EXIT /B 0

SET /A C_FOUND+=1
ECHO ------------------------------------------------------------
ECHO Found folder: !dir!

IF "%MODE%"=="1" (
    ECHO   [SCAN MODE] This folder and its contents would be deleted.
    >>"%TMP_REPORT%" ECHO WOULD REMOVE  folder !dir!
    EXIT /B 0
)

CALL :confirm "Delete this folder and everything inside it?"
IF ERRORLEVEL 1 (
    ECHO   Skipped. Nothing was changed.
    SET /A C_SKIP+=1
    >>"%TMP_REPORT%" ECHO SKIPPED       folder !dir!
    EXIT /B 0
)

SET /A tries=0
:rf_try
RMDIR /S /Q "!dir!" >NUL 2>&1
IF NOT EXIST "!dir!\" GOTO rf_ok
SET /A tries+=1
IF !tries! GEQ 5 GOTO rf_fail
timeout /t 3 /nobreak >NUL
GOTO rf_try

:rf_ok
ECHO   Folder deleted.
SET /A C_DONE+=1
>>"%TMP_REPORT%" ECHO REMOVED       folder !dir!
EXIT /B 0

:rf_fail
ECHO   Could not delete everything. Some files are still in use.
SET "REBOOT=1"
SET /A C_FAIL+=1
>>"%TMP_REPORT%" ECHO FAILED        folder !dir! - files in use
EXIT /B 0


REM ============================================================
REM  :remove_regkey  "key"
REM  Only proceeds for keys whose last component is AntiCheatExpert.
REM ============================================================
:remove_regkey
SET "key=%~1"
IF /I NOT "!key:~-16!"=="\AntiCheatExpert" EXIT /B 0
reg.exe query "%key%" %REGVIEW% >NUL 2>&1
IF ERRORLEVEL 1 EXIT /B 0

SET /A C_FOUND+=1
SET "regname="
FOR /F "tokens=2,*" %%A IN ('reg.exe query "%key%" /v DisplayName %REGVIEW% 2^>NUL ^| findstr /C:"DisplayName"') DO SET "regname=%%B"

ECHO ------------------------------------------------------------
ECHO Found registry key: !key!
IF DEFINED regname ECHO   DisplayName : !regname!

IF "%MODE%"=="1" (
    ECHO   [SCAN MODE] This registry key would be deleted.
    >>"%TMP_REPORT%" ECHO WOULD REMOVE  registry !key!
    EXIT /B 0
)

CALL :confirm "Delete this registry key?"
IF ERRORLEVEL 1 (
    ECHO   Skipped. Nothing was changed.
    SET /A C_SKIP+=1
    >>"%TMP_REPORT%" ECHO SKIPPED       registry !key!
    EXIT /B 0
)

reg.exe delete "%key%" /f %REGVIEW% >NUL 2>&1
IF ERRORLEVEL 1 (
    ECHO   Could not delete the key.
    SET /A C_FAIL+=1
    >>"%TMP_REPORT%" ECHO FAILED        registry !key!
) ELSE (
    ECHO   Key deleted.
    SET /A C_DONE+=1
    >>"%TMP_REPORT%" ECHO REMOVED       registry !key!
)
EXIT /B 0


REM ============================================================
REM  :remove_driver_file  "file name only, from DIR output"
REM  Only proceeds for names that start with ACE- and end with .sys,
REM  only inside System32\drivers, and only when no service with the
REM  same name is still registered. Deletes that exact file only.
REM ============================================================
:remove_driver_file
SET "fname=%~1"
IF NOT DEFINED fname EXIT /B 0
IF /I NOT "!fname:~0,4!"=="ACE-" EXIT /B 0
IF /I NOT "!fname:~-4!"==".sys" EXIT /B 0

SET "target=%SystemPath%\drivers\!fname!"
IF NOT EXIST "!target!" EXIT /B 0

SET /A C_FOUND+=1
ECHO ------------------------------------------------------------
ECHO Found driver file: !target!
FOR %%S IN ("!target!") DO ECHO   Size: %%~zS bytes   Modified: %%~tS

SET "svcbase=!fname:~0,-4!"
SET "stillreg="
sc.exe query "!svcbase!" >NUL 2>&1
IF NOT ERRORLEVEL 1 SET "stillreg=1"

IF "%MODE%"=="1" (
    IF DEFINED stillreg ECHO   [SCAN MODE] This file would be deleted after service removal.
    IF NOT DEFINED stillreg ECHO   [SCAN MODE] This file would be deleted.
    >>"%TMP_REPORT%" ECHO WOULD REMOVE  driver file !fname!
    EXIT /B 0
)

IF DEFINED stillreg (
    ECHO   Skipped: the matching service !svcbase! is still registered.
    ECHO   Remove the service first, or restart Windows if it is waiting
    ECHO   to be removed, then run this script again.
    SET /A C_SKIP+=1
    >>"%TMP_REPORT%" ECHO SKIPPED       driver file !fname! - service still registered
    EXIT /B 0
)

CALL :confirm "Delete this file?"
IF ERRORLEVEL 1 (
    ECHO   Skipped. Nothing was changed.
    SET /A C_SKIP+=1
    >>"%TMP_REPORT%" ECHO SKIPPED       driver file !fname!
    EXIT /B 0
)

SET /A tries=0
:rdf_try
DEL /F /Q "!target!" >NUL 2>&1
IF NOT EXIST "!target!" GOTO rdf_ok
SET /A tries+=1
IF !tries! GEQ 12 GOTO rdf_fail
timeout /t 5 /nobreak >NUL
GOTO rdf_try

:rdf_ok
ECHO   File deleted.
SET /A C_DONE+=1
>>"%TMP_REPORT%" ECHO REMOVED       driver file !fname!
EXIT /B 0

:rdf_fail
ECHO   File is still locked by Windows.
SET "REBOOT=1"
SET /A C_FAIL+=1
>>"%TMP_REPORT%" ECHO FAILED        driver file !fname! - locked
EXIT /B 0
