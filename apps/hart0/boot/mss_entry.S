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

    .globl reset_vector
    .globl _start

reset_vector:
_start:

    csrr a0, mhartid; beqz a0, e51

u54:

    #define CLINT_MSIP    0x02000000
    #define U54_PROG_BASE 0x80000000 // DDR
    #define U54_PROG_SIZE 0x04000000 // 64M

    # pause app cores
    csrw mstatus, zero; csrw mie, MIP_MSIP

    # reset msip
    la a1, CLINT_MSIP
    slli t0, a0, 2; addi a0, a0, -1
    add a1, t0, a1
 0: sw zero, (a1)

 1: wfi; csrr t0, mip; andi t0, t0, MIP_MSIP; beqz t0, 1b

    # resume @itim
    fence.i

    li t0, U54_PROG_BASE
    li t1, U54_PROG_SIZE
    mul t1, t1, a0
    add t0, t0, t1
    ld t1, (t0); beqz t1, 0b
    jr (t0)

e51:
    # clear the Return Address Stack
    call .clear_ras
    li a1, 0x3
    csrw 0x7c0, a1

    /* Setup trap handler */
    la a4, trap_vector
    csrw mtvec, a4          # initalise machine trap vector address
    /* Make sure that mtvec is updated before continuing */
    1:
    csrr a5, mtvec
    bne a4, a5, 1b

    /* Disable and clear all interrupts */
    li a2,  MSTATUS_MIE
    csrc mstatus, a2        # clear interrupt enable bit
    csrw mie, zero
    csrw mip, zero

    # mscratch must be init to zero - we are not using scratch memory
   #csrw mscratch, zero /* Hex Five Mod */
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

    la a4, __stack_bottom_h0$  # keep bottom of stack in a5 so we can init later
    la sp, __stack_top_h0$

    # clear the stack
    mv  a5, sp
.init_stack:
    sd zero, 0(a4)
    addi a4, a4, 8
    blt a4, a5, .init_stack

    # clear the heap
    la  a4, __heap_start
    la  a5, __heap_end
.init_heap:
    sd zero, 0(a4)
    addi a4, a4, 8
    blt a4, a5, .init_heap

    # clear DTIM - stop memory errors on initial access via cache
    li a2, MPFS_HAL_CLEAR_MEMORY
    beq x0, a2, .skip_mem_clear
    call    .clear_dtim
    call    .clear_l2lim
.skip_mem_clear:

    # Clear bus error unit accrued register on start-up
    la a4,0x01700020UL; sb x0, 0(a4)
    la a4,0x01701020UL; sb x0, 0(a4)
    la a4,0x01702020UL; sb x0, 0(a4)
    la a4,0x01703020UL; sb x0, 0(a4)
    la a4,0x01704020UL; sb x0, 0(a4)

    # main_first_hart()
    j main_first_hart

    #in case of return, loop forever. nop's added so can be seen in debugger
    0: nop; nop; j 0b


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
    bge a0, a1, .zero_section_done
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
 * The following copy_switch_code() symbol overrides the weak symbol in the HAL and does
 * a safe copy of HW config data
 */
    .globl  copy_switch_code
    .type   copy_switch_code, @function
copy_switch_code:
    la      a5, __sc_start           // a5 = __sc_start
    la      a4, __sc_load            // a4 = __sc_load
    beq a5,a4,.copy_switch_code_done // if a5 == a4, goto copy_switch_code_done
    la      a3, __sc_end             // a3 = __sc_end
    beq a5,a3,.copy_switch_code_done // if a5 == a3, goto copy_switch_code_done
.copy_switch_code_loop:
    lw  a2,0(a4)                     // a2 = *a4
    sw  a2,0(a5)                     // *a5 = a2
    addi    a5,a5,4                  // a5+=4
    addi    a4,a4,4                  // a4+=4

    bltu    a5,a3,.copy_switch_code_loop // if a5 < a3, goto copy_switch_code_loop
.copy_switch_code_done:
    ret

/*******************************************************************************
 *
 */
#define START__OF_LIM 0x08000000
#define END__OF_LIM   0x08200000
#define START__OF_DTM 0x01000000
#define END__OF_DTM   0x01002000


.clear_l2lim:
    // Clear the LIM
    //
    // On reset, the first 15 ways are L2 and the last way is cache
    // We can initialize all, as cache write through to DDR is blocked
    // until DDR in initialized, so will have no effect other than clear ECC
    //
    // NOTE: we need to check if we are debugging from LIM,if so do not
    // initialize.
    //
    la a2, __text_start
    la  a4, 0x08000000          # start of LIM address
    and a2, a2, a4
    bnez a2, .done_clear
    la  a5, 0x08200000          # end of LIM address
    j   1f
.clear_dtim:
    //
    // Clear the E51 DTIM to prevent any ECC memory errors on initial access
    //
    la  a4, 0x01000000          # DTIM start
    la  a5, 0x01002000          # DTIM end
1:
    // common loop used by both .clear_l2lim and .clear_dtim
    sd   x0, 0(a4)
    add a4, a4, __SIZEOF_POINTER__
    blt a4, a5, 1b
.done_clear:
    ret

/*
 * record_ecc_error_counts on reset
 * These are non-zero in the coreplex.
 * Can be checked later on to see if values have changed
 *      a0 = mECCDataFailCount save address
        a1 = mECCDataCorrectionCount save address
        a2 = mECCDirFixCount save address
 */
.record_ecc_error_counts:
    # Store initial ECC errors
    #define mECCDataFailCount               0x02010168U
    la  a5, mECCDataFailCount
    mv  a4, a0// eg. Use stat of DTIM in not used for anything else  0x01000100
    lw  t2,0(a5)
    sw  t2,0(a4)
    #define mECCDataCorrectionCount         0x02010148U
    la  a5, mECCDataCorrectionCount
    mv  a4, a1// eg. Use stat of DTIM in not used for anything else 0x01000110
    lw  t2,0(a5)
    sw  t2,0(a4)
    #define mECCDirFixCount                 0x02010108u
    la  a5, mECCDirFixCount
    mv  a4, a2// eg. Use stat of DTIM in not used for anything else 0x01000120
    lw  t2,0(a5)
    sw  t2,0(a4)
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


