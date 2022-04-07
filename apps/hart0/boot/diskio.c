/*-----------------------------------------------------------------------*/
/* Low level disk I/O module SKELETON for FatFs     (C)ChaN, 2019        */
/*-----------------------------------------------------------------------*/
/* If a working storage control module is available, it should be        */
/* attached to the FatFs via a glue function rather than modifying it.   */
/* This is an example of glue functions to attach various exsisting      */
/* storage control modules to the FatFs module with a defined API.       */
/*-----------------------------------------------------------------------*/

#include "ff.h"			/* Obtains integer types */
#include "diskio.h"		/* Declarations of disk functions */

/* Definitions of physical drive number for each drive */
#define DEV_MMC     0   /* Example: Map MMC/SD  to physical drive 0 */
#define DEV_RAM		1	/* Example: Map Ramdisk to physical drive 1 */
#define DEV_USB		2	/* Example: Map USB MSD to physical drive 2 */

//-------------------------------------------------------------------------
#include "drivers/mss/mss_mmc/mss_mmc.h"
#define MMC_BUS_VOLTAGE_1V8
#define MMC_BLOCK_COUNT_MAX 65535 // (32MB-512)/512 = 65535

static DSTATUS dev_mmc_disk_status = STA_NOINIT;

/*-----------------------------------------------------------------------*/
/* Get Drive Status                                                      */
/*-----------------------------------------------------------------------*/

DSTATUS disk_status (BYTE pdrv) {

	DSTATUS status = STA_NOINIT;

	switch (pdrv) {

	case DEV_MMC :
	    status = dev_mmc_disk_status;
	    break;

	}

	return status;
}

/*-----------------------------------------------------------------------*/
/* Inidialize a Drive                                                    */
/*-----------------------------------------------------------------------*/

DSTATUS disk_initialize (BYTE pdrv) {

    DSTATUS status = STA_NOINIT;

	switch (pdrv) {

	case DEV_MMC : {

	    const mss_mmc_cfg_t mss_mmc_cfg = {
	        .card_type = MSS_MMC_CARD_TYPE_MMC,
	        .data_bus_width = MSS_MMC_DATA_WIDTH_8BIT,
	    #if defined(MMC_BUS_VOLTAGE_1V8)
	        .bus_voltage = MSS_MMC_1_8V_BUS_VOLTAGE,
	        .clk_rate = MSS_MMC_CLOCK_200MHZ,
	        .bus_speed_mode = MSS_MMC_MODE_HS200,
	    #elif defined(MMC_BUS_VOLTAGE_3V3)
	        .bus_voltage = MSS_MMC_3_3V_BUS_VOLTAGE,
	        .clk_rate = MSS_MMC_CLOCK_50MHZ,
	        .bus_speed_mode = MSS_MMC_MODE_SDR,
	    #endif
	    };

	    if (MSS_MMC_init(&mss_mmc_cfg) == MSS_MMC_INIT_SUCCESS){
	        status = RES_OK;
	        dev_mmc_disk_status = RES_OK;
	    }

	    break;
	}

	}

	return status;
}


/*-----------------------------------------------------------------------*/
/* Read Sector(s)                                                        */
/*-----------------------------------------------------------------------*/

DRESULT disk_read (
	BYTE pdrv,		/* Physical drive nmuber to identify the drive */
	BYTE *buff,		/* Data buffer to store read data */
	LBA_t sector,	/* Start sector in LBA */
	UINT count		/* Number of sectors to read */
)
{
	DRESULT result = RES_PARERR;

	switch (pdrv) {

	case DEV_MMC :

	    /*if (count==1) {

            if (MSS_MMC_single_block_read(sector, (uint32_t *)buff) == MSS_MMC_TRANSFER_SUCCESS)
                result = RES_OK;

        } else*/ if (count <= MMC_BLOCK_COUNT_MAX){

            while (MSS_MMC_get_transfer_status() == MSS_MMC_TRANSFER_IN_PROGRESS){;}

            MSS_MMC_sdma_read(sector, buff, count*512);

            while (MSS_MMC_get_transfer_status() == MSS_MMC_TRANSFER_IN_PROGRESS){;}

            if (MSS_MMC_get_transfer_status() == MSS_MMC_TRANSFER_SUCCESS)
                result = RES_OK;

        }

		break;

	}

	return result;
}

/*-----------------------------------------------------------------------*/
/* Write Sector(s)                                                       */
/*-----------------------------------------------------------------------*/

#if FF_FS_READONLY == 0

DRESULT disk_write (
	BYTE pdrv,			/* Physical drive nmuber to identify the drive */
	const BYTE *buff,	/* Data to be written */
	LBA_t sector,		/* Start sector in LBA */
	UINT count			/* Number of sectors to write */
)
{
    DRESULT result = RES_PARERR;

	switch (pdrv) {

	case DEV_MMC :

        /*if (count==1) {

            if (MSS_MMC_single_block_write((uint32_t *)buff, sector) == MSS_MMC_TRANSFER_SUCCESS)
                result = RES_OK;

        } else*/ if (count <= MMC_BLOCK_COUNT_MAX){

            while (MSS_MMC_get_transfer_status() == MSS_MMC_TRANSFER_IN_PROGRESS){;}

            MSS_MMC_sdma_write(buff, sector, count*512);

            while (MSS_MMC_get_transfer_status() == MSS_MMC_TRANSFER_IN_PROGRESS){;}

            if (MSS_MMC_get_transfer_status() == MSS_MMC_TRANSFER_SUCCESS)
                result = RES_OK;

        }

        break;

	}

	return result;
}

#endif


/*-----------------------------------------------------------------------*/
/* Miscellaneous Functions                                               */
/*-----------------------------------------------------------------------*/

DRESULT disk_ioctl (
	BYTE pdrv,		/* Physical drive nmuber (0..) */
	BYTE cmd,		/* Control code */
	void *buff		/* Buffer to send/receive control data */
)
{
    DRESULT result = RES_PARERR;

	switch (pdrv) {

	case DEV_MMC :

	    switch (cmd){

	    /* Complete pending write process (needed at FF_FS_READONLY == 0) */
        case CTRL_SYNC        :

            if (MSS_MMC_get_transfer_status() == MSS_MMC_TRANSFER_SUCCESS)
                result = RES_OK;
            break;

        /* Get media size (needed at FF_USE_MKFS == 1) */
        case GET_SECTOR_COUNT :
            break;

        /* Get sector size (needed at FF_MAX_SS != FF_MIN_SS) */
        case GET_SECTOR_SIZE  :
            break;

        /* Get erase block size (needed at FF_USE_MKFS == 1) */
        case GET_BLOCK_SIZE   :
            break;

        /* Inform device that the data on the block of sectors is no longer used (needed at FF_USE_TRIM == 1) */
        case CTRL_TRIM        :
            break;

	    }

	    break;

	}

	return result;
}

