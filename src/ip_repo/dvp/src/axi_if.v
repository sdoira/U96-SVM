/***************************************************************************
* Copyright (C) 2020 Nu-Gate Technology. All rights reserved.
* SPDX-License-Identifier: GPL-3.0-or-later
 ***************************************************************************/
`timescale 1 ns / 1 ps

module axi_if #(
	// Width of S_AXI data bus
	parameter integer C_S_AXI_DATA_WIDTH = 32,
	// Width of S_AXI address bus
	parameter integer C_S_AXI_ADDR_WIDTH = 14,
	
	parameter integer VERSION = 32'h0000
)(
	// AXI Interface
	axi_aclk,
	axi_aresetn,
	axi_awaddr,
	axi_awprot,
	axi_awvalid,
	axi_awready,
	axi_wdata,
	axi_wstrb,
	axi_wvalid,
	axi_wready,
	axi_bresp,
	axi_bvalid,
	axi_bready,
	axi_araddr,
	axi_arprot,
	axi_arvalid,
	axi_arready,
	axi_rdata,
	axi_rresp,
	axi_rvalid,
	axi_rready,
	
	// Memory Mapped Register Interface
	led,
	gpio_in,
	hgt,
	wdt,
	
	// Internal Bus
	addr,
	cs,
	wr,
	wrdata,
	rddata,
	
	// Interrupt
	grb_r_done,
	grb_l_done,
	intr
);

//==========================================================================
// Port Declaration
//==========================================================================
// AXI Interface
input			axi_aclk;
input			axi_aresetn;
input	[13:0]	axi_awaddr;
input	[2:0]	axi_awprot;
input			axi_awvalid;
output			axi_awready;
input	[31:0]	axi_wdata;
input	[3:0]	axi_wstrb;
input			axi_wvalid;
output			axi_wready;
output	[1:0]	axi_bresp;
output			axi_bvalid;
input			axi_bready;
input	[13:0]	axi_araddr;
input	[2:0]	axi_arprot;
input			axi_arvalid;
output			axi_arready;
output	[31:0]	axi_rdata;
output	[1:0]	axi_rresp;
output			axi_rvalid;
input			axi_rready;

// Memory Mapped Register Interface
output	[1:0]	led;
input	[1:0]	gpio_in;
output	[10:0]	hgt, wdt;

// Internal Bus
output	[11:0]	addr;
output	[3:0]	cs;
output			wr;
output	[31:0]	wrdata;
input	[31:0]	rddata;

// Interrupt
input			grb_r_done;
input			grb_l_done;
output			intr;


//==========================================================================
// Reg/Wire Declaration
//==========================================================================
// Write Process
reg				axi_awready;
reg				aw_en;
reg		[13:0] 	axi_awaddr_r;
reg				axi_wready;
wire			slv_reg_wren;
reg		[31:0]	testpad;
reg		[1:0]	led;
reg		[31:0]	intr_enb;
reg		[10:0]	hgt, wdt;
reg				axi_bvalid;
reg		[1:0] 	axi_bresp;

// Timer
reg		[35:0]	timer;

// Interrupt
reg		[31:0]	intr_sts;
//reg		[31:0]	intr_sts_r;
//wire			intr_gen;
//reg				intr_gen_r;
wire			intr;

// Read Process
reg				axi_arready;
reg		[13:0] 	axi_araddr_r;
wire			rd_trig;
reg		[3:0]	rd_trig_r;
reg				axi_rvalid;
reg		[1:0] 	axi_rresp;
wire			slv_reg_rden;
wire	[31:0]	reg_data_out;
reg		[31:0]	axi_rdata;

// Internal Bus Converter
reg		[13:0]	S_AXI_ARADDR_1;
wire	[13:0]	addr_full;
wire	[11:0]	addr;
wire	[31:0]	wrdata;
wire			wr;


//==========================================================================
// Write Process
//==========================================================================
// Write Address
always @(posedge axi_aclk) begin
	if	(~axi_aresetn) begin
		axi_awready <= 1'b0;
		aw_en       <= 1'b1;
	end 
	else begin
		if (~axi_awready && axi_awvalid && axi_wvalid && aw_en) begin
			axi_awready <= 1'b1;
			aw_en       <= 1'b0;
		end
		else if (axi_bready && axi_bvalid) begin
			aw_en       <= 1'b1;
			axi_awready <= 1'b0;
		end
		else begin
			axi_awready <= 1'b0;
		end
	end
end

always @(posedge axi_aclk) begin
	if (~axi_aresetn) begin
		axi_awaddr_r <= 0;
	end 
	else begin
    	if (~axi_awready && axi_awvalid && axi_wvalid && aw_en) begin
			axi_awaddr_r <= axi_awaddr;
		end
	end
end

// Write Data
always @(posedge axi_aclk) begin
	if (~axi_aresetn) begin
		axi_wready <= 1'b0;
	end 
	else begin
		if (~axi_wready && axi_wvalid && axi_awvalid && aw_en) begin
			axi_wready <= 1'b1;
		end
		else begin
			axi_wready <= 1'b0;
		end
	end
end

assign slv_reg_wren = (axi_wready & axi_wvalid & axi_awready & axi_awvalid);

always @(posedge axi_aclk) begin
	if (~axi_aresetn) begin
		testpad  <= 32'h01234567;
		led      <=  2'b01;
		intr_enb <= 32'b0;
		hgt      <= 11'd480;
		wdt      <= 11'd640;
	end 
	else begin
		if (slv_reg_wren) begin
			case (axi_awaddr_r[13:2])
				12'h001: testpad  <= axi_wdata;
				12'h002: led      <= axi_wdata[1:0];
				12'h005: intr_enb <= axi_wdata;
				12'h008: begin
					hgt           <= axi_wdata[26:16];
					wdt           <= axi_wdata[10: 0];
				end
				default: begin
					testpad  <= testpad;
					led      <= led;
					intr_enb <= intr_enb;
					hgt      <= hgt;
					wdt      <= wdt;
				end
			endcase
		end
	end
end

// Write Response
always @(posedge axi_aclk) begin
	if (~axi_aresetn) begin
		axi_bvalid  <= 0;
		axi_bresp   <= 2'b0;
	end 
	else begin
		if (axi_awready && axi_awvalid && ~axi_bvalid && axi_wready && axi_wvalid) begin
			// indicates a valid write response is available
			axi_bvalid <= 1'b1;
			axi_bresp  <= 2'b0; // 'OKAY' response 
		end
		else begin
			if (axi_bready && axi_bvalid) begin
				axi_bvalid <= 1'b0; 
			end
		end
	end
end


//==========================================================================
// Timer
//==========================================================================
always @(posedge axi_aclk) begin
	if (~axi_aresetn) begin
		timer <= 36'b0;
	end 
	else begin
		timer <= timer + 1'b1;
	end
end


//==========================================================================
// Interrupt
//==========================================================================
always @(negedge axi_aresetn or posedge axi_aclk) begin
	if (~axi_aresetn) begin
		intr_sts <= 32'b0;
	end 
	else begin
		if (slv_reg_wren & axi_awaddr_r[13:2] == 12'h006) begin
			intr_sts <= intr_sts & ~axi_wdata; // write '1' to clear
		end
		else begin
			intr_sts[31:2] <= 30'b0;
			intr_sts[1] <= (grb_r_done) ? 1'b1 : intr_sts[1];
			intr_sts[0] <= (grb_l_done) ? 1'b1 : intr_sts[0];
		end
	end
end

/*
always @(negedge axi_aresetn or posedge axi_aclk) begin
	if (~axi_aresetn) begin
		intr_sts_r <= 32'b0;
	end 
	else begin
		intr_sts_r <= intr_sts;
	end
end

assign intr_gen = |(intr_enb[31:0] & intr_sts[31:0] & ~intr_sts_r[31:0]);

always @(negedge axi_aresetn or posedge axi_aclk) begin
	if (~axi_aresetn) begin
		intr_gen_r <= 1'b0;
	end 
	else begin
		intr_gen_r <= intr_gen;
	end
end

assign intr = intr_gen_r | intr_gen;
*/
assign intr = |(intr_enb[31:0] & intr_sts[31:0]);


//==========================================================================
// Read Process
//==========================================================================
// Read Address
always @(posedge axi_aclk) begin
	if (~axi_aresetn) begin
		axi_arready  <= 1'b0;
		axi_araddr_r <= 0;
	end 
	else begin
		if (~axi_arready && axi_arvalid) begin
			axi_arready  <= 1'b1;
			axi_araddr_r <= axi_araddr;
		end
		else begin
			axi_arready <= 1'b0;
		end
	end
end

assign rd_trig = (axi_arready && axi_arvalid && ~axi_rvalid);

always @(posedge axi_aclk) begin
	if (~axi_aresetn) begin
		rd_trig_r <= 0;
	end
	else begin
		rd_trig_r <= {rd_trig_r[2:0], rd_trig};
	end
end

always @(posedge axi_aclk) begin
	if (~axi_aresetn) begin
		axi_rvalid <= 0;
		axi_rresp  <= 0;
	end 
	else begin
		if (rd_trig_r[3]) begin
			// Valid read data is available at the read data bus
			axi_rvalid <= 1'b1;
			axi_rresp  <= 2'b0; // 'OKAY' response
		end   
		else if (axi_rvalid && axi_rready) begin
			// Read data is accepted by the master
			axi_rvalid <= 1'b0;
		end
	end
end

assign slv_reg_rden = rd_trig_r[2];

// CS0 [0000h-0FFCh] 00_0000_0000_0000 - 00_1111_1111_1100
// CS1 [1000h-1FFCh] 01_0000_0000_0000 - 01_1111_1111_1100
// CS2 [2000h-2FFCh] 10_0000_0000_0000 - 10_1111_1111_1100
// CS3 [3000h-3FFCh] 11_0000_0000_0000 - 11_1111_1111_1100
assign reg_data_out[31:0] = (
	(axi_araddr_r[13:2] == 12'h000) ? VERSION :
	(axi_araddr_r[13:2] == 12'h001) ? testpad :
	(axi_araddr_r[13:2] == 12'h002) ? {30'b0, led[1:0]} :
	(axi_araddr_r[13:2] == 12'h004) ? timer[35:4] :
	(axi_araddr_r[13:2] == 12'h005) ? intr_enb[31:0] :
	(axi_araddr_r[13:2] == 12'h006) ? intr_sts[31:0] :
	(axi_araddr_r[13:2] == 12'h007) ? {30'b0, gpio_in[1:0]} :
	(axi_araddr_r[13:2] == 12'h008) ? {5'b0, hgt[10:0], 5'b0, wdt[10:0]} :
	                                  rddata[31:0]
);

// Output register or memory read data
always @(posedge axi_aclk) begin
	if (~axi_aresetn) begin
		axi_rdata <= 0;
	end 
	else begin
		if (slv_reg_rden) begin
			axi_rdata <= reg_data_out;
		end
	end
end


//==========================================================================
// Internal Bus Converter
//==========================================================================
always @(posedge axi_aclk) begin
	if (~axi_aresetn) begin
		S_AXI_ARADDR_1 <= 0;
	end
	else begin
		if (axi_arvalid & axi_arready) begin
			S_AXI_ARADDR_1 <= axi_araddr;
		end
	end
end
   
assign addr_full[13:0] = (
	(axi_wvalid)  ? axi_awaddr[13:0] : 
	(axi_arvalid) ? axi_araddr[13:0] :
	                S_AXI_ARADDR_1[13:0]
);
assign addr = addr_full[11:0];
assign wrdata[31:0] = axi_wdata[31:0];
assign cs[0] = (addr_full[13:12] == 2'b00);
assign cs[1] = (addr_full[13:12] == 2'b01);
assign cs[2] = (addr_full[13:12] == 2'b10);
assign cs[3] = (addr_full[13:12] == 2'b11);
assign wr = axi_wready;


endmodule
