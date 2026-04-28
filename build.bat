@echo off
REM ============================================================================
REM build.bat — Build and run Tower Defense Arena on Windows
REM Requires: UASM (uasm64.exe) and a linker (link.exe from MSVC or GoLink)
REM ============================================================================

setlocal enabledelayedexpansion

echo ============================================
echo  Tower Defense Arena — Windows Build Script
echo ============================================
echo.

REM ============================================================================
REM Configuration — adjust paths if needed
REM ============================================================================
set ASM=uasm64
set ASMFLAGS=-win64 -Zp8 -I.
set LINKER=link
set OBJDIR=obj
set TARGET=tower_defense.exe

REM ============================================================================
REM Check tools
REM ============================================================================
echo [1/4] Checking tools...

where %ASM% >nul 2>&1
if errorlevel 1 (
    echo [ERROR] %ASM% not found in PATH.
    echo Install UASM via: winget install AsmProject.UASM
    echo Then add its install directory to your PATH.
    echo See WINDOWS_GUIDE.md for details.
    goto :error
)
echo   [OK] %ASM% found

where %LINKER% >nul 2>&1
if errorlevel 1 (
    echo [WARN] %LINKER% not found. Trying ml64 as fallback...
    set LINKER=ml64
    where !LINKER! >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] No linker found. Install Visual Studio Build Tools.
        echo See WINDOWS_GUIDE.md for details.
        goto :error
    )
)
echo   [OK] %LINKER% found
echo.

REM ============================================================================
REM Create output directory
REM ============================================================================
echo [2/4] Preparing build directory...
if not exist %OBJDIR% mkdir %OBJDIR%
echo   [OK] %OBJDIR%\ ready
echo.

REM ============================================================================
REM Assemble all source files
REM ============================================================================
echo [3/4] Assembling source files...

set OBJS=
for %%f in (data score enemies towers collision renderer input game_loop main) do (
    echo   Assembling src\%%f.asm ...
    %ASM% %ASMFLAGS% -Fo%OBJDIR%\%%f.obj src\%%f.asm
    if errorlevel 1 (
        echo [ERROR] Failed to assemble %%f.asm
        goto :error
    )
    set OBJS=!OBJS! %OBJDIR%\%%f.obj
)
echo   [OK] All source files assembled
echo.

REM ============================================================================
REM Link
REM ============================================================================
echo [4/4] Linking...

%LINKER% /NODEFAULTLIB /SUBSYSTEM:CONSOLE /ENTRY:mainCRTStartup /OUT:%TARGET% %OBJS% kernel32.lib
if errorlevel 1 (
    echo [ERROR] Linking failed
    goto :error
)

echo.
echo ============================================
echo  Build successful: %TARGET%
echo ============================================
echo.

REM ============================================================================
REM Run
REM ============================================================================
echo Starting game...
%TARGET%
goto :end

:error
echo.
echo ============================================
echo  BUILD FAILED
echo ============================================
exit /b 1

:end
endlocal
