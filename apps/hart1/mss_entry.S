/*******************************************************************************
 * See LICENSE for license details.
 * Modifications copyright (C) 2021 Hex Five Security, Inc.
 */

/*******************************************************************************
 * @file entry.S
 * @author Microchip-FPGA Embedded Systems Solutions
 * @brief entry functions.
 *
 */

#include "mpfs_hal/common/bits.h"
#include "mpfs_hal/common/encoding.h"
#include "mpfs_hal/common/mss_mtrap.h"
#include "mpfs_hal/startup_gcc/system_startup_defs.h"
#include "mpfs_hal_config/mss_sw_config.h"

  .globl _start

reset_vector:
_start:
    /*
     * clear the Return Address Stack
     */
    call .clear_ras
    li a1, 0x3
    csrw 0x7c0, a1

    /* Setup trap handler */
    la a4, trap_vector
    csrw mtvec, a4          # initalise machine trap vector address
    /* Make sure that mtvec is updated before continuing */
    1:
    csrr    a5, mtvec
    bne a4, a5, 1b

    /* Disable and clear all interrupts */
    li a2,  MSTATUS_MIE
    csrc mstatus, a2        # clear interrupt enable bit
    csrw mie, zero
    csrw mip, zero
    # Init delegation registers, mideleg, medeleg, if a U54
    # These are not initialised by the hardware and come up in a random state
    csrr a0, mhartid
    csrw mideleg, 0
    csrw medeleg, 0
    # mscratch must be init to zero- we are not using scratch memory
    csrw mscratch, zero
    csrw mcause, zero
    csrw mepc, zero
    /*
     * clear regs
     */
    li  x1, 0
    li  x2, 0
    li  x3, 0
    li  x4, 0
    li  x5, 0
    li  x6, 0
    li  x7, 0
    li  x8, 0
    li  x9, 0
    li  x10,0
    li  x11,0
    li  x12,0
    li  x13,0
    li  x14,0
    li  x15,0
    li  x16,0
    li  x17,0
    li  x18,0
    li  x19,0
    li  x20,0
    li  x21,0
    li  x22,0
    li  x23,0
    li  x24,0
    li  x25,0
    li  x26,0
    li  x27,0
    li  x28,0
    li  x29,0
    li  x30,0
    li  x31,0

    # enable FPU and accelerator if present, setting ignored on E51
    li t0, MSTATUS_FS | MSTATUS_XS
    csrs mstatus, t0

    # Init floating point control register to zero
    fscsr x0

     # make sure XLEN agrees with compilation choice, if not will loop here
.LxlenCheck:
    csrr t0, misa
#if __riscv_xlen == 64
    bltz t0, .LxlenPass
#else
    bgez t0, .LxlenPass
#endif
    j .LxlenCheck
.LxlenPass:

    # initialize global pointer, global data
    # The __global_pointer is allocated in the linker script. It points to a
    # location 2k after sdata start as the offsets used in the gp are +/- 2k
    # See https://www.sifive.com/blog/2017/08/28/all-aboard-part-3-linker-relaxation-in-riscv-toolchain/
    # see: http://www.rowleydownload.co.uk/arm/documentation/gnu/as/RISC_002dV_002dDirectives.html
    .option push
    .option norelax
    la gp, __global_pointer$
    .option pop

    # get core id
    csrr a0, mhartid
    li a1,  0
    beq a0, a1, .hart0
    li a1,  1
    beq a0, a1, .hart1
    li a1,  2
    beq a0, a1, .hart2
    li a1,  3
    beq a0, a1, .hart3
    li a1,  4
    beq a0, a1, .hart4

.hart0:
    la a4, __stack_bottom_h0$  # keep bottom of stack in a5 so we can init later
    la sp, __stack_top_h0$
    j .continue
.hart1:
    la a4, __stack_bottom_h1$  # keep bottom of stack in a5 so we can init later
    la sp, __stack_top_h1$
    j .continue
