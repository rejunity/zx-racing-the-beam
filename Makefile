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

%.tap: %.asm
	$(AS) $< -o $@


# build and run
clear: clear.tap
	$(EMU) $^

screen: screen.tap
	$(EMU) $^

vscroll: vscroll.tap
	$(EMU) $^

colors: colors.tap
	$(EMU) $^

colors2: colors2.tap
	$(EMU) $^
