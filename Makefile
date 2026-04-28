# ============================================================================
# Makefile — Tower Defense Arena
# Cross-compile x86-64 MASM assembly on Linux using UASM + MinGW-w64
# ============================================================================

ASM      = uasm
ASMFLAGS = -win64 -Zp8 -I.
CC       = x86_64-w64-mingw32-gcc
LDFLAGS  = -nostdlib -lkernel32 -luser32 -Wl,--subsystem,console

SRCDIR   = src
OBJDIR   = obj
TARGET   = tower_defense.exe

# Source files
SRCS     = $(SRCDIR)/data.asm \
           $(SRCDIR)/score.asm \
           $(SRCDIR)/enemies.asm \
           $(SRCDIR)/towers.asm \
           $(SRCDIR)/collision.asm \
           $(SRCDIR)/renderer.asm \
           $(SRCDIR)/input.asm \
           $(SRCDIR)/game_loop.asm \
           $(SRCDIR)/main.asm

# Object files
OBJS     = $(OBJDIR)/data.obj \
           $(OBJDIR)/score.obj \
           $(OBJDIR)/enemies.obj \
           $(OBJDIR)/towers.obj \
           $(OBJDIR)/collision.obj \
           $(OBJDIR)/renderer.obj \
           $(OBJDIR)/input.obj \
           $(OBJDIR)/game_loop.obj \
           $(OBJDIR)/main.obj

# ============================================================================
# Targets
# ============================================================================

.PHONY: all clean run

all: $(OBJDIR) $(TARGET)

$(OBJDIR):
	mkdir -p $(OBJDIR)

$(TARGET): $(OBJS)
	$(CC) -o $@ $^ $(LDFLAGS)
	@echo "=== Build complete: $(TARGET) ==="

# Pattern rule: assemble each .asm -> .obj
$(OBJDIR)/%.obj: $(SRCDIR)/%.asm
	$(ASM) $(ASMFLAGS) -Fo$(OBJDIR)/$*.obj $<

# ============================================================================
# Run via Wine
# ============================================================================
run: $(TARGET)
	wine $(TARGET)

# ============================================================================
# Clean
# ============================================================================
clean:
	rm -rf $(OBJDIR) $(TARGET)
	@echo "=== Cleaned ==="
