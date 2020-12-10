//=============================================================================
// Copyright (C) 2020 Nu-Gate Technology. All rights reserved.
// SPDX-License-Identifier: MIT
//=============================================================================
//=============================================================================
//!
//! @file xusb_main.c
//!
//! C source file for the implementation of USB main loop.
//!
//! <pre>
//! MODIFICATION HISTORY:
//!
//! Ver   Who  Date       Changes
//! ----- ---- ---------- -----------------------------------------------------
//! 1.0   sd   2020.12.08 First release
//! </pre>
//=============================================================================
#include "xusb_main.h"

// Initialize a DFU data structure
static USBCH9_DATA storage_data = {
	.ch9_func = {
		// Set the chapter9 hooks
		.Usb_Ch9SetupDevDescReply = Usb_Ch9SetupDevDescReply,
		.Usb_Ch9SetupCfgDescReply = Usb_Ch9SetupCfgDescReply,
		.Usb_Ch9SetupBosDescReply = Usb_Ch9SetupBosDescReply,
		.Usb_Ch9SetupStrDescReply = Usb_Ch9SetupStrDescReply,
		.Usb_SetConfiguration = Usb_SetConfiguration,
		.Usb_SetConfigurationApp = Usb_SetConfigurationApp,
		.Usb_SetInterfaceHandler = Usb_SetInterfaceHandler,
		.Usb_ClassReq = Usb_ClassReq,
		.Usb_GetDescReply = NULL,
	},
	.data_ptr = (void *)NULL,
};

extern volatile struct FPGA_REG *fpga;
extern struct UVC_APP_DATA app_data;

//=============================================================================
//! XUSB Initialize
//-----------------------------------------------------------------------------
//! @return XST_SUCCESS else XST_FAILURE
//-----------------------------------------------------------------------------
//! @brief This function initializes USB driver.
//=============================================================================
int Xusb_Init (void)
{
	s32 Status;

	// Initialize the USB driver so that it's ready to use,
	// specify the controller ID that is generated in xparameters.h
	UsbConfigPtr = LookupConfig(USB_DEVICE_ID);
	if (NULL == UsbConfigPtr) {
		return XST_FAILURE;
	}

	// We are passing the physical base address as the third argument
	// because the physical and virtual base address are the same in our
	// example.  For systems that support virtual memory, the third
	// argument needs to be the virtual base address.
	Status = CfgInitialize(&UsbInstance, UsbConfigPtr, UsbConfigPtr->BaseAddress);
	if (XST_SUCCESS != Status) {
		return XST_FAILURE;
	}

	// hook up chapter9 handler
	Set_Ch9Handler(UsbInstance.PrivateData, Ch9Handler);

	// Assign the data to usb driver
	Set_DrvData(UsbInstance.PrivateData, &storage_data);

	// Assign user-defined data to usb driver
	storage_data.data_ptr = (void*)&app_data;

	// set endpoint handlers
	SetEpHandler(UsbInstance.PrivateData, 2, USB_EP_DIR_IN, IntrRxHandler);
	SetEpHandler(UsbInstance.PrivateData, 3, USB_EP_DIR_IN, BulkInHandler);

	return XST_SUCCESS;
}

