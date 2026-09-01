@echo off
:: ============================================
:: ShowMMR v2.0 Installer (EN)
:: by: t.me/xanoya  |  2026-08-30
:: ============================================

:: ---------- Section 0: window no longer "closes itself" ----------
:: When the .bat is launched by double-click, Explorer creates a temporary
:: cmd.exe window that auto-closes the instant the script finishes (even if
:: it crashed). That's what caused the "opens and closes" effect - the
:: script may have run (or failed) in a split second and the window never
:: gave you a chance to read anything. So first we relaunch ourselves
:: inside a window that is guaranteed to stay open (cmd /k).
if /I "%~1"=="__started" (
    shift
) else (
    start "ShowMMR v2" /D "%~dp0" cmd /k call "%~f0" __started "%~1"
    exit /b 0
)

setlocal EnableDelayedExpansion

:: ---------- Config (Section 3.1) ----------
set "APP_VER=2.0"
set "LOG_FILE=%~dp0showmmr_log.txt"
set "LOG_LEVEL=DEBUG"
set "DOTA_PATH="
set "VERIFY_RESULT=SUCCESS"
set "STEAM_ID=1537228913"
set "VCFG_NAME=user_keys_%STEAM_ID%_slot3.vcfg"

:: ---------- Paths ----------
set "SRC_DIR=%~dp0source"
set "USERKEYS_DIR=%~dp0user_keys"
set "TOOL_VER=2.0"
set "BUILD_BAT=%~dp0build_vpk.bat"
call :log "INFO" "INIT" "Script started via cmd, checking admin rights..."


:: ---------- Admin rights check ----------
net session >nul 2>&1
if errorlevel 1 (
    echo.
    echo  [!] Script started WITHOUT administrator rights.
    echo      Install, uninstall and diagnostics need admin rights.
    echo      Close this window and run: Right-click -^> "Run as administrator".
    echo.
    echo      Press any key to continue anyway ^(some functions may not work^)...
    pause >nul
)
:: ---------- Launch args (drag-and-drop, Section 6.2) ----------
if "%~1" neq "" (
    set "DRAGGED_PATH=%~1"
)

:: ---------- Color scheme (Section 2.1) ----------
color 0B
title ShowMMR v2

:: ---------- Header (Section 2.2) ----------
call :clear_screen
echo.
echo  =========================================
echo    ShowMMR v2
echo    by: t.me/xanoya
echo  =========================================
echo.

:: ---------- Log init (Section 3) ----------
call :rotate_logs
call :check_logs_on_start
call :log "INFO" "INIT" "ShowMMR v2 started, build %APP_VER%"
if defined DRAGGED_PATH (
    call :log "INFO" "DRAG" "Path received at launch: %DRAGGED_PATH%"
)

:: ============================================
:: MENU (Section 2.3)
:: ============================================
:menu
call :clear_screen
echo.
echo  =========================================
echo    ShowMMR v2
echo    by: t.me/xanoya
echo  =========================================
echo.
echo  Choose an action:
echo.
echo   1. Install ShowMMR
echo   2. Update ShowMMR
echo   3. Uninstall ShowMMR
echo   4. Check files
echo   5. Update MMR (match history)
echo   6. Build VPK from source
echo   7. View logs
echo   8. Diagnostics
echo   9. Exit
echo.
set /p "choice=Enter number: "

if "%choice%"=="1" goto :install
if "%choice%"=="2" goto :update
if "%choice%"=="3" goto :uninstall
if "%choice%"=="4" goto :check
if "%choice%"=="5" goto :update_mmr
if "%choice%"=="6" goto :build_vpk
if "%choice%"=="7" goto :view_logs
if "%choice%"=="8" goto :diagnostics
if "%choice%"=="9" goto :end

echo  [X] Invalid input.
pause
goto :menu

