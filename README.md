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

Skip the SDK instructions below and go directly to [run the Trusted Firmware](#run-the-trusted-firmware)


### Installation ###

TBC ...


### Legalities ###

Please remember that export/import and/or use of strong cryptography software, providing cryptography hooks, or even just communicating technical details about cryptography software is illegal in some parts of the world. So when you import this software to your country, re-distribute it from there or even just email technical suggestions or even source patches to the authors or other people you are strongly advised to pay close attention to any laws or regulations which apply to you. Hex Five Security, Inc. and the authors of the software included in this repository are not liable for any violations you make here. So be careful, it is your responsibility.

MultiZone and HEX-Five are registered trademarks of Hex Five Security, Inc.

MultiZone technology is protected by patents US 16450826 and PCT US1938774.
