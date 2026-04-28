@echo off
REM dev_env.bat ? Opens an x64 MASM build console for Tower Defense Arena
REM Double-click this file to start building.

if not exist "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" (
    echo ERROR: vcvars64.bat not found. Please re-run install_masm.ps1
    pause
    exit /b 1
)

call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"

echo.
echo  =============================================================
echo   Tower Defense Arena ^| x64 MASM Build Environment
echo  =============================================================
echo.
echo   Build:   nmake /f Makefile.win
echo   Run:     nmake /f Makefile.win run
echo   Clean:   nmake /f Makefile.win clean
echo.
echo   Or just run:  tower_defense.exe
echo.

cd /d "%~dp0"
cmd /k