:: ============================================
:: LOGGING FUNCTION (Section 3.2)
:: call :log "LEVEL" "COMPONENT" "MESSAGE"
:: ============================================
:log
set "LEVEL=%~1"
set "COMPONENT=%~2"
set "MESSAGE=%~3"
set "TIMESTAMP=%DATE:~-4,4%-%DATE:~-7,2%-%DATE:~-10,2% %TIME:~0,2%:%TIME:~3,2%:%TIME:~6,2%"

if not exist "%LOG_FILE%" (
    echo [%TIMESTAMP%] [INFO] [INIT] Log file created >> "%LOG_FILE%"
)

echo [%TIMESTAMP%] [%LEVEL%] [%COMPONENT%] %MESSAGE% >> "%LOG_FILE%"

:: Console output (only INFO, WARN, ERROR, SUCCESS)
if "%LEVEL%"=="DEBUG" goto :eof
if "%LEVEL%"=="INFO"  echo   [%COMPONENT%] %MESSAGE%
if "%LEVEL%"=="WARN"  echo   [%COMPONENT%] %MESSAGE%
if "%LEVEL%"=="ERROR" echo   [%COMPONENT%] %MESSAGE%
if "%LEVEL%"=="SUCCESS" echo   [%COMPONENT%] %MESSAGE%
goto :eof

:: ============================================
:: LOG ROTATION (Section 3.3)
:: ============================================
:rotate_logs
if not exist "%LOG_FILE%" goto :eof
for %%F in ("%LOG_FILE%") do set "LOG_SIZE=%%~zF"
if "%LOG_SIZE%"=="" goto :eof
if %LOG_SIZE% GTR 10485760 (
    set "ARCHIVE_NAME=showmmr_log_OLD_%DATE:~-4,4%%DATE:~-7,2%%DATE:~-10,2%_%TIME:~0,2%%TIME:~3,2%.txt"
    move /Y "%LOG_FILE%" "%~dp0%ARCHIVE_NAME%" >nul 2>&1
    call :log "INFO" "LOG" "Log archived: %ARCHIVE_NAME%"
)
:: Delete old archives (keep 5)
set /a "KEEP=0"
for /f "tokens=* delims=" %%A in ('dir /b /o-d "%~dp0showmmr_log_OLD_*.txt" 2^>nul') do (
    set /a "KEEP+=1"
    if !KEEP! GTR 5 (
        del /Q "%~dp0%%A" >nul 2>&1
        call :log "DEBUG" "LOG" "Deleted old log: %%A"
    )
)
goto :eof

:: ============================================
:: CHECK LOGS ON STARTUP (Section 3.4)
:: ============================================
:check_logs_on_start
if not exist "%LOG_FILE%" (
    echo [%DATE:~-4,4%-%DATE:~-7,2%-%DATE:~-10,2% %TIME:~0,2%:%TIME:~3,2%:%TIME:~6,2%] [INFO] [INIT] Log created > "%LOG_FILE%"
)
set "ERROR_COUNT=0"
for /f "tokens=*" %%A in ('findstr /C:"[ERROR]" "%LOG_FILE%" 2^>nul ^| find /c /v ""') do set "ERROR_COUNT=%%A"
if "%ERROR_COUNT%"=="" set "ERROR_COUNT=0"
if %ERROR_COUNT% GTR 0 (
    echo  [!] Found %ERROR_COUNT% errors from previous runs in the log.
    echo   Running diagnostics is recommended ^(option 8^).
    echo.
    set /p "RUN_DIAG=Run diagnostics now? (Y/N): "
    if /i "%RUN_DIAG%"=="Y" goto :diagnostics
)
goto :eof

:: ============================================
:: FIND DOTA 2 (Section 4.1)
:: ============================================
:find_dota
call :log "DEBUG" "PATH" "Starting Dota 2 search"

