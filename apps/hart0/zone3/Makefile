# Copyright(C) 2020 Hex Five Security, Inc. - All Rights Reserved

TARGET := zone3.elf

C_SRCS := main.c

LINKER_SCRIPT := linker.ld

TOP_DIR := $(abspath ../../..)

INCLUDES := -I$(TOP_DIR)/ext/multizone

### BSP
BSP_DIR := ../bsp
NEWLIB_DIR := $(BSP_DIR)/newlib
include $(NEWLIB_DIR)/newlib.mk