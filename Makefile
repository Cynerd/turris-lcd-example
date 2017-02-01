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
CFLAGS += -Wall
CFLAGS += -Iliblcd -include $(O)/build/config.h

# Apply CPREFIX
CXX:=$(CPREFIX)$(CXX)

### Source files list ###########################
SRC = turris-lcd.cpp
### End of source files list ####################

CSRC = $(patsubst %,src/%,$(filter %.cpp,$(SRC)))

OBJ = $(patsubst src/%.cpp,$(O)/build/%.o,$(CSRC))
DEP = $(patsubst src/%.cpp,$(O)/build/%.d,$(CSRC))

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
	@echo " CLEAN liblcd"
	$(Q)$(MAKE) -C liblcd clean
	$(Q)$(RM) liblcd/libliquidcrystali2c.a

## Building targets ##
ifeq (,$(filter clean prune help \
	  ,$(MAKECMDGOALS))) # Ignore build targets if goal is not building

ifeq ($(DEBUG),yes)
-include $(DEP) # If developing, use dependencies from source files
.PHONY: dependency dep
dependency dep:: $(DEP)
$(DEP): $(O)/build/%.d: src/%.cpp
	@mkdir -p "$(@D)"
	@echo " DEP   $@"
	$(Q)$(CXX) -MM -MG -MT '$*.o $@' $(CFLAGS) $< -MF $@
endif # DEBUG

$(O)/turris-lcd: $(OBJ) liblcd/libliquidcrystali2c.a
	@echo " LD    $@"
	$(Q)$(CXX) $(LDFLAGS) $^ -o $@

$(OBJ): $(O)/build/%.o: src/%.cpp $(O)/build/config.h
	@mkdir -p "$(@D)"
	@echo " CXX   $@"
	$(Q)$(CXX) -c $(CFLAGS) $< -o $@

$(O)/build/config.h: $(O)/.config
	@mkdir -p "$(@D)"
	@echo " CONF  $@"
	$(Q)$(O)/configure --op-h > $@

liblcd/libliquidcrystali2c.a:
	$(Q)$(MAKE) -C liblcd static
endif

## Configuation files ##
$(O)/.config:
	$(error Please run configure script first)

$(O)/.config.mk: $(O)/.config
	@echo " CONF  $@"
	$(Q)$(O)/configure --op-makefile > $@
