#!/usr/bin/env bash
# ============================================================================
# run_and_test.sh — Build, verify, and run Tower Defense Arena
# Cross-compilation test script for Linux (using Wine)
# ============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0

pass() {
    echo -e "  ${GREEN}[PASS]${NC} $1"
    PASS=$((PASS + 1))
}

fail() {
    echo -e "  ${RED}[FAIL]${NC} $1"
    FAIL=$((FAIL + 1))
}

warn() {
    echo -e "  ${YELLOW}[WARN]${NC} $1"
}

echo "============================================"
echo " Tower Defense Arena — Build & Test Script"
echo "============================================"
echo ""

# ============================================================================
# 1. Check toolchain
# ============================================================================
echo "[1/6] Checking toolchain..."

if command -v uasm &>/dev/null; then
    pass "uasm found"
else
    fail "uasm not found — install UASM assembler"
fi

if command -v x86_64-w64-mingw32-gcc &>/dev/null; then
    pass "x86_64-w64-mingw32-gcc found: $(x86_64-w64-mingw32-gcc --version | head -1)"
else
    fail "MinGW-w64 GCC not found — install mingw-w64-gcc"
fi

if command -v wine &>/dev/null; then
    pass "wine found: $(wine --version 2>/dev/null || echo 'available')"
else
    warn "wine not found — cannot test run (build still possible)"
fi

if command -v make &>/dev/null; then
    pass "make found"
else
    fail "make not found"
fi

echo ""

# ============================================================================
# 2. Clean build
# ============================================================================
echo "[2/6] Clean build..."

make clean 2>/dev/null || true

if make 2>&1; then
    pass "Build completed"
else
    fail "Build failed"
    exit 1
fi

echo ""

# ============================================================================
# 3. Verify output
# ============================================================================
echo "[3/6] Verifying output..."

if [ -f "tower_defense.exe" ]; then
    pass "tower_defense.exe exists"
else
    fail "tower_defense.exe not found"
    exit 1
fi

FILE_INFO=$(file tower_defense.exe)
if echo "$FILE_INFO" | grep -q "PE32+"; then
    pass "Valid PE32+ (x86-64) executable"
else
    fail "Not a valid PE64 executable: $FILE_INFO"
fi

if echo "$FILE_INFO" | grep -q "console"; then
    pass "Subsystem: console"
else
    warn "Subsystem may not be console: $FILE_INFO"
fi

SIZE=$(stat -c%s tower_defense.exe 2>/dev/null || stat -f%z tower_defense.exe 2>/dev/null)
if [ "$SIZE" -gt 1000 ]; then
    pass "File size: ${SIZE} bytes (reasonable)"
else
    warn "File size is small: ${SIZE} bytes"
fi

echo ""

# ============================================================================
# 4. Check object files
# ============================================================================
echo "[4/6] Checking object files..."

EXPECTED_OBJS="data score enemies towers collision renderer input game_loop main"
for obj in $EXPECTED_OBJS; do
    if [ -f "obj/${obj}.obj" ]; then
        pass "obj/${obj}.obj exists"
    else
        fail "obj/${obj}.obj missing"
    fi
done

echo ""

# ============================================================================
# 5. Check source files
# ============================================================================
echo "[5/6] Verifying source file headers..."

check_owner() {
    local file="$1"
    local expected="$2"
    if grep -qi "$expected" "$file"; then
        pass "$file — owner: $expected"
    else
        fail "$file — missing owner '$expected'"
    fi
}

check_owner "src/game_loop.asm" "Khadija (502430)"
check_owner "src/enemies.asm"   "Khadija (502430)"
check_owner "src/score.asm"     "Khadija (502430)"
check_owner "src/towers.asm"    "Saneha (517085)"
check_owner "src/collision.asm" "Saneha (517085)"
check_owner "src/renderer.asm"  "Saneha (517085)"
check_owner "src/input.asm"     "Saneha (517085)"

echo ""

# ============================================================================
# 6. Symbol check (verify key exports exist)
# ============================================================================
echo "[6/6] Checking key symbols in executable..."

if command -v x86_64-w64-mingw32-nm &>/dev/null; then
    NM="x86_64-w64-mingw32-nm"
elif command -v x86_64-w64-mingw32-objdump &>/dev/null; then
    NM=""
else
    warn "No nm/objdump for symbol checking"
    NM=""
fi

if [ -n "$NM" ]; then
    SYMBOLS=$($NM tower_defense.exe 2>/dev/null || true)
    for sym in mainCRTStartup game_loop_init game_loop_update enemies_init enemies_spawn towers_init towers_place collision_update renderer_init renderer_draw input_init input_poll score_init score_add; do
        if echo "$SYMBOLS" | grep -q "$sym"; then
            pass "Symbol found: $sym"
        else
            fail "Symbol missing: $sym"
        fi
    done
else
    warn "Skipping symbol check (no nm available)"
fi

echo ""

# ============================================================================
# Summary
# ============================================================================
echo "============================================"
echo " Results:  ${GREEN}${PASS} passed${NC}  ${RED}${FAIL} failed${NC}"
echo "============================================"
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo -e "${RED}Some checks failed!${NC}"
    exit 1
fi

echo -e "${GREEN}All checks passed!${NC}"
echo ""

# ============================================================================
# Run with Wine (optional — pass --run flag)
# ============================================================================
if [ "$1" = "--run" ] && command -v wine &>/dev/null; then
    echo "Starting Tower Defense Arena via Wine..."
    wine tower_defense.exe
else
    echo "To run the game: wine tower_defense.exe"
    echo "Or: make run"
fi