:: Path from Steam registry
call :log "DEBUG" "REG" "Checking HKCU\Software\Valve\Steam"
set "STEAM_PATH="
for /f "tokens=2,*" %%a in ('reg query "HKEY_CURRENT_USER\Software\Valve\Steam" /v SteamPath 2^>nul ^| find "SteamPath"') do (
    set "STEAM_PATH=%%b"
    if defined STEAM_PATH set "STEAM_PATH=!STEAM_PATH:/=\!"
)
if defined STEAM_PATH (
    call :log "INFO" "REG" "Steam found: !STEAM_PATH!"
    set "CANDIDATE=!STEAM_PATH!\steamapps\common\dota 2 beta\game"
    if exist "!CANDIDATE!\dota_mods" (
        set "DOTA_PATH=!CANDIDATE!"
        call :log "SUCCESS" "PATH" "Dota 2 found (registry): !CANDIDATE!"
        set "DOTA_PATH=!CANDIDATE!"
        goto :found
    )
)

:: Default paths
set "PATHS[1]=C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\game"
set "PATHS[2]=C:\Program Files\Steam\steamapps\common\dota 2 beta\game"
set "PATHS[3]=%USERPROFILE%\Steam\steamapps\common\dota 2 beta\game"
set "PATHS[4]=D:\Steam\steamapps\common\dota 2 beta\game"
set "PATHS[5]=E:\Steam\steamapps\common\dota 2 beta\game"

for %%i in (1 2 3 4 5) do (
    set "CURRENT_PATH=!PATHS[%%i]!"
    call :log "DEBUG" "PATH" "Checking: !CURRENT_PATH!"
    if exist "!CURRENT_PATH!\dota_mods" (
        set "DOTA_PATH=!CURRENT_PATH!"
        call :log "SUCCESS" "PATH" "Dota 2 found: !DOTA_PATH!"
        goto :found
    )
)

:: Manual entry
call :log "WARN" "PATH" "Automatic search failed"
echo  [X] Dota 2 not found automatically.
set /p "MANUAL_PATH=Enter path to the dota 2 beta \"game\" folder: "
if exist "%MANUAL_PATH%\dota_mods" (
    set "DOTA_PATH=%MANUAL_PATH%"
    call :log "INFO" "PATH" "Path entered manually: %DOTA_PATH%"
) else (
    call :log "ERROR" "PATH" "Invalid path: %MANUAL_PATH%"
    goto :error
)

:found
call :log "DEBUG" "PATH" "Search finished: %DOTA_PATH%"
goto :eof

:: ============================================
:: CHECK DEPENDENCIES (Section 4.2)
:: ============================================
:check_deps
call :log "INFO" "DEPS" "Starting dependency check"

:: Steam
call :log "DEBUG" "DEPS" "Checking Steam (registry)"
reg query "HKEY_CURRENT_USER\Software\Valve\Steam" /v SteamPath >nul 2>&1
if errorlevel 1 (
    call :log "WARN" "DEPS" "Steam not found in registry (check skipped)"
) else (
    call :log "SUCCESS" "DEPS" "Steam found in registry"
)

:: game folder found
if not defined DOTA_PATH (
    call :log "ERROR" "DEPS" "Dota 2 not found (DOTA_PATH is empty)"
    goto :error
)

:: dota_mods folder
if not exist "!DOTA_PATH!\dota_mods" (
    call :log "WARN" "DEPS" "dota_mods folder does not exist (will be created)"
    mkdir "!DOTA_PATH!\dota_mods" 2>nul
)

:: user_keys folder
if not exist "%USERKEYS_DIR%" (
    call :log "WARN" "DEPS" "user_keys folder not found (will be created)"
    mkdir "%USERKEYS_DIR%" 2>nul
)

:: Admin rights
net session >nul 2>&1
if errorlevel 1 (
    call :log "ERROR" "DEPS" "No administrator rights"
    echo  [X] No administrator rights.
    goto :error
) else (
    call :log "SUCCESS" "DEPS" "Administrator rights confirmed"
)

