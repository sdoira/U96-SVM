//=============================================================================
// Copyright (C) 2020 Nu-Gate Technology. All rights reserved.
// SPDX-License-Identifier: MIT
//=============================================================================
//=============================================================================
//!
//! @file fpga.h
//!
//! Header file for fpga.c
//!
//! <pre>
//! MODIFICATION HISTORY:
//!
//! Ver   Who  Date       Changes
//! ----- ---- ---------- -----------------------------------------------------
//! 1.0   sd   2020.12.07 First release
//! </pre>
//=============================================================================
#ifndef FPGA_H
#define FPGA_H

#include "xparameters.h"


//=============================================================================
// Memory Mapped Registers
//=============================================================================
//! Register map for COM (common functions)
struct FPGA_REG_COM {
	volatile unsigned int Version;			//!< [0000h]
	volatile unsigned int Testpad;			//!< [0004h]
	volatile unsigned int LED;				//!< [0008h]
	volatile unsigned int Switch;			//!< [000Ch]
	volatile unsigned int Timer;			//!< [0010h]
	volatile unsigned int InterruptEnable;	//!< [0014h]
	volatile unsigned int InterruptStatus;	//!< [0018h]
	volatile unsigned int GPIO;				//!< [001Ch]
	volatile unsigned int Size;				//!< [0020h]
	volatile unsigned int rsvd[1015];
};

//! Register map for DDR Arbiter
struct FPGA_REG_ARB {
	volatile unsigned int Control;
	volatile unsigned int Status;
	volatile unsigned int rsvd[62];
};

//! Register map for CSI Interface
struct FPGA_REG_CSI {
	volatile unsigned int Control;
	volatile unsigned int Status;
	volatile unsigned int Size;
	volatile unsigned int PatternSelect;
	volatile unsigned int FrameLength;
	volatile unsigned int FrameCount;
	volatile unsigned int rsvd[58];
};

//! Register map for Frame Grabber
struct FPGA_REG_GRB {
	volatile unsigned int Control;
	volatile unsigned int Status;
	volatile unsigned int Address_A;
	volatile unsigned int Address_B;
	volatile unsigned int Address_C;
	volatile unsigned int BurstLength;
	volatile unsigned int Trigger;
	volatile unsigned int rsvd[57];
};

//! FPGA register space
struct FPGA_REG {
	struct FPGA_REG_COM  com;    //!< [0000h - 0FFEh]
	struct FPGA_REG_ARB  arb;    //!< [1000h - 10FEh]
	struct FPGA_REG_CSI  csi_l;  //!< [1100h - 11FEh]
	struct FPGA_REG_CSI  csi_r;  //!< [1200h - 12FEh]
	struct FPGA_REG_GRB  grb_l;  //!< [1300h - 13FEh]
	struct FPGA_REG_GRB  grb_r;  //!< [1400h - 14FEh]
};

//=============================================================================
// Register Bit Field Definition
//=============================================================================
#define FPGA_CSI_CTRL_VRSTN		0x00000001


//=============================================================================
// Other Definition
//=============================================================================
// Frequency of pl_clk0 in Hz
#define FPGA_CLOCK_FREQUENCY	100000000

#define FPGA_ACTIVE_BANK_OFFSET		8

#define FPGA_INTR_GRB_L		0x00000001
#define FPGA_INTR_GRB_R		0x00000002


//=============================================================================
// Function Prototypes
//=============================================================================
int Fpga_ReadVersion (void);
int Fpga_ReadActiveBank ();
void Fpga_Init (unsigned int bank_a, unsigned int bank_b, unsigned int bank_c);


#endif
