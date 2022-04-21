/* Copyright(C) 2021 Hex Five Security, Inc. - All Rights Reserved */

#include <stdlib.h> // utoa()
#include <string.h>

#include "mpfs_hal/mss_hal.h"
#include "mpfs_hal/common/nwc/mss_nwc_init.h"
#include "mpfs_hal/startup_gcc/system_startup_defs.h"
#include "drivers/mss/mss_mmuart/mss_uart.h"
#include "drivers/mss/mss_sys_services/mss_sys_services.h"

#include "ff.h"
#include "diskio.h"

/* Linker symbols defined in ../bsp/memory.ld */
extern char zone1_prog, zone1_prog_len;
extern char zone2_prog, zone2_prog_len;
extern char zone3_prog, zone3_prog_len;
extern char zone4_prog, zone4_prog_len;
extern char hart1_prog, hart1_prog_len;
extern char hart2_prog, hart2_prog_len;
extern char hart3_prog, hart3_prog_len;
extern char hart4_prog, hart4_prog_len;

typedef const struct {
    const char* file_name;
    uint64_t* const load_addr;
    const uint64_t load_size;
} FW_IMAGE;

const FW_IMAGE fw_image[] = {
#if BOOT_MODE == 1
    {"zone1.bin", (uint64_t* const)(&zone1_prog), (const uint64_t)&zone1_prog_len},
    {"zone2.bin", (uint64_t* const)(&zone2_prog), (const uint64_t)&zone2_prog_len},
    {"zone3.bin", (uint64_t* const)(&zone3_prog), (const uint64_t)&zone3_prog_len},
    {"zone4.bin", (uint64_t* const)(&zone4_prog), (const uint64_t)&zone4_prog_len},
#endif
    {"hart1.bin", (uint64_t* const)(&hart1_prog), (const uint64_t)&hart1_prog_len},
    {"hart2.bin", (uint64_t* const)(&hart2_prog), (const uint64_t)&hart2_prog_len},
    {"hart3.bin", (uint64_t* const)(&hart3_prog), (const uint64_t)&hart3_prog_len},
    {"hart4.bin", (uint64_t* const)(&hart4_prog), (const uint64_t)&hart4_prog_len},
};

FRESULT f_load(FW_IMAGE fw, FIL *f_file);

