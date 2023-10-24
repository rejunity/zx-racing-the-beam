# tools
AS=tools/zmac
EMU=open tools/Fuse.app

# type of ZX to emulate
ZX?=48 # 48K by default

# targets
TAPES+=screen_timing.tap
TAPES+=interrupt_mode2.tap
TAPES+=raster.tap
TAPES+=checkers.tap checkers_hscroll.tap

TAPES+=vscroll.tap
TAPES+=clear.tap
TAPES+=screen.tap

TAPES+=zebra.tap
TAPES+=colors.tap
TAPES+=colors2.tap

# rules
.PHONY: all clean
all: $(TAPES)

clean:
	rm -f $(TAPES)

# compile asm to tape
%.tap: %.asm
	$(AS) $< -o $@

# run tape with emu
%: %.tap
	$(EMU) $^ --args --machine $(ZX) --no-confirm-actions
