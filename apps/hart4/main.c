/* Copyright(C) 2021 Hex Five Security, Inc. - All Rights Reserved */

#include <stddef.h> // NULL
#include <string.h>

#include "mpfs_hal/mss_hal.h"

#include "owi_sequence.h"
#include "mss_multizone.h"

typedef enum {zone1=1, zone2, zone3, zone4} Zone;
typedef enum {DISCONNECTED, CONNECTED} usb_state_enum;

#define MAN_CMD_TIME 200*1000 // 200ms @1MHz RTC
#define CMD_DUMMY 0xFFFFFF
#define CMD_STOP  0x000000
volatile uint32_t man_cmd = CMD_STOP;
volatile usb_state_enum usb_state = 0;
volatile uint8_t usb_event = 0;

/* ------------------------------------------------------------------------- */
#include "drivers/mss/mss_usb/mss_usb_host.h"
#include "drivers/mss/mss_usb/mss_usb_host_gen.h"
#include "drivers/mss/mss_usb/mss_usb_std_def.h"

mss_usbh_tdev_info_t dev_info;

uint8_t usb_cmd_buf[USB_SETUP_PKT_LEN] = {
        0x40,       //uint8_t  bmRequestType
        0x06,       //uint8_t  bRequest
        0x00, 0x01, //uint16_t wValue
        0x00, 0x00, //uint16_t wIndex
        0x03, 0x00  //uint16_t wLenght = sizeof data_buf[]
};

uint32_t usb_data_buf = 0x000000;

void usb_write(const uint32_t cmd){

    usb_data_buf = cmd;

    const mss_usb_ep_state_t cep_st = MSS_USBH_get_cep_state();

    if (cep_st == MSS_USB_EP_VALID || cep_st == MSS_USB_CEP_IDLE){

        MSS_USBH_configure_control_pipe(dev_info.addr);

        MSS_USBH_start_control_xfr(usb_cmd_buf,
                                  (uint8_t*)&usb_data_buf,
                                  USB_STD_REQ_DATA_DIR_OUT,
                                  USB_SETUP_PKT_LEN);
    }

}

void USB_DEV_enumerated(mss_usbh_tdev_info_t tdev_info){
    dev_info = tdev_info;
}
void USB_DEV_class_driver_assigned(void){
    usb_event=1;
    usb_state = CONNECTED;
}
void USB_DEV_dettached(void){
    if (usb_state == CONNECTED) usb_event=1;
    usb_state = DISCONNECTED;
}

mss_usbh_user_cb_t MSS_USBH_user_cb = {
    NULL, //USB_DEV_attached,
    USB_DEV_dettached,
    NULL, //USB_DEV_oc_error,
    USB_DEV_enumerated,
    USB_DEV_class_driver_assigned,
    NULL, //USB_DEV_not_supported,
    NULL, //USB_DEV_permanent_erro
};

mss_usbh_gen_user_cb_t MSS_USBH_HID_user_cb = {
    NULL, //GEN_DEV_valid_config,
    NULL, //GEN_DEV_ready,
    NULL, //GEN_DEV_driver_released,
    NULL, //GEN_DEV_error,
    NULL, //GEN_DEV_decode
};

/* ------------------------------------------------------------------------- */

typedef enum {
    USB_HOST_TASK,
    ROBOT_SEQ_TASK,
    ROBOT_CMD_TASK,
} Task;

uint64_t usb_host_task(void);   // USB Host
uint64_t robot_seq_task(void);  // OWI sequence
uint64_t robot_cmd_task(void);  // OWI Manual cmd stop

static struct {
    uint64_t (*task)(void);
    uint64_t timecmp;
} timer[] = {
    {usb_host_task, UINT64_MAX},
    {robot_seq_task, UINT64_MAX},
    {robot_cmd_task, UINT64_MAX},
};

void timer_set(const Task task, const uint64_t timecmp){

    timer[task].timecmp = timecmp;

    uint64_t timecmp_min = UINT64_MAX;
    for (size_t i=0; i<sizeof(timer)/sizeof(timer[0]); i++)
        timecmp_min = timer[i].timecmp < timecmp_min ?
                        timer[i].timecmp :
                        timecmp_min;

}

void timer_handler(const uint64_t time){

    for (size_t i=0; i<sizeof(timer)/sizeof(timer[0]); i++){

        if(time >= timer[i].timecmp){
            timer_set(i, timer[i].task());
        }

    }

}

uint64_t usb_host_task(){ // OWI sequence

    MSS_USBH_task();
    MSS_USBH_GEN_task();
    MSS_USBH_1ms_tick();

    return 0; // 0 = run at every systick (1ms @1MHz RTC)

}

uint64_t robot_seq_task(){ // OWI auto sequence

    uint64_t timecmp = UINT64_MAX;

    if (usb_state){

        if (owi_sequence_next()!=-1){
            usb_write(owi_sequence_get_cmd());
            timecmp = readmtime() + owi_sequence_get_ms()*1000; // 1000 = 1ms @1MHz RTC
        }

    }

    return timecmp;

}
uint64_t robot_cmd_task(){ // OWI stop manual cmd
    usb_write(man_cmd = CMD_STOP);
    return UINT64_MAX;
}

