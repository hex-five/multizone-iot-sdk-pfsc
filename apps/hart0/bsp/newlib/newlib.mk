# Copyright(C) 2020 Hex Five Security, Inc. - All Rights Reserved

.PHONY: all
all: $(TARGET)

ASM_SRCS += $(NEWLIB_DIR)/crt0.S
C_SRCS   += $(NEWLIB_DIR)/newlib.c

INCLUDES += -I$(BSP_DIR)

ASM_OBJS = $(abspath $(ASM_SRCS:.S=.o))
C_OBJS   = $(abspath $(C_SRCS:.c=.o))

CFLAGS += -march=rv64imac -mabi=lp64
CFLAGS += -mcmodel=medany -msmall-data-limit=8
CFLAGS += -ffunction-sections -fdata-sections
CFLAGS += -Wall -Wextra -Wstrict-prototypes -Wbad-function-cast
CFLAGS += -Wno-maybe-uninitialized -Wno-parentheses -Wno-unused-function -Wno-unused-parameter -Wno-unused-variable -Wno-unused-but-set-variable # -Wno-array-bounds

CFLAGS += -DBOOT_MODE=$(BOOT_MODE)

ifeq ($(BOOT_MODE),0)
    CFLAGS += -Og -g3
else ifeq ($(BOOT_MODE),1)
    CFLAGS += -Os -flto -msave-restore
endif

LDFLAGS += -T $(BSP_DIR)/memory.ld
LDFLAGS += -T $(LINKER_SCRIPT)
LDFLAGS += --specs=nano.specs --specs=nosys.specs -nostartfiles
LDFLAGS += -Xlinker --gc-sections
LDFLAGS += -Wl,-Map,$(MAP) -Wl,--cref

LINK_OBJS = $(ASM_OBJS) $(C_OBJS)
LINK_DEPS = $(LINKER_SCRIPT)

HEX := $(subst .elf,.hex,$(TARGET))
BIN := $(subst .elf,.bin,$(TARGET))
LST := $(subst .elf,.lst,$(TARGET))
MAP := $(subst .elf,.map,$(TARGET))
SIZ := $(subst .elf,.siz,$(TARGET))

$(TARGET): $(LINK_OBJS) $(LINK_DEPS)
	$(info LD $(subst $(TOP_DIR)/,,$(abspath $@)))
	@$(CC) $(CFLAGS) $(LINK_OBJS) -o $@ $(LDFLAGS)
	@$(OBJCOPY) -S -O ihex $(TARGET) $(HEX)
	@$(OBJCOPY) -S -O binary $(TARGET) $(BIN)	
	@$(OBJDUMP) --all-headers --demangle --disassemble --file-headers --wide -D $(TARGET) > $(LST)
	@$(SIZE) --format=sysv $(TARGET) > $(SIZ)

$(ASM_OBJS): %.o: %.S $(HEADERS)
	$(info CC $(subst $(TOP_DIR)/,,$<))
	@$(CC) $(CFLAGS) $(INCLUDES) -c -o $@ $<

$(C_OBJS): %.o: %.c $(HEADERS)
	$(info CC $(subst $(TOP_DIR)/,,$<))
	@$(CC) $(CFLAGS) $(INCLUDES) -c -o $@ $<

.PHONY: clean
clean:
	rm -rf $(TARGET) $(LINK_OBJS) $(HEX) $(BIN) $(LST) $(MAP) $(SIZ)
