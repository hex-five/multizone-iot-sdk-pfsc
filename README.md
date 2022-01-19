# multizone-iot-sdk-pfsc

MultiZone® Trusted Firmware is the quick and safe way to build secure IoT applications with any RISC-V processor. It provides secure access to commercial and private IoT clouds, remote firmware updates, and telemetry. The built-in Trusted Execution Environment provides hardware-enforced separation to shield the execution of trusted applications from untrusted 3rd party libraries.

Complete firmware stack optimized for RISC-V processors:

- Provides secure access to any IoT clouds, secure boot, remote firmware updates, etc.
- Works with any RISC-V processor: no need for proprietary TrustZone-like hardware
- Rapid development: pre-integrated TEE, TCP/IP, TLS/ECC, MQTT, FreeRTOS, GCC, Eclipse
- Built-in Trusted Execution Environment providing multiple separated runtime domains
- Commercial open source license: no GPL contamination, no royalties, free evaluation

The MultiZone® IoT Firmware works with any 32-bit and 64-bit RISC-V processor with standard U-mode extension. For a quick start, we recommend the development kit based on the open source softcore X300 developed by Hex Five Security. It is an enhanced version of the E300 SoC (Rocket rv32) originally developed at U.C. Berkeley. Like the E300, the X300 is designed to be programmed onto a Xilinx Artix-7. The X300 bitstream is entirely free for commercial and non-commercial use.

This version of the MultiZone Secure IoT Firmware supports the following hardware development kits:

- [Xilinx Artix-7 Arty FPGA Evaluation Kit](https://www.xilinx.com/products/boards-and-kits/arty.html)

- [Microchip PolarFire SoC FPGA Icicle Kit](https://www.microsemi.com/existing-parts/parts/152514)


This repository is for the Microchip Icicle Kit board [reference design 2021.02](https://github.com/polarfire-soc/icicle-kit-reference-design/releases/tag/2021.02)

### Quick Start ###

Download and install [Microchip flash programmer software FPExpress](https://download-soc.microsemi.com/FPGA/v2021.3/prod/Program_Debug_v2021.3_lin.bin)

Download and unzip the release asset [Icicle-Kit-2021.02-Trusted-Firmware.zip](https://github.com/hex-five/multizone-iot-sdk-pfsc/releases/download/v2.2.2/.zip) 

Program the Icicle board: FPExpress > project > new job proj > import > job file : MPFS_ICICLE_KIT_BASE_DESIGN.job > run

Skip the SDK instructions below and go directly to [run the MultiZone Trusted Firmware](#run-multizone-trusted-firmware)


### Installation ###

This SDK works with any versions of Linux, Windows, and Mac capable of running Java 1.8 or greater. The directions in this readme have been carefully verified with fresh installations of Debian 11.2.0 and Ubuntu 20.04.3 LTS. Other Linux distros are similar. Windows developers may want to install a Linux emulation environment like MYSYS2/MinGW64 or Windows Subsystem for Linux. Hex Five's precompiled toolchain and openOCD for Windows are available at https://hex-five.com/download/

**Linux prerequisites**

```
sudo apt update
sudo apt install git build-essential default-jre gtkterm mosquitto-clients    
```

_Note_: the package gtkterm is optional and required only to connect to the reference application via a local terminal. It is not required to build, debug, and load the MultiZone Firmware or to connect to the target via Ethernet. Any other serial terminal application of choice would do.

_Note_: the package mosquitto-clients is optional and required only to test MQTT funcionality including telemetry and remote firmware updates. It is not required to build, debug, and load MultiZone Firmware or to connect to the target via Ethernet. Any other MQTT client application of choice would do.

**Microchip prerequisites**

- [Microchip FlashPro Software (fpgenprog)](https://www.microsemi.com/product-directory/programming-and-debug/4977-flashpro)

_Note_: Microchip FlashPro Software is optional and only required to boot MultiZone Firmware from the Icicle eNVM flash memory. It is not required to build, load, debug, and run the firmware in ram. Alternatively, the FPExpress software can be downloaded as part of Microchip Libero SoC suite. 

- [Microchip SoftConsole (RISC-V Toolchain and OpenOCD)](https://www.microsemi.com/product-directory/design-tools/4879-softconsole#downloads)

_Note_: the SoftConsole software is neededed only to provide the RISC-V Toolchain and the OpenOCD folders. It is not required to build, load, debug, and run the MultiZone Firmware. Alternatively, you can build and debug MultiZone Firmware from the command line with Makefile and GDB or you can use your own Eclipse installation with the Eclipse CDT project incuded in this repo - see section below.   


### Legalities ###

Please remember that export/import and/or use of strong cryptography software, providing cryptography hooks, or even just communicating technical details about cryptography software is illegal in some parts of the world. So when you import this software to your country, re-distribute it from there or even just email technical suggestions or even source patches to the authors or other people you are strongly advised to pay close attention to any laws or regulations which apply to you. Hex Five Security, Inc. and the authors of the software included in this repository are not liable for any violations you make here. So be careful, it is your responsibility.

MultiZone and HEX-Five are registered trademarks of Hex Five Security, Inc.

MultiZone technology is protected by patents US 16450826 and PCT US1938774.
