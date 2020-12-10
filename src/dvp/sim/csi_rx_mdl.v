//==========================================================================
// Copyright (C) 2020 Nu-Gate Technology. All rights reserved.
// SPDX-License-Identifier: MIT
//==========================================================================
`timescale 1ns / 1ps

module csi_rx_mdl # (
	parameter integer WDT = 640,
	parameter integer HGT = 480
) (
	// Global Control
	clk,
	
	// Control
	enb,
	
	// AXI Stream Output
	tvalid,
	tready,
	tuser,
	tlast,
	tdata,
	tdest,
	tkeep
);


//==========================================================================
// Parameter Settings
//==========================================================================
// FPGA Version
localparam WDT_BLK = (HGT > 100) ? HGT / 10 : 10;


//==========================================================================
// Port Declaration
//==========================================================================
// Global Control
input			clk;

// Control
input			enb;

// AXI Stream Output
output			tvalid;
input			tready;
output			tuser;
output			tlast;
output	[31:0]	tdata;
output	[3:0]	tdest;
output	[3:0]	tkeep;


//==========================================================================
// Reg/Wire Declaration
//==========================================================================
// Control
integer			phase;
wire			act;
integer			hcnt;
wire			hcnt_end;
integer			vcnt;
wire			vcnt_end;

// AXI4 Stream Interface
wire			sof;


//==========================================================================
// Control
//==========================================================================
initial begin
	phase <= 0;
	forever @(posedge clk) begin
		if (enb) begin
			if (tready) begin
				phase <= phase + 1;
			end
		end
		else begin
			phase <= 0;
		end
	end
end

assign act = phase[3];

initial begin
	hcnt <= 0;
	forever @(posedge clk) begin
		if (enb) begin
			if (act) begin
				if (hcnt_end) begin
					hcnt <= 0;
				end
				else begin
					hcnt <= hcnt + 1;
				end
			end
		end
		else begin
			hcnt <= 0;
		end
	end
end

assign hcnt_end = (hcnt == WDT + WDT_BLK - 1);

initial begin
	vcnt <= 0;
	forever @(posedge clk) begin
		if (enb) begin
			if (act) begin
				if (hcnt_end) begin
					if (vcnt_end) begin
						vcnt <= 0;
					end
					else begin
						vcnt <= vcnt + 1;
					end
				end
			end
		end
		else begin
			vcnt <= 0;
		end
	end
end

assign vcnt_end = (vcnt == HGT - 1);


//==========================================================================
// AXI4 Stream Interface
//==========================================================================
assign sof = (enb & act & (hcnt == 0) & (vcnt == 0));

assign tvalid = enb & act & (hcnt < WDT);
assign tuser = sof;
assign tlast = enb & (hcnt == WDT - 1);
assign tdata[31:0] = (tvalid) ? hcnt : 32'b0;
assign tdest[3:0] = 0;
assign tkeep[3:0] = 4'hF;


endmodule