/* ------------------------------------------------------------------------- */
void e51(void) {
/* ------------------------------------------------------------------------- */

    /* Enable all peripherals */
    SYSREG->SOFT_RESET_CR   = 0x00000000; // TBD: actual bitmask
    SYSREG->SUBBLK_CLOCK_CR = 0xFFFFFFFF; // TBD: actual bitmask

    SYSREG->GPIO_INTERRUPT_FAB_CR |= (1 << 30); // zone3 SW2
    SYSREG->GPIO_INTERRUPT_FAB_CR |= (1 << 31); // zone3 SW3

    /* Config eMMC */
    #define LIBERO_SETTING_IOMUX1_CR_eMMC                   0x11111111UL
    #define LIBERO_SETTING_IOMUX2_CR_eMMC                   0x00FF1111UL
    #define LIBERO_SETTING_IOMUX6_CR_eMMC                   0x00000000UL
    #define LIBERO_SETTING_MSSIO_BANK4_CFG_CR_eMMC          0x00040A0DUL
    #define LIBERO_SETTING_MSSIO_BANK4_IO_CFG_0_1_CR_eMMC   0x09280928UL
    #define LIBERO_SETTING_MSSIO_BANK4_IO_CFG_2_3_CR_eMMC   0x09280928UL
    #define LIBERO_SETTING_MSSIO_BANK4_IO_CFG_4_5_CR_eMMC   0x09280928UL
    #define LIBERO_SETTING_MSSIO_BANK4_IO_CFG_6_7_CR_eMMC   0x09280928UL
    #define LIBERO_SETTING_MSSIO_BANK4_IO_CFG_8_9_CR_eMMC   0x09280928UL
    #define LIBERO_SETTING_MSSIO_BANK4_IO_CFG_10_11_CR_eMMC 0x09280928UL
    #define LIBERO_SETTING_MSSIO_BANK4_IO_CFG_12_13_CR_eMMC 0x09280928UL

    SYSREG->IOMUX1_CR = LIBERO_SETTING_IOMUX1_CR_eMMC;
    SYSREG->IOMUX2_CR = LIBERO_SETTING_IOMUX2_CR_eMMC;
    SYSREG->IOMUX6_CR = LIBERO_SETTING_IOMUX6_CR_eMMC;
    SYSREG->MSSIO_BANK4_CFG_CR = LIBERO_SETTING_MSSIO_BANK4_CFG_CR_eMMC;
    SYSREG->MSSIO_BANK4_IO_CFG_0_1_CR = LIBERO_SETTING_MSSIO_BANK4_IO_CFG_0_1_CR_eMMC;
    SYSREG->MSSIO_BANK4_IO_CFG_2_3_CR = LIBERO_SETTING_MSSIO_BANK4_IO_CFG_2_3_CR_eMMC;
    SYSREG->MSSIO_BANK4_IO_CFG_4_5_CR = LIBERO_SETTING_MSSIO_BANK4_IO_CFG_4_5_CR_eMMC;
    SYSREG->MSSIO_BANK4_IO_CFG_6_7_CR = LIBERO_SETTING_MSSIO_BANK4_IO_CFG_6_7_CR_eMMC;
    SYSREG->MSSIO_BANK4_IO_CFG_8_9_CR = LIBERO_SETTING_MSSIO_BANK4_IO_CFG_8_9_CR_eMMC;
    SYSREG->MSSIO_BANK4_IO_CFG_10_11_CR = LIBERO_SETTING_MSSIO_BANK4_IO_CFG_10_11_CR_eMMC;
    SYSREG->MSSIO_BANK4_IO_CFG_12_13_CR = LIBERO_SETTING_MSSIO_BANK4_IO_CFG_12_13_CR_eMMC;

    /* Init PLIC for all harts & enable e51 interrupts */
    PLIC_init(0); /* hart_id = 0 */
    PLIC_init(4); /* hart_id = 4 */

    PLIC_SetPriority(USB_DMA_PLIC, 2);
    PLIC_SetPriority(USB_MC_PLIC, 2);

    PLIC_SetPriority(MMC_main_PLIC, 3);
    PLIC_SetPriority(MMC_wakeup_PLIC, 3);

    __enable_irq();

    /* Copy lower 32 bits of the Device Serial Number in TEMP0 - zone1 mqtt_id & random */
    uint32_t serial_number[4]; // 128-bit DSN
    MSS_SYS_get_serial_number((uint8_t*)serial_number, 0);
    SYSREG->TEMP0 = serial_number[0];

    /* Init UART0 - print() boot messages */
    #define print(x) MSS_UART_polled_tx_string (&g_mss_uart0_lo, (unsigned char*) x)
    MSS_UART_init(&g_mss_uart0_lo, MSS_UART_115200_BAUD, MSS_UART_DATA_8_BITS | MSS_UART_NO_PARITY | MSS_UART_ONE_STOP_BIT);
    print("\e[2J\e[H");
    print("HEX-Five MultiZone® Trusted Firmware\n\r\n");

    /* Mount local eMMC FAT/exFAT  - force full FAT scan */
    FATFS f_fatfs; FATFS* fs = &f_fatfs; unsigned free_clust=0;
    if ( (f_mount(&f_fatfs, "", 1) || f_getfree("", &free_clust, &fs)) != FR_OK) {
        f_unmount("");
        print("Can't mount eMMC volume\n\rCheck J34 & J43 position [2-3].");
        for(;;); // abort
    }

    /* Load binaries from eMMC */
    for (size_t i = 0; i < sizeof fw_image / sizeof fw_image[0]; i++){

        FIL f_file;

        if (f_load(fw_image[i], &f_file) == FR_OK){

            char strbuff[32] = "emmc://"; strcat(strbuff, fw_image[i].file_name);
            char fsize[8+1] = ""; utoa(f_size(&f_file), fsize, 10);
            for (size_t i=0; i<sizeof(fsize)-strlen(fsize); i++){strcat(strbuff, " ");}
            strcat(strbuff, fsize);
            strcat(strbuff, "\n\r");
            print(strbuff);

        } else if (strncmp("zone", fw_image[i].file_name, 4)==0){

            if (free_clust>0){
                print("Remote firmware update in progress ...");
                break;

            } else {
                f_unmount("");
                print("eMMC volume full.");
                for(;;); // abort
            }

        }

    } f_unmount("");

    /* Release U54 harts */
    CLINT->MSIP[1] = 0x01U; //raise_soft_interrupt(1);
    CLINT->MSIP[2] = 0x01U; //raise_soft_interrupt(2);
    CLINT->MSIP[3] = 0x01U; //raise_soft_interrupt(3);
    CLINT->MSIP[4] = 0x01U; //raise_soft_interrupt(4);

    /* Start MultiZone TEE */
    asm volatile ("csrr ra, mscratch; csrw mtvec, ra; ecall");

}

