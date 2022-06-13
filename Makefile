# tools
AS=~/speccy/zmac
EMU=open ~/speccy/Fuse.emu/Fuse.app

# targets
TAPES=clear.tap screen.tap vscroll.tap colors.tap colors2.tap

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
	$(EMU) $^
