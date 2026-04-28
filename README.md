# Tower Defense Arena
### x86-64 Assembly — Windows Console Game

```
  ████████╗ ██████╗ ██╗    ██╗███████╗██████╗
     ██╔══╝██╔═══██╗██║    ██║██╔════╝██╔══██╗
     ██║   ██║   ██║██║ █╗ ██║█████╗  ██████╔╝
     ██║   ██║   ██║██║███╗██║██╔══╝  ██╔══██╗
     ██║   ╚██████╔╝╚███╔███╔╝███████╗██║  ██║
     ╚═╝    ╚═════╝  ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝
  ██████╗ ███████╗███████╗███████╗███╗   ██╗███████╗███████╗
  ██╔══██╗██╔════╝██╔════╝██╔════╝████╗  ██║██╔════╝██╔════╝
  ██║  ██║█████╗  █████╗  █████╗  ██╔██╗ ██║███████╗█████╗
  ██║  ██║██╔══╝  ██╔══╝  ██╔══╝  ██║╚██╗██║╚════██║██╔══╝
  ██████╔╝███████╗██║     ███████╗██║ ╚████║███████║███████╗
  ╚═════╝ ╚══════╝╚═╝     ╚══════╝╚═╝  ╚═══╝╚══════╝╚══════╝
                      ═══ A R E N A ═══
```

> **100% x86-64 Assembly.** No C. No runtime. Just registers, opcodes, and Windows.

---

## Table of Contents

