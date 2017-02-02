#MAKEFLAGS += --no-builtin-rules

# This variable can be overwritten to show executed commands
Q ?= @

# Default output path. This is used when output (writable) directory is different
# than project directory. You shouldn't be setting it by hand, but it is used in
# external Makefiles.
O ?= .

# Load configuration
-include $(O)/.config.mk

.PHONY: all
all: $(O)/turris-lcd

ifeq ($(DEBUG),yes)
CFLAGS += -ggdb -DDEBUG
endif
CFLAGS += -Isrc/liblcd

# Apply CPREFIX
CXX:=$(CPREFIX)$(CXX)

### Source files list ###########################
SRC = turris-lcd.cpp \
	  liblcd/I2CIO.cpp \
	  liblcd/LCD.cpp \
	  liblcd/LiquidCrystal.cpp \
	  liblcd/LiquidCrystal_I2C.cpp \
	  liblcd/smbus.c
### End of source files list ####################

CPPSRC = $(patsubst %,src/%,$(filter %.cpp,$(SRC)))
CSRC = $(patsubst %,src/%,$(filter %.c,$(SRC)))

CPPOBJ = $(patsubst src/%.cpp,$(O)/build/%.o,$(CPPSRC))
COBJ = $(patsubst src/%.c,$(O)/build/%.o,$(CSRC))

.PHONY: help
help:
	@echo "General extendable macro language make targets:"
	@echo " turris-lcd  - Build geml executable"
	@echo " help        - Prints this text help."
	@echo " clean       - Cleans builded files"
	@echo " prune       - Same as clean but also removes configuration."
	@echo "Some enviroment variables to be defined:"
	@echo " Q             - Define emty to show executed commands"

# Cleaning
.PHONY: clean
clean::
	@echo " CLEAN build"
	$(Q)$(RM) -r $(O)/build
	$(Q)$(RM) $(O)/.config.mk
	@echo " CLEAN turris-lcd"
	$(Q)$(RM) $(O)/turris-lcd
.PHONY: prune
prune:: clean
	@echo " CLEAN configuration"
	$(Q)$(RM) $(O)/.config $(O)/.config.mk 

## Building targets ##
ifeq (,$(filter clean prune help \
	  ,$(MAKECMDGOALS))) # Ignore build targets if goal is not building

$(O)/turris-lcd: $(COBJ) $(CPPOBJ)
	@echo " LD    $@"
	$(Q)$(CXX) $(LDFLAGS) $^ -o $@

# We use CXX intensionally even on C files
$(COBJ): $(O)/build/%.o: src/%.c
	@mkdir -p "$(@D)"
	@echo " CXX   $@"
	$(Q)$(CXX) -c $(CFLAGS) $< -o $@

$(CPPOBJ): $(O)/build/%.o: src/%.cpp
	@mkdir -p "$(@D)"
	@echo " CXX   $@"
	$(Q)$(CXX) -c $(CFLAGS) $< -o $@
endif

## Configuation files ##
$(O)/.config:
	$(error Please run configure script first)

$(O)/.config.mk: $(O)/.config
	@echo " CONF  $@"
	$(Q)$(O)/configure --op-makefile > $@