//=============================================================================
//! XUSB Main
//-----------------------------------------------------------------------------
//! @return XST_SUCCESS else XST_FAILURE
//-----------------------------------------------------------------------------
//! @brief Main loop of USB function.
//=============================================================================
int Xusb_Main (void)
{
	s32 Status;
	unsigned char ch;
	int remain;
	int payload_size, buf_size;
	u8 *data_ptr;

	// application specific data structure
	struct UVC_APP_DATA *app_data = Uvc_GetAppData(&UsbInstance);

	// Start the controller so that Host can see our device
	Usb_Start(UsbInstance.PrivateData);

	while(1) {

		// press "esc" to leave
		if (uart_getc2(&ch)) {
			if (ch == 0x1B) {
				return XST_SUCCESS;
			} else if (ch == 0x0D) {
				unsigned long ptn_sel = fpga->csi_l.PatternSelect;
				if (ptn_sel == 5) {
					ptn_sel = 0;
				} else {
					ptn_sel++;
				}
				fpga->csi_l.PatternSelect = ptn_sel;
				fpga->csi_r.PatternSelect = ptn_sel;
				ch = 0;
			}
		}

		// Transfer data only after video streaming parameters are committed
		if (app_data->state == UVC_STATE_COMMIT) {
			// wait for new frame
			while(app_data->img_received == 0) {}

			// points the head of the frame buffer
			switch(app_data->bank) {
			case 0:  data_ptr = (u8*)IMG_BUF_A; break;
			case 1:  data_ptr = (u8*)IMG_BUF_B; break;
			case 2:  data_ptr = (u8*)IMG_BUF_C; break;
			default: data_ptr = (u8*)IMG_BUF_A; break;
			}

			data_ptr -= app_data->header_size;
			app_data->img_received = 0;
			remain = app_data->commit.dwMaxVideoFrameSize;
			app_data->busy = 0;

			while(remain > 0) {
				if (remain > app_data->max_payload_size) {
					payload_size = app_data->max_payload_size;
				} else {
					payload_size = remain;
				}
				buf_size = payload_size + app_data->header_size;
				remain -= payload_size;

				// embed header in image buffer
				memcpy (data_ptr, (u8*)&app_data->header, app_data->header_size);

				// data transfer
				app_data->busy = 1;
				Status = EpBufferSend(UsbInstance.PrivateData, 3, data_ptr, buf_size);
				Xil_AssertNonvoid(Status == XST_SUCCESS);

				// wait for transfer complete
				while(app_data->busy == 1) {}

				// next transfer
				data_ptr += payload_size;
			}

			// toggle field bit
			app_data->header.bmHeaderInfo ^= UVC_PAYLOAD_HEADER_FID;
		}
	}

	return XST_SUCCESS;
}

//=============================================================================
//! Interrupt RX Handler
//-----------------------------------------------------------------------------
//! @param *CallBackRef
//! @param RequestedBytes
//! @param BytesTxed
//-----------------------------------------------------------------------------
//! @brief This handler is called when data is received from interrupt
//! endpoint. Not used in this design.
//=============================================================================
void IntrRxHandler(void *CallBackRef, u32 RequestedBytes, u32 BytesTxed)
{
	xil_printf("IntrRxHandler\r\n");
}

//=============================================================================
//! Bulk Input Handler
//-----------------------------------------------------------------------------
//! @param *CallBackRef
//! @param RequestedBytes
//! @param BytesTxed
//-----------------------------------------------------------------------------
//! @brief This handler is called when data transfer through bulk endpoint is
//! completed.
//=============================================================================
void BulkInHandler(void *CallBackRef, u32 RequestedBytes, u32 BytesTxed)
{
	struct UVC_APP_DATA *app_data = Uvc_GetAppData((struct Usb_DevData*)CallBackRef);
	app_data->busy = 0;
}

//=============================================================================
//! XUSB Setup Interrupt
//-----------------------------------------------------------------------------
//! @param *IntcPtr		Pointer to the instance of the interrupt controller
//-----------------------------------------------------------------------------
//! @return XST_SUCCESS else XST_FAILURE
//-----------------------------------------------------------------------------
//! @brief This function sets up the USB interrupt.
//=============================================================================
s32 Xusb_SetupInterrupt (void *IntcPtr)
{
	s32 Status;

	// Connect to the interrupt controller
	Status = XScuGic_Connect(
		(XScuGic*)IntcPtr,
		USB_INT_ID,
		(Xil_ExceptionHandler)XUsbPsu_IntrHandler,
		(void*)UsbInstance.PrivateData
	);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	// Enable the interrupt for the USB
	XScuGic_Enable((XScuGic*)IntcPtr, USB_INT_ID);

	// Enable interrupts for Reset, Disconnect, ConnectionDone, Link State
	// Wakeup and Overflow events.
	XUsbPsu_EnableIntr(
		UsbInstance.PrivateData,
		XUSBPSU_DEVTEN_VNDRDEVTSTRCVEDEN | // added
		XUSBPSU_DEVTEN_EVNTOVERFLOWEN |
		XUSBPSU_DEVTEN_CMDCMPLTEN | // added
		XUSBPSU_DEVTEN_ERRTICERREN | // added
		//XUSBPSU_DEVTEN_SOFEN | // added
		XUSBPSU_DEVTEN_EOPFEN | // added
		XUSBPSU_DEVTEN_HIBERNATIONREQEVTEN | // added
		XUSBPSU_DEVTEN_WKUPEVTEN |
		XUSBPSU_DEVTEN_ULSTCNGEN |
		XUSBPSU_DEVTEN_CONNECTDONEEN |
		XUSBPSU_DEVTEN_USBRSTEN |
		XUSBPSU_DEVTEN_DISCONNEVTEN
	);

	return XST_SUCCESS;
}
