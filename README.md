# multizone-iot-sdk-pfsc

MultiZone® Trusted Firmware is the quick and safe way to build secure embedded applications with any RISC-V processor. It provides secure access to commercial and private clouds, remote firmware updates, and telemetry. The built-in Trusted Execution Environment provides hardware-enforced separation to shield the execution of trusted applications from untrusted 3rd party software.

Complete firmware stack optimized for RISC-V processors:

- Provides secure access to any IoT clouds, secure boot, remote firmware updates, telemetry, etc.
- Works with any RISC-V processor: no need for proprietary crypto hardware
- Rapid development: pre-integrated TEE, TCP/IP, TLS/ECC, MQTT, FreeRTOS, GCC, Eclipse
- Built-in Trusted Execution Environment providing multiple separated runtime domains
- Commercial open source license: no GPL contamination, no royalties, free evaluation

The MultiZone® IoT Firmware works with any 32-bit and 64-bit RISC-V processor with standard U-mode extension. For a quick start, we recommend the development kit based on the open source softcore X300 developed by Hex Five Security. It is an enhanced version of the E300 SoC (Rocket rv32) originally developed at U.C. Berkeley. Like the E300, the X300 is designed to be programmed onto a Xilinx Artix-7. The X300 bitstream is entirely free for commercial and non-commercial use.

This version of the MultiZone Secure IoT Firmware works with the following development boards:

