FILES := display.s timer.s main.s
DEBUG_ROM := ./debug_rom.txt
ROM := ./rom.bin
VASM := $(HOME)/.local/bin/vasm6502_oldstyle
DEBUG_FLAGS := -Ftest -dotdir -wdc02 -opt-branch -quiet -o $(TEST_ROM)
BUILD_FLAGS := -Fbin -dotdir -wdc02 -opt-branch -quiet -o $(ROM)

.PHONY: all
all:
	@for file in $(FILES) ; do \
		printf "Assembling %s... " $$file ; \
		$(VASM) $(BUILD_FLAGS) $$file ; \
		printf "done\n" ; \
	done

.PHONY: debug
debug:
	@for file in $(FILES) ; do \
		printf "Assembling %s... " $$file ; \
		$(VASM) $(DEBUG_FLAGS) $$file ; \
		printf "done\n" ; \
	done

.PHONY: clean
clean:
	-rm -f $(ROM) $(TEST_ROM)

