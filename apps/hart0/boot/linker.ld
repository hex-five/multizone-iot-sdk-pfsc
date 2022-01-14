/*******************************************************************************
 * See LICENSE for license details.
 * Modifications copyright (C) 2021 Hex Five Security, Inc.
 */

/*******************************************************************************
 * 
 * file name : mpfs_lim.ld
 * Code located in LIM. Used when debugging start-up code.
 */
 
OUTPUT_ARCH( "riscv" )
ENTRY(_start)

MEMORY
{
    ROM (rx)  : ORIGIN = boot_prog, LENGTH = boot_prog_len
    RAM (rwx) : ORIGIN = boot_data, LENGTH = boot_data_len

    scratchpad  (rwx) : ORIGIN = 0x0A000000, LENGTH = 512k
    switch_code (rx)  : ORIGIN = 0x01001c00, LENGTH = 1k     
}

HEAP_SIZE = 0K;

STACK_SIZE_E51_APPLICATION   = 1k;
STACK_SIZE_U54_1_APPLICATION = 0;
STACK_SIZE_U54_2_APPLICATION = 0;
STACK_SIZE_U54_3_APPLICATION = 0;
STACK_SIZE_U54_4_APPLICATION = 0;

SECTIONS
{

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
  } >ROM
 
  .l2_scratchpad : ALIGN(0x10)
  { 
    __l2_scratchpad_load = LOADADDR(.l2_scratchpad);
    __l2_scratchpad_start = .;
    __l2_scratchpad_vma_start = .; 
    *(.l2_scratchpad)
    . = ALIGN(0x10);
    __l2_scratchpad_end = .;
    __l2_scratchpad_vma_end = .;
  } >scratchpad AT>ROM
  
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
  } >switch_code AT>ROM     /* On the MPFS for startup code use,  >switch_code AT>eNVM */

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
  } >RAM AT >ROM

  .sdata2 : ALIGN(0x10)
  {
      *(.sdata2 .sdata2.* .gnu.linkonce.s2.*)
  } >RAM AT >ROM

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
  } >RAM AT >ROM

  /* sbss section */
  .sbss : ALIGN(0x10)
  {
    __sbss_start = .;
    *(.sbss .sbss.* .gnu.linkonce.sb.*)
    *(.scommon)
    . = ALIGN(0x10);
    __sbss_end = .;
  } >RAM
  
  /* sbss section */
  .bss : ALIGN(0x10)
  { 
    __bss_start = .;
    *(.shbss)
    *(.bss .bss.* .gnu.linkonce.b.*)
    *(COMMON)
    . = ALIGN(0x10);
    __bss_end = .;
  } >RAM

  /* End of uninitialized data segment */
  _end = .;
  
  .heap : ALIGN(0x10)
  {
    __heap_start = .;
    . += HEAP_SIZE;
    __heap_end = .;
    . = ALIGN(0x10);
    _heap_end = __heap_end;
  } >RAM
  
  /* must be on 4k boundary- corresponds to page size */
  .stack : ALIGN(64) /* 0x1000 */
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
    
  } >RAM
}

