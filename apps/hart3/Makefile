# Copyright(C) 2020 Hex Five Security, Inc. - All Rights Reserved

TARGET := hart3.elf

C_SRCS   := main.c
ASM_SRCS := mss_entry.S
LINKER_SCRIPT := linker.ld

TOP_DIR := $(abspath ../..)
EXT_DIR := $(TOP_DIR)/ext
PLATFORM_DIR      := $(EXT_DIR)/pfsc-platform
ICICLE_KIT_ES_DIR := $(EXT_DIR)/icicle-kit-es
MULTIZONE_DIR     := $(EXT_DIR)/multizone

CFLAGS += -DNDEBUG

INCLUDES += -I $(ICICLE_KIT_ES_DIR)
INCLUDES += -I $(ICICLE_KIT_ES_DIR)/platform_config
INCLUDES += -I $(PLATFORM_DIR)
INCLUDES += -I $(PLATFORM_DIR)/platform_config_reference
INCLUDES += -I $(MULTIZONE_DIR)

#C_SRCS += $(PLATFORM_DIR)/mpfs_hal/startup_gcc/system_startup.c
C_SRCS += $(PLATFORM_DIR)/mpfs_hal/startup_gcc/newlib_stubs.c
C_SRCS += $(PLATFORM_DIR)/mpfs_hal/common/mss_clint.c
C_SRCS += $(PLATFORM_DIR)/mpfs_hal/common/mss_irq_handler_stubs.c
C_SRCS += $(PLATFORM_DIR)/mpfs_hal/common/mss_mtrap.c
C_SRCS += $(PLATFORM_DIR)/mpfs_hal/common/mss_plic.c
C_SRCS += $(PLATFORM_DIR)/mpfs_hal/common/mss_pmp.c
C_SRCS += $(PLATFORM_DIR)/mpfs_hal/common/mss_util.c
C_SRCS += $(PLATFORM_DIR)/drivers/mss/mss_mmuart/mss_uart.c

CFLAGS += -march=rv64gc -mabi=lp64d # g = imafd
CFLAGS += -mcmodel=medany -msmall-data-limit=8
CFLAGS += -mstrict-align -mno-save-restore
CFLAGS += -ffunction-sections -fdata-sections -fsigned-char
CFLAGS += -Wall -Wextra -Wstrict-prototypes -Wbad-function-cast
CFLAGS += -Wno-unused-parameter #-Wno-maybe-uninitialized -Wno-unused-variable -Wno-unused-function -Wno-unused-but-set-variable #-Wno-array-bounds
CFLAGS += -O0 -g3 # MCHP Bug: anything but -O0 => GDB msg "The riscv_frame_cache's start_addr is ..."
#CFLAGS += -Os -flto -msave-restore

LDFLAGS += -T ../hart0/bsp/memory.ld
LDFLAGS += -T $(LINKER_SCRIPT)
LDFLAGS += --specs=nano.specs --specs=nosys.specs -nostartfiles
LDFLAGS += -Xlinker --gc-sections

# =================================================================================

.PHONY: all
all: $(TARGET)

ASM_OBJS := $(abspath $(ASM_SRCS:.S=.o))
C_OBJS   := $(abspath $(C_SRCS:.c=.o))

LINK_OBJS := $(ASM_OBJS) $(C_OBJS)
LINK_DEPS := $(LINKER_SCRIPT)

HEX := $(subst .elf,.hex,$(TARGET))
BIN := $(subst .elf,.bin,$(TARGET))
LST := $(subst .elf,.lst,$(TARGET))
MAP := $(subst .elf,.map,$(TARGET))
SIZ := $(subst .elf,.siz,$(TARGET))

$(TARGET): $(LINK_OBJS) $(LINK_DEPS)
	$(info LD $(subst $(TOP_DIR)/,,$(abspath $@)))
	@$(CC) $(CFLAGS) $(INCLUDES) $(LINK_OBJS) -o $@ $(LDFLAGS)
	@$(OBJCOPY) -S -O ihex $(TARGET) $(HEX)	
	@$(OBJCOPY) -S -O binary $(TARGET) $(BIN)	
	@$(OBJDUMP) --all-headers --demangle --disassemble --file-headers --wide -D $(TARGET) > $(LST)
	@$(SIZE) --format=sysv $(TARGET) > $(SIZ)

$(ASM_OBJS): %.o: %.S $(HEADERS) $(SOC_CONF_DIR)
	$(info CC $(subst $(TOP_DIR)/,,$<))
	@$(CC) $(CFLAGS) $(INCLUDES) -c -o $@ $<

$(C_OBJS): %.o: %.c $(HEADERS) $(SOC_CONF_DIR)
	$(info CC $(subst $(TOP_DIR)/,,$<))
	@$(CC) $(CFLAGS) $(INCLUDES) -c -o $@ $<


.PHONY: clean
clean:
	rm -rf $(TARGET) $(LINK_OBJS) $(HEX) $(BIN) $(LST) $(MAP) $(SIZ)
