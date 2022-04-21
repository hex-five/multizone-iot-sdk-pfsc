# Copyright(C) 2021 Hex Five Security, Inc. - All Rights Reserved

#############################################################
# Build profiles
# - BOOT_MODE = 0 : Debug (load with OpenOCD/GDB)
# - BOOT_MODE = 1 : Production (load from eNVM)
#############################################################

BOOT_MODE ?= 0

ifeq ($(filter $(BOOT_MODE), 0 1), $(BOOT_MODE))
    export BOOT_MODE
else
    $(error Invalid boot mode $(BOOT_MODE).)
endif

#############################################################
# Toolchain definitions
#############################################################

ifndef RISCV
   $(error RISCV not set.)
endif

export CROSS_COMPILE := $(abspath $(RISCV))/bin/riscv64-unknown-elf-
export CC      := $(CROSS_COMPILE)gcc
export OBJDUMP := $(CROSS_COMPILE)objdump
export OBJCOPY := $(CROSS_COMPILE)objcopy
export GDB     := $(CROSS_COMPILE)gdb
export AR      := $(CROSS_COMPILE)ar
export LD      := $(CROSS_COMPILE)ld
export STRIP   := $(CROSS_COMPILE)strip
export SIZE    := $(CROSS_COMPILE)size

#############################################################
# Build binaries
#############################################################

.PHONY: all
all: 

ifeq ($(BOOT_MODE),0) 

	$(MAKE) -C ext/icicle-kit-es

	$(MAKE) -B -C apps/hart0/boot
#	$(MAKE) -B -C apps/hart0/zone1
	$(MAKE) -B -C apps/hart0/zone2
	$(MAKE)    -C apps/hart0/zone3
	$(MAKE)    -C apps/hart0/zone4

	$(MAKE) -B -C apps/hart1
	$(MAKE)    -C apps/hart2
	$(MAKE)    -C apps/hart3
	$(MAKE)    -C apps/hart4

	@java -jar ext/multizone/multizone.jar \
		--arch PFSC-LIM \
		--config apps/hart0/bsp/multizone.cfg \
		--boot apps/hart0/boot/boot.hex \
		--output firmware.hex \
		apps/hart0/zone1/zone1.hex \
		apps/hart0/zone2/zone2.hex \
		apps/hart0/zone3/zone3.hex \
		apps/hart0/zone4/zone4.hex \

else ifeq ($(BOOT_MODE),1)

	$(MAKE) -C ext/icicle-kit-es
	$(MAKE) -B -C apps/hart0/boot
#	$(MAKE) -B -C apps/hart0/zone1
	$(MAKE) -B -C apps/hart0/zone2
	$(MAKE)    -C apps/hart0/zone3
	$(MAKE)    -C apps/hart0/zone4

	$(MAKE) -B -C apps/hart1
	$(MAKE)    -C apps/hart2
	$(MAKE)    -C apps/hart3
	$(MAKE)    -C apps/hart4

	@java -jar ext/multizone/multizone.jar \
	--arch PFSC-LIM \
	--config apps/hart0/bsp/multizone.cfg \
	--boot apps/hart0/boot/boot.hex \
	--output firmware.hex \
	--load 0x20220100 \
	apps/hart0/zone1/zone1.hex \

endif

#############################################################
# Load to memory
#############################################################

ifeq ($(BOOT_MODE),0)

    ifndef OPENOCD
       $(error OPENOCD not set.)
    endif

    OPENOCD_BIN := $(abspath $(OPENOCD))/bin/openocd

    OPENOCDARGS += --command 'set DEVICE MPFS'
    OPENOCDARGS += --file '$(abspath $(OPENOCD))/share/openocd/scripts/board/microsemi-riscv.cfg'

    GDB_PORT ?= 3333
    GDB_LOAD_ARGS ?= -batch    
    GDB_LOAD_CMDS += -ex 'target extended-remote localhost:$(GDB_PORT)'
    GDB_LOAD_CMDS += -ex 'monitor reset init'
    GDB_LOAD_CMDS += -ex 'load'
    GDB_LOAD_CMDS += -ex 'thread apply all set $$pc=0x08000000'
    GDB_LOAD_CMDS += -ex 'monitor resume'
    GDB_LOAD_CMDS += -ex 'monitor shutdown'
    GDB_LOAD_CMDS += -ex 'quit'

    .PHONY: load
    load:
		$(OPENOCD_BIN) $(OPENOCDARGS) & \
		$(GDB) firmware.hex $(GDB_LOAD_ARGS) $(GDB_LOAD_CMDS)

else ifeq ($(BOOT_MODE),1)

    ifndef FPGENPROG
       $(error FPGENPROG not set)
    endif

    ifndef SC_INSTALL_DIR
       $(error SC_INSTALL_DIR not set)
    endif

    MPFS_BOOT_MODE_PROG := $(abspath $(SC_INSTALL_DIR))/extras/mpfs/mpfsBootmodeProgrammer.jar

    .PHONY: load
    load:

		# Convert firmware.hex to firmware.elf as required by mpfsBootmodeProgrammer.jar
		@$(OBJCOPY) -S -I ihex -O binary firmware.hex firmware.bin
		@$(LD) -b binary -r -o firmware.tmp firmware.bin
		@$(OBJCOPY) --rename-section .data=.text --set-section-flags .data=alloc,code,load firmware.tmp
		@$(LD) firmware.tmp -T apps/hart0/bsp/hex2elf.ld -o firmware.elf
		@$(STRIP) -s firmware.elf

		# Invoke flash programmer
		@java -jar $(MPFS_BOOT_MODE_PROG) --bootmode 1 --die MPFS250T_ES --package FCVG484 firmware.elf
		@rm -rf bootmode1 firmware.tmp firmware.bin

endif

#############################################################
# Clean
#############################################################	

.PHONY: clean
clean: 
	$(MAKE) -C apps/hart1 clean
	$(MAKE) -C apps/hart2 clean
	$(MAKE) -C apps/hart3 clean
	$(MAKE) -C apps/hart4 clean

	$(MAKE) -C apps/hart0/boot clean
#	$(MAKE) -C apps/hart0/zone1 clean
	$(MAKE) -C apps/hart0/zone2 clean
	$(MAKE) -C apps/hart0/zone3 clean
	$(MAKE) -C apps/hart0/zone4 clean

	$(MAKE) -C ext/icicle-kit-es clean

	rm -rf multizone.* firmware.* bootmode* 	
