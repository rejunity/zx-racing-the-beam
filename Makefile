# tools
AS=tools/zmac
EMU=open tools/Fuse.app

# type of ZX to emulate
ZX?=48 # 48K by default

# targets
TAPES+=clear.tap
TAPES+=screen.tap
TAPES+=vscroll.tap
TAPES+=checkers.tap checkers_hscroll.tap
TAPES+=interrupt_mode2.tap
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
