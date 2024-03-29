/*******************************************************************************
 * Copyright 2019-2021 Microchip FPGA Embedded Systems Solutions.
 *
 * SPDX-License-Identifier: MIT
 *
 * MPFS HAL Embedded Software
 *
 * Modifications copyright (C) 2021 Hex Five Security, Inc.  
 */
/*******************************************************************************
 * 
 * file name : mpfs_lim.ld
 * Used when debugging code. The debugger loads the code to LIM.
 * 
 * You can find details on the PolarFireSoC Memory map in the mpfs-memory-hierarchy.md
 * which can be found under the link below:
 * https://github.com/polarfire-soc/polarfire-soc-documentation
 * 
 */
 
OUTPUT_ARCH( "riscv" )
ENTRY(_start)

/*-----------------------------------------------------------------------------

-- MSS hart Reset vector

The MSS reset vector for each hart is stored securely in the MPFS.
The most common usage will be where the reset vector for each hart will be set
to the start of the envm at address 0x2022_0100, giving 128K-256B of contiguous
non-volatile storage. Normally this is where the initial boot-loader will 
reside. (Note: The first 256B page of envm is used for metadata associated with 
secure boot. When not using secure boot (mode 0,1), this area is still reserved 
by convention. It allows easier transition from non-secure to secure boot flow
during the development process.

------------------------------------------------------------------------------*/

MEMORY
{
    envm (rx) : ORIGIN  = 0x20220100, LENGTH = 128k - 0x100
    dtim (rwx) : ORIGIN = 0x01000000, LENGTH = 7k
    switch_code (rx) : ORIGIN = 0x01001c00, LENGTH = 1k
    e51_itim (rwx) : ORIGIN = 0x01800000, LENGTH = 28k
    u54_1_itim (rwx) : ORIGIN = 0x01808000, LENGTH = 28k
    u54_2_itim (rwx) : ORIGIN = 0x01810000, LENGTH = 28k
    u54_3_itim (rwx) : ORIGIN = 0x01818000, LENGTH = 28k
    u54_4_itim (rwx) : ORIGIN = 0x01820000, LENGTH = 28k
    l2lim_prog (rx)  : ORIGIN = boot_prog,  LENGTH = boot_prog_len /* Hex Five mod */
    l2lim_data (rwx) : ORIGIN = boot_data,  LENGTH = boot_data_len /* Hex Five mod */   
    scratchpad(rwx)  : ORIGIN = 0x0A000000, LENGTH = 256k
    /* DDR sections example */
    ddr_cached_32bit (rwx) : ORIGIN  = 0x80000000, LENGTH = 768M
    ddr_non_cached_32bit (rwx) : ORIGIN  = 0xC0000000, LENGTH = 256M
    ddr_wcb_32bit (rwx) : ORIGIN  = 0xD0000000, LENGTH = 256M
    ddr_cached_38bit (rwx) : ORIGIN  = 0x1000000000, LENGTH = 1024M
    ddr_non_cached_38bit (rwx) : ORIGIN  = 0x1400000000, LENGTH = 0k
    ddr_wcb_38bit (rwx) : ORIGIN  = 0x1800000000, LENGTH  = 0k
}

HEAP_SIZE           = 4k;               /* needs to be calculated for your application if using */

/*
 * There is common area for shared variables, accessed from a pointer in a harts HLS
 */
SIZE_OF_COMMON_HART_MEM = 0k;

/* 
 * The stack size needs to be calculated for your                                
 * application. It must be Must be aligned                                       
 * Also Thread local storage (AKA hart local storage) is allocated for each hart 
 * as part of the stack                                                          
 * So the memory map will look like once apportion in startup code:              
 * stack hart0  Actual Stack size = (STACK_SIZE_PER_HART - HLS_DEBUG_AREA_SIZE)  
 * TLS hart 0                                                                    
 * stack hart1                                                                   
 * TLS hart 1                                                                    
 * etc                                                                           
 * note: HLS_DEBUG_AREA_SIZE is defined in mss_sw_config.h                       
 */

/*
 * Stack size for each hart's application.
 * These are the stack sizes that will be allocated to each hart before starting
 * each hart's application function, e51(), u54_1(), u54_2(), u54_3(), u54_4().
 */
STACK_SIZE_E51_APPLICATION   = 8k;
STACK_SIZE_U54_1_APPLICATION = 0k;
STACK_SIZE_U54_2_APPLICATION = 0k;
STACK_SIZE_U54_3_APPLICATION = 0k;
STACK_SIZE_U54_4_APPLICATION = 0k;


