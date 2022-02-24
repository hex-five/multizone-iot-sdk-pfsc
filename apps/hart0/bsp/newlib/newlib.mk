# Copyright(C) 2020 Hex Five Security, Inc. - All Rights Reserved

.PHONY: all
all: $(TARGET)

ASM_SRCS += $(NEWLIB_DIR)/crt0.S
C_SRCS   += $(NEWLIB_DIR)/newlib.c

INCLUDES += -I$(BSP_DIR)

LDFLAGS += -T $(BSP_DIR)/memory.ld
LDFLAGS += -T $(LINKER_SCRIPT)
LDFLAGS += --specs=nano.specs
LDFLAGS += --specs=nosys.specs
LDFLAGS += -nostartfiles
LDFLAGS += -Xlinker --gc-sections
LDFLAGS += -Wl,-Map,$(MAP) -Wl,--cref

ASM_OBJS := $(ASM_SRCS:.S=.o)
C_OBJS := $(C_SRCS:.c=.o)

LINK_OBJS += $(ASM_OBJS) $(C_OBJS)
LINK_DEPS += $(LINKER_SCRIPT)

CLEAN_OBJS += $(TARGET) $(LINK_OBJS)

CFLAGS += -march=rv64imac -mabi=lp64
CFLAGS += -mcmodel=medany
CFLAGS += -msmall-data-limit=8
CFLAGS += -ffunction-sections -fdata-sections
CFLAGS += -Wall -Wextra
CFLAGS += -Wno-unused-parameter -Wno-unused-variable -Wno-unused-function -Wno-unused-but-set-variable -Wno-array-bounds
CFLAGS += -Og -g # MCHP Bug: anything but -O0 => GDB msg "The riscv_frame_cache's start_addr is ..."
#CFLAGS += -Os -g

HEX = $(subst .elf,.hex,$(TARGET))
BIN = $(subst .elf,.bin,$(TARGET))
LST = $(subst .elf,.lst,$(TARGET))
MAP = $(subst .elf,.map,$(TARGET))
SIZ = $(subst .elf,.siz,$(TARGET))

$(TARGET): $(LINK_OBJS) $(LINK_DEPS)
	$(CC) $(CFLAGS) $(INCLUDES) $(LINK_OBJS) -o $@ $(LDFLAGS)
	$(OBJCOPY) -O ihex $(TARGET) $(HEX)
	$(OBJCOPY) -S -O binary $(TARGET) $(BIN)	
	$(OBJDUMP) --all-headers --demangle --disassemble --file-headers --wide -D $(TARGET) > $(LST)
	$(SIZE) --format=sysv $(TARGET) > $(SIZ)

$(ASM_OBJS): %.o: %.S $(HEADERS)
	$(CC) $(CFLAGS) $(INCLUDES) -c -o $@ $<

$(C_OBJS): %.o: %.c $(HEADERS)
	$(CC) $(CFLAGS) $(INCLUDES) -c -o $@ $<

.PHONY: clean
clean:
	rm -rf $(TARGET) $(LINK_OBJS) $(HEX) $(BIN) $(LST) $(MAP) $(SIZ)
