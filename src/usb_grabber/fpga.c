//=============================================================================
// Copyright (C) 2020 Nu-Gate Technology. All rights reserved.
// SPDX-License-Identifier: MIT
//=============================================================================
//=============================================================================
//!
//! @file fpga.c
//!
//! C source for FPGA related functions.
//!
//! <pre>
//! MODIFICATION HISTORY:
//!
//! Ver   Who  Date       Changes
//! ----- ---- ---------- -----------------------------------------------------
//! 1.0   sd   2020.12.07 First release
//! </pre>
//=============================================================================
#include "fpga.h"

//! FPGA register space
volatile struct FPGA_REG *fpga = (struct FPGA_REG *)XPAR_DVP_0_BASEADDR;

//=============================================================================
//! FPGA Read Version
//-----------------------------------------------------------------------------
//! @return FPGA version number
//=============================================================================
int Fpga_ReadVersion (void) {
	return (fpga->com.Version);
}

//=============================================================================
//! FPGA Read Active Bank Index
//-----------------------------------------------------------------------------
//! @return The index of bank which contains the latest image data.
//=============================================================================
int Fpga_ReadActiveBank (void) {
	int bank = (fpga->grb_l.Status >> FPGA_ACTIVE_BANK_OFFSET) & 0x3;
	return bank;
}

//==========================================================================
//! Initialize FPGA
//--------------------------------------------------------------------------
//! @param bank_[a/b/c]	Start address of each bank of triple buffer.
//--------------------------------------------------------------------------
//! @breif This function initializes FPGA and start DMA transfer of image
//! data through MIPI CSI interface.
//==========================================================================
void Fpga_Init (unsigned int bank_a, unsigned int bank_b, unsigned int bank_c) {
	fpga->com.InterruptEnable = 0x00000001;
	fpga->grb_l.Address_A = bank_a;
	fpga->grb_l.Address_B = bank_b;
	fpga->grb_l.Address_C = bank_c;
	fpga->grb_l.Trigger   = 0x00000001;
	fpga->grb_r.Address_A = bank_a;
	fpga->grb_r.Address_B = bank_b;
	fpga->grb_r.Address_C = bank_c;
	fpga->grb_r.Trigger   = 0x00000001;
	fpga->arb.Control   = 0x00000001;
	fpga->grb_l.Control   = 0x00000001;
	fpga->grb_r.Control   = 0x00000001;
}