/* ------------------------------------------------------------------------- */
int main_first_hart(HLS_DATA* hls) {
/* ------------------------------------------------------------------------- */
    uint64_t hartid = read_csr(mhartid);

    if(hartid == MPFS_HAL_FIRST_HART)
    {
        uint8_t hart_id;
        ptrdiff_t stack_top;

        /*
         * We only use code within the conditional compile
         * #ifdef MPFS_HAL_HW_CONFIG
         * if this program is used as part of the initial board bring-up
         * Please comment/uncomment MPFS_HAL_HW_CONFIG define in
         * platform/config/software/mpfs_hal/sw_config.h
         * as required.
         */
#ifdef  MPFS_HAL_HW_CONFIG
        config_l2_cache();
#endif  /* MPFS_HAL_HW_CONFIG */

        init_memory();
#ifndef MPFS_HAL_HW_CONFIG
        hls->my_hart_id = MPFS_HAL_FIRST_HART;
#endif
#ifdef  MPFS_HAL_HW_CONFIG
        load_virtual_rom();
        (void)init_bus_error_unit();
        (void)init_mem_protection_unit();
        (void)init_pmp((uint8_t)MPFS_HAL_FIRST_HART);
        (void)mss_set_apb_bus_cr((uint32_t)LIBERO_SETTING_APBBUS_CR);
#endif  /* MPFS_HAL_HW_CONFIG */
        /*
         * Initialise NWC
         *      Clocks
         *      SGMII
         *      DDR
         *      IOMUX
         */
#ifdef  MPFS_HAL_HW_CONFIG
        (void)mss_nwc_init();

        /* main hart init's the PLIC */
        PLIC_init_on_reset();

        /*
         * Turn on fic interfaces by default. Drivers will turn on/off other MSS
         * peripherals as required.
         */
        (void)mss_config_clk_rst(MSS_PERIPH_FIC0, (uint8_t)MPFS_HAL_FIRST_HART, PERIPHERAL_ON);
        (void)mss_config_clk_rst(MSS_PERIPH_FIC1, (uint8_t)MPFS_HAL_FIRST_HART, PERIPHERAL_ON);
        (void)mss_config_clk_rst(MSS_PERIPH_FIC2, (uint8_t)MPFS_HAL_FIRST_HART, PERIPHERAL_ON);
        (void)mss_config_clk_rst(MSS_PERIPH_FIC3, (uint8_t)MPFS_HAL_FIRST_HART, PERIPHERAL_ON);

#endif /* MPFS_HAL_HW_CONFIG */
        (void)main_other_hart(hls);
    }

    /* should never get here */
    while(true)
    {
       static volatile uint64_t counter = 0U;
       /* Added some code as debugger hangs if in loop doing nothing */
       counter = counter + 1U;
    }

    return (0);
}

/* ------------------------------------------------------------------------- */
uint8_t init_pmp(uint8_t hart_id) {
/* ------------------------------------------------------------------------- */

  //pmp_configure(hart_id);
    return (0U);
}

/* ------------------------------------------------------------------------- */
FRESULT f_load(FW_IMAGE fw, FIL *f_file) {
/* ------------------------------------------------------------------------- */

    FRESULT f_result = f_open(f_file, fw.file_name, FA_READ);

    if (f_result == FR_OK && f_size(f_file) > 0 && f_size(f_file) <= fw.load_size) {

        /* Eval version: lock down zone1 (keep eNVM img & ignore eMMC bin */
        if (strcmp(fw.file_name, "zone1.bin") != 0){

            unsigned bytes_read;
            f_result = f_read(f_file, (void*) fw.load_addr, f_size(f_file), &bytes_read);

        }

    }

    f_close(f_file);

    return f_result;

}

