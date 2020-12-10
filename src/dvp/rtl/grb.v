//==========================================================================
// Copyright (C) 2020 Nu-Gate Technology. All rights reserved.
// SPDX-License-Identifier: MIT
//==========================================================================
`timescale 1 ns / 1 ps

module grb # (
	parameter integer POSITION = 0 // L = 0, R = 1
) (
	// Global Control
	rst_n, clk,
	
	// Parameter
	hgt_m1,
	wdt,
	
	// Internal Bus I/F
	ibus_cs,
	ibus_wr,
	ibus_addr,
	ibus_wrdata,
	ibus_rddata,
	
	// AXI Stream Input
	csi_tdata,
	csi_tdest,
	csi_tuser,
	csi_tkeep,
	csi_tvalid,
	csi_tlast,
	csi_tready,
	
	// Arbiter I/F
	dwr_req,
	dwr_ack,
	dwr_dout,
	dwr_vout
);


//==========================================================================
// Port Declaration
//==========================================================================
// Global Control
input			rst_n, clk;

// Parameter
input	[10:0]	hgt_m1, wdt;

// Internal Bus I/F
input			ibus_cs;
input			ibus_wr;
input	[7:0]	ibus_addr;
input	[31:0]	ibus_wrdata;
output	[31:0]	ibus_rddata;

// AXI Stream Input
input	[15:0]	csi_tdata;
input	[3:0]	csi_tdest;
input			csi_tuser;
input	[3:0]	csi_tkeep;
input			csi_tvalid;
input			csi_tlast;
output			csi_tready;

// Arbiter I/F
output			dwr_req;
input			dwr_ack;
output	[31:0]	dwr_dout;
output			dwr_vout;


//==========================================================================
// Reg/Wire Declaration
//==========================================================================
// Register Interface
reg				ctrl;
reg		[10:0]	addr_a, addr_b, addr_c;
reg		[7:0]	bst_len_m1;
wire	[8:0]	bst_len;
wire	[31:0]	ibus_rddata;
wire			enb;
reg				trig;

// AXI4 Interface
wire			csi_tready, sof;

// FIFO Write
reg				trig_hold;
reg				grb_on;
wire			data_valid;
reg		[15:0]	csi_tdata_r;
reg				wr_phase;
wire			fifo_wr;
wire	[31:0]	fifo_din;

// FIFO Instance
wire			fifo_full;
wire	[10:0]	fifo_cnt;
wire	[31:0]	fifo_dout;
wire			fifo_empty;
reg				fifo_ovf, fifo_udf;

// FIFO Read
wire			data_rdy;
reg		[1:0]	state;
reg		[7:0]	bst_cnt;
wire			bst_end;

// Frame Buffer Control
wire	[10:0]	next_col;
reg		[10:0]	col_cnt;
wire			col_end;
reg		[10:0]	row_cnt;
wire			row_end, frm_end;
reg		[1:0]	bank, bank_r;
reg				last_bst;

// DDR Write Request
reg				dwr_req;
wire			fifo_rd;
wire			cmd_phase, addr_phase;
reg				data_phase;
reg		[30:0]	addr;
wire			dwr_vout;
wire	[31:0]	dwr_dout;


//==========================================================================
// Register Interface
//==========================================================================
always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		ctrl       <=  1'b0;
		addr_a     <= 11'h200;
		addr_b     <= 11'h214;
		addr_c     <= 11'h218;
		bst_len_m1 <=  8'd63; // burst length minus 1
	end
	else begin
		if (ibus_cs & ibus_wr) begin
			case (ibus_addr[7:2])
				6'h00: ctrl       <= ibus_wrdata[    0];
				6'h02: addr_a     <= ibus_wrdata[30:20];
				6'h03: addr_b     <= ibus_wrdata[30:20];
				6'h04: addr_c     <= ibus_wrdata[30:20];
				6'h05: bst_len_m1 <= ibus_wrdata[ 7: 0];
				default: begin
					ctrl       <= ctrl;
					addr_a     <= addr_a;
					addr_b     <= addr_b;
					addr_c     <= addr_c;
					bst_len_m1 <= bst_len_m1;
				end
			endcase
		end
	end
end

assign bst_len[8:0] = bst_len_m1 + 1'b1; // actual length

assign ibus_rddata[31:0] = (
	(~ibus_cs)               ?  32'b0 :
	(ibus_addr[7:2] == 6'h0) ? {31'b0, ctrl} :
	(ibus_addr[7:2] == 6'h1) ? {22'b0, bank_r[1:0], 5'b0, grb_on, fifo_udf, fifo_ovf} :
	(ibus_addr[7:2] == 6'h2) ? {1'b0, addr_a[10:0], 20'b0} :
	(ibus_addr[7:2] == 6'h3) ? {1'b0, addr_b[10:0], 20'b0} :
	(ibus_addr[7:2] == 6'h4) ? {1'b0, addr_c[10:0], 20'b0} :
	(ibus_addr[7:2] == 6'h5) ? {24'b0, bst_len_m1[7:0]} :
	                           32'b0
);

assign enb = ctrl;

always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		trig <= 1'b0;
	end
	else begin
		if (ibus_cs & ibus_wr & (ibus_addr[7:2] == 6'h6)) begin
			trig <= 1'b1;
		end
		else begin
			trig <= 1'b0;
		end
	end
end


//==========================================================================
// AXI4 Interface
//--------------------------------------------------------------------------
// tuser bit assignment
// [95:80] CRC
// [79:72] ECC
// [71:70] Reserved
// [69:64] Data Type
// [63:48] Word Count
// [47:32] Line Number
// [31:16] Frame Number
// [15: 2] Reserved
// [    1] Packet Error
// [    0] Start of Frame
//==========================================================================
assign csi_tready = 1'b1;
assign sof = csi_tuser;


//==========================================================================
// FIFO Write
//==========================================================================
always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		trig_hold <= 1'b0;
	end
	else begin
		if (sof) begin
			trig_hold <= 1'b0;
		end
		else if (trig) begin
			trig_hold <= 1'b1;
		end
	end
end

always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		grb_on <= 1'b0;
	end
	else begin
		if (~enb) begin
			grb_on <= 1'b0;
		end
		else if (trig_hold & sof) begin
			grb_on <= 1'b1;
		end
	end
end

assign data_valid = ((trig_hold & sof) | grb_on) & csi_tvalid;

always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		csi_tdata_r <= 16'b0;
	end
	else begin
		if (~enb) begin
			csi_tdata_r <= 0;
		end
		else if (data_valid) begin
			csi_tdata_r <= csi_tdata;
		end
	end
end

always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		wr_phase <= 1'b0;
	end
	else begin
		if (~enb) begin
			wr_phase <= 1'b0;
		end
		else if (data_valid) begin
			wr_phase <= ~wr_phase;
		end
	end
end

assign fifo_wr = wr_phase;

// little endian for USB
assign fifo_din[31:0] = {
	csi_tdata[ 7:0],
	csi_tdata[15:8],
	csi_tdata_r[ 7:0],
	csi_tdata_r[15:8]
};


//==========================================================================
// FIFO Instance
//==========================================================================
// 32-bits x 2048 words FIFO
grb_fifo grb_fifo (
	// Common
	.srst (~enb),
	.clk  (clk),
	
	// Write Port
	.din    (fifo_din[31:0]),
	.wr_en  (fifo_wr),
	.full   (fifo_full),
	.data_count  (fifo_cnt[10:0]),
	.wr_rst_busy (),
	
	// Read Port
	.rd_en  (fifo_rd),
	.dout   (fifo_dout[31:0]),
	.empty  (fifo_empty),
	.rd_rst_busy   ()
);

always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		fifo_ovf <= 1'b0;
	end
	else begin
		if (~enb) begin
			fifo_ovf <= 1'b0;
		end
		else if (fifo_full & fifo_wr) begin
			fifo_ovf <= 1'b1;
		end
	end
end

always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		fifo_udf <= 1'b0;
	end
	else begin
		if (~enb) begin
			fifo_udf <= 1'b0;
		end
		else if (fifo_empty & fifo_rd) begin
			fifo_udf <= 1'b1;
		end
	end
end


//==========================================================================
// FIFO Read
//==========================================================================
assign data_rdy = (fifo_cnt[10:0] > bst_len_m1[7:0]);

always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		state <= 2'b0;
	end
	else begin
		if (~enb) begin
			state <= 0;
		end
		else begin
			case (state)
				0: if (data_rdy) state <= 1;
				1: if (dwr_ack)  state <= 2;
				2: if (bst_end)  state <= 3;
				3:               state <= 0;
			endcase
		end
	end
end

always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		bst_cnt <= 8'b0;
	end
	else begin
		if (state == 2) begin
			if (bst_end) begin
				bst_cnt <= 0;
			end
			else begin
				bst_cnt <= bst_cnt + 1'b1;
			end
		end
		else begin
			bst_cnt <= 0;
		end
	end
end

assign bst_end = (state == 2) & (bst_cnt == bst_len_m1);


//==========================================================================
// Frame Buffer Control
//==========================================================================
assign next_col[10:0] = col_cnt[10:0] + bst_len[8:0];

always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		col_cnt <= 11'b0;
	end
	else begin
		if (~enb | sof) begin
			col_cnt <= 0;
		end
		else if (bst_end) begin
			if (col_end) begin
				col_cnt <= 0;
			end
			else begin
				col_cnt <= next_col;
			end
		end
	end
end

//assign col_end = bst_end & (next_col > wdt_m1);
assign col_end = (next_col >= wdt[10:1]);

always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		row_cnt <= 11'b0;
	end
	else begin
		if (~enb | sof) begin
			row_cnt <= 0;
		end
		else if (bst_end & col_end) begin
			row_cnt <= row_cnt + 1'b1;
		end
	end
end

assign row_end = (row_cnt == hgt_m1);
assign frm_end = bst_end & col_end & row_end;

always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		bank <= 2'b0;
	end
	else begin
		if (~enb) begin
			bank <= 0;
		end
		else if (frm_end) begin
			if (bank == 2) begin
				bank <= 0;
			end
			else begin
				bank <= bank + 1'b1;
			end
		end
	end
end

always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		bank_r <= 2'b0;
	end
	else begin
		if (~enb) begin
			bank_r <= 0;
		end
		else if (frm_end) begin
			bank_r <= bank;
		end
	end
end

always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		last_bst <= 1'b0;
	end
	else begin
		//if ((next_col > wdt_m1) & row_end) begin
		if (col_end & row_end) begin
			last_bst <= 1'b1;
		end
		else begin
			last_bst <= 1'b0;
		end
	end
end


//==========================================================================
// DDR Write Request
//==========================================================================
always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		dwr_req <= 1'b0;
	end
	else begin
		if (~enb) begin
			dwr_req <= 1'b0;
		end
		else if ((state == 0) & data_rdy) begin
			dwr_req <= 1'b1;
		end
		else if (state == 3) begin
			dwr_req <= 1'b0;
		end
	end
end

assign fifo_rd = (state == 2);

assign cmd_phase = (state == 1) & dwr_ack;
assign addr_phase = (state == 2) & (bst_cnt == 0);

always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		data_phase <= 1'b0;
	end
	else begin
		data_phase <= fifo_rd;
	end
end

always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		addr <= 31'b0;
	end
	else begin
		if (~enb) begin
			addr <= 0;
		end
		else if (sof) begin
			if (POSITION == 0) begin
				case (bank)
					0: addr <= {addr_a[10:0], 20'b0};
					1: addr <= {addr_b[10:0], 20'b0};
					2: addr <= {addr_c[10:0], 20'b0};
					default: addr <= {addr_a[10:0], 20'b0};
				endcase
			end
			else begin
				case (bank)
					0: addr <= {addr_a[10:0], 8'b0, wdt[10:0], 1'b0};
					1: addr <= {addr_b[10:0], 8'b0, wdt[10:0], 1'b0};
					2: addr <= {addr_c[10:0], 8'b0, wdt[10:0], 1'b0};
					default: addr <= {addr_a[10:0], 8'b0, wdt[10:0], 1'b0};
				endcase
			end
		end
		else if (bst_end) begin
			if (col_end) begin
				addr <= addr + {bst_len[8:0], 2'b00} + {wdt[10:0], 1'b0};
			end
			else begin
				addr <= addr + {bst_len[8:0], 2'b00};
			end
		end
	end
end

assign dwr_vout = cmd_phase | addr_phase | data_phase;
assign dwr_dout[31:0] = (
	(cmd_phase)  ? {22'b0, last_bst, 1'b0, bst_len_m1[7:0]} :
	(addr_phase) ? {1'b0, addr[30:0]} :
	(data_phase) ? fifo_dout[31:0] :
	               32'b0
);


endmodule
