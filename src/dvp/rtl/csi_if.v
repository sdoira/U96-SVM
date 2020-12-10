//==========================================================================
// Copyright (C) 2020 Nu-Gate Technology. All rights reserved.
// SPDX-License-Identifier: MIT
//==========================================================================
`timescale 1 ns / 1 ps

module csi_if (
	// Global Control
	rst_n, clk,
	
	// Internal Bus I/F
	ibus_cs,
	ibus_wr,
	ibus_addr,
	ibus_wrdata,
	ibus_rddata,
	
	// CSI Receiver Control
	vrst_n,
	
	// AXI Stream Input
	tvalid_in,
	tready_in,
	tuser_in,
	tlast_in,
	tdata_in,
	tdest_in,
	tkeep_in,
	
	// AXI Stream Output
	tvalid_out,
	tready_out,
	tuser_out,
	tlast_out,
	tdata_out,
	tdest_out,
	tkeep_out
);


//==========================================================================
// Port Declaration
//==========================================================================
// Global Control
input			rst_n, clk;

// Internal Bus I/F
input			ibus_cs;
input			ibus_wr;
input	[7:0]	ibus_addr;
input	[31:0]	ibus_wrdata;
output	[31:0]	ibus_rddata;

// CSI Receiver Control
output			vrst_n;

// AXI Stream Input
input			tvalid_in;
output			tready_in;
input			tuser_in;
input			tlast_in;
input	[15:0]	tdata_in;
input	[3:0]	tdest_in;
input	[3:0]	tkeep_in;

// AXI Stream Output
output			tvalid_out;
input			tready_out;
output			tuser_out;
output			tlast_out;
output	[15:0]	tdata_out;
output	[3:0]	tdest_out;
output	[3:0]	tkeep_out;


//==========================================================================
// Reg/Wire Declaration
//==========================================================================
// Register Interface
reg				ctrl;
reg		[3:0]	ptn_sel;
wire			vrst_n;
wire	[31:0]	ibus_rddata;

// Frame Format Measurement
reg				tlast_in_r;
reg		[15:0]	col, col_r;
wire			sof;
reg		[15:0]	row, row_r;
reg		[31:0]	frm_len, frm_len_r;
reg		[31:0]	frm_cnt;

// Test Pattern Generator
reg		[7:0]	ptn1, ptn2, ptn3;
reg		[12:0]	ptn4_cnt1;
reg		[2:0]	ptn4_cnt2;
wire	[15:0]	ptn4;
wire	[7:0]	ptn5;

// Output Selector
reg				tvalid_out;
reg				tready_in;
reg				tuser_out, tlast_out;
reg		[15:0]	tdata_out;
reg		[3:0]	tdest_out, tkeep_out;


//==========================================================================
// Register Interface
//==========================================================================
always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		ctrl    <= 1'b0;
		ptn_sel <= 4'b0;
	end
	else begin
		if (ibus_cs & ibus_wr) begin
			case (ibus_addr[7:2])
				6'h00: ctrl    <= ibus_wrdata[    0];
				6'h03: ptn_sel <= ibus_wrdata[ 3: 0];
				default: begin
					ctrl    <= ctrl;
					ptn_sel <= ptn_sel;
				end
			endcase
		end
	end
end

assign vrst_n = ctrl;

assign ibus_rddata[31:0] = (
	(~ibus_cs)               ?  32'b0 :
	(ibus_addr[7:2] == 6'h0) ? {31'b0, ctrl} :
	(ibus_addr[7:2] == 6'h1) ?  32'b0 :
	(ibus_addr[7:2] == 6'h2) ? {row_r[15:0], col_r[15:0]} :
	(ibus_addr[7:2] == 6'h3) ? {28'b0, ptn_sel[3:0]} :
	(ibus_addr[7:2] == 6'h4) ? {frm_len_r[31:0]} :
	(ibus_addr[7:2] == 6'h5) ? {frm_cnt[31:0]} :
	                            32'b0
);


//==========================================================================
// Frame Format Measurement
//==========================================================================
always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		tlast_in_r <= 1'b0;
	end
	else begin
		tlast_in_r <= tlast_in;
	end
end

// column count
always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		col <= 16'b0;
	end
	else begin
		if (~vrst_n) begin
			col <= 0;
		end
		else if (tlast_in_r) begin
			col <= 0;
		end
		else if (tvalid_in) begin
			col <= col + 1'b1;
		end
	end
end

always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		col_r <= 16'b0;
	end
	else begin
		if (~vrst_n) begin
			col_r <= 0;
		end
		else if (tlast_in_r) begin
			col_r <= col;
		end
	end
end

assign sof = tuser_in; // start of frame

// row count
always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		row <= 16'b0;
	end
	else begin
		if (sof) begin
			row <= 0;
		end
		else if (tlast_in) begin
			row <= row + 1'b1;
		end
	end
end

always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		row_r <= 16'b0;
	end
	else begin
		if (~vrst_n) begin
			row_r <= 0;
		end
		else if (sof) begin
			row_r <= row;
		end
	end
end

// interval between sof
always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		frm_len <= 32'b0;
	end
	else begin
		if (~vrst_n | sof) begin
			frm_len <= 0;
		end
		else begin
			frm_len <= frm_len + 1'b1;
		end
	end
end

always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		frm_len_r <= 32'b0;
	end
	else begin
		if (~vrst_n) begin
			frm_len_r <= 0;
		end
		else if (sof) begin
			frm_len_r <= frm_len;
		end
	end
end

// accumulative number of frames
always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		frm_cnt <= 32'b0;
	end
	else begin
		if (~vrst_n) begin
			frm_cnt <= 0;
		end
		else if (sof) begin
			frm_cnt <= frm_cnt + 1'b1;
		end
	end
end


//==========================================================================
// Test Pattern Generator
//==========================================================================
// Pattern1: horizontal incremental
always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		ptn1 <= 8'b0;
	end
	else begin
		if (sof | tlast_in) begin
			ptn1 <= 0;
		end
		else if (tvalid_in) begin
			ptn1 <= ptn1 + 1'b1;
		end
	end
end

// Pattern2: vertical incremental
always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		ptn2 <= 8'b0;
	end
	else begin
		if (sof) begin
			ptn2 <= 0;
		end
		else if (tlast_in) begin
			ptn2 <= ptn2 + 1'b1;
		end
	end
end

// Pattern3: frame incremental
always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		ptn3 <= 8'b0;
	end
	else begin
		if (sof) begin
			ptn3 <= ptn3 + 1'b1;
		end
	end
end

// Pattern4: color bar
always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		ptn4_cnt1 <= 13'b0; // bar width (1/8 total width)
		ptn4_cnt2 <=  3'b0; // color
	end
	else begin
		if (sof | tlast_in) begin
			ptn4_cnt1 <= 0;
			ptn4_cnt2 <= 0;
		end
		else if (tvalid_in) begin
			if (ptn4_cnt1 == col_r[15:3] - 1'b1) begin
				ptn4_cnt1 <= 0;
				ptn4_cnt2 <= ptn4_cnt2 + 1'b1;
			end
			else begin
				ptn4_cnt1 <= ptn4_cnt1 + 1'b1;
			end
		end
	end
end

//   Wh  Ye  Cy  Gr  Mg  Rd  Bl  Bk
// Y 255 255 215 199  79  63  15   0
// U 128   0 223   0 255  32 255 128
// V 128 143   0   0 255 255 112 128
assign ptn4[15:8] = ( // Y
	(ptn4_cnt2[2:0] == 0) ? 255 :
	(ptn4_cnt2[2:0] == 1) ? 255 :
	(ptn4_cnt2[2:0] == 2) ? 215 :
	(ptn4_cnt2[2:0] == 3) ? 199 :
	(ptn4_cnt2[2:0] == 4) ?  79 :
	(ptn4_cnt2[2:0] == 5) ?  63 :
	(ptn4_cnt2[2:0] == 6) ?  15 :
	                          0
);
assign ptn4[7:0] = ( // U/V
	(ptn4_cnt2[2:0] == 0) ? ((~col[0]) ? 128 : 128) :
	(ptn4_cnt2[2:0] == 1) ? ((~col[0]) ?   0 : 143) :
	(ptn4_cnt2[2:0] == 2) ? ((~col[0]) ? 223 :   0) :
	(ptn4_cnt2[2:0] == 3) ? ((~col[0]) ?   0 :   0) :
	(ptn4_cnt2[2:0] == 4) ? ((~col[0]) ? 255 : 255) :
	(ptn4_cnt2[2:0] == 5) ? ((~col[0]) ?  32 : 255) :
	(ptn4_cnt2[2:0] == 6) ? ((~col[0]) ? 255 : 112) :
	                        ((~col[0]) ? 128 : 128)
);

// Pattern5: grid (64-pix)
assign ptn5[7:0] = (col[6] ^ row[6]) ? 8'd0 : 8'd255;


//==========================================================================
// Output Selector
//==========================================================================
always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		tvalid_out <=  1'b0;
		tready_in  <=  1'b0;
		tuser_out  <=  1'b0;
		tlast_out  <=  1'b0;
		tdata_out  <= 16'b0;
		tdest_out  <=  4'b0;
		tkeep_out  <=  4'b0;
	end
	else begin
		tvalid_out <= tvalid_in;
		tready_in  <= tready_out;
		tuser_out  <= tuser_in;
		tlast_out  <= tlast_in;
		tdata_out  <= (
			(~tvalid_in)        ? 16'h0080           :
			(ptn_sel[3:0] == 0) ? tdata_in[15:0]     :
			(ptn_sel[3:0] == 1) ? {ptn1[7:0], 8'h80} :
			(ptn_sel[3:0] == 2) ? {ptn2[7:0], 8'h80} :
			(ptn_sel[3:0] == 3) ? {ptn3[7:0], 8'h80} :
			(ptn_sel[3:0] == 4) ?  ptn4[15:0]        :
			(ptn_sel[3:0] == 5) ? {ptn5[7:0], 8'h80} :
			                      tdata_in[15:0]
		);
		tdest_out  <= tdest_in[3:0];
		tkeep_out  <= tkeep_in[3:0];
	end
end



endmodule
