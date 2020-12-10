/***************************************************************************
* Copyright (C) 2020 Nu-Gate Technology. All rights reserved.
* SPDX-License-Identifier: GPL-3.0-or-later
 ***************************************************************************/
`timescale 1 ns / 1 ps

module arb (
	// Global Control
	rst_n, clk,
	
	// Internal Bus I/F
	ibus_cs,
	ibus_wr,
	ibus_addr,
	ibus_wrdata,
	ibus_rddata,
	
	// Status
	done,
	
	// FIFO I/F
	req,
	ack,
	valid_in,
	data_in,
	strb_in,
	valid_out,
	data_out,
	
	// AXI I/F
	axi_aclk,
	axi_awaddr,
	axi_awlen,
	axi_awvalid,
	axi_awready,
	axi_wdata,
	axi_wstrb,
	axi_wvalid,
	axi_wready,
	axi_wlast,
	axi_araddr,
	axi_arlen,
	axi_arvalid,
	axi_arready,
	axi_rdata,
	axi_rvalid,
	axi_rready,
	axi_rlast,
	axi_bvalid,
	axi_bready
);


//==========================================================================
// Parameter Settings
//==========================================================================
parameter NR = 6; // number of requests


//==========================================================================
// Port Declaration
//==========================================================================
// Global Control
input				rst_n, clk;

// Internal Bus I/F
input				ibus_cs;
input				ibus_wr;
input	[7:0]		ibus_addr;
input	[31:0]		ibus_wrdata;
output	[31:0]		ibus_rddata;

// Status
output	[NR-1:0]	done;

// FIFO I/F
input	[NR-1:0]	req;
output	[NR-1:0]	ack;
input				valid_in;
input	[31:0]		data_in;
input	[3:0]		strb_in;
output				valid_out;
output	[31:0]		data_out;

// AXI I/F
input				axi_aclk;
output	[31:0]		axi_awaddr;
output	[7:0]		axi_awlen;
output				axi_awvalid;
input				axi_awready;
output	[31:0]		axi_wdata;
output	[3:0]		axi_wstrb;
output				axi_wvalid;
input				axi_wready;
output				axi_wlast;
output	[31:0]		axi_araddr;
output	[7:0]		axi_arlen;
output				axi_arvalid;
input				axi_arready;
input	[31:0]		axi_rdata;
input				axi_rvalid;
output				axi_rready;
input				axi_rlast;
input				axi_bvalid;
output				axi_bready;


//==========================================================================
// Reg/Wire Declaration
//==========================================================================
// Register Interface
reg		[3:0]		ctrl;
wire	[31:0]		ibus_rddata;
wire				fifo_enb;

// Arbiter
reg		[NR-1:0]	ack;
wire				busy;
reg		[NR-1:0]	ack_r;

// FIFO Instance
wire				fifo_wr;
wire	[35:0]		fifo_din;
wire	[35:0]		fifo_dout;
wire				fifo_full;
wire				fifo_empty;
reg					fifo_ovf;
reg					fifo_udf;

// FIFO Read
wire				axi_ready;
wire				fifo_rd;
reg		[2:0]		rd_state;
wire				last_bit;
wire				rd_wrn;
wire	[7:0]		bst_len_m1;
reg					last_bit_r;
reg					rd_wrn_r;
reg		[7:0]		bst_len_m1_r;
reg		[7:0]		bst_cnt;
wire				bst_end;
wire	[NR-1:0]	done;

// AXI Write Interface
reg					axi_awvalid;
wire	[31:0]		axi_awaddr;
reg					axi_wvalid;
wire	[3:0]		axi_wstrb;
wire	[31:0]		axi_wdata;
wire	[7:0]		axi_awlen;
reg					axi_wlast;
reg					axi_bready;

// AXI Read Interface
reg					axi_arvalid;
wire	[31:0]		axi_araddr;
wire				axi_rready;
wire	[7:0]		axi_arlen;
wire	[31:0]		data_out;
wire				valid_out;


//==========================================================================
// Register Interface
//==========================================================================
always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		ctrl <= 4'b0001;
	end
	else begin
		if (ibus_cs & ibus_wr) begin
			case (ibus_addr[7:2])
				6'h00: ctrl <= ibus_wrdata[3:0];
				default: begin
					ctrl <= ctrl;
				end
			endcase
		end
	end
end

assign ibus_rddata[31:0] = (
	(~ibus_cs)              ?  32'b0 :
	(ibus_addr[7:2] == 6'h0) ? {28'b0, ctrl[3:0]} :
	(ibus_addr[7:2] == 6'h1) ? {30'b0, fifo_udf, fifo_ovf} :
	                           32'b0
);

assign fifo_enb = ctrl[0];


//==========================================================================
// Arbiter
//==========================================================================
always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		ack <= {NR{1'b0}};
	end
	else begin
		if (~busy) begin
			if      (req[0]) ack[0] <= 1'b1; // grb
			else if (req[1]) ack[1] <= 1'b1; // 
			else if (req[3]) ack[3] <= 1'b1; // 
			else if (req[2]) ack[2] <= 1'b1; // 
			else if (req[4]) ack[4] <= 1'b1; // 
			else if (req[5]) ack[5] <= 1'b1; // 
		end
		else if (ack[0]) ack[0] <= req[0];
		else if (ack[1]) ack[1] <= req[1];
		else if (ack[2]) ack[2] <= req[2];
		else if (ack[3]) ack[3] <= req[3];
		else if (ack[4]) ack[4] <= req[4];
		else if (ack[5]) ack[5] <= req[5];
	end
end

assign busy = |ack[NR-1:0] | (rd_state != 0);

always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		ack_r <= {NR{1'b0}};
	end
	else begin
		if (rd_state == 1) begin
			ack_r <= ack;
		end
	end
end


//==========================================================================
// FIFO Instance
//==========================================================================
assign fifo_wr  = valid_in;
assign fifo_din[35:0] = {strb_in[3:0], data_in[31:0]};

// 36-bits x 512 words FIFO
arb_fifo arb_fifo (
	// Common
	.clk   (clk),
	.srst  (~fifo_enb),
	
	// Write Port
	.din   (fifo_din[35:0]),
	.wr_en (fifo_wr),
	.full  (fifo_full),
	.wr_rst_busy (),
	
	// Read Port
	.rd_en (fifo_rd),
	.dout  (fifo_dout[35:0]),
	.empty (fifo_empty),
	.rd_rst_busy ()
);

always @(negedge rst_n or posedge axi_aclk) begin
	if (~rst_n) begin
		fifo_ovf <= 1'b0;
	end
	else begin
		if (~fifo_enb) begin
			fifo_ovf <= 1'b0;
		end
		else if (fifo_full & fifo_wr) begin
			fifo_ovf <= 1'b1;
		end
	end
end

always @(negedge rst_n or posedge axi_aclk) begin
	if (~rst_n) begin
		fifo_udf <= 1'b0;
	end
	else begin
		if (~fifo_enb) begin
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
assign axi_ready = axi_awready & axi_arready;

assign fifo_rd = (
	((rd_state == 0) & ~fifo_empty & axi_ready) |
	((rd_state == 1) & ~fifo_empty) |
	((rd_state == 2) & ~fifo_empty) |
	((rd_state == 3) & ~fifo_empty & axi_wready)
);

always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		rd_state <= 3'b0;
	end
	else begin
		case (rd_state)
			0: if (fifo_rd)      rd_state <= 1;
			1: begin
				if (fifo_rd) begin
					if (~rd_wrn) rd_state <= 2; // write
					else         rd_state <= 5; // read
				end
			end
			2: if (fifo_rd)      rd_state <= 3;
			3: if (bst_end)      rd_state <= 4;
			4: if (axi_bready)   rd_state <= 0;
			5: if (bst_end)      rd_state <= 0;
		endcase
	end
end

assign last_bit   = fifo_dout[9];
assign rd_wrn     = fifo_dout[8];
assign bst_len_m1 = fifo_dout[7:0];

always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		last_bit_r   <= 1'b0;
		rd_wrn_r     <= 1'b0;
		bst_len_m1_r <= 8'b0;
	end
	else begin
		if (rd_state == 1) begin
			last_bit_r   <= last_bit;
			rd_wrn_r     <= rd_wrn;
			bst_len_m1_r <= bst_len_m1;
		end
	end
end

always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		bst_cnt <= 8'b0;
	end
	else begin
		if (~fifo_enb | bst_end) begin
			bst_cnt <= 0;
		end
		else if (
			(((rd_state == 2) | (rd_state == 3)) & fifo_rd) |
			((rd_state == 5) & axi_rvalid)
		) begin
			bst_cnt <= bst_cnt + 1'b1;
		end
	end
end

assign bst_end = (
	((rd_state == 3) & (bst_cnt == bst_len_m1_r)) |
	((rd_state == 5) & (bst_cnt == bst_len_m1_r) & axi_rvalid)
);

assign done[NR-1:0] = (last_bit_r & axi_bready) ? ack_r : {NR{1'b0}};


//==========================================================================
// AXI Write Interface
//==========================================================================
always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		axi_awvalid <= 1'b0;
	end
	else begin
		if ((rd_state == 1) & fifo_rd & ~rd_wrn) begin
			axi_awvalid <= 1'b1;
		end
		else begin
			axi_awvalid <= 1'b0;
		end
	end
end

assign axi_awaddr[31:0] = (axi_awvalid) ? fifo_dout[31:0] : 32'b0;

always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		axi_wvalid <= 1'b0;
	end
	else begin
		if ((rd_state == 2) || (rd_state == 3)) begin
			axi_wvalid <= 1'b1;
		end
		else begin
			axi_wvalid <= 1'b0;
		end
	end
end

assign axi_wstrb[3:0]   = (axi_wvalid) ? fifo_dout[35:32] : 4'hF;
assign axi_wdata[31:0]  = (axi_wvalid) ? fifo_dout[31: 0] : 32'b0;
assign axi_awlen[7:0]   = bst_len_m1_r[7:0];

always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		axi_wlast <= 1'b0;
	end
	else begin
		if (~rd_wrn_r & bst_end) begin
			axi_wlast <= 1'b1;
		end
		else begin
			axi_wlast <= 1'b0;
		end
	end
end

always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		axi_bready <= 1'b0;
	end
	else begin
		if (axi_bready) begin
			axi_bready <= 1'b0;
		end
		else if (axi_bvalid) begin
			axi_bready <= 1'b1;
		end
	end
end


//==========================================================================
// AXI Read Interface
//==========================================================================
always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		axi_arvalid <= 1'b0;
	end
	else begin
		if ((rd_state == 1) & fifo_rd & rd_wrn) begin
			axi_arvalid <= 1'b1;
		end
		else begin
			axi_arvalid <= 1'b0;
		end
	end
end

assign axi_araddr[31:0] = (axi_arvalid) ? fifo_dout[31:0] : 32'b0;
assign axi_rready       = (rd_state == 4);
assign axi_arlen[7:0]   = bst_len_m1_r[7:0];

assign data_out[31:0]  = axi_rdata[31:0];
assign valid_out = axi_rready & axi_rvalid;


//==========================================================================
// Debug
//==========================================================================
wire	[7:0]	tp;
reg		[7:0]	tp_r;
reg				err;

assign tp = axi_wdata[15:8];

always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		tp_r <= 8'hFF;
	end
	else begin
		if (axi_wvalid & axi_wready) begin
			tp_r <= tp;
		end
	end
end

always @(negedge rst_n or posedge clk) begin
	if (~rst_n) begin
		err <= 1'b0;
	end
	else begin
		if (axi_wvalid & axi_wready) begin
			if (tp != tp_r + 1'b1) begin
				err <= 1'b1;
			end
			else begin
				err <= 1'b0;
			end
		end
	end
end


endmodule