1. [What is this?](#1-what-is-this)
2. [How to Play](#2-how-to-play)
3. [Windows Setup — Complete Beginner Guide](#3-windows-setup--complete-beginner-guide)
   - [Prerequisites Checklist](#prerequisites-checklist)
   - [Step 1 — Allow PowerShell Scripts](#step-1--allow-powershell-scripts)
   - [Step 2 — Run the Installer](#step-2--run-the-installer)
   - [Step 3 — Open the Build Console](#step-3--open-the-build-console)
   - [Step 4 — Build the Game](#step-4--build-the-game)
   - [Step 5 — Play!](#step-5--play)
4. [Manual Installation (Advanced)](#4-manual-installation-advanced)
5. [Project Structure](#5-project-structure)
6. [Linux / Cross-Compile Build](#6-linux--cross-compile-build)
7. [Developer Notes — Owners & Modules](#7-developer-notes--owners--modules)
8. [Troubleshooting](#8-troubleshooting)
9. [Glossary for Beginners](#9-glossary-for-beginners)

---

## 1. What is this?

Tower Defense Arena is a **classic tower defense game** written entirely in
**x86-64 MASM assembly language** — one of the lowest-level programming
languages you can write on modern hardware.

- Enemies march down a winding path toward your base
- You place towers that automatically attack nearby enemies
- Survive all 5 waves to win

The game runs as a standard **Windows console application** — no graphics
engine, no game framework, just raw Windows API calls drawn character by
character on your terminal.

```
  Wave: 2    Score: 350    Gold: 65    Lives: 18
  ┌──────────────────────────────────────────────────────────┐
  │  ....  ######.......................................  ..  │
  │  ....  #.............................................  .  │
  │  >> >> #.....[T].........[T]..............[T]......  ..  │
  │  ....  #.............................................  .  │
  │  ....  #########.............................########  .  │
  │  ....  .........# 
         >>>                #........................  ..  │
  └──────────────────────────────────────────────────────────┘
  Arrows:Move  1/2/3:Tower  SPACE:Place  Q:Quit
  [1]Basic $20   [2]Sniper $40   [3]Splash $30
```

---

## 2. How to Play

| Key | Action |
|-----|--------|
| `Arrow Keys` | Move the placement cursor around the map |
| `1` | Select Basic Tower ($20, short range, fast fire) |
| `2` | Select Sniper Tower ($40, long range, high damage) |
| `3` | Select Splash Tower ($30, medium range, area damage) |
| `Space` | Place the selected tower at the cursor position |
| `Enter` | Start the game (from menu) / Start next wave |
| `Q` | Quit the game |

**Tip:** Towers can only be placed on empty tiles (not on the path).
You earn gold by killing enemies. Spend it wisely!

---

## 3. Windows Setup — Complete Beginner Guide

> **If you've never done anything like this before — follow every step.**
> Each step has exactly what to click and type.

### Prerequisites Checklist

Before you start, make sure you have:

- [ ] Windows 10 version 1903 or later (or Windows 11)
- [ ] Internet connection (for downloading ~1.5 GB of tools)
- [ ] ~4 GB of free disk space
- [ ] About 20–30 minutes of time

To check your Windows version: press `Win + R`, type `winver`, press Enter.

---

### Step 1 — Allow PowerShell Scripts

Windows blocks PowerShell scripts by default as a security measure.
You need to **temporarily allow** the installer to run.

**Option A — Safest (allows just this one script, nothing else):**

1. Press `Win + X` on your keyboard
2. Click **"Windows PowerShell (Admin)"** or **"Terminal (Admin)"**
3. If asked "Do you want to allow this app to make changes?" — click **Yes**
4. In the blue/black window that opens, paste this command and press Enter:

```
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

5. Type `Y` and press Enter when prompted
6. You can now close this window

> **What does this do?**
> It allows scripts that you downloaded *and personally agreed to run*
> to execute. It does NOT allow random scripts from the internet to run
> automatically. You can always reverse this with:
> `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Restricted`

**Option B — Run the script without changing any settings (even simpler):**

Skip step 1 entirely — in Step 2 below, use the special bypass command instead
of double-clicking. We'll show you exactly what to type.

---

### Step 2 — Run the Installer

The installer script (`install_masm.ps1`) will:
- Download and install **Visual Studio 2022 Build Tools** (~1.5 GB)
  *(This is Microsoft's free toolkit — it includes `ml64.exe`, which is MASM)*
- Find where `ml64.exe` was installed
- Add it to your PATH so you can use it anywhere
- Create `dev_env.bat` — a shortcut that opens a pre-configured build console

**How to run the installer:**

1. Open **File Explorer** and navigate to this project's folder
2. In the address bar at the top, click and type `powershell` then press Enter
   *(This opens PowerShell already in the right folder)*

3. Paste this command and press Enter:

```powershell
powershell -ExecutionPolicy Bypass -File install_masm.ps1
```

> A window might pop up showing the Visual Studio installer making progress.
> This is normal. **Do not close it.** Wait until the PowerShell window says
> "Installation Complete!"

4. When installation is done you will see:

```
  =============================================================
   Installation Complete!
  =============================================================

  OPTION A (easiest):
    Double-click  dev_env.bat  in this folder.
    Then type:    nmake /f Makefile.win
```

> **Already have Visual Studio 2022 installed?**
> Run: `powershell -ExecutionPolicy Bypass -File install_masm.ps1 -SkipInstall`

---

### Step 3 — Open the Build Console

You need a special command prompt that knows where MASM is.
You have two choices — **pick the one that feels easier:**

**Easy way — use dev_env.bat:**

1. In the project folder, **double-click** `dev_env.bat`
2. A black command prompt window opens showing:

```
  =============================================================
   Tower Defense Arena | x64 MASM Build Environment
  =============================================================

   Build:   nmake /f Makefile.win
   Run:     nmake /f Makefile.win run
   Clean:   nmake /f Makefile.win clean
```

3. You are now ready to build!

**Alternative way — use the Start Menu:**

1. Press the `Windows` key
2. Search for: `x64 Native Tools Command Prompt for VS 2022`
3. Click it to open
4. Navigate to your project folder:
   ```
   cd C:\path\to\coal-proj
   ```
   *(Replace `C:\path\to\coal-proj` with the actual path to this folder)*

---

### Step 4 — Build the Game

Inside the build console from Step 3, type exactly this and press Enter:

```
nmake /f Makefile.win
```

You should see output like this:

```
ml64 /nologo /c /Cx /W3 /I. /Foobj\data.obj src\data.asm
ml64 /nologo /c /Cx /W3 /I. /Foobj\score.obj src\score.asm
ml64 /nologo /c /Cx /W3 /I. /Foobj\enemies.obj src\enemies.asm
ml64 /nologo /c /Cx /W3 /I. /Foobj\towers.obj src\towers.asm
ml64 /nologo /c /Cx /W3 /I. /Foobj\collision.obj src\collision.asm
ml64 /nologo /c /Cx /W3 /I. /Foobj\renderer.obj src\renderer.asm
ml64 /nologo /c /Cx /W3 /I. /Foobj\input.obj src\input.asm
ml64 /nologo /c /Cx /W3 /I. /Foobj\game_loop.obj src\game_loop.asm
ml64 /nologo /c /Cx /W3 /I. /Foobj\main.obj src\main.asm
link /nologo /SUBSYSTEM:CONSOLE /ENTRY:mainCRTStartup /NODEFAULTLIB ...

 === Build complete: tower_defense.exe ===
```

If you see `=== Build complete: tower_defense.exe ===` — **you're done!**

> **Got errors?** See the [Troubleshooting](#8-troubleshooting) section below.

---

### Step 5 — Play!

Either:
- Type `nmake /f Makefile.win run` and press Enter

Or:
- Double-click `tower_defense.exe` in File Explorer
- Or type `tower_defense.exe` in the build console

**On the main menu, press `Enter` to start your first wave. Good luck!**

---

## 4. Manual Installation (Advanced)

If you prefer to install manually without the PowerShell script:

### 4a. Install Visual Studio 2022 Build Tools via winget

Open PowerShell or Command Prompt and run:

```powershell
winget install --id Microsoft.VisualStudio.2022.BuildTools `
    --override "--quiet --norestart --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.Windows11SDK.22000"
```

### 4b. Install via the Visual Studio Installer (GUI)

1. Go to: https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022
2. Click **"Free download"** under *Build Tools for Visual Studio 2022*
3. Run the downloaded installer
4. In the installer, check **"C++ build tools"** workload
5. Make sure these components are also checked:
   - MSVC v143 — VS 2022 C++ x64/x86 build tools
   - Windows 11 SDK (or Windows 10 SDK)
6. Click **Install**

### 4c. Find ml64.exe and add to PATH

After installing, `ml64.exe` is at a path like:

```
C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\
  VC\Tools\MSVC\14.XX.XXXXX\bin\HostX64\x64\ml64.exe
```

*(The `14.XX.XXXXX` part depends on the installed version)*

To add to PATH permanently:
1. Press `Win + R`, type `sysdm.cpl`, press Enter
2. Click **Advanced** tab → **Environment Variables**
3. Under *User variables*, click **PATH** → **Edit**
4. Click **New** and paste the full path (up to but not including `\ml64.exe`)
5. Click OK, OK, OK

### 4d. Verify

Open a new Command Prompt and run:
```
ml64 /?
nmake /?
```

Both should print a help message without errors.

---

## 5. Project Structure

```
coal-proj/
│
├── src/                        ← All assembly source files
│   ├── defs.inc                  Constants, struct offsets, extern declarations
│   │                             (included by every .asm file)
│   │
│   ├── data.asm                  Global variables and strings (all shared data)
│   ├── main.asm                  Entry point — calls init functions, runs game loop
│   │
│   ├── game_loop.asm             Wave timing, game state machine, main update
│   ├── enemies.asm               Enemy spawning, movement, path following
│   ├── score.asm                 Score tracking
│   │
│   ├── towers.asm                Tower placement, stat lookup, attack cooldowns
│   ├── collision.asm             Tower-vs-enemy hit detection and damage
│   ├── renderer.asm              All screen drawing via Windows Console API
│   └── input.asm                 Keyboard input via ReadConsoleInputA
│
├── obj/                        ← Compiled object files (created by make/nmake)
│
├── Makefile                    ← Linux build (UASM + MinGW-w64, tested with Wine)
├── Makefile.win                ← Windows build (MASM ml64 + link.exe, nmake)
│
├── install_masm.ps1            ← Auto-install MASM on Windows (run this first!)
├── dev_env.bat                 ← Opens a pre-configured MASM build console
├── build.bat                   ← Simple one-click build script
│
├── run_and_test.sh             ← Linux: build and test under Wine
├── WINDOWS_GUIDE.md            ← Detailed Windows setup reference
└── README.md                   ← This file
```

### How the modules connect

```
main.asm
  └─ calls ─► game_loop_init / game_loop_update
                  ├─► enemies_spawn / enemies_update
                  ├─► towers_update
                  ├─► collision_update ──► score_add
                  └─► input_poll ──────► towers_place

renderer_draw  (called from main loop, reads all shared data from data.asm)
```

All shared variables (enemy array, tower array, player gold/lives, etc.)
live in `data.asm`. Every other module declares `extrn` references to them
via `defs.inc`.

---

## 6. Linux / Cross-Compile Build

If you are developing on Linux and want to build a Windows `.exe` to test
with Wine:

### Requirements

```bash
# Arch Linux
sudo pacman -S uasm mingw-w64-gcc wine

# Ubuntu / Debian
sudo apt install mingw-w64 wine
# UASM: download from https://github.com/Terraspace/UASM/releases
```

### Build

```bash
make          # Build tower_defense.exe
make run      # Build and run under Wine
make clean    # Delete obj/ and tower_defense.exe
```

### Why two assemblers?

| Assembler | Used for | Notes |
|-----------|----------|-------|
| `uasm` (UASM) | Linux build | Free, cross-platform, MASM-compatible superset |
| `ml64` (MASM) | Windows build | Microsoft's official assembler, ships with VS |

The source code is compatible with both. The only difference was
`option win64:11` (a UASM extension) which has been removed.

---

## 7. Developer Notes — Owners & Modules

| Module | File | Owner |
|--------|------|-------|
| Entry point | `main.asm` | Shared |
| Shared data | `data.asm` | Shared |
| Definitions | `defs.inc` | Shared |
| Game loop & waves | `game_loop.asm` | Khadija (502430) |
| Enemy AI & pathing | `enemies.asm` | Khadija (502430) |
| Score system | `score.asm` | Khadija (502430) |
| Tower logic | `towers.asm` | Saneha (517085) |
| Collision/damage | `collision.asm` | Saneha (517085) |
| Renderer | `renderer.asm` | Saneha (517085) |
| Input handling | `input.asm` | Saneha (517085) |

### Windows API calls used

| API Function | Purpose |
|---|---|
| `GetStdHandle` | Get `STDOUT` / `STDIN` handle |
| `SetConsoleTitleA` | Set window title bar text |
| `SetConsoleCursorPosition` | Move cursor before writing text |
| `WriteConsoleA` | Write text to the screen |
| `SetConsoleCursorInfo` | Hide the blinking cursor |
| `ReadConsoleInputA` | Read keyboard events |
| `GetNumberOfConsoleInputEvents` | Non-blocking input check |
| `GetConsoleMode` / `SetConsoleMode` | Configure raw key input |
| `Sleep` | Delay between frames (frame rate control) |
| `ExitProcess` | Clean exit |
| `FillConsoleOutputCharacterA` | Clear the screen |
| `SetConsoleTextAttribute` | Change text colour |

### x64 Calling Convention (Windows)

All function calls follow the **Microsoft x64 ABI**:

```
Parameter 1  →  RCX
Parameter 2  →  RDX
Parameter 3  →  R8
Parameter 4  →  R9
Parameter 5+ →  stack (above the 32-byte shadow space)

Return value →  RAX

Caller saves: RAX, RCX, RDX, R8, R9, R10, R11
Callee saves: RBX, RBP, RDI, RSI, R12, R13, R14, R15
Stack:        must be 16-byte aligned BEFORE the call instruction
              (so RSP mod 16 == 8 just inside any function)
Shadow space: 32 bytes ABOVE the return address must be
              reserved by the caller for the callee's use
```

Every procedure in this project allocates stack manually with `sub rsp, N`
and restores it with `add rsp, N` before `ret`.

---

## 8. Troubleshooting

### "nmake is not recognized as an internal or external command"

You are in a regular Command Prompt, not the MASM build environment.

**Fix:** Double-click `dev_env.bat`, or open
*"x64 Native Tools Command Prompt for VS 2022"* from the Start Menu.

---

### "ml64 : error A2008: syntax error: option"

You may have an older version of this file that still contains `option win64:11`.
MASM's `ml64.exe` does not support this UASM extension.

**Fix:**
```
nmake /f Makefile.win clean
```
Then check that every `.asm` file does **not** contain `option win64:11`.
The current source files have already had this line removed.

---

### "LINK : fatal error LNK1561: entry point must be defined"

The linker cannot find `mainCRTStartup`.

**Fix:** Make sure `src\main.asm` compiled correctly. Run:
```
ml64 /nologo /c /Cx /I. /Foobj\main.obj src\main.asm
```
and check for errors.

---

### "LINK : fatal error LNK1104: cannot open file 'kernel32.lib'"

The Windows SDK was not installed (or not selected) during VS Build Tools setup.

**Fix options:**
- Re-run `install_masm.ps1` (it will install the missing components)
- Or manually install: open *Visual Studio Installer*, click **Modify** on
  *Build Tools 2022*, and ensure **Windows 11 SDK** is checked

---

### "winget is not recognized"

winget ships with *App Installer* from the Microsoft Store.

**Fix:** Open the Microsoft Store, search for **"App Installer"**, and
click **Update** (or Install). Then re-open your terminal.

---

### "This script cannot be run because running scripts is disabled"

PowerShell execution policy is blocking the installer.

**Fix:**
```powershell
powershell -ExecutionPolicy Bypass -File install_masm.ps1
```
This runs just this script without changing your system settings.

---

### The game window closes immediately

The game may have crashed.

**Fix:** Run it from inside the build console (not by double-clicking the .exe)
so you can see any error output:
```
tower_defense.exe
```

---

### I made changes to a .asm file and the game didn't change

The old `.obj` file is still being used.

**Fix:**
```
nmake /f Makefile.win rebuild
```
This forces a full clean rebuild.

---

## 9. Glossary for Beginners

| Term | What it means in plain English |
|------|-------------------------------|
| **Assembly language** | A very low-level programming language where you write instructions that the CPU executes directly, like `mov eax, 5` (put the number 5 into the register named EAX) |
| **MASM** | *Microsoft Macro Assembler* — Microsoft's official tool that converts assembly source code into a runnable file |
| **ml64.exe** | The actual program that does the assembly for 64-bit code (the name "ML64" stands for Macro assembler for 64-bit) |
| **UASM** | *Universal Assembler* — an open-source alternative to MASM used on Linux. Compatible with the same assembly syntax |
| **nmake** | *NMake* — Microsoft's version of the Unix `make` tool. It reads `Makefile.win` and runs the right commands in the right order |
| **linker / link.exe** | A program that takes the compiled pieces (`.obj` files) and joins them into one final `.exe` file |
| **.obj file** | An intermediate compiled file — not runnable yet, but ready to be linked |
| **.asm file** | An assembly source code file — human-readable text that MASM converts to machine code |
| **.inc file** | An include file — like a header in C, it holds shared definitions included by all `.asm` files |
| **x86-64** | The CPU architecture used by almost all Windows PCs (also called AMD64 or x64) |
| **Register** | An extremely fast, tiny storage location inside the CPU (e.g. RAX, RBX, RCX…) |
| **Windows API** | A set of functions provided by Windows that programs can call to do things like print text, read keyboard input, and exit |
| **kernel32.dll** | A core Windows DLL containing fundamental system functions. Our game only uses this. |
| **PE64** | *Portable Executable 64-bit* — the file format of a Windows `.exe` |
| **Calling convention** | An agreed-upon set of rules about how functions pass arguments and return values. On Windows x64, first argument goes in RCX, second in RDX, etc. |
| **Shadow space** | 32 bytes that the *caller* must allocate on the stack before calling any Windows API function. The callee can use this space to (optionally) save the register arguments it received. |
| **Wine** | A compatibility layer that lets you run Windows `.exe` files on Linux. Used here for testing without a real Windows machine |
| **PATH** | A list of directories that Windows searches when you type a command in the terminal. Adding `ml64.exe`'s folder to PATH means you can type `ml64` anywhere |

---

<div align="center">

Built with 💻 + assembly opcodes

*Khadija (502430) · Saneha (517085)*

</div>


Set-Location "d:\downloads\coal-proj-4cutie\coal-proj"
cmd /c "call ""C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build\vcvars64.bat"" & nmake /f Makefile.win"
.\tower_defense.exe