.hart2:
    la a4, __stack_bottom_h2$  # keep bottom of stack in a5 so we can init later
    la sp, __stack_top_h2$
    j .continue
.hart3:
    la a4, __stack_bottom_h3$  # keep bottom of stack in a5 so we can init later
    la sp, __stack_top_h3$
    j .continue
.hart4:
    la a4, __stack_bottom_h4$  # keep bottom of stack in a5 so we can init later
    la sp, __stack_top_h4$

.continue:

    # clear HLS and stack
    mv  a5, sp
.init_stack:
    #csrw mepc, zero
    STORE x0, 0(a4)
    add a4, a4, __SIZEOF_POINTER__
    blt a4, a5, .init_stack

    # clear the heap
    la  a4, __heap_start
    la  a5, __heap_end
.init_heap:
    #csrw mepc, zero
    STORE x0, 0(a4)
    add a4, a4, __SIZEOF_POINTER__
    blt a4, a5, .init_heap

    /* Load data section */
    la a0, __data_load
    la a1, __data_start
    la a2, __data_end
    bgeu a1, a2, 2f
1:
    ld t0, (a0); sd t0, (a1)
    addi a0, a0, 8
    addi a1, a1, 8
    bltu a1, a2, 1b
2:
    /* Load sdata section */
    la a0, __sdata_load
    la a1, __sdata_start
    la a2, __sdata_end
    bgeu a1, a2, 2f
1:
    ld t0, (a0); sd t0, (a1)
    addi a0, a0, 8
    addi a1, a1, 8
    bltu a1, a2, 1b
2:

    /* Clear bss section */
    la a0, __bss_start
    la a1, __bss_end
    bgeu a0, a1, 2f
1:
    sd zero, (a0)
    addi a0, a0, 8
    bltu a0, a1, 1b
2:

    /* Clear sbss section */
    la a0, __sbss_start
    la a1, __sbss_end
    bgeu a0, a1, 2f
1:
    sd zero, (a0)
    addi a0, a0, 8
    bltu a0, a1, 1b
2:

    /* Disable and clear all interrupts- should be only a sw interrupt */
    li a2,  MSTATUS_MIE
    csrc mstatus, a2        # clear interrupt enable bit
    csrw mie, zero
    csrw mip, zero

    call main

.LoopForeverOther:
    #in case of return, loop forever. nop's added so can be seen in debugger
    nop
    nop
    j .LoopForeverOther

/******************************************************************************/
/******************************interrupt handeling below here******************/
/******************************************************************************/
.align 2
trap_vector:
    # The mscratch register is an XLEN-bit read/write register dedicated for use by machine mode.
    # Typically, it is used to hold a pointer to a machine-mode hart-local context space and swapped
    # with a user register upon entry to an M-mode trap handler.
    # In this implementation, we are noty using HLS
    # csrrw sp, mscratch, sp                    #copy sp to mscratch, and mscrath to sp

    addi sp, sp, -INTEGER_CONTEXT_SIZE     # moves sp down stack to make I
                                           # INTEGER_CONTEXT_SIZE area
    # Preserve the registers.
    STORE sp, 2*REGBYTES(sp)               # sp
    STORE a0, 10*REGBYTES(sp)              # save a0,a1 in the created CONTEXT
    STORE a1, 11*REGBYTES(sp)
    STORE ra, 1*REGBYTES(sp)
    STORE gp, 3*REGBYTES(sp)
    STORE tp, 4*REGBYTES(sp)
    STORE t0, 5*REGBYTES(sp)
    STORE t1, 6*REGBYTES(sp)
    STORE t2, 7*REGBYTES(sp)
    STORE s0, 8*REGBYTES(sp)
    STORE s1, 9*REGBYTES(sp)
    STORE a2,12*REGBYTES(sp)
    STORE a3,13*REGBYTES(sp)
    STORE a4,14*REGBYTES(sp)
    STORE a5,15*REGBYTES(sp)
    STORE a6,16*REGBYTES(sp)
    STORE a7,17*REGBYTES(sp)
    STORE s2,18*REGBYTES(sp)
    STORE s3,19*REGBYTES(sp)
    STORE s4,20*REGBYTES(sp)
    STORE s5,21*REGBYTES(sp)
    STORE s6,22*REGBYTES(sp)
    STORE s7,23*REGBYTES(sp)
    STORE s8,24*REGBYTES(sp)
    STORE s9,25*REGBYTES(sp)
    STORE s10,26*REGBYTES(sp)
    STORE s11,27*REGBYTES(sp)
    STORE t3,28*REGBYTES(sp)
    STORE t4,29*REGBYTES(sp)
    STORE t5,30*REGBYTES(sp)
    STORE t6,31*REGBYTES(sp)
    # Invoke the handler.
    mv a0, sp                          # a0 <- regs
    # Please note: mtval is the newer name for register mbadaddr
    # If you get a compile failure here, use the newer name
    # At this point (2019), both are supported in latest compiler
    # older compiler versions only support mbadaddr, so going with this.
    # See: https://github.com/riscv/riscv-gcc/issues/133
    csrr a1, mbadaddr                 # useful for anaysis when things go wrong
    csrr a2, mepc
    jal trap_from_machine_mode