- [Xilinx Artix-7 Arty FPGA Evaluation Kit](https://www.xilinx.com/products/boards-and-kits/arty.html)

- [Microchip PolarFire SoC FPGA Icicle Kit](https://www.microsemi.com/existing-parts/parts/152514)

This repository is for the Microchip Icicle Kit board reference design [2021.02](https://github.com/polarfire-soc/icicle-kit-reference-design/releases/tag/2021.02), [2021.04](https://github.com/polarfire-soc/icicle-kit-reference-design/releases/tag/2021.04), [2021.08](https://github.com/polarfire-soc/icicle-kit-reference-design/releases/tag/2021.08), [2021.11](https://github.com/polarfire-soc/icicle-kit-reference-design/releases/tag/2021.11)


### Quick Start ###

- Download and install [Microsemi Flash Programmer](https://download-soc.microsemi.com/FPGA/v2021.3/prod/Program_Debug_v2021.3_lin.bin)
- Download and unzip the release asset [Icicle-Kit-2021.11-Trusted-Firmware.zip](https://github.com/hex-five/multizone-iot-sdk-pfsc/releases/download/v2.2.5/Icicle-Kit-2021.11-Trusted-Firmware.zip)
- Verify that jumpers J34 and J43 are in position 2-3
- Connect the power adapter to J29 and a micro USB cable to J33. Do NOT connect the ethernet port yet.
- Turn on the power switch SW6. 
- Program the Icicle board: FPExpress > Project > New job proj > Import > Job file: MPFS_ICICLE_KIT_BASE_DESIGN.job > Run
- Skip the instructions below and go directly to [MultiZone Reference Application](#multizone-reference-application)


### Installation ###

This SDK works with any versions of Linux, Windows, and Mac capable of running Java 1.8 or greater. The directions in this readme have been carefully verified with fresh installations of Debian 11.2 and Ubuntu 20.04. Other Linux distros are similar. Windows developers may want to install Windows Subsystem for Linux or a Linux emulation environment like MYSYS2/MinGW64. Hex Five's precompiled toolchain and openOCD for Windows are available at https://hex-five.com/download/

**Linux prerequisites**

```
sudo apt update
sudo apt install git build-essential default-jre gtkterm mosquitto-clients
```
_Note_: the package gtkterm is optional and required only to connect to the reference application via a local terminal. It is not required to build, debug, and load the MultiZone Firmware or to connect to the target via Ethernet. Any other serial terminal application of choice would do.

_Note_: the package mosquitto-clients is optional and required only to test MQTT funcionality including telemetry and remote firmware updates. It is not required to build, debug, and load MultiZone Firmware or to connect to the target via local terminal. Any other MQTT client application of choice would do.

<a name="udev-rules"></a>Add the three lines below to /etc/udev/rules.d/99.rules to access the Icicle serial port over USB.
```
# Microsemi PolarFire SoC Icicle - UART J11 - ID 10c4:ea71 Cygnal Integrated Products, Inc.
SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4",ATTRS{idProduct}=="ea71", MODE="664", GROUP="plugdev"
SUBSYSTEM=="usb", ATTR{idVendor} =="10c4",ATTR{idProduct} =="ea71", MODE="664", GROUP="plugdev"
```
Reboot or run ```sudo udevadm trigger```

**Microchip prerequisites**

- [Microsemi Flash Programmer](https://www.microsemi.com/product-directory/programming-and-debug/4977-flashpro)

_Note_: Microchip FlashPro Software is optional and only required to boot MultiZone firmware from the PolarFire SoC eNVM memory. It is not required to build, load, debug, and run the firmware in ram. Alternatively, the FPExpress software can be downloaded as part of Microchip Libero SoC suite. 

- [Microchip SoftConsole (RISC-V Toolchain and OpenOCD)](https://www.microsemi.com/product-directory/design-tools/4879-softconsole#downloads)

_Note_: the SoftConsole software is neededed only to provide the RISC-V Toolchain and the OpenOCD folders. It is not required to build, load, debug, and run the MultiZone Firmware. Alternatively, you can build and debug MultiZone Firmware from the command line with Makefile and GDB or you can use your own Eclipse installation with the Eclipse CDT project incuded in this repo - see [Eclipse CDT Project](#optional-eclipse-cdt-project).   

**Trusted Firmware SDK**

```
git clone --recursive https://github.com/hex-five/multizone-iot-sdk-pfsc.git
cd multizone-iot-sdk-pfsc
git apply -p1 ext/pfsc-platform.patch --directory=ext/pfsc-platform
```
```
export SC_INSTALL_DIR=~/Microchip/SoftConsole-v2021.3-7.0.0.599
export FPGENPROG=~/microsemi/Program_Debug_v2021.3/Program_Debug_Tool/bin64/fpgenprog
export RISCV=$SC_INSTALL_DIR/riscv-unknown-elf-gcc
export OPENOCD=$SC_INSTALL_DIR/openocd
```
_Note_: change SC_INSTALL_DIR and FPGENPROG according to your installation.

build and load to ram for debug (boot mode 0):
```
make && make load
```
build and load to flash for production (boot mode 1):
```
make BOOT_MODE=1 && make load BOOT_MODE=1
```

**eMMC flash setup**

MultiZone Trusted Firmware relies on the Icicle Kit eMMC flash for the local storage of binary files and firmware updates.

For this to work make sure that:
- jumpers J34 and J43 are switched to position 2-3 (1.8V)
- the eMMC drive is partitioned with at least one volume formatted FAT or exFAT
- the FAT/exFAT file system is writable and has at least 256KB of free space available

_Note_: the eMMC flash is likely to work out-of-the-box without any intervention as it should ship preformatted with one FAT boot partition. If you run into any issues with the eMMC, follow these [instructions](https://github.com/polarfire-soc/polarfire-soc-documentation/blob/master/boards/mpfs-icicle-kit-es/updating-icicle-kit/updating-icicle-kit-design-and-linux.md#eMMC) or drop us a note at [info@hex-five-com](mailto:info@hex-five-com).


### MultiZone Reference application ###

**First boot - Automatic system update**

Connect the ethernet port J2 to an Internet router, or to your computer if Internet sharing is enabled - see https://help.ubuntu.com/community/Internet/ConnectionSharing. The router should provide DHCP configuration including IPV4 address and DNS server(s). There is no need to open inbound ports as the MQTT client connects to the broker via the standard HTTPS/TLS outbound port 443, which is usually open.

The first time the Trusted Firmware boots, it connects to Hex Five's release server to pull firmware updates. Pay attention to the green leds near the ethernet port. They should blink briefly upon establishing link connections and while downloading the system updates. Depending on the speed of your Internet connection, after a few seconds the system will reboot automatically and the red led LED2 will start blinking to indicate normal system activity.

**Local Access via UART - No ethernet connection**

Linux users: make sure you have access rights to the USB port connected to the Icicle Kit - see [Linux prereqs](#udev-rules)

Connect the Icicle Kit micro USB J11 to your computer.

On your computer, start a serial terminal console (GtkTerm) and connect to /dev/ttyUSB0 at 115200-8-N-1

Hit enter a few times until the cursor 'Z2 >' appears on the screen:

```
===================================================================
                    MultiZone® Trusted Firmware                    
             Patents US 11,151,262 and PCT/US2019/03877            
   Copyright© 2022 Hex Five Security, Inc. - All Rights Reserved   
===================================================================
This version of MultiZone® Trusted Firmware is meant for evaluation
purposes only. As such, use of this software is governed by the    
Evaluation License. There may be other functional limitations as   
described in the evaluation SDK documentation. The commercial      
version of the software does not have these restrictions.          
===================================================================
Machine ISA   : 0x00101105 RV64 ACIMU 
Vendor        : 0x00000000  
Architecture  : 0x00000000  
Implementation: 0x00000000 
Hart id       : 0x0 
CPU clock     : 600 MHz 
RTC clock     : 1 MHz 
 
PLIC @0x0c000000 
GPIO @0x20122000 
 
Z2 > 
Commands: yield send recv pmp load store exec stats timer restart 
```
observe Zone 3 heartbeat LED2 (red)

press SW2 to toggle LED4 (yellow)

press SW3 to toggle LED3 (yellow)

observe the messages sent by Zone 3 to Zone 2

```
Z3 > IRQ SW3

Z3 > IRQ SW2
```
send a ping to Zone 3 and observe the reply
```
Z2 > send 3 ping

Z3 > pong
```
For a detailed explanation of all the features of the MultiZone Reference Application see [MultiZone Security Reference Manual](https://github.com/hex-five/multizone-iot-sdk-pfsc/tree/master/ext/multizone/manual.pdf)

**Secure Remote Access via Mutually Authenticated TLS/MQTT - Ethernet connection**  

Connect the ethernet port J2 to an Internet router

After a few seconds the client should connect to Hex Five's public MQTT broker:
```
Z1 > eth1: link up
 
Z1 > dhcp: address 10.42.0.181
 
Z1 > dns: mqtt-broker.hex-five.com 54.177.73.90

Z1 > sntp: 04/01/2022 00:54:53 GMT
 
Z1 > mqtt: client id mzone-50b26099 
 
Z1 > mqtt: connected TLSv1.2

```
Take note of your unique mqtt client id - mzone-50b26099 in the example above. You will need it to interact with the target via MQTT messages published and subscribed to the subtopics mzone-xxxxxxxx/. The MQTT client id is derived from the PolarFire SoC Device Serial Number and unique to your Icicle Kit.

**Telemetry - Send and Receive TLS/MQTT Messages**

In the following examples replace ```mzone-xxxxxxxx``` with your unique client id.

In a new terminal console, subscribe (listen) to all topics for your device:
```
cd multizone-iot-sdk-pfsc
CLIENT_ID=mzone-xxxxxxxx
alias mosquitto_sub='mosquitto_sub --host mqtt-broker.hex-five.com --cafile pki/hexfive-ca.crt --cert pki/test.crt --key pki/test.key'
mosquitto_sub -t $CLIENT_ID/# -v
```
In a new terminal console, publish (send) MQTT messages to the subtopics mapped to zones:
```
cd multizone-iot-sdk-pfsc
CLIENT_ID=mzone-xxxxxxxx
alias mosquitto_pub='mosquitto_pub --host mqtt-broker.hex-five.com --cafile pki/hexfive-ca.crt --cert pki/test.crt --key pki/test.key'

mosquitto_pub -t $CLIENT_ID/zone1 -m ping
mosquitto_pub -t $CLIENT_ID/zone2 -m ping
mosquitto_pub -t $CLIENT_ID/zone3 -m ping
mosquitto_pub -t $CLIENT_ID/zone4 -m ping
mosquitto_pub -t $CLIENT_ID/zone2 -m MultiZone
```

**Remote Firmware Updates**

Remotely deploy new firmware to hart #1 in zone #5:

```
mosquitto_pub -t $CLIENT_ID/hart1.bin -f apps/hart1/hart1.bin
```

On your computer, start a new serial terminal console (GtkTerm) and connect to /dev/ttyUSB1 at 115200-8-N-1.
```
mosquitto_pub -t $CLIENT_ID/zone5 -m ping
mosquitto_pub -t $CLIENT_ID/zone5 -m Microchip!
```
Observe the newly deployed firmware running on hart #1 (Zone 5) and connected to the local UART /dev/ttyUSB1

```
===================================================================
                    MultiZone® Trusted Firmware                    
             Patents US 11,151,262 and PCT/US2019/03877            
   Copyright© 2022 Hex Five Security, Inc. - All Rights Reserved   
===================================================================
This version of MultiZone® Trusted Firmware is meant for evaluation
purposes only. As such, use of this software is governed by the    
Evaluation License. There may be other functional limitations as   
described in the evaluation SDK documentation. The commercial      
version of the software does not have these restrictions.          
===================================================================

Z1 > Microchip!

H1 > Commands: load store exec send recv pmp 
```
Optional: repeat with hart #2 in Zone 6 (/dev/ttyUSB2), hart #3 in Zone 7 (/dev/ttyUSB3), and hart #4 in Zone 8.


### Optional: Eclipse CDT Project ###

This repository includes a complete Eclipse CDT project for developers familiar with the Eclipse IDE. No additional plugins or 3rd party components are required to build and upload MultiZone to the target. The [OpenOCD debugging plug-in](https://eclipse-embed-cdt.github.io/debug/openocd) is optional and recommended to debug over OpenOCD/JTAG. 

_Note_: Microchip SoftConsole users may prefer this version of the project [SoftConsole-2021.3-Trusted-Firmware.zip](https://github.com/hex-five/multizone-iot-sdk-pfsc/releases/download/v2.2.5/SoftConsole-2021.3-Trusted-Firmware.zip). This version doesn't include the git repo and provides the fully populated file tree ready to go, with all dependencies and patches applied. It is recommended to import this project into a new workspace separate from Microchip stock extras/workspace.examples.   

**Eclipse project Setup**

Optional: Install a fresh copy of [Eclipse CDT 10.5.0 for Eclipse 2021-12](https://www.eclipse.org/cdt/downloads.php):

Optional: install the OpenOCD debugging plugin
```
Help > Install new software > Add > Name : Embedded C/C++ v6.x Updates
Help > Install new software > Add > Location : https://download.eclipse.org/embed-cdt/updates/v6/
Help > Install new software : Embedded C/C++ OpenOCD Debugging
```
Import the MultiZone Trusted Firmware project
```
Files > Open project from file system > Import source : multizone-iot-sdk-pfsc
files > Open project from file system > Search for nested projects : deselect
files > Open project from file system > Finish
```
Configure Microchip dependencies FPGENPROG and SC_INSTALL_DIR according to your installation
```
Project > properties > C/C++ > Build > Environment
FPGENPROG ${HOME}/microsemi/Program_Debug_v2021.3/Program_Debug_Tool/bin64/fpgenprog
SC_INSTALL_DIR ${HOME}/Microchip/SoftConsole-v2021.3-7.0.0.599
```
Select the project profile: debug (ram / boot mode 0) or production (envm / boot mode 1)
```
Project > Build configurations > Set Active > Debug or Production
```
Build and load to target
```
Build Targets > all
Build Targets > load
```
Debug:
```
Run > Debug configurations > multizone-iot-sdk-pfsc > Debug
```

![alt text](https://hex-five.com/wp-content/uploads/multizone-eclipse-proj.png)


### Legalities ###

Please remember that export/import and/or use of strong cryptography software, providing cryptography hooks, or even just communicating technical details about cryptography software is illegal in some parts of the world. So when you import this software to your country, re-distribute it from there or even just email technical suggestions or even source patches to the authors or other people you are strongly advised to pay close attention to any laws or regulations which apply to you. Hex Five Security, Inc. and the authors of the software included in this repository are not liable for any violations you make here. So be careful, it is your responsibility.

_MultiZone and HEX-Five are registered trademarks of Hex Five Security, Inc._

_MultiZone technology is protected by patents US 11,151,262 and PCT/US2019/038774_
