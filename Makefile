# tools
AS=tools/zmac
EMU=open tools/Fuse.app
BUILD_DIR=build

# type of ZX to emulate
ZX?=48 # 48K by default

# targets
ASMS+=screen_timing.asm
ASMS+=screen_timing.128k.asm
ASMS+=interrupt_mode2.asm
ASMS+=raster.asm
ASMS+=checkers.asm checkers_hscroll.asm

ASMS+=ay200hz.asm

ASMS+=vscroll.asm
ASMS+=clear.asm
ASMS+=screen.asm

ASMS+=zebra.asm
ASMS+=colors.asm
ASMS+=colors2.asm

TAPES=$(patsubst %.asm,%.tap,$(ASMS))
BUILD_TAPES=$(TAPES:%=$(BUILD_DIR)/%)

# rules
.PHONY: all clean
all: $(BUILD_TAPES)

clean:
	@rm -f $(BUILD_TAPES)
	@rmdir build

# compile asm to tape
$(BUILD_DIR)/%.tap: %.asm
	mkdir -p $(dir $@)
	$(AS) $< -o $@

# run tape with emu
$(BUILD_DIR)/%: $(BUILD_DIR)/%.tap
	$(EMU) $< --args --machine $(if $(findstring .128,$<),128,$(ZX)) --no-confirm-actions