restore_regs:
    # Restore all of the registers.
    LOAD ra, 1*REGBYTES(sp)
    LOAD gp, 3*REGBYTES(sp)
    LOAD tp, 4*REGBYTES(sp)
    LOAD t0, 5*REGBYTES(sp)
    LOAD t1, 6*REGBYTES(sp)
    LOAD t2, 7*REGBYTES(sp)
    LOAD s0, 8*REGBYTES(sp)
    LOAD s1, 9*REGBYTES(sp)
    LOAD a0,10*REGBYTES(sp)
    LOAD a1,11*REGBYTES(sp)
    LOAD a2,12*REGBYTES(sp)
    LOAD a3,13*REGBYTES(sp)
    LOAD a4,14*REGBYTES(sp)
    LOAD a5,15*REGBYTES(sp)
    LOAD a6,16*REGBYTES(sp)
    LOAD a7,17*REGBYTES(sp)
    LOAD s2,18*REGBYTES(sp)
    LOAD s3,19*REGBYTES(sp)
    LOAD s4,20*REGBYTES(sp)
    LOAD s5,21*REGBYTES(sp)
    LOAD s6,22*REGBYTES(sp)
    LOAD s7,23*REGBYTES(sp)
    LOAD s8,24*REGBYTES(sp)
    LOAD s9,25*REGBYTES(sp)
    LOAD s10,26*REGBYTES(sp)
    LOAD s11,27*REGBYTES(sp)
    LOAD t3,28*REGBYTES(sp)
    LOAD t4,29*REGBYTES(sp)
    LOAD t5,30*REGBYTES(sp)
    LOAD t6,31*REGBYTES(sp)
    LOAD sp, 2*REGBYTES(sp)
    addi sp, sp, +INTEGER_CONTEXT_SIZE  # moves sp up stack to reclaim
                                        # INTEGER_CONTEXT_SIZE area
    mret

 /*****************************************************************************/
 /******************************interrupt handeling above here*****************/
 /*****************************************************************************/

.enable_sw_int:
    li a2, MIP_MSIP
    csrw mie, a2            # Set MSIE bit to receive IPI
    li a2,  MSTATUS_MIE
    csrs mstatus, a2        # enable interrupts
    /* flush the instruction cache */
    fence.i
    ret

 /***********************************************************************************
 *
 * The following init_memory() symbol overrides the weak symbol in the HAL and does
 * a safe copy of RW data and clears zero-init memory
 *
 */
    // zero_section helper function:
    //       a0 = exec_start_addr
    //       a1 = exec_end_addr
    //
    .globl  zero_section
    .type   zero_section, @function
zero_section:
    beq a0, a1, .zero_section_done
    sd  zero, (a0)
    addi    a0, a0, 8
    j   zero_section