SECTIONS
{
    PROVIDE(__envm_start = ORIGIN(envm));
    PROVIDE(__envm_end = ORIGIN(envm) + LENGTH(envm));
    PROVIDE(__ddr_cached_32bit_start = ORIGIN(ddr_cached_32bit));
    PROVIDE(__ddr_cached_32bit_end = ORIGIN(ddr_cached_32bit) + LENGTH(ddr_cached_32bit));
    PROVIDE(__ddr_non_cached_32bit_start = ORIGIN(ddr_non_cached_32bit));
    PROVIDE(__ddr_non_cached_32bit_end = ORIGIN(ddr_non_cached_32bit) + LENGTH(ddr_non_cached_32bit));
    PROVIDE(__ddr_wcb_32bit_start = ORIGIN(ddr_wcb_32bit));
    PROVIDE(__ddr_wcb_32bit_end = ORIGIN(ddr_wcb_32bit) + LENGTH(ddr_wcb_32bit));
    PROVIDE(__ddr_cached_38bit_start = ORIGIN(ddr_cached_38bit));
    PROVIDE(__ddr_cached_38bit_end = ORIGIN(ddr_cached_38bit) + LENGTH(ddr_cached_38bit));
    PROVIDE(__ddr_non_cached_38bit_start = ORIGIN(ddr_non_cached_38bit));
    PROVIDE(__ddr_non_cached_38bit_end = ORIGIN(ddr_non_cached_38bit) + LENGTH(ddr_non_cached_38bit));
    PROVIDE(__ddr_wcb_38bit_start = ORIGIN(ddr_wcb_38bit));
    PROVIDE(__ddr_wcb_38bit_end = ORIGIN(ddr_wcb_38bit) + LENGTH(ddr_wcb_38bit));
    PROVIDE(__dtim_start = ORIGIN(dtim));
    PROVIDE(__dtim_end = ORIGIN(dtim) + LENGTH(dtim));
    PROVIDE(__e51itim_start = ORIGIN(e51_itim));
    PROVIDE(__e51itim_end = ORIGIN(e51_itim) + LENGTH(e51_itim));
    PROVIDE(__u54_1_itim_start = ORIGIN(u54_1_itim));
    PROVIDE(__u54_1_itim_end = ORIGIN(u54_1_itim) + LENGTH(u54_1_itim));
    PROVIDE(__u54_2_itim_start = ORIGIN(u54_2_itim));
    PROVIDE(__u54_2_itim_end = ORIGIN(u54_2_itim) + LENGTH(u54_2_itim));
    PROVIDE(__u54_3_itim_start = ORIGIN(u54_3_itim));
    PROVIDE(__u54_3_itim_end = ORIGIN(u54_3_itim) + LENGTH(u54_3_itim));
    PROVIDE(__u54_4_itim_start = ORIGIN(u54_4_itim));
    PROVIDE(__u54_4_itim_end = ORIGIN(u54_4_itim) + LENGTH(u54_4_itim));
    /* text: text code section */
    .text : ALIGN(0x10)
    {
        __text_load = LOADADDR(.text);
        __text_start = .; 
         *(.text.init)
        . = ALIGN(0x10);
        *(.text .text.* .gnu.linkonce.t.*)
        *(.plt)
        . = ALIGN(0x10);

        KEEP (*crtbegin.o(.ctors))
        KEEP (*(EXCLUDE_FILE (*crtend.o) .ctors))
        KEEP (*(SORT(.ctors.*)))
        KEEP (*crtend.o(.ctors))
        KEEP (*crtbegin.o(.dtors))
        KEEP (*(EXCLUDE_FILE (*crtend.o) .dtors))
        KEEP (*(SORT(.dtors.*)))
        KEEP (*crtend.o(.dtors))

        *(.rodata .rodata.* .gnu.linkonce.r.*)
        *(.sdata2 .sdata2.* .gnu.linkonce.s2.*)
        *(.gcc_except_table) 
        *(.eh_frame_hdr)
        *(.eh_frame)

        KEEP (*(.init))
        KEEP (*(.fini))

        PROVIDE_HIDDEN (__preinit_array_start = .);
        KEEP (*(.preinit_array))
        PROVIDE_HIDDEN (__preinit_array_end = .);
        PROVIDE_HIDDEN (__init_array_start = .);
        KEEP (*(SORT(.init_array.*)))
        KEEP (*(.init_array))
        PROVIDE_HIDDEN (__init_array_end = .);
        PROVIDE_HIDDEN (__fini_array_start = .);
        KEEP (*(.fini_array))
        KEEP (*(SORT(.fini_array.*)))
        PROVIDE_HIDDEN (__fini_array_end = .);

        *(.srodata.cst16) *(.srodata.cst8) *(.srodata.cst4) *(.srodata.cst2)
        *(.srodata*)

        . = ALIGN(0x10);
        __text_end = .;
        . = ALIGN(0x10);
    } > l2lim_prog
 
    .l2_scratchpad : ALIGN(0x10)
    { 
        . = ALIGN (0x10);
        __l2_scratchpad_load = LOADADDR(.l2_scratchpad);
        __l2_scratchpad_start = .;
        __l2_scratchpad_vma_start = .; 
        *(.l2_scratchpad)
        . = ALIGN(0x10);
        __l2_scratchpad_end = .;
        __l2_scratchpad_vma_end = .;
    } >scratchpad AT> l2lim_prog
  
    /* 
    *   The .ram_code section will contain the code That is run from RAM.
    *   We are using this code to switch the clocks including eNVM clock.
    *   This can not be done when running from eNVM
    *   This will need to be copied to ram, before any of this code is run.
    */
    .ram_code :
    {
        . = ALIGN (4);
        __sc_load = LOADADDR (.ram_code);
        __sc_start = .;
        *(.ram_codetext)        /* .ram_codetext sections (code) */
        *(.ram_codetext*)       /* .ram_codetext* sections (code)  */
        *(.ram_coderodata)      /* read-only data (constants) */
        *(.ram_coderodata*)
        . = ALIGN (4);
        __sc_end = .;
    } >switch_code AT> l2lim_prog     /* On the MPFS for startup code use,  >switch_code AT>eNVM */

    /* must be on 4k boundary- corresponds to page size */
    .stack : ALIGN(0x1000)
    {
        PROVIDE(__stack_bottom_h0$ = .);
        PROVIDE(__app_stack_bottom_h0 = .);
        . += STACK_SIZE_E51_APPLICATION;
        PROVIDE(__app_stack_top_h0 = .);
        PROVIDE(__stack_top_h0$ = .);

        PROVIDE(__stack_bottom_h1$ = .);
        PROVIDE(__app_stack_bottom_h1$ = .);
        . += STACK_SIZE_U54_1_APPLICATION;
        PROVIDE(__app_stack_top_h1 = .);
        PROVIDE(__stack_top_h1$ = .);

        PROVIDE(__stack_bottom_h2$ = .);
        PROVIDE(__app_stack_bottom_h2 = .);
        . += STACK_SIZE_U54_2_APPLICATION;
        PROVIDE(__app_stack_top_h2 = .);
        PROVIDE(__stack_top_h2$ = .);

        PROVIDE(__stack_bottom_h3$ = .);
        PROVIDE(__app_stack_bottom_h3 = .);
        . += STACK_SIZE_U54_3_APPLICATION;
        PROVIDE(__app_stack_top_h3 = .);
        PROVIDE(__stack_top_h3$ = .);

        PROVIDE(__stack_bottom_h4$ = .);
        PROVIDE(__app_stack_bottom_h4 = .);
        . += STACK_SIZE_U54_4_APPLICATION;
        PROVIDE(__app_stack_top_h4 = .);
        PROVIDE(__stack_top_h4$ = .);

    } > l2lim_data
    
    .heap : ALIGN(0x10)
    {
        __heap_start = .;
        . += HEAP_SIZE;
        __heap_end = .;
        . = ALIGN(0x10);
        _heap_end = __heap_end;
    } > l2lim_data

    /* short/global data section */
    .sdata : ALIGN(0x10)
    {
        __sdata_load = LOADADDR(.sdata);
        __sdata_start = .; 
        /* offset used with gp(gloabl pointer) are +/- 12 bits, so set point to middle of expected sdata range */
        /* If sdata more than 4K, linker used direct addressing. Perhaps we should add check/warning to linker script if sdata is > 4k */
        __global_pointer$ = . + 0x800;
        *(.sdata .sdata.* .gnu.linkonce.s.*)
        . = ALIGN(0x10);
        __sdata_end = .;
    } > l2lim_data AT > l2lim_prog

    /* data section */
    .data : ALIGN(0x10)
    { 
        __data_load = LOADADDR(.data);
        __data_start = .; 
        *(.got.plt) *(.got)
        *(.shdata)
        *(.data .data.* .gnu.linkonce.d.*)
        . = ALIGN(0x10);
        __data_end = .;
    } > l2lim_data AT > l2lim_prog

    /* sbss section */
    .sbss : ALIGN(0x10)
    {
        __sbss_start = .;
        *(.sbss .sbss.* .gnu.linkonce.sb.*)
        *(.scommon)
        . = ALIGN(0x10);
        __sbss_end = .;
    } > l2lim_data
  
    /* sbss section */
    .bss : ALIGN(0x10)
    { 
        __bss_start = .;
        *(.shbss)
        *(.bss .bss.* .gnu.linkonce.b.*)
        *(COMMON)
        . = ALIGN(0x10);
        __bss_end = .;
    } > l2lim_data

    /* End of uninitialized data segment */
    _end = .;
    
    /* 
     * memory shared accross harts. 
     * The boot Hart Local Storage holds a pointer to this area for each hart if 
     * when enabled by setting MPFS_HAL_SHARED_MEM_ENABLED define in the
     * mss_sw_config.h
     */
    .app_hart_common : /* ALIGN(0x1000) */
    {
        PROVIDE(__app_hart_common_start = .);
        . += SIZE_OF_COMMON_HART_MEM;
        PROVIDE(__app_hart_common_end = .);
    } > l2lim_data

}
