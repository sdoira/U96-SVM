//=============================================================================
// Copyright (C) 2020 Nu-Gate Technology. All rights reserved.
// SPDX-License-Identifier: MIT
//=============================================================================
//=============================================================================
//!
//! @file xusb_main.h
//!
//! Header file for xusb_main.c
//!
//! <pre>
//! MODIFICATION HISTORY:
//!
//! Ver   Who  Date       Changes
//! ----- ---- ---------- -----------------------------------------------------
//! 1.0   sd   2020.12.07 First release
//! </pre>
//=============================================================================
#ifndef XUSB_MAIN_H
#define XUSB_MAIN_H

#include "xparameters.h"
#include "xil_printf.h"
#include "sleep.h"
#include <stdio.h>
#include "xusb_wrapper.h"
#include "xil_exception.h"
#include "xscugic.h"

#include "xusb_ch9_video.h"
#include "uart.h"
#include "main.h"


//=============================================================================
// Constant Definitions
//=============================================================================
#define MEMORY_SIZE (64 * 1024)
u8 Buffer[MEMORY_SIZE] ALIGNMENT_CACHELINE;

#define CH9_DEBUG

//=============================================================================
// Function Prototypes
//=============================================================================
int Xusb_Init (void);
int Xusb_Main (void);
void IntrRxHandler (void *CallBackRef, u32 RequestedBytes, u32 BytesTxed);
void BulkInHandler (void *CallBackRef, u32 RequestedBytes, u32 BytesTxed);
s32 Xusb_SetupInterrupt (void *IntcPtr);


//=============================================================================
// Variable Definitions
//=============================================================================
struct Usb_DevData UsbInstance;
extern struct UVC_INFO uvc_info;
extern struct XUSB_TX_INFO tx_info;

Usb_Config *UsbConfigPtr;

XScuGic	InterruptController;	// Interrupt controller instance

#define	INTC_DEVICE_ID		XPAR_SCUGIC_SINGLE_DEVICE_ID
#define	USB_INT_ID			XPAR_XUSBPS_0_INTR


#endif
