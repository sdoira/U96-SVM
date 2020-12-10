//=============================================================================
// Copyright (C) 2020 Nu-Gate Technology. All rights reserved.
// SPDX-License-Identifier: MIT
//=============================================================================
//=============================================================================
//!
//! @file ov5640.c
//!
//! This file contains the functions regarding to the manipulations of
//! OV5640 CMOS sensor.
//!
//! <pre>
//! MODIFICATION HISTORY:
//!
//! Ver   Who  Date       Changes
//! ----- ---- ---------- -----------------------------------------------------
//! 1.0   sd   2020.12.07 First release
//! </pre>
//=============================================================================
#include "ov5640.h"

//=============================================================================
//! OV5640 Software Reset
//-----------------------------------------------------------------------------
//! @param mode		OV5640_RESET_ASSERT: assert reset,
//!            		OV5640_RESET_RELEASE: release reset
//-----------------------------------------------------------------------------
//! @brief This function asserts or de-asserts software reset to OV5640
//! depending on the value of "mode" parameter.
//=============================================================================
void Ov5640_SoftwareReset (int mode) {
	unsigned char reg_value;
	Ov5640_I2cRead(OV5640_ADDR_SYSTEM_CTROL0, &reg_value);

	if (mode == OV5640_RESET_ASSERT) {
		reg_value |= OV5640_SYSTEM_CTROL0_SOFTWARE_RESET;
	} else {
		reg_value &= ~OV5640_SYSTEM_CTROL0_SOFTWARE_RESET;
	}

	Ov5640_I2cWrite(OV5640_ADDR_SYSTEM_CTROL0, reg_value);
}

//=============================================================================
//! OV5640 Power Mode
//-----------------------------------------------------------------------------
//! @param mode		OV5640_POWER_UP: set to power up mode,
//!            		OV5640_POWER_DOWN: set to power down mode
//-----------------------------------------------------------------------------
//! @brief This function sets the power mode of OV5640 to power up state of
//! power down state depending on the value of "mode" parameter.
//=============================================================================
void Ov5640_PowerMode (int mode) {
	unsigned char reg_value;
	Ov5640_I2cRead(OV5640_ADDR_SYSTEM_CTROL0, &reg_value);

	if (mode == OV5640_POWER_DOWN) {
		reg_value |= OV5640_SYSTEM_CTROL0_SOFTWARE_POWERDOWN;
	} else {
		reg_value &= ~OV5640_SYSTEM_CTROL0_SOFTWARE_POWERDOWN;
	}

	Ov5640_I2cWrite(OV5640_ADDR_SYSTEM_CTROL0, reg_value);
}

//=============================================================================
//! OV5640 I2c Read
//-----------------------------------------------------------------------------
//! @param reg_addr		I2C register address
//! @param *reg_value	Read-out data is stored here
//-----------------------------------------------------------------------------
//! @brief This function reads 1 byte of data from the specified address
//! through I2C interface of OV5640.
//-----------------------------------------------------------------------------
//! @note Channel must be set properly in I2C expander (TCA9548A).
//=============================================================================
void Ov5640_I2cRead (unsigned int reg_addr, unsigned char *reg_value) {
	unsigned char tmp[2];
	tmp[0] = ((reg_addr >> 8) & 0xFF); // register address high byte
	tmp[1] =  (reg_addr       & 0xFF); // low byte

	I2c_Write(OV5640_I2C_ADDR, tmp, 2);

	I2c_Read(OV5640_I2C_ADDR, reg_value, 1);
}

//=============================================================================
//! OV5640 I2c Write
//-----------------------------------------------------------------------------
//! @param reg_addr		I2C register address
//! @param reg_value	Data to be written
//-----------------------------------------------------------------------------
//! @brief This function writes 1 byte of data to the specified address
//! through I2C interface of OV5640.
//-----------------------------------------------------------------------------
//! @note Channel must be set properly in I2C expander (TCA9548A).
//=============================================================================
void Ov5640_I2cWrite (unsigned int reg_addr, unsigned char reg_value) {
	unsigned char tmp[3];
	tmp[0] = ((reg_addr >> 8) & 0xFF); // register address high byte
	tmp[1] =  (reg_addr       & 0xFF); // low byte
	tmp[2] = reg_value;

	I2c_Write(OV5640_I2C_ADDR, tmp, 3);
}