:: Free disk space (no WMIC - it's missing on new Windows 11 24H2+ builds)
call :get_free_mb "!DOTA_PATH:~0,2!"
if %FREE_MB% LSS 100 (
    call :log "WARN" "DEPS" "Low free space: %FREE_MB% MB"
    echo  [!] Low free space: %FREE_MB% MB
) else (
    call :log "INFO" "DEPS" "Free space: %FREE_MB% MB"
)

call :log "SUCCESS" "DEPS" "All dependencies checked"
goto :eof

:: ============================================
:: CHECK FILES (menu 4)
:: ============================================
:check
call :clear_screen
call :log "INFO" "CHECK" "=== Checking files ==="
call :find_dota
if not defined DOTA_PATH (
    call :log "ERROR" "CHECK" "Dota 2 not found"
    goto :error
)
call :verify_files
pause
goto :menu

:: ============================================
:: INSTALL (Section 4.3)
:: ============================================
:install
call :clear_screen
call :log "INFO" "INSTALL" "=== Starting install ==="

:: Find Dota 2
call :find_dota
if not defined DOTA_PATH (
    call :log "ERROR" "INSTALL" "Dota 2 not found"
    goto :error
)

:: Check dependencies
call :check_deps

:: Check that the built VPK exists - single folder: %~dp0
set "MOD_VPK=%~dp0pak02_dir.vpk"
if not exist "%MOD_VPK%" (
    call :log "ERROR" "INSTALL" "pak02_dir.vpk not found next to the script"
    echo  [X] pak02_dir.vpk not found next to the script.
    echo   Expected: %~dp0pak02_dir.vpk
    echo   Working VPK ^(30429 bytes^) should be in the single data folder: %~dp0
    echo   Copy it from the backup if needed.
    pause
    goto :menu
)

:: Backup
call :log "INFO" "BACKUP" "Creating backup"
set "BACKUP_DIR=%~dp0backup_%DATE:~-4,4%%DATE:~-7,2%%DATE:~-10,2%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%"
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

:: Backup mod folder
if exist "!DOTA_PATH!\dota_mods\pak02_dir.vpk" (
    copy /Y "!DOTA_PATH!\dota_mods\pak02_dir.vpk" "%BACKUP_DIR%\pak02_dir.vpk" >nul 2>&1
    call :log "SUCCESS" "BACKUP" "Backed up mod VPK: %BACKUP_DIR%\pak02_dir.vpk"
)
:: Backup cfg
if exist "!DOTA_PATH!\dota\cfg\%VCFG_NAME%" (
    copy /Y "!DOTA_PATH!\dota\cfg\%VCFG_NAME%" "%BACKUP_DIR%\%VCFG_NAME%" >nul 2>&1
    call :log "SUCCESS" "BACKUP" "Backed up cfg: %BACKUP_DIR%\%VCFG_NAME%"
)

:: Copy VPK to dota_mods
call :log "INFO" "COPY" "Copying pak02_dir.vpk to dota_mods"
copy /Y "%MOD_VPK%" "!DOTA_PATH!\dota_mods\pak02_dir.vpk" >nul 2>&1
if errorlevel 1 (
    call :log "ERROR" "COPY" "Error copying VPK (code: %ERRORLEVEL%)"
    goto :error
) else (
    call :log "SUCCESS" "COPY" "pak02_dir.vpk copied"
)

:: Copy vcfg (if it already exists)
if exist "%USERKEYS_DIR%\%VCFG_NAME%" (
    call :log "INFO" "COPY" "Copying %VCFG_NAME% to game\dota\cfg"
    if not exist "!DOTA_PATH!\dota\cfg" mkdir "!DOTA_PATH!\dota\cfg" 2>nul
    copy /Y "%USERKEYS_DIR%\%VCFG_NAME%" "!DOTA_PATH!\dota\cfg\%VCFG_NAME%" >nul 2>&1
    if errorlevel 1 (
        call :log "WARN" "COPY" "Could not copy vcfg (file may be locked by Dota)"
    ) else (
        call :log "SUCCESS" "COPY" "vcfg copied"
    )
)

:: Verify result
call :verify_files
if "!VERIFY_RESULT!"=="ERROR" (
    call :log "ERROR" "INSTALL" "File verification failed"
    goto :error
)

call :log "SUCCESS" "INSTALL" "=== Install completed successfully ==="
echo.
echo  [OK] Install completed.
echo   Log: %LOG_FILE%
echo   NOTE: Restart Dota 2 so the mod takes effect.
pause
goto :menu

:: ============================================
:: UPDATE (Section 4.4)
:: ============================================
:update
call :clear_screen
call :log "INFO" "UPDATE" "=== Update (reinstall) ==="
call :find_dota
if not defined DOTA_PATH (
    call :log "ERROR" "UPDATE" "Dota 2 not found"
    goto :error
)
call :check_deps
goto :install

:: ============================================
:: UNINSTALL (Section 4.5)
:: ============================================
:uninstall
call :clear_screen
call :log "INFO" "UNINSTALL" "=== Starting uninstall ==="
call :find_dota
if not defined DOTA_PATH (
    call :log "ERROR" "UNINSTALL" "Dota 2 not found"
    goto :error
)

:: Find latest backup
set "LATEST_BACKUP="
for /f "tokens=* delims=" %%A in ('dir /b /o-d "%~dp0backup_*" 2^>nul') do (
    set "LATEST_BACKUP=%%A"
    goto :backup_found
)
:backup_found

:: Restore from backup if it exists
if defined LATEST_BACKUP (
    call :log "INFO" "UNINSTALL" "Restoring from: !LATEST_BACKUP!"
    if exist "%~dp0!LATEST_BACKUP!\pak02_dir.vpk" (
        copy /Y "%~dp0!LATEST_BACKUP!\pak02_dir.vpk" "!DOTA_PATH!\dota_mods\pak02_dir.vpk" >nul 2>&1
        call :log "SUCCESS" "UNINSTALL" "pak02_dir.vpk restored from backup"
    ) else (
        call :log "INFO" "UNINSTALL" "No pak02_dir.vpk in backup (removing mod)"
        del /Q "!DOTA_PATH!\dota_mods\pak02_dir.vpk" 2>nul
        call :log "SUCCESS" "UNINSTALL" "pak02_dir.vpk removed"
    )
    if exist "%~dp0!LATEST_BACKUP!\%VCFG_NAME%" (
        if exist "!DOTA_PATH!\dota\cfg" (
            copy /Y "%~dp0!LATEST_BACKUP!\%VCFG_NAME%" "!DOTA_PATH!\dota\cfg\%VCFG_NAME%" >nul 2>&1
            call :log "SUCCESS" "UNINSTALL" "%VCFG_NAME% restored from backup"
        )
    )
) else (
    call :log "WARN" "UNINSTALL" "No backup found, removing ShowMMR files"
    del /Q "!DOTA_PATH!\dota_mods\pak02_dir.vpk" 2>nul
    call :log "SUCCESS" "UNINSTALL" "pak02_dir.vpk removed"
)

call :log "SUCCESS" "UNINSTALL" "=== Uninstall completed ==="
echo  [OK] Uninstall completed.
pause
goto :menu

:: ============================================
:: VERIFY FILES (Section 4.6)
:: ============================================
:verify_files
call :log "INFO" "VERIFY" "Checking files"
set "VERIFY_RESULT=SUCCESS"
set "MISSING_FILES=0"

:: Check installed VPK
if not exist "!DOTA_PATH!\dota_mods\pak02_dir.vpk" (
    call :log "ERROR" "VERIFY" "Installed pak02_dir.vpk not found"
    set /a "MISSING_FILES+=1"
    set "VERIFY_RESULT=ERROR"
) else (
    call :log "DEBUG" "VERIFY" "pak02_dir.vpk is installed"
)

if exist "%USERKEYS_DIR%\%VCFG_NAME%" (
    call :log "DEBUG" "VERIFY" "vcfg found in user_keys"
) else (
    call :log "WARN" "VERIFY" "vcfg not found (run MMR update, option 5)"
)

if "%MISSING_FILES%"=="0" (
    call :log "SUCCESS" "VERIFY" "All files present"
    echo  [OK] All files present
) else (
    call :log "ERROR" "VERIFY" "Missing files: %MISSING_FILES%"
    echo  [X] Missing files: %MISSING_FILES%
)
goto :eof

:: ============================================
:: UPDATE MMR via ShowMMR.exe (Section 4.3b)
:: ============================================
:update_mmr
call :clear_screen
call :log "INFO" "MMR" "=== Updating MMR ==="

:: Find the tool
set "TOOL_EXE=%~dp0ShowMMR_tool\bin\Release\net48\ShowMMR.exe"
if not exist "%TOOL_EXE%" (
    call :log "ERROR" "MMR" "ShowMMR.exe not found: %TOOL_EXE%"
    echo  [X] ShowMMR_tool\bin\Release\net48\ShowMMR.exe not found.
    echo   Build the tool ^(build.bat^) or point to the right path.
    pause
    goto :menu
)

call :find_dota
if not defined DOTA_PATH (
    call :log "ERROR" "MMR" "Dota 2 not found"
    goto :error
)

:: Steam login prompt
echo.
set "steam_user="
set /p "steam_user=Steam login (Enter to use cached .auth): "

:: Run the tool inside user_keys (it generates the vcfg there)
if not exist "%USERKEYS_DIR%" mkdir "%USERKEYS_DIR%" 2>nul
if exist "%~dp0ShowMMR_tool\*.auth" copy /Y "%~dp0ShowMMR_tool\*.auth" "%USERKEYS_DIR%\" >nul 2>&1
if exist "%~dp0*.auth" copy /Y "%~dp0*.auth" "%USERKEYS_DIR%\" >nul 2>&1
pushd "%USERKEYS_DIR%"
if "%steam_user%"=="" (
    call :log "INFO" "MMR" "Running ShowMMR.exe with cached .auth"
    "%TOOL_EXE%" > "%~dp0showmmr_tool_out.txt" 2>&1
) else (
    call :log "INFO" "MMR" "Running ShowMMR.exe for: %steam_user%"
    echo   It is recommended to pre-create an .auth cache for %steam_user% next to the tool.
    "%TOOL_EXE%" "%steam_user%" > "%~dp0showmmr_tool_out.txt" 2>&1
)
set "TOOL_EXIT=!ERRORLEVEL!"
popd

:: Check result - fallback to existing vcfg in ShowMMR_tool if generation failed
if not exist "%USERKEYS_DIR%\%VCFG_NAME%" (
    if exist "%~dp0ShowMMR_tool\%VCFG_NAME%" (
        copy /Y "%~dp0ShowMMR_tool\%VCFG_NAME%" "%USERKEYS_DIR%\%VCFG_NAME%" >nul 2>&1
        call :log "WARN" "MMR" "vcfg not generated, copied existing from ShowMMR_tool"
        echo  [!] vcfg not generated, using existing from ShowMMR_tool
    )
)
if not exist "%USERKEYS_DIR%\%VCFG_NAME%" (
    call :log "ERROR" "MMR" "vcfg was not generated"
    echo  [X] File %VCFG_NAME% was not created. Check showmmr_tool_out.txt
    pause
    goto :menu
)

:: Copy to game\dota\cfg
call :log "INFO" "MMR" "Copying vcfg to game\dota\cfg"
if not exist "!DOTA_PATH!\dota\cfg" mkdir "!DOTA_PATH!\dota\cfg" 2>nul
copy /Y "%USERKEYS_DIR%\%VCFG_NAME%" "!DOTA_PATH!\dota\cfg\%VCFG_NAME%" >nul 2>&1
if errorlevel 1 (
    call :log "ERROR" "MMR" "Could not copy vcfg (is Dota running? Close Dota)"
    echo  [X] Could not copy. Close Dota 2 and try again.
    pause
    goto :menu
)
call :log "SUCCESS" "MMR" "MMR updated: %VCFG_NAME%"
echo  [OK] MMR updated.
echo   Restart Dota 2.
pause
goto :menu

:: ============================================
:: BUILD VPK FROM SOURCE (Section 4.3c)
:: ============================================
:build_vpk
call :clear_screen
call :log "INFO" "BUILD" "=== Building VPK from source ==="

if not exist "%SRC_DIR%" (
    call :log "ERROR" "BUILD" "source folder not found"
    echo  [X] source folder not found next to the script.
    pause
    goto :menu
)

if not exist "%BUILD_BAT%" (
    call :log "ERROR" "BUILD" "build_vpk.bat not found"
    echo  [X] build_vpk.bat not found.
    echo   Working VPK already at %~dp0pak02_dir.vpk ^(single folder^) - no build needed.
    echo   If you need to rebuild, use Dota Workshop Tools or place VPK manually.
    echo  [X] build_vpk.bat not found ^(the VPK build script^).
    echo   You need build_vpk.bat from the project ^(resourcecompiler + vpk^).
    echo   Alternatively, place a prebuilt pak02_dir.vpk next to the script.
    pause
    goto :menu
)

call :log "INFO" "BUILD" "Running build_vpk.bat"
echo   Building VPK from source...
call "%BUILD_BAT%"
call :log "INFO" "BUILD" "Build finished (code: !ERRORLEVEL!)"

if exist "%~dp0pak02_dir.vpk" (
    call :log "SUCCESS" "BUILD" "pak02_dir.vpk built"
    echo  [OK] VPK built: %~dp0pak02_dir.vpk
) else (
    call :log "WARN" "BUILD" "pak02_dir.vpk was not created - check build_vpk.bat"
    echo  [!] pak02_dir.vpk was not found after the build.
)
pause
goto :menu

:: ============================================
:: VIEW LOGS (Section 4.7)
:: ============================================
:view_logs
call :clear_screen
call :log "INFO" "LOG" "Viewing logs"
if not exist "%LOG_FILE%" (
    echo  [X] Log file not found.
    pause
    goto :menu
)
echo.
echo  --- Viewing logs (%LOG_FILE%) ---
echo.
echo  1. Last 20 lines
echo  2. All errors
echo  3. All warnings
echo  4. Clear log
echo  5. Back
echo.
set /p "LOG_CHOICE=Choose: "

if "%LOG_CHOICE%"=="1" (
    echo.
    echo  === Last 20 lines ===
    powershell -NoProfile -Command "Get-Content -Tail 20 '%LOG_FILE%'"
)
if "%LOG_CHOICE%"=="2" (
    echo.
    echo  === All errors ===
    findstr /C:"[ERROR]" "%LOG_FILE%"
)
if "%LOG_CHOICE%"=="3" (
    echo.
    echo  === All warnings ===
    findstr /C:"[WARN]" "%LOG_FILE%"
)
if "%LOG_CHOICE%"=="4" (
    set /p "CONFIRM=Clear the log? (Y/N): "
    if /i "%CONFIRM%"=="Y" (
        echo. > "%LOG_FILE%"
        call :log "INFO" "LOG" "Log cleared"
        echo  [OK] Log cleared
    )
)
if "%LOG_CHOICE%"=="5" goto :menu
pause
goto :view_logs

:: ============================================
:: DIAGNOSTICS (Section 4.8)
:: ============================================
:diagnostics
call :clear_screen
call :log "INFO" "DIAG" "=== Running diagnostics ==="
call :find_dota
echo.
echo  === ShowMMR v2 Diagnostics ===
echo.

echo  [1/8] Checking log...
if exist "%LOG_FILE%" (
    call :log "SUCCESS" "DIAG" "Log found"
    echo   [OK] Log found
) else (
    call :log "WARN" "DIAG" "Log not found"
    echo   [!] Log not found
)

echo  [2/8] Checking Steam...
reg query "HKEY_CURRENT_USER\Software\Valve\Steam" /v SteamPath >nul 2>&1
if not errorlevel 1 (
    call :log "SUCCESS" "DIAG" "Steam found"
    echo   [OK] Steam found
) else (
    call :log "ERROR" "DIAG" "Steam not found"
    echo   [X] Steam not found
)

echo  [3/8] Checking Dota 2...
if defined DOTA_PATH (
    call :log "SUCCESS" "DIAG" "Dota 2: !DOTA_PATH!"
    echo   [OK] Dota 2: !DOTA_PATH!
) else (
    call :log "ERROR" "DIAG" "Dota 2 not found"
    echo   [X] Dota 2 not found
)

echo  [4/8] Checking installed VPK...
if exist "!DOTA_PATH!\dota_mods\pak02_dir.vpk" (
    call :log "SUCCESS" "DIAG" "pak02_dir.vpk is installed"
    echo   [OK] pak02_dir.vpk is installed
) else (
    call :log "ERROR" "DIAG" "pak02_dir.vpk is NOT installed"
    echo   [X] pak02_dir.vpk is NOT installed
)

echo  [5/8] Checking user_keys...
if exist "%USERKEYS_DIR%" (
    call :log "SUCCESS" "DIAG" "user_keys found"
    echo   [OK] user_keys found
) else (
    call :log "ERROR" "DIAG" "user_keys not found"
    echo   [X] user_keys not found
)

echo  [6/8] Checking administrator rights...
net session >nul 2>&1
if not errorlevel 1 (
    call :log "SUCCESS" "DIAG" "Administrator rights"
    echo   [OK] Administrator rights
) else (
    call :log "WARN" "DIAG" "No administrator rights"
    echo   [!] No administrator rights
)

echo  [7/8] Checking free disk space...
call :get_free_mb "!DOTA_PATH:~0,2!"
if %FREE_MB% GTR 100 (
    call :log "SUCCESS" "DIAG" "Free space: %FREE_MB% MB"
    echo   [OK] Free space: %FREE_MB% MB
) else (
    call :log "ERROR" "DIAG" "Low free space: %FREE_MB% MB"
    echo   [X] Low free space: %FREE_MB% MB
)

echo  [8/8] Checking files...
call :verify_files

echo.
echo  === Diagnostics complete ===
call :log "SUCCESS" "DIAG" "Diagnostics complete"
pause
goto :menu

:: ============================================
:: FREE DISK SPACE CHECK (replaces WMIC)
:: call :get_free_mb "C:"  -> returns FREE_MB
:: ============================================
:get_free_mb
set "_DRV=%~1"
if "%_DRV%"=="" set "_DRV=C:"
set "_PSFREE="
for /f "usebackq delims=" %%v in (`powershell -NoProfile -Command "try { [math]::Floor((Get-PSDrive -Name ('%_DRV%').Substring(0,1) -ErrorAction Stop).Free / 1MB) } catch { -1 }"`) do set "_PSFREE=%%v"
if not defined _PSFREE set "_PSFREE=-1"
if "%_PSFREE%"=="-1" (
    call :log "WARN" "DEPS" "Could not determine free space (PowerShell unavailable?), skipping check"
    set "FREE_MB=999999"
) else (
    set "FREE_MB=%_PSFREE%"
)
goto :eof

:: ============================================
:: GLOBAL ERROR HANDLER (Section 6.3)
:: ============================================
:error
call :log "ERROR" "GLOBAL" "An error occurred (code: %ERRORLEVEL%)"
echo.
echo  [X] An error occurred.
echo   Check the log: %LOG_FILE%
echo.
pause
goto :menu

:: ============================================
:: CLEAR SCREEN
:: ============================================
:clear_screen
cls
goto :eof

:: ============================================
:: EXIT
:: ============================================
:end
call :log "INFO" "EXIT" "Program finished"
exit /b 0