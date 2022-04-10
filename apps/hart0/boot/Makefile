# Copyright(C) 2020 Hex Five Security, Inc. - All Rights Reserved

TARGET := boot.elf

C_SRCS 	 := e51.c diskio.c
ASM_SRCS := mss_entry.S

LINKER_SCRIPT := linker.ld

TOP_DIR := $(abspath ../../../)
EXT_DIR := $(TOP_DIR)/ext
PLATFORM_DIR      := $(EXT_DIR)/pfsc-platform
ICICLE_KIT_ES_DIR := $(EXT_DIR)/icicle-kit-es
MULTIZONE_DIR     := $(EXT_DIR)/multizone
FATFS_SRC_DIR     := $(EXT_DIR)/fatfs/source

INCLUDES := -I.
INCLUDES += -I$(ICICLE_KIT_ES_DIR)
INCLUDES += -I$(ICICLE_KIT_ES_DIR)/platform_config
INCLUDES += -I$(PLATFORM_DIR)
INCLUDES += -I$(PLATFORM_DIR)/platform_config_reference
INCLUDES += -I$(MULTIZONE_DIR)
INCLUDES += -I$(FATFS_SRC_DIR)

C_SRCS  += $(FATFS_SRC_DIR)/ff.c
C_SRCS  += $(FATFS_SRC_DIR)/ffunicode.c

#ASM_SRCS+= $(PLATFORM_DIR)/mpfs_hal/startup_gcc/mss_entry.S
ASM_SRCS+= $(PLATFORM_DIR)/mpfs_hal/startup_gcc/mss_utils.S
C_SRCS  += $(PLATFORM_DIR)/mpfs_hal/startup_gcc/system_startup.c
C_SRCS  += $(PLATFORM_DIR)/mpfs_hal/startup_gcc/newlib_stubs.c
C_SRCS  += $(PLATFORM_DIR)/mpfs_hal/common/mss_clint.c
C_SRCS  += $(PLATFORM_DIR)/mpfs_hal/common/mss_irq_handler_stubs.c
C_SRCS  += $(PLATFORM_DIR)/mpfs_hal/common/mss_l2_cache.c
C_SRCS  += $(PLATFORM_DIR)/mpfs_hal/common/mss_mpu.c
C_SRCS  += $(PLATFORM_DIR)/mpfs_hal/common/mss_mtrap.c
C_SRCS  += $(PLATFORM_DIR)/mpfs_hal/common/mss_peripherals.c
C_SRCS  += $(PLATFORM_DIR)/mpfs_hal/common/mss_plic.c
C_SRCS  += $(PLATFORM_DIR)/mpfs_hal/common/mss_util.c
C_SRCS  += $(PLATFORM_DIR)/mpfs_hal/common/nwc/mss_ddr.c
C_SRCS  += $(PLATFORM_DIR)/mpfs_hal/common/nwc/mss_ddr_debug.c
C_SRCS  += $(PLATFORM_DIR)/mpfs_hal/common/nwc/mss_ddr_test_pattern.c
C_SRCS  += $(PLATFORM_DIR)/mpfs_hal/common/nwc/mss_io.c
C_SRCS  += $(PLATFORM_DIR)/mpfs_hal/common/nwc/mss_nwc_init.c
C_SRCS  += $(PLATFORM_DIR)/mpfs_hal/common/nwc/mss_pll.c
C_SRCS  += $(PLATFORM_DIR)/mpfs_hal/common/nwc/mss_sgmii.c
C_SRCS  += $(PLATFORM_DIR)/drivers/mss/mss_gpio/mss_gpio.c
C_SRCS  += $(PLATFORM_DIR)/drivers/mss/mss_mmc/mss_mmc.c
C_SRCS  += $(PLATFORM_DIR)/drivers/mss/mss_mmc/mss_mmc_if.c
C_SRCS  += $(PLATFORM_DIR)/drivers/mss/mss_mmuart/mss_uart.c
C_SRCS  += $(PLATFORM_DIR)/drivers/mss/mss_sys_services/mss_sys_services.c

CFLAGS := -DNDEBUG -DBOOT_MODE=$(BOOT_MODE)

CFLAGS += -march=rv64imac -mabi=lp64 # g = imafd
CFLAGS += -mcmodel=medany -msmall-data-limit=8
CFLAGS += -ffunction-sections -fdata-sections
CFLAGS += -Wall -Wextra -Wstrict-prototypes -Wbad-function-cast
CFLAGS += -Wno-unused-local-typedefs -Wno-parentheses -Wno-unused-parameter -Wno-maybe-uninitialized -Wno-unused-variable -Wno-unused-function -Wno-unused-but-set-variable
ifeq ($(BOOT_MODE),0)
    CFLAGS += -Og -g3
else ifeq ($(BOOT_MODE),1)
    CFLAGS += -Os -flto -msave-restore
endif

LDFLAGS := -T ../bsp/memory.ld -T $(LINKER_SCRIPT)
LDFLAGS += --specs=nano.specs --specs=nosys.specs -nostartfiles
LDFLAGS += -Xlinker --gc-sections

# =================================================================================

.PHONY: all
all: $(TARGET)

ASM_OBJS := $(ASM_SRCS:.S=.o)
C_OBJS   := $(C_SRCS:.c=.o)

LINK_OBJS := $(ASM_OBJS) $(C_OBJS)
LINK_DEPS := $(LINKER_SCRIPT)

HEX = $(subst .elf,.hex,$(TARGET))
BIN = $(subst .elf,.bin,$(TARGET))
LST = $(subst .elf,.lst,$(TARGET))
MAP = $(subst .elf,.map,$(TARGET))
SIZ = $(subst .elf,.siz,$(TARGET))

$(TARGET): $(LINK_OBJS) $(LINK_DEPS)
	$(info LD $(subst $(TOP_DIR)/,,$(abspath $@)))
	@$(CC) $(CFLAGS) $(LINK_OBJS) -o $@ $(LDFLAGS)
	@$(OBJCOPY) -O ihex $(TARGET) $(HEX)	
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