/* ------------------------------------------------------------------------- */

#define MSG_SIZE 16
volatile char inbox[4][MSG_SIZE] = { "", "", "", ""};

/* ------------------------------------------------------------------------- */
void msg_handler(const Zone zone, const char *msg){
/* ------------------------------------------------------------------------- */

    if (strcmp("ping", msg)==0){
        MZONE_SEND(zone, "pong");

    } else if (usb_state==CONNECTED && man_cmd==CMD_STOP){

        if (strcmp("stop", msg)==0) owi_sequence_stop_req();

        else if (!owi_sequence_is_running()){

                 if (strcmp("start", msg)==0) {owi_sequence_start(MAIN);   timer_set(ROBOT_SEQ_TASK, 0);}
            else if (strcmp("fold",  msg)==0) {owi_sequence_start(FOLD);   timer_set(ROBOT_SEQ_TASK, 0);}
            else if (strcmp("unfold",msg)==0) {owi_sequence_start(UNFOLD); timer_set(ROBOT_SEQ_TASK, 0);}

            // Manual single-command adjustments
            else if (strcmp("q", msg)==0) man_cmd = 0x000001; // grip close
            else if (strcmp("a", msg)==0) man_cmd = 0x000002; // grip open
            else if (strcmp("w", msg)==0) man_cmd = 0x000004; // wrist up
            else if (strcmp("s", msg)==0) man_cmd = 0x000008; // wrist down
            else if (strcmp("e", msg)==0) man_cmd = 0x000010; // elbow up
            else if (strcmp("d", msg)==0) man_cmd = 0x000020; // elbow down
            else if (strcmp("r", msg)==0) man_cmd = 0x000040; // shoulder up
            else if (strcmp("f", msg)==0) man_cmd = 0x000080; // shoulder down
            else if (strcmp("t", msg)==0) man_cmd = 0x000100; // base clockwise
            else if (strcmp("g", msg)==0) man_cmd = 0x000200; // base counterclockwise
            else if (strcmp("y", msg)==0) man_cmd = 0x010000; // light on

            if (man_cmd != CMD_STOP){
                usb_write(man_cmd);
                timer_set(ROBOT_CMD_TASK, readmtime() + MAN_CMD_TIME);
            }

        }

    }

}

/* ------------------------------------------------------------------------- */
int main(void) {
/* ------------------------------------------------------------------------- */

    /* Enable irqs */
    set_csr(mie, MIP_MSIP);
    set_csr(mie, MIP_MEIP);
    __enable_irq();
    
    /* Init 1ms SysTick */
    SysTick_Config();
    
    /* Initialize the USB driver */
    MSS_USBH_init(&MSS_USBH_user_cb);
    MSS_USBH_GEN_init(&MSS_USBH_HID_user_cb);
    MSS_USBH_register_class_driver(MSS_USBH_GEN_get_handle());

    /* Start the USB host task */
    timer_set(USB_HOST_TASK, 0);

    while (1) {

        /* Application level USB event - device conn/disconn */
        if (usb_event){

            switch (usb_state){

            case CONNECTED :
                MZONE_SEND(zone1, (char[16]){"USB CONNECT"}); // local uart
                MZONE_SEND(zone2, (char[16]){"USB CONNECT"}); // remote broker

                usb_write(0x000002); // grip open - ack dev conn
                timer_set(ROBOT_CMD_TASK, readmtime() + 300*1000);
                break;

            case DISCONNECTED :
                MZONE_SEND(zone1, (char[16]){"USB DISCONNECT"}); // local uart
                MZONE_SEND(zone2, (char[16]){"USB DISCONNECT"}); // remote broker

                owi_sequence_stop();
                break;

            }

            usb_event = 0;

        }

        /* Process MultiZone IPC messages */
        for (Zone zone = zone1; zone <= zone4; zone++) {

            clear_csr(mie, MIP_MSIP);

            if (inbox[zone-1][0] != '\0') {
                msg_handler(zone, (const char*)inbox[zone-1]);
                inbox[zone-1][0] = '\0';
            }

            set_csr(mie, MIP_MSIP);

        }


        /* Pause hart */
        asm volatile("wfi");

    } // while(1)

}

// ------------------------------------------------------------------------
void SysTick_Handler_h4_IRQHandler(void){

    timer_handler(readmtime());

}

// ------------------------------------------------------------------------
void Software_h4_IRQHandler(void){

    for (Zone zone = zone1; zone <= zone4; zone++) {
        char msg[MSG_SIZE];
        if (MZONE_RECV(zone, msg))
            memcpy((char*) &inbox[zone-1][0], msg, MSG_SIZE);
    }

    clear_soft_interrupt();

}

// ------------------------------------------------------------------------
void handle_m_trap_h4(uintptr_t * regs, uintptr_t mcause, uintptr_t mepc){

    asm volatile ("j _start");
    //asm volatile ("ebreak");
    //for(;;);

}