//=============================================================================
//! OV5640 Initialize Registers
//-----------------------------------------------------------------------------
//! @param test_mode	OV5640_TEST_NORMAL: normal operation,
//!            			OV5640_TEST_COLORBAR: color bar
//-----------------------------------------------------------------------------
//! @brief This function contains register settings common to all resolution
//! modes.
//-----------------------------------------------------------------------------
//! @note Channel must be set properly in I2C expander (TCA9548A).
//=============================================================================
void Ov5640_RegisterInit (int test_mode) {

	//------------------------------------------------------------------
	// System and IO Pad Control [0x3000 - 0x3052]
	//------------------------------------------------------------------
	// SYSTEM CONTROL
	// no document, doesn't work if removed
	Ov5640_I2cWrite(0x302E, 0x08);

	// SC PLL CONTROL0
	// [7  ] Debug mode
	// [6:4] PLL charge pump control
	// [3:0] MIPI bit mode
	Ov5640_I2cWrite(0x3034, 0x18); // MIPI 8-bit mode

	// SC PLLS CTRL3
	// [7:6] Debug mode
	// [5:4] PLLS pre-divider
	// [3  ] Debug mode
	// [2  ] PLLS root divider
	// [1:0] PLLS seld5
	Ov5640_I2cWrite(0x303D, 0x10);

	// MIPI CONTROL 00
	// [7:5] mipi_lane_mode
	// [4  ] MIPI TX PHY power down
	// [3  ] MIPI RX PHY power down
	// [2  ] mipi_en
	// [1:0] Debug mode
	// setting 3'b010 to bit[7:5] will set mipi 2-lane mode
	// it differs from the datasheet
	Ov5640_I2cWrite(0x300E, 0x45); // MIPI enable, MIPI 2-lane mode

	//------------------------------------------------------------------
	// SCCB Control [0x3100 - 0x3108]
	//------------------------------------------------------------------
	// SCCB SYSTEM CTRL1
	// [7:2] Debug mode
	// [1  ] Select system input clock
	// [0  ] Debug mode
	Ov5640_I2cWrite(0x3103, 0x03);

	// SYSTEM ROOT DIVIDER
	// [7:6] Debug mode
	// [5:4] PCLK root divider
	// [3:2] sclk2x root divider
	// [1:0] SCLK root divider
	Ov5640_I2cWrite(0x3108, 0x11);

	//------------------------------------------------------------------
	// AWB Gain Control [0x3400 - 0x3406]
	//------------------------------------------------------------------
	// AWB MANUAL CONTROL
	// [7:1] Debug mode
	// [0]   AWB gain manual enable
	Ov5640_I2cWrite(0x3406, 0x00); // AWB auto mode

	//------------------------------------------------------------------
	// Timing Control [0x3800 - 0x3821]
	//------------------------------------------------------------------
	// TIMING TC REG21
	// [7:6] Debug mode
	// [5  ] JPEG enable
	// [4:3] Debug mode
	// [2  ] ISP mirror
	// [1  ] Sensor mirror
	// [0  ] Horizontal binning enable
	Ov5640_I2cWrite(0x3821, 0x06); // ISP mirror, Sensor mirror

	//------------------------------------------------------------------
	// Format Control [0x4300 - 0x430D]
	//------------------------------------------------------------------
	// FORMAT CONTROL 00
	// [7:4] Output format of formatter module
	// [3:0] Output sequence
	Ov5640_I2cWrite(0x4300, 0x30); // YUV422, YUYV...

	//------------------------------------------------------------------
	// MIPI control [0x4800 - 0x4837]
	//------------------------------------------------------------------
	// MIPI CTRL 00
	// [7:6] Debug mode
	// [5  ] Clock lane gate enable
	// [4  ] Line sync enable
	// [3  ] Lane select
	// [2  ] Idle status
	// [1:0] Debug mode
	Ov5640_I2cWrite(0x4800, 0x04); // free running, no short packet, lane1 default, LP11

	// PCLK PERIOD
	// not sure how to calculate this value.
	// values between 7 to 22 seems working.
	Ov5640_I2cWrite(0x4837, 18); // PCLK = 111MHz (18 * 0.5  = 9.0ns)

	//------------------------------------------------------------------
	// ISP Top Control [0x5000 - 0x5063]
	//------------------------------------------------------------------
	// ISP CONTROL 00
	// [7  ] LENC correction enable
	// [6  ] Debug mode
	// [5  ] RAW GMA enable
	// [4:3] Debug mode
	// [2  ] Black pixel cancellation enable
	// [1  ] Whtie pixel cancellation enable
	// [0  ] Color interpolation enable
	Ov5640_I2cWrite(0x5000, 0xD7); // B/W pixel cancellation enable, Color interpolation enable

	// ISP CONTROL 01
	// [7  ] Special digital effect enable
	// [6  ] Debug mode
	// [5  ] Scale enable
	// [4:3] Debug mode
	// [2  ] UV average enable
	// [1  ] Color matrix enable
	// [0  ] Auto white balance enable
	Ov5640_I2cWrite(0x5001, 0x03); // Color matrix enable, Auto white balance enable

	// FORMAT MUX CONTROL
	// [7:4] Debug mode
	// [3  ] Fmt vfirst
	// [2:0] Format select
	// Format MUX Control
	Ov5640_I2cWrite(0x501F, 0x00); // ISP YUV422

	// PRE ISP TEST SETTING 1
	// [7  ] Pre ISP enable
	// [6  ] Rolling
	// [5  ] Transparent
	// [4  ] Square BW
	// [3:2] Pre ISP bar style
	// [1:0] Test select
	switch (test_mode) {
	case OV5640_TEST_COLORBAR:
		Ov5640_I2cWrite(0x503D, 0x80);
		break;
	default:
		Ov5640_I2cWrite(0x503D, 0x00); // test disable (default)
		break;
	}

	// Unknown settings
	// removing these settings results in strange saturation
	Ov5640_I2cWrite(0x3618, 0x00);
	Ov5640_I2cWrite(0x3612, 0x29);
	Ov5640_I2cWrite(0x3708, 0x64);
	Ov5640_I2cWrite(0x3709, 0x52);
	Ov5640_I2cWrite(0x370C, 0x03);
};

