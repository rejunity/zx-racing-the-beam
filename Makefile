# tools
AS=tools/zmac
EMU=open tools/Fuse.app

# type of ZX to emulate
ZX?=48 # 48K by default

# targets
TAPES=clear.tap screen.tap vscroll.tap checkers.tap checkers_hscroll.tap interrupt_mode2.tap colors.tap colors2.tap

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
	$(EMU) $^ --args --machine $(ZX)
