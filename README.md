# U96-SVM
Stereo vision front-end for Ultra96v2


## About
U96-SVM is an add-on board for Avnet Ultra96v2.
This board has dual CMOS image sensors and two mikroBUS sites.
This repository contains all design files for the hardware and a sample project 
which transfers stereo images through a USB interface.

![U96-SVM](https://github.com/sdoira/U96-SVM/blob/main/U96-SVM_320x240.png)


## Tools

These tools are used to create this project.
1. Avnet Ultra96v2
2. Autocad EAGLE 9.6.2
3. Xilinx Vivado 2020.1
4. Xilinx Vitis 2020.1


## PCB
This PCB is designed to be compliant with 96Boards specifications.
The number of layers is 4.
The minimum trace width and minimum drill diameter are 0.15mm and 0.25mm respectively.
This design rule is according to EuroCircuits 6D class.


EAGLE 9.6.2 is used in designing PCB.
This project doesn't contain Gerber files. EAGLE board layout file (.brd) is directly used to order manufacturing.
If you want to place an order simply upload the BRD file to the EuroCircuits website.
The assembly service is also possible by enabling the "Include assembly" option then upload the BOM file.


## USB Interface
This device is recognized as USB Video Class (UVC) device when connected to the host PC.
The sample project supports the following resolution both for USB2.1 and USB3.0.

| USB Ver. | Single Image Resolution | FPS  |
| :---     | :---                    | :--- |
| 2.0      | 640 x 480               | 30   |
| 3.0      | 640 x 480               | 30   |

The left and right images are combined horizontally.
The actual output image is twice wide.


## Vivado Project
This repository contains 2 Vivado projects.
One of them is the Vivado top level project.
The other is a project for a user-created IP module.
Both of them can be created by running TCL scripts.
Refer to "create_project_dvp.pdf" and "create_project1.pdf" about how to create these projects.


## Vitis Project
The Vitis project contains a sample application named "usb_grabber".
This application, when launched, automatically starts DMA transferring of stereo images while waiting for a USB connection.
Refer to "create_vitis_project.pdf" about how to create a Vitis project.


## License
### Hardware
The hardware documentation and products included in this repository are licensed under the TAPR Open Hardware License (www.tapr.org/OHL).
The hardware documentation is contained in the following directory.

	/eagle/

### Software
The software design files included in this repository are available under the MIT license.
Such design files are contained in the following directories.

	/src/dvp/rtl/		--- Verilog-HDL RTL source
	/src/dvp/sim/		--- Verilog-HDL simulation test bench
	/src/usb_grabber/	--- C source


