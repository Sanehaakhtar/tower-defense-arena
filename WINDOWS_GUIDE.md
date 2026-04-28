# Tower Defense Arena — Windows Setup & Build Guide

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installing UASM (MASM-compatible Assembler)](#installing-uasm)
3. [Installing Visual Studio Build Tools (Linker)](#installing-visual-studio-build-tools)
4. [Setting Up PATH](#setting-up-path)
5. [Building the Project](#building-the-project)
6. [Running the Game](#running-the-game)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

- **Windows 10 or later** (x64)
- **winget** (Windows Package Manager) — comes pre-installed on Windows 10 1809+ / Windows 11
- **UASM** — MASM-compatible assembler for x86-64
- **Microsoft MSVC Linker** (`link.exe`) from Visual Studio Build Tools

---

## Installing UASM

### Option A: Using winget (Recommended)

Open **PowerShell** or **Command Prompt** as Administrator:

```powershell
winget install AsmProject.UASM
```

This installs UASM to a directory like:
```
C:\Program Files\UASM\
```

Verify installation:
```cmd
uasm64 -?
```

### Option B: Manual Download

1. Go to: https://github.com/AsmProject/UASM/releases
2. Download the latest Windows x64 release (e.g., `uasm257_x64.zip`)
3. Extract to `C:\Tools\UASM\`
4. Add `C:\Tools\UASM\` to your system PATH (see [Setting Up PATH](#setting-up-path))

---

## Installing Visual Studio Build Tools

The MSVC linker (`link.exe`) is needed to link object files into a Windows executable.

### Option A: Using winget

```powershell
winget install Microsoft.VisualStudio.2022.BuildTools
```

During installation, select the **"Desktop development with C++"** workload.

### Option B: Manual Download

1. Go to: https://visualstudio.microsoft.com/downloads/
2. Scroll down to **"Tools for Visual Studio"**
3. Download **"Build Tools for Visual Studio 2022"**
4. Run installer, select **"Desktop development with C++"**

After installation, the linker is at:
```
C:\Program Files\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\<version>\bin\Hostx64\x64\link.exe
```

---

## Setting Up PATH

### Finding UASM Path

After installing UASM, find its location:
```cmd
where uasm64
```
If not found, check:
- `C:\Program Files\UASM\`
- `C:\Users\<you>\AppData\Local\Programs\UASM\`

### Finding MSVC Linker Path

Open **"x64 Native Tools Command Prompt for VS 2022"** from the Start Menu — this automatically sets up all MSVC paths.

Alternatively, find link.exe manually:
```cmd
dir /s "C:\Program Files\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\*link.exe"
```

### Adding to System PATH

1. Press `Win + R`, type `sysdm.cpl`, press Enter
2. Go to **Advanced** tab → **Environment Variables**
3. Under **System variables**, find **Path**, click **Edit**
4. Click **New** and add the UASM directory:
   ```
   C:\Program Files\UASM
   ```
5. Click **New** and add the MSVC tools directory (the one containing `link.exe`):
   ```
   C:\Program Files\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\14.xx.xxxxx\bin\Hostx64\x64
   ```
6. Click **OK** on all dialogs
7. Close and reopen any command prompts

### Verify PATH Setup

Open a **new** command prompt and run:
```cmd
uasm64 -?
link /?
```

Both should produce help output (not "command not found").

---

## Building the Project

### Method 1: Using the Batch File (Easiest)

Simply double-click `build.bat` or run from command prompt:

```cmd
cd path\to\tower-defense-arena
build.bat
```

The batch file will:
1. Check that UASM and the linker are available
2. Assemble all `.asm` source files
3. Link into `tower_defense.exe`
4. Run the game automatically

### Method 2: Using Visual Studio Developer Command Prompt

1. Open **"x64 Native Tools Command Prompt for VS 2022"** from the Start Menu
2. Navigate to the project:
   ```cmd
   cd path\to\tower-defense-arena
   ```
3. Assemble each file:
   ```cmd
   mkdir obj
   uasm64 -win64 -Zp8 -I. -Foobj\data.obj src\data.asm
   uasm64 -win64 -Zp8 -I. -Foobj\score.obj src\score.asm
   uasm64 -win64 -Zp8 -I. -Foobj\enemies.obj src\enemies.asm
   uasm64 -win64 -Zp8 -I. -Foobj\towers.obj src\towers.asm
   uasm64 -win64 -Zp8 -I. -Foobj\collision.obj src\collision.asm
   uasm64 -win64 -Zp8 -I. -Foobj\renderer.obj src\renderer.asm
   uasm64 -win64 -Zp8 -I. -Foobj\input.obj src\input.asm
   uasm64 -win64 -Zp8 -I. -Foobj\game_loop.obj src\game_loop.asm
   uasm64 -win64 -Zp8 -I. -Foobj\main.obj src\main.asm
   ```
4. Link:
   ```cmd
   link /NODEFAULTLIB /SUBSYSTEM:CONSOLE /ENTRY:mainCRTStartup /OUT:tower_defense.exe obj\*.obj kernel32.lib
   ```

---

## Running the Game

```cmd
tower_defense.exe
```

### Controls

| Key          | Action                     |
|--------------|----------------------------|
| Arrow keys   | Move placement cursor      |
| 1            | Select Basic Tower ($20)   |
| 2            | Select Sniper Tower ($40)  |
| 3            | Select Splash Tower ($30)  |
| Space        | Place tower at cursor      |
| Enter        | Start game / Next wave     |
| Q            | Quit                       |

### Game Rules

- Enemies follow a winding path from **S** (spawn) to **B** (base)
- Place towers on empty tiles to shoot enemies as they pass
- Each enemy that reaches the base costs 1 life
- Killing enemies earns gold and score
- Survive all 5 waves to win!

### Tower Types

| Tower   | Char | Cost | Range | Damage | Cooldown |
|---------|------|------|-------|--------|----------|
| Basic   | T    | $20  | 3     | 10     | 5 ticks  |
| Sniper  | R    | $40  | 6     | 25     | 10 ticks |
| Splash  | X    | $30  | 4     | 15     | 8 ticks  |

---

## Troubleshooting

### "uasm64 is not recognized as an internal or external command"

UASM is not in your PATH. See [Setting Up PATH](#setting-up-path).

### "link is not recognized"

Open the **x64 Native Tools Command Prompt** instead of regular cmd, or add the MSVC bin directory to PATH.

### "unresolved external symbol" errors during linking

Make sure you're linking with `kernel32.lib`:
```cmd
link /NODEFAULTLIB /SUBSYSTEM:CONSOLE /ENTRY:mainCRTStartup /OUT:tower_defense.exe obj\*.obj kernel32.lib
```

### "winget is not recognized"

Update Windows to the latest version, or install App Installer from the [Microsoft Store](https://www.microsoft.com/p/app-installer/9nblggh4nns1).

### Build works but game shows garbled/no output

- Ensure you're running in a standard Windows Console (`cmd.exe`), not PowerShell ISE
- Try: Right-click title bar → Properties → Font → Consolas or Lucida Console
- Resize the console window to at least 60 columns × 25 rows

### Cross-Compilation from Linux

On Arch Linux / Kali, the project uses `uasm` and `x86_64-w64-mingw32-gcc`:
```bash
# Install dependencies (Arch)
sudo pacman -S mingw-w64-gcc wine uasm

# Build
make

# Run via Wine
make run

# Full test suite
./run_and_test.sh
```

---

## Project Structure

```
src/
├── defs.inc          ; Shared constants, equates, extern declarations (header)
├── data.asm          ; All global structs, variables, strings
├── main.asm          ; Entry point — calls init, then game loop
├── game_loop.asm     ; Main loop, wave timing, game state machine
├── enemies.asm       ; Enemy spawn, movement, path logic
├── towers.asm        ; Tower placement, attack, cooldown
├── collision.asm     ; Hit detection between towers and enemies
├── renderer.asm      ; All display output — Windows Console API calls
├── input.asm         ; Keyboard input via ReadConsoleInput
└── score.asm         ; Score tracking
```

### File Ownership

| File            | Owner              |
|-----------------|--------------------|
| game_loop.asm   | Khadija (502430)   |
| enemies.asm     | Khadija (502430)   |
| score.asm       | Khadija (502430)   |
| towers.asm      | Saneha (517085)    |
| collision.asm   | Saneha (517085)    |
| renderer.asm    | Saneha (517085)    |
| input.asm       | Saneha (517085)    |