.zero_section_done:
    ret

    // zero_section helper function:
    //       a0 = exec_start_addr
    //       a1 = exec_end_addr
    //       a2 = start count
    //
    .globl  count_section
    .type   count_section, @function
count_section:
    beq a0, a1, .count_section_done
    sd  a2, (a0)
    addi    a0, a0, 8
    addi    a2, a2, 8
    j   count_section
.count_section_done:
    ret

    // copy_section helper function:
    //  a0 = load_addr
    //  a1 = exec_start_addr
    //  a2 = exec_end_addr
    .globl  copy_section
    .type   copy_section, @function
copy_section:
    beq     a1, a0, .copy_section_done // if load_addr == exec_start_addr, goto copy_section_done
.check_if_copy_section_done:
    beq a1, a2, .copy_section_done // if offset != length, goto keep_copying
.keep_copying:
    ld  a3, 0(a0)                  // val = *load_addr
    sd  a3, 0(a1)                  // *exec_start_addr = val;
    addi    a0, a0, 8              // load_addr = load_addr + 8
    addi    a1, a1, 8              // exec_start_addr = exec_start_addr + 8
    j   .check_if_copy_section_done
.copy_section_done:
    ret



/***********************************************************************************
 *
 * memfill() - fills memory, alternate to lib function when not available
 */
    // config_copy helper function:
    //  a0 = dest
    //  a1 = value to fill
    //  a2 = length
    .globl  memfill
    .type   memfill, @function
memfill:
    mv  t1,a0
    mv  t2,a1
    beqz    a2,2f
1:
    sb  t2,0(t1)
    addi    a2,a2,-1
    addi    t1,t1,1
    bnez    a2,1b
2:
    ret

/***********************************************************************************
 *
 * The following config_copy() symbol overrides the weak symbol in the HAL and does
 * a safe copy of HW config data
 */
    // config_copy helper function:
    //  a0 = dest
    //  a1 = src
    //  a2 = length
    .globl  config_copy
    .type   config_copy, @function
config_copy:
    mv  t1,a0
    beqz    a2,2f
1:
    lb  t2,0(a1)
    sb  t2,0(t1)
    addi    a2,a2,-1
    addi    t1,t1,1
    addi    a1,a1,1
    bnez    a2,1b
2:
    ret

/***********************************************************************************
 *
 * config_32_copy () Copies a word at a time, used when copying to contigous registers
 */
    // config_copy helper function:
    //  a0 = dest
    //  a1 = src
    //  a2 = length
    .globl  config_32_copy
    .type   config_32_copy, @function
config_32_copy:
    mv  t1,a0
    beqz    a2,2f
1:
    lw  t2,0(a1)
    sw  t2,0(t1)
    addi    a2,a2,-4
    addi    t1,t1,4
    addi    a1,a1,4
    bnez    a2,1b
2:
    ret

 /***********************************************************************************
 *
 * config_64_copy - copying using 64 bit loads, addresses must be on 64 bit boundary
 */
    // config_copy helper function:
    //  a0 = dest
    //  a1 = src
    //  a2 = length
    .globl  config_64_copy
    .type   config_64_copy, @function
config_64_copy:
    mv  t1,a0
    beqz    a2,2f
1:
    ld  t2,0(a1)
    sd  t2,0(t1)
    addi    a2,a2,-8
    addi    t1,t1,8
    addi    a1,a1,8
    bnez    a2,1b
2:
    ret

/*
 * clear_ras , clear_ras_2_deep
 * Two deep function calls. 
 * Used to clear the interal processor Return Address Stack
 * This is belt and braces, may not be required
 */
.clear_ras:
    mv a5, x1
    nop
    call .clear_ras_2_deep
    nop
    nop
    nop
    nop
    nop
    nop
    mv  x1, a5
    ret

.clear_ras_2_deep:
    nop
    nop
    nop
    nop
    nop
    nop
    ret