//=============================================================================
//! OV5640 Set Image Format
//-----------------------------------------------------------------------------
//! @param resolution	Resolution mode chosen from OV5640_RESOLUTION
//! @param fps			Target FPS value
//-----------------------------------------------------------------------------
//! @brief This function contains register settings which depends of the
//! resolution and FPS.
//-----------------------------------------------------------------------------
//! @note Channel must be set properly in I2C expander (TCA9548A).
//! @note Only resolution 640x480 is tested.
//=============================================================================
void Ov5640_Format (int resolution, double fps) {

	//------------------------------------------------------------------
	// System and IO Pad Control [0x3000 - 0x3052]
	//------------------------------------------------------------------
	// SC PLL CONTRL1
	// [7:4] System clock divider
	// [3:0] Scale divider for MIPI
	Ov5640_I2cWrite(0x3035, 0x21);

	// SC PLL CONTRL2
	// [7:0] PLL multiplier
	// this formula is derived experimentally and only available for 640x480
	double tmpd = (70.0 / 75.0) * fps;
	unsigned char tmpc = (unsigned char)tmpd;
	Ov5640_I2cWrite(0x3036, tmpc);

	// SC PLL CONTRL3
	// [7:5] Debug mode
	// [4  ] PLL root divider
	// [3:0] PLL pre-divider
	Ov5640_I2cWrite(0x3037, 0x05);

	//------------------------------------------------------------------
	// Timing Control [0x3800 - 0x3821]
	//------------------------------------------------------------------
	int x_addr_stt, x_addr_end;
	int y_addr_stt, y_addr_end;
	int output_width;
	int output_height;
	int total_h_size;
	int total_v_size;

	// not tested except 640x480
	switch (resolution) {
	case OV5640_RESOLUTION_640_480:
		x_addr_stt    =    0;
		x_addr_end    = 2623;
		y_addr_stt    =    4;
		y_addr_end    = 1947;
		output_width  =  640;
		output_height =  480;
		total_h_size  = 1896;
		total_v_size  =  984;
		break;
	case OV5640_RESOLUTION_1920_1080:
		output_width  = 1920;
		output_height = 1080;
		break;
	case OV5640_RESOLUTION_1280_720:
		output_width  = 1280;
		output_height =  720;
		break;
	case OV5640_RESOLUTION_960_540:
		output_width  =  960;
		output_height =  540;
		break;
	case OV5640_RESOLUTION_640_360:
		output_width  =  640;
		output_height =  360;
		break;
	case OV5640_RESOLUTION_320_240:
		output_width  =  320;
		output_height =  240;
		break;
	case OV5640_RESOLUTION_320_200:
		output_width  =  320;
		output_height =  200;
		break;
	default:
		x_addr_stt    =    0;
		x_addr_end    = 2623;
		y_addr_stt    =    4;
		y_addr_end    = 1947;
		output_width  =  640;
		output_height =  480;
		total_h_size  = 1896;
		total_v_size  =  984;
		break;
	}

	// X/Y Start Address
	Ov5640_I2cWrite(0x3800, (x_addr_stt >> 8) & 0x0F);
	Ov5640_I2cWrite(0x3801,  x_addr_stt       & 0xFF);
	Ov5640_I2cWrite(0x3802, (y_addr_stt >> 8) & 0x0F);
	Ov5640_I2cWrite(0x3803,  y_addr_stt       & 0xFF);

	// X/Y End Address
	Ov5640_I2cWrite(0x3804, (x_addr_end >> 8) & 0x0F);
	Ov5640_I2cWrite(0x3805,  x_addr_end       & 0xFF);
	Ov5640_I2cWrite(0x3806, (y_addr_end >> 8) & 0x0F);
	Ov5640_I2cWrite(0x3807,  y_addr_end       & 0xFF);

	// Output Width/Height
	Ov5640_I2cWrite(0x3808, (output_width >> 8) & 0x0F);
	Ov5640_I2cWrite(0x3809,  output_width       & 0xFF);
	Ov5640_I2cWrite(0x380A, (output_height >> 8) & 0x07);
	Ov5640_I2cWrite(0x380B,  output_height       & 0xFF);

	// Total H/V Size
	Ov5640_I2cWrite(0x380C, (total_h_size >> 8) & 0x1F);
	Ov5640_I2cWrite(0x380D,  total_h_size       & 0xFF);
	Ov5640_I2cWrite(0x380E, (total_v_size >> 8) & 0xFF);
	Ov5640_I2cWrite(0x380F,  total_v_size       & 0xFF);

	// TIMING X INC
	// [7:4] Horizontal odd subsample increment
	// [3:0] Horizontal even subsample increment
	Ov5640_I2cWrite(0x3814, 0x62);

	// TIMING Y INC
	// [7:4] Vertical odd subsample increment
	// [3:0] Vertical even subsample increment
	Ov5640_I2cWrite(0x3815, 0x62);
};

//=============================================================================
//! OV5640 Initialize
//-----------------------------------------------------------------------------
//! @param test_mode	OV5640_TEST_NORMAL: normal operation,
//!            			OV5640_TEST_COLORBAR: color bar
//! @param resolution	Resolution mode chosen from OV5640_RESOLUTION
//! @param fps			Target FPS value
//-----------------------------------------------------------------------------
//! @brief Top level function regarding to initialization of OV5640.
//-----------------------------------------------------------------------------
//! @note Channel must be set properly in I2C expander (TCA9548A).
//=============================================================================
int Ov5640_Init(int test_mode, int resolution, double fps)
{
	Ov5640_PowerMode(OV5640_POWER_DOWN);

	// common register settings
	Ov5640_RegisterInit(test_mode);

	// format dependant settings
	Ov5640_Format(resolution, fps);

	Ov5640_PowerMode(OV5640_POWER_UP);

	return 0;
}

