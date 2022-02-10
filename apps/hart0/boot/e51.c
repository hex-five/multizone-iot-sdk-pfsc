/* Copyright(C) 2021 Hex Five Security, Inc. - All Rights Reserved */

#include "mpfs_hal/mss_hal.h"
#include "mpfs_hal/common/nwc/mss_nwc_init.h"

/* ------------------------------------------------------------------------- */
void e51(void) {
/* ------------------------------------------------------------------------- */


    /* Init PLIC */
     PLIC_init();

    /* Enable peripherals */
    SYSREG->SOFT_RESET_CR = 0U;
    SYSREG->SUBBLK_CLOCK_CR = 0xFFFFFFFFUL;

    /* MultiZone TEE zone3 SW2/SW3 */
    SYSREG->GPIO_INTERRUPT_FAB_CR |= (1 << 30); // SW2
    SYSREG->GPIO_INTERRUPT_FAB_CR |= (1 << 31); // SW3

    /* Release U54 hart1,2,3,4 */
//    raise_soft_interrupt(1);
//    raise_soft_interrupt(2);
//    raise_soft_interrupt(3);
//    raise_soft_interrupt(4);

    /* Boot MultiZone TEE */
    asm volatile("csrr t0, mscratch; csrw mtvec, t0; ecall");

}

#include "mpfs_hal/startup_gcc/system_startup_defs.h"

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
