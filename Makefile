# Copyright(C) 2021 Hex Five Security, Inc. - All Rights Reserved

#############################################################
# Platform definitions
#############################################################

export RISCV_ARCH := rv64imac
export RISCV_ABI  := lp64

#############################################################
# Toolchain definitions
#############################################################

ifndef RISCV
   $(error RISCV not set)
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
# Rules for building the firmware image
#############################################################

.PHONY: all
all: clean

	$(MAKE) -C apps/hart1
	$(MAKE) -C apps/hart2
	$(MAKE) -C apps/hart3
	$(MAKE) -C apps/hart4

	$(MAKE) -C apps/hart0/boot
#	$(MAKE) -C apps/hart0/zone1
	$(MAKE) -C apps/hart0/zone2
	$(MAKE) -C apps/hart0/zone3
	$(MAKE) -C apps/hart0/zone4

	@java -jar ext/multizone/multizone.jar \
		--arch PFSC-LIM \
		--config apps/hart0/bsp/multizone.cfg \
		--boot apps/hart0/boot/boot.hex \
		--output firmware.hex \
		apps/hart0/zone1/zone1.hex \
		apps/hart0/zone2/zone2.hex \
		apps/hart0/zone3/zone3.hex \
		apps/hart0/zone4/zone4.hex \

#	srec_cat -o firmware.hex -I \
#				firmware.hex -I \
#				apps/hart1/hart1.hex -I \
#				apps/hart2/hart2.hex -I \
#				apps/hart3/hart3.hex -I \
#				apps/hart4/hart4.hex -I \

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

	rm -rf multizone.* firmware.* bootmode* 

#############################################################
# Load to LIM (debug - boot mode 0)
#############################################################

ifndef OPENOCD
   $(error OPENOCD not set)
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

.PHONY: load-ram
load-ram:
	$(OPENOCD_BIN) $(OPENOCDARGS) & \
	$(GDB) firmware.hex $(GDB_LOAD_ARGS) $(GDB_LOAD_CMDS)

#############################################################
# Load to eNVM (production - boot mode 1)
#############################################################

ifndef FPGENPROG
   $(error FPGENPROG not set)
endif

ifndef SC_INSTALL_DIR
   $(error SC_INSTALL_DIR not set)
endif

MPFS_BOOT_MODE_PROG := $(abspath $(SC_INSTALL_DIR))/extras/mpfs/mpfsBootmodeProgrammer.jar

.PHONY: load-rom
load-rom:

    # Build loader
	@java -jar ext/multizone/multizone.jar \
	--arch PFSC-LIM \
	--load 0x20220100 \
	--config apps/hart0/bsp/multizone.cfg \
	--boot apps/hart0/boot/boot.hex \
	--output firmware.hex \
	apps/hart0/zone1/zone1.hex \
	apps/hart0/zone2/zone2.hex \
	apps/hart0/zone3/zone3.hex \
	apps/hart0/zone4/zone4.hex \

    # Convert firmware.hex to firmware.elf as required by mpfsBootmodeProgrammer.jar
	@$(OBJCOPY) -S -I ihex -O binary firmware.hex firmware.bin
	@$(LD) -b binary -r -o firmware.tmp firmware.bin
	@$(OBJCOPY) --rename-section .data=.text --set-section-flags .data=alloc,code,load firmware.tmp
	@$(LD) firmware.tmp -T apps/hart0/bsp/hex2elf.ld -o firmware.elf
	@$(STRIP) -s firmware.elf

    # Invoke flash programmer
	@java -jar $(MPFS_BOOT_MODE_PROG) --bootmode 1 --die MPFS250T_ES --package FCVG484 firmware.elf
	@rm -rf bootmode1 firmware.tmp firmware.bin
