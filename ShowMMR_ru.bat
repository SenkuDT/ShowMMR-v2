@echo off
:: ============================================
:: ShowMMR v2.0 Installer (RU)
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
call :log "INFO" "INIT" "Скрипт запущен через cmd, проверка прав..."


:: ---------- Admin rights check ----------
net session >nul 2>&1
if errorlevel 1 (
    echo.
    echo  [!] Скрипт запущен БЕЗ прав администратора.
    echo      Для установки, удаления и диагностики нужны права администратора.
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
call :log "INFO" "INIT" "ShowMMR v2 запущен, сборка %APP_VER%"
if defined DRAGGED_PATH (
    call :log "INFO" "DRAG" "Получен путь при запуске: %DRAGGED_PATH%"
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
echo  Выберите действие:
echo.
echo   1. Установить ShowMMR
echo   2. Обновить ShowMMR
echo   3. Удалить ShowMMR
echo   4. Проверить файлы
echo   5. Обновить MMR (история матчей)
echo   6. Собрать VPK из исходников
echo   7. Просмотр логов
echo   8. Диагностика
echo   9. Выход
echo.
set /p "choice=Введите номер: "

if "%choice%"=="1" goto :install
if "%choice%"=="2" goto :update
if "%choice%"=="3" goto :uninstall
if "%choice%"=="4" goto :check
if "%choice%"=="5" goto :update_mmr
if "%choice%"=="6" goto :build_vpk
if "%choice%"=="7" goto :view_logs
if "%choice%"=="8" goto :diagnostics
if "%choice%"=="9" goto :end

echo  [X] Неверный ввод.
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
call :log "DEBUG" "PATH" "Поиск Dota 2"

:: Path from Steam registry
call :log "DEBUG" "REG" "Проверка HKCU\Software\Valve\Steam"
set "STEAM_PATH="
for /f "tokens=2,*" %%a in ('reg query "HKEY_CURRENT_USER\Software\Valve\Steam" /v SteamPath 2^>nul ^| find "SteamPath"') do (
    set "STEAM_PATH=%%b"
    if defined STEAM_PATH set "STEAM_PATH=!STEAM_PATH:/=\!"
)
if defined STEAM_PATH (
    call :log "INFO" "REG" "Steam найден: !STEAM_PATH!"
    set "CANDIDATE=!STEAM_PATH!\steamapps\common\dota 2 beta\game"
    if exist "!CANDIDATE!\dota_mods" (
        set "DOTA_PATH=!CANDIDATE!"
        call :log "SUCCESS" "PATH" "Dota 2 найдена (реестр): !CANDIDATE!"
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
    call :log "DEBUG" "PATH" "Проверка: !CURRENT_PATH!"
    if exist "!CURRENT_PATH!\dota_mods" (
        set "DOTA_PATH=!CURRENT_PATH!"
        call :log "SUCCESS" "PATH" "Dota 2 найдена: !DOTA_PATH!"
        goto :found
    )
)

:: Manual entry
call :log "WARN" "PATH" "Автоматический поиск не удался"
echo  [X] Dota 2 не найдена автоматически.
set /p "MANUAL_PATH=Enter path to the dota 2 beta \"game\" folder: "
if exist "%MANUAL_PATH%\dota_mods" (
    set "DOTA_PATH=%MANUAL_PATH%"
    call :log "INFO" "PATH" "Путь введен вручную: %DOTA_PATH%"
) else (
    call :log "ERROR" "PATH" "Неверный путь: %MANUAL_PATH%"
    goto :error
)

:found
call :log "DEBUG" "PATH" "Поиск завершен: %DOTA_PATH%"
goto :eof

:: ============================================
:: CHECK DEPENDENCIES (Section 4.2)
:: ============================================
:check_deps
call :log "INFO" "DEPS" "Проверка зависимостей"

:: Steam
call :log "DEBUG" "DEPS" "Проверка Steam (реестр)"
reg query "HKEY_CURRENT_USER\Software\Valve\Steam" /v SteamPath >nul 2>&1
if errorlevel 1 (
    call :log "WARN" "DEPS" "Steam не найден в реестре (проверка пропущена)"
) else (
    call :log "SUCCESS" "DEPS" "Steam найден в реестре"
)

:: game folder found
if not defined DOTA_PATH (
    call :log "ERROR" "DEPS" "Dota 2 не найдена (путь пуст)"
    goto :error
)

:: dota_mods folder
if not exist "!DOTA_PATH!\dota_mods" (
    call :log "WARN" "DEPS" "Папка dota_mods не существует (будет создана)"
    mkdir "!DOTA_PATH!\dota_mods" 2>nul
)

:: user_keys folder
if not exist "%USERKEYS_DIR%" (
    call :log "WARN" "DEPS" "Папка user_keys не найдена (будет создана)"
    mkdir "%USERKEYS_DIR%" 2>nul
)

:: Admin rights
net session >nul 2>&1
if errorlevel 1 (
    call :log "ERROR" "DEPS" "Нет прав администратора"
    echo  [X] Нет прав администратора.
    goto :error
) else (
    call :log "SUCCESS" "DEPS" "Права администратора подтверждены"
)

:: Free disk space (no WMIC - it's missing on new Windows 11 24H2+ builds)
call :get_free_mb "!DOTA_PATH:~0,2!"
if %FREE_MB% LSS 100 (
    call :log "WARN" "DEPS" "Мало свободного места: %FREE_MB% MB"
    echo  [!] Мало свободного места: %FREE_MB% MB
) else (
    call :log "INFO" "DEPS" "Свободно: %FREE_MB% MB"
)

call :log "SUCCESS" "DEPS" "Все зависимости проверены"
goto :eof

:: ============================================
:: CHECK FILES (menu 4)
:: ============================================
:check
call :clear_screen
call :log "INFO" "CHECK" "=== Проверка файлов ==="
call :find_dota
if not defined DOTA_PATH (
    call :log "ERROR" "CHECK" "Dota 2 не найдена"
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
call :log "INFO" "INSTALL" "=== Начало установки ==="

:: Find Dota 2
call :find_dota
if not defined DOTA_PATH (
    call :log "ERROR" "INSTALL" "Dota 2 не найдена"
    goto :error
)

:: Check dependencies
call :check_deps

:: Check that the built VPK exists - single folder: %~dp0
set "MOD_VPK=%~dp0pak02_dir.vpk"
if not exist "%MOD_VPK%" (
    call :log "ERROR" "INSTALL" "pak02_dir.vpk не найден рядом со скриптом"
    echo  [X] pak02_dir.vpk не найден рядом со скриптом.
    echo   Ожидалось: %~dp0pak02_dir.vpk
    echo   Working VPK ^(30429 bytes^) should be in the single data folder: %~dp0
    echo   Скопируйте его из бэкапа если нужно.
    pause
    goto :menu
)

:: Назадup
call :log "INFO" "BACKUP" "Создание бэкапа"
set "BACKUP_DIR=%~dp0backup_%DATE:~-4,4%%DATE:~-7,2%%DATE:~-10,2%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%"
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

:: Назадup mod folder
if exist "!DOTA_PATH!\dota_mods\pak02_dir.vpk" (
    copy /Y "!DOTA_PATH!\dota_mods\pak02_dir.vpk" "%BACKUP_DIR%\pak02_dir.vpk" >nul 2>&1
    call :log "SUCCESS" "BACKUP" "Сохранен VPK мода: %BACKUP_DIR%\pak02_dir.vpk"
)
:: Назадup cfg
if exist "!DOTA_PATH!\dota\cfg\%VCFG_NAME%" (
    copy /Y "!DOTA_PATH!\dota\cfg\%VCFG_NAME%" "%BACKUP_DIR%\%VCFG_NAME%" >nul 2>&1
    call :log "SUCCESS" "BACKUP" "Сохранен cfg: %BACKUP_DIR%\%VCFG_NAME%"
)

:: Copy VPK to dota_mods
call :log "INFO" "COPY" "Копирование pak02_dir.vpk в dota_mods"
copy /Y "%MOD_VPK%" "!DOTA_PATH!\dota_mods\pak02_dir.vpk" >nul 2>&1
if errorlevel 1 (
    call :log "ERROR" "COPY" "Ошибка копирования VPK (код: %ERRORLEVEL%)"
    goto :error
) else (
    call :log "SUCCESS" "COPY" "pak02_dir.vpk скопирован"
)

:: Copy vcfg (if it already exists)
if exist "%USERKEYS_DIR%\%VCFG_NAME%" (
    call :log "INFO" "COPY" "Копирование %VCFG_NAME% в game\dota\cfg"
    if not exist "!DOTA_PATH!\dota\cfg" mkdir "!DOTA_PATH!\dota\cfg" 2>nul
    copy /Y "%USERKEYS_DIR%\%VCFG_NAME%" "!DOTA_PATH!\dota\cfg\%VCFG_NAME%" >nul 2>&1
    if errorlevel 1 (
        call :log "WARN" "COPY" "Не удалось скопировать vcfg (файл занят Dota)"
    ) else (
        call :log "SUCCESS" "COPY" "vcfg скопирован"
    )
)

:: Verify result
call :verify_files
if "!VERIFY_RESULT!"=="ERROR" (
    call :log "ERROR" "INSTALL" "Проверка файлов не пройдена"
    goto :error
)

call :log "SUCCESS" "INSTALL" "=== Установка успешно завершена ==="
echo.
echo  [OK] Установка завершена.
echo   Log: %LOG_FILE%
echo   ПРИМЕЧАНИЕ: Перезапустите Dota 2.
pause
goto :menu

:: ============================================
:: UPDATE (Section 4.4)
:: ============================================
:update
call :clear_screen
call :log "INFO" "UPDATE" "=== Обновление (переустановка) ==="
call :find_dota
if not defined DOTA_PATH (
    call :log "ERROR" "UPDATE" "Dota 2 не найдена"
    goto :error
)
call :check_deps
goto :install

:: ============================================
:: UNINSTALL (Section 4.5)
:: ============================================
:uninstall
call :clear_screen
call :log "INFO" "UNINSTALL" "=== Начало удаления ==="
call :find_dota
if not defined DOTA_PATH (
    call :log "ERROR" "UNINSTALL" "Dota 2 не найдена"
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
    call :log "INFO" "UNINSTALL" "Восстановление из: !LATEST_BACKUP!"
    if exist "%~dp0!LATEST_BACKUP!\pak02_dir.vpk" (
        copy /Y "%~dp0!LATEST_BACKUP!\pak02_dir.vpk" "!DOTA_PATH!\dota_mods\pak02_dir.vpk" >nul 2>&1
        call :log "SUCCESS" "UNINSTALL" "pak02_dir.vpk восстановлен из бэкапа"
    ) else (
        call :log "INFO" "UNINSTALL" "Нет pak02_dir.vpk в бэкапе (удаление мода)"
        del /Q "!DOTA_PATH!\dota_mods\pak02_dir.vpk" 2>nul
        call :log "SUCCESS" "UNINSTALL" "pak02_dir.vpk удален"
    )
    if exist "%~dp0!LATEST_BACKUP!\%VCFG_NAME%" (
        if exist "!DOTA_PATH!\dota\cfg" (
            copy /Y "%~dp0!LATEST_BACKUP!\%VCFG_NAME%" "!DOTA_PATH!\dota\cfg\%VCFG_NAME%" >nul 2>&1
            call :log "SUCCESS" "UNINSTALL" "%VCFG_NAME% восстановлен из бэкапа"
        )
    )
) else (
    call :log "WARN" "UNINSTALL" "Бэкап не найден, удаление файлов ShowMMR"
    del /Q "!DOTA_PATH!\dota_mods\pak02_dir.vpk" 2>nul
    call :log "SUCCESS" "UNINSTALL" "pak02_dir.vpk удален"
)

call :log "SUCCESS" "UNINSTALL" "=== Удаление завершено ==="
echo  [OK] Удаление завершено.
pause
goto :menu

:: ============================================
:: VERIFY FILES (Section 4.6)
:: ============================================
:verify_files
call :log "INFO" "VERIFY" "Проверка файлов"
set "VERIFY_RESULT=SUCCESS"
set "MISSING_FILES=0"

:: Check installed VPK
if not exist "!DOTA_PATH!\dota_mods\pak02_dir.vpk" (
    call :log "ERROR" "VERIFY" "Установленный pak02_dir.vpk не найден"
    set /a "MISSING_FILES+=1"
    set "VERIFY_RESULT=ERROR"
) else (
    call :log "DEBUG" "VERIFY" "pak02_dir.vpk установлен"
)

if exist "%USERKEYS_DIR%\%VCFG_NAME%" (
    call :log "DEBUG" "VERIFY" "vcfg найден в user_keys"
) else (
    call :log "WARN" "VERIFY" "vcfg не найден (обновите MMR, пункт 5)"
)

if "%MISSING_FILES%"=="0" (
    call :log "SUCCESS" "VERIFY" "Все файлы на месте"
    echo  [OK] Все файлы на месте
) else (
    call :log "ERROR" "VERIFY" "Отсутствуют файлы: %MISSING_FILES%"
    echo  [X] Отсутствуют файлы: %MISSING_FILES%
)
goto :eof

:: ============================================
:: UPDATE MMR via ShowMMR.exe (Section 4.3b)
:: ============================================
:update_mmr
call :clear_screen
call :log "INFO" "MMR" "=== Обновление MMR ==="

:: Find the tool
set "TOOL_EXE=%~dp0ShowMMR_tool\bin\Release\net48\ShowMMR.exe"
if not exist "%TOOL_EXE%" (
    call :log "ERROR" "MMR" "ShowMMR.exe не найден: %TOOL_EXE%"
    echo  [X] ShowMMR_tool\bin\Release\net48\ShowMMR.exe не найден.
    echo   Build the tool ^(build.bat^) or point to the right path.
    pause
    goto :menu
)

call :find_dota
if not defined DOTA_PATH (
    call :log "ERROR" "MMR" "Dota 2 не найдена"
    goto :error
)

:: Steam login prompt
echo.
set "steam_user="
set /p "steam_user=Логин Steam (Enter для кеша .auth): "

:: Run the tool inside user_keys (it generates the vcfg there)
if not exist "%USERKEYS_DIR%" mkdir "%USERKEYS_DIR%" 2>nul
if exist "%~dp0ShowMMR_tool\*.auth" copy /Y "%~dp0ShowMMR_tool\*.auth" "%USERKEYS_DIR%\" >nul 2>&1
if exist "%~dp0*.auth" copy /Y "%~dp0*.auth" "%USERKEYS_DIR%\" >nul 2>&1
pushd "%USERKEYS_DIR%"
if "%steam_user%"=="" (
    call :log "INFO" "MMR" "Запуск ShowMMR.exe с кешем .auth"
    "%TOOL_EXE%" > "%~dp0showmmr_tool_out.txt" 2>&1
) else (
    call :log "INFO" "MMR" "Запуск ShowMMR.exe для: %steam_user%"
    echo   Рекомендуется заранее создать кеш .auth для %steam_user% рядом с инструментом.
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
    call :log "ERROR" "MMR" "vcfg не был создан"
    echo  [X] File %VCFG_NAME% не был создан. Проверьте showmmr_tool_out.txt
    pause
    goto :menu
)

:: Copy в game\dota\cfg
call :log "INFO" "MMR" "Копирование vcfg в game\dota\cfg"
if not exist "!DOTA_PATH!\dota\cfg" mkdir "!DOTA_PATH!\dota\cfg" 2>nul
copy /Y "%USERKEYS_DIR%\%VCFG_NAME%" "!DOTA_PATH!\dota\cfg\%VCFG_NAME%" >nul 2>&1
if errorlevel 1 (
    call :log "ERROR" "MMR" "Не удалось скопировать vcfg (Dota запущена? Закройте Dota)"
    echo  [X] Не удалось скопировать. Закройте Dota 2 и попробуйте снова.
    pause
    goto :menu
)
call :log "SUCCESS" "MMR" "MMR обновлен: %VCFG_NAME%"
echo  [OK] MMR обновлен.
echo   Перезапустите Dota 2.
pause
goto :menu

:: ============================================
:: BUILD VPK FROM SOURCE (Section 4.3c)
:: ============================================
:build_vpk
call :clear_screen
call :log "INFO" "BUILD" "=== Сборка VPK из исходников ==="

if not exist "%SRC_DIR%" (
    call :log "ERROR" "BUILD" "папка source не найдена"
    echo  [X] папка source не найдена next to the script.
    pause
    goto :menu
)

if not exist "%BUILD_BAT%" (
    call :log "ERROR" "BUILD" "build_vpk.bat не найден"
    echo  [X] build_vpk.bat не найден.
    echo   Рабочий VPK уже в %~dp0pak02_dir.vpk ^(single folder^) - no build needed.
    echo   Если нужно пересобрать, используйте Dota Workshop Tools или поместите VPK вручную.
    echo  [X] build_vpk.bat не найден ^(the VPK build script^).
    echo   You need build_vpk.bat from the project ^(resourcecompiler + vpk^).
    echo   Или поместите готовый pak02_dir.vpk рядом со скриптом.
    pause
    goto :menu
)

call :log "INFO" "BUILD" "Запуск build_vpk.bat"
echo   Сборка VPK из исходников...
call "%BUILD_BAT%"
call :log "INFO" "BUILD" "Сборка завершена (код: !ERRORLEVEL!)"

if exist "%~dp0pak02_dir.vpk" (
    call :log "SUCCESS" "BUILD" "pak02_dir.vpk собран"
    echo  [OK] VPK собран: %~dp0pak02_dir.vpk
) else (
    call :log "WARN" "BUILD" "pak02_dir.vpk не был создан - проверьте build_vpk.bat"
    echo  [!] pak02_dir.vpk не найден после сборки.
)
pause
goto :menu

:: ============================================
:: VIEW LOGS (Section 4.7)
:: ============================================
:view_logs
call :clear_screen
call :log "INFO" "LOG" "Просмотр логов"
if not exist "%LOG_FILE%" (
    echo  [X] Файл лога не найден.
    pause
    goto :menu
)
echo.
echo  --- Просмотр логов (%LOG_FILE%) ---
echo.
echo  1. Последние 20 строк
echo  2. Все ошибки
echo  3. Все предупреждения
echo  4. Очистить лог
echo  5. Назад
echo.
set /p "LOG_CHOICE=Выберите: "

if "%LOG_CHOICE%"=="1" (
    echo.
    echo  === Последние 20 строк ===
    powershell -NoProfile -Command "Get-Content -Tail 20 '%LOG_FILE%'"
)
if "%LOG_CHOICE%"=="2" (
    echo.
    echo  === Все ошибки ===
    findstr /C:"[ERROR]" "%LOG_FILE%"
)
if "%LOG_CHOICE%"=="3" (
    echo.
    echo  === Все предупреждения ===
    findstr /C:"[WARN]" "%LOG_FILE%"
)
if "%LOG_CHOICE%"=="4" (
    set /p "CONFIRM=Очистить лог? (Y/N): "
    if /i "%CONFIRM%"=="Y" (
        echo. > "%LOG_FILE%"
        call :log "INFO" "LOG" "Лог очищен"
        echo  [OK] Лог очищен
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
call :log "INFO" "DIAG" "=== Запуск диагностики ==="
call :find_dota
echo.
echo  === ShowMMR v2 Диагностика ===
echo.

echo  [1/8] Проверка лога...
if exist "%LOG_FILE%" (
    call :log "SUCCESS" "DIAG" "Лог найден"
    echo   [OK] Лог найден
) else (
    call :log "WARN" "DIAG" "Лог не найден"
    echo   [!] Лог не найден
)

echo  [2/8] Проверка Steam...
reg query "HKEY_CURRENT_USER\Software\Valve\Steam" /v SteamPath >nul 2>&1
if not errorlevel 1 (
    call :log "SUCCESS" "DIAG" "Steam найден"
    echo   [OK] Steam найден
) else (
    call :log "ERROR" "DIAG" "Steam не найден"
    echo   [X] Steam не найден
)

echo  [3/8] Проверка Dota 2...
if defined DOTA_PATH (
    call :log "SUCCESS" "DIAG" "Dota 2: !DOTA_PATH!"
    echo   [OK] Dota 2: !DOTA_PATH!
) else (
    call :log "ERROR" "DIAG" "Dota 2 не найдена"
    echo   [X] Dota 2 не найдена
)

echo  [4/8] Проверка установленного VPK...
if exist "!DOTA_PATH!\dota_mods\pak02_dir.vpk" (
    call :log "SUCCESS" "DIAG" "pak02_dir.vpk установлен"
    echo   [OK] pak02_dir.vpk установлен
) else (
    call :log "ERROR" "DIAG" "pak02_dir.vpk НЕ установлен"
    echo   [X] pak02_dir.vpk НЕ установлен
)

echo  [5/8] Проверка user_keys...
if exist "%USERKEYS_DIR%" (
    call :log "SUCCESS" "DIAG" "user_keys найден"
    echo   [OK] user_keys найден
) else (
    call :log "ERROR" "DIAG" "user_keys не найден"
    echo   [X] user_keys не найден
)

echo  [6/8] Проверка прав администратора...
net session >nul 2>&1
if not errorlevel 1 (
    call :log "SUCCESS" "DIAG" "Права администратора"
    echo   [OK] Права администратора
) else (
    call :log "WARN" "DIAG" "Нет прав администратора"
    echo   [!] Нет прав администратора
)

echo  [7/8] Проверка свободного места...
call :get_free_mb "!DOTA_PATH:~0,2!"
if %FREE_MB% GTR 100 (
    call :log "SUCCESS" "DIAG" "Свободно: %FREE_MB% MB"
    echo   [OK] Свободно: %FREE_MB% MB
) else (
    call :log "ERROR" "DIAG" "Мало свободного места: %FREE_MB% MB"
    echo   [X] Мало свободного места: %FREE_MB% MB
)

echo  [8/8] Проверка файлов...
call :verify_files

echo.
echo  === Диагностика complete ===
call :log "SUCCESS" "DIAG" "Диагностика complete"
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
    call :log "WARN" "DEPS" "Не удалось определить свободное место (PowerShell недоступен?), пропуск"
    set "FREE_MB=999999"
) else (
    set "FREE_MB=%_PSFREE%"
)
goto :eof

:: ============================================
:: GLOBAL ERROR HANDLER (Section 6.3)
:: ============================================
:error
call :log "ERROR" "GLOBAL" "Произошла ошибка (код: %ERRORLEVEL%)"
echo.
echo  [X] Произошла ошибка.
echo   Проверьте лог: %LOG_FILE%
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
call :log "INFO" "EXIT" "Программа завершена"
exit /b 0