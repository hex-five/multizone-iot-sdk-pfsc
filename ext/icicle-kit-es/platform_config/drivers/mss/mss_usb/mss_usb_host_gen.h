/* Copyright(C) 2021 Hex Five Security, Inc. - All Rights Reserved */

#ifndef __MSS_USB_HOST_GEN_H_
#define __MSS_USB_HOST_GEN_H_

#include <stdint.h>
#include "drivers/mss/mss_usb/mss_usb_config.h"

#ifdef __cplusplus
extern "C" {
#endif

#ifdef MSS_USB_HOST_ENABLED
  
/*-------------------------------------------------------------------------*//**
  Types exported from USBH-GEN driver
  ============================
 */

/*-------------------------------------------------------------------------*//**
  The mss_usbh_gen_err_code_t provides a type to identify the error occurred
  during retrieving configuration and other class specific descriptors from the
  attached GEN class device. This type can be used with genh_error  call-back
  function element of mss_usbh_gen_user_cb_t type to identify the exact cause
  of the error. The meaning of the constants is as described below

  |          Constant             |                Description                   |
  |-------------------------------|----------------------------------------------|
  | USBH_GEN_EP_NOT_VALID         | Indicates that the endpoint information      |
  |                               | retrieved from the attached device was not   |
  |                               | consistent with the GEN class.               |
  |                               |                                              |
  | USBH_GEN_CLR_CEP_STALL_ERROR  | Indicates that the host controller was not   |
  |                               | able to clear the stall condition on the     |
  |                               | attached device even after multiple retries. |
  
 */
typedef enum mss_usbh_gen_err_code
{
    USBH_GEN_NO_ERROR = 0,
    USBH_GEN_EP_NOT_VALID = -1,
    USBH_GEN_CLR_CEP_STALL_ERROR = -2,
    USBH_GEN_WRONG_DESCR = -3,
    
} mss_usbh_gen_err_code_t;

/*-------------------------------------------------------------------------*//**
  The mss_usbh_GEN_state_t provides a type for the states of operation of the
  USBH-GEN driver. Most of the states are internally used by the USBH-GEN driver
  during the enumeration process. The USBH-GEN driver is ready to perform data
  transfers with the attached device when the driver is in state
  USBH_GEN_DEVICE_READY. The USBH_GEN_ERROR state indicates that the error was
  detected either during enumeration or during the normal data transfer
  operations with the attached device even after retries.
 */
typedef enum mss_usbh_gen_state
{
    USBH_GEN_IDLE,
    USBH_GEN_GET_CLASS_DESCR,
    USBH_GEN_WAIT_GET_CLASS_DESCR,
    
    USBH_GEN_SET_CONFIG,
    USBH_GEN_WAIT_SET_CONFIG,
    USBH_GEN_WAIT_DEV_SETTLE,

    USBH_GEN_REQ_GET_REPORT_DESC,
    USBH_GEN_WAIT_REQ_GET_REPORT_DESC,
    USBH_GEN_REQ_SET_IDLE,
    USBH_GEN_WAIT_REQ_SET_IDLE,

    USBH_GEN_REQ_GET_GEN_DESC,
    USBH_GEN_WAIT_GET_GEN_DESC,

    USBH_GEN_DEVICE_READY,

    USBH_GEN_REQ_SET_PROTOCOL,
    USBH_GEN_WAIT_REQ_SET_PROTOCOL,
    USBH_GEN_DEVICE_RETRY,
    USBH_GEN_ERROR
    
} mss_usbh_gen_state_t;

/*------------------------Public data structures-----------------------------*/
/*-------------------------------- USBH-GEN----------------------------------*/
/*----------------------------------------------------------------------------*/

/*-------------------------------------------------------------------------*//**
  The mss_usbh_gen_user_cb_t provides the prototype for all the call-back
  functions which must be implemented by the user application. The user
  application must define and initialize a structure of this type and provide
  the address of that structure as parameter to the MSS_USBH_GEN_init() function.

  genh_valid_config
  The function pointed by the genh_valid_config function pointer will be called
  to indicate that a valid GEN class configuration was found on the attached
  device and the device is configured for this configuration.

  genh_tdev_ready
  The function pointed by the genh_tdev_ready function pointer is called when
  this driver is able to retrieve all the GEN class specific information
  (including sector size and sector number) from the attached device and is
  ready to perform the data transfers.

  genh_driver_released
  The function pointed by the genh_driver_released function pointer is called to
  indicate to the application that this driver is released by the USBH driver.
  This could be either because the GEN class device is now detached or there is
  permanent error with the USBH driver.

  genh_error
  The function pointed by the genh_error function pointer is called to indicate
  that there was an error while retrieving the class specific descriptor
  information from the attached GEN class device. The error_code parameter
  indicates the exact cause of the error.
  
  genh_decode
  The function pointed by the genh_decode function pointer is called to indicate
  that there is a new report received from the attached GEN class device. The
  data parameter indicates the location of received data present in the internal
  buffer.
  
 */
typedef struct mss_usbh_gen_user_cb
{
  void (*genh_valid_config)(void);
  void (*genh_tdev_ready)(void);
  void (*genh_driver_released)(void);
  void (*genh_error)(int8_t error_code);
  void (*genh_decode)(uint8_t *data);
  
} mss_usbh_gen_user_cb_t;


/*----------------------------------------------------------------------------*/
/*----------------------MSS USBH-GEN Public APIs------------------------------*/
/*----------------------------------------------------------------------------*/


/*-------------------------------------------------------------------------*//**
  The MSS_USBH_GEN_init() function must be used by the application to initialize
  the USBH-GEN driver. This function must be called before any other function of
  the USBH-GEN driver.

  @param user_cb
    The user_cb parameter provides a pointer to the structure of type
    mss_usbh_gen_user_cb_t. This pointer is used to call the application
    call-back functions by the USBH-GEN driver. These call-back functions can
    be used by the application to provide error/status messages to the user or
    for performing the application specific handling of the events.

  @return
    This function does not return a value.

  Example:
  @code
      MSS_USBH_init(&MSS_USBH_user_cb);
      MSS_USBH_GEN_init(&MSS_USBH_GEN_user_cb);
      MSS_USBH_register_class_driver(MSS_USBH_GEN_get_handle());
  @endcode
*/
void
MSS_USBH_GEN_init
(
    mss_usbh_gen_user_cb_t* user_sb
);

/***************************************************************************//**
  The MSS_USBH_GEN_task() function is the main task of the USBH-GEN driver.
  This function monitors the events from the USBH driver as well as the user
  application and makes decisions. This function must be called repeatedly by
  the application to allow the USBH-GEN driver to perform the housekeeping
  tasks.A timer/scheduler can be used to call this function at regular intervals
  or it can be called from the main continuous foreground loop of the 
  application.

  @param
    This function does not take any parameters.

  @return
    This function does not return a value.

  Example:
  @code
  @endcode
 */
void
MSS_USBH_GEN_task
(
    void
);

/***************************************************************************//**
  The MSS_USBH_GEN_get_handle() function must be used by the application to get
  the handle from the USBH-GEN driver. This handle must then be used to register
  this driver with the USBH driver.

  @param
    This function does not take any parameters.

  @return
    This function returns a pointer to the class-handle structure.

  Example:
  @code
      MSS_USBH_init(&MSS_USBH_user_cb);
      MSS_USBH_GEN_init(&MSS_USBH_GEN_user_cb);
      MSS_USBH_register_class_driver(MSS_USBH_GEN_get_handle());
  @endcode
 */
void*
MSS_USBH_GEN_get_handle
(
    void
);

/***************************************************************************//**
  The MSS_USBH_GEN_get_state() function can be used to find out the current
  state of the USBH-GEN driver. This information can be used by the application
  to check the readiness of the USBH-GEN driver to start the data transfers. The
  USBH-GEN driver can perform data transfers only when it is in the
  USBH_GEN_DEVICE_READY state.

  @param
    This function does not take any parameters.

  @return
    This function returns a value of type mss_usbh_gen_state_t indicating the
    current state of the USBH-GEN driver.

  Example:
  @code
      if (USBH_GEN_DEVICE_READY == MSS_USBH_GEN_get_state())
      {
          *result = MSS_USBH_GEN_get_sector_count();
          return RES_OK;
      }
      else if (USBH_GEN_DEVICE_READY < MSS_USBH_GEN_get_state())
      {
          *result = 0u;
          return RES_NOTRDY;
      }
  @endcode
 */
mss_usbh_gen_state_t
MSS_USBH_GEN_get_state
(
    void
);

#endif  /* MSS_USB_HOST_ENABLED */

#ifdef __cplusplus
}
#endif

#endif  /* __MSS_USB_HOST_GEN_H_ */

