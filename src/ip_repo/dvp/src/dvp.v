/***************************************************************************
* Copyright (C) 2020 Nu-Gate Technology. All rights reserved.
* SPDX-License-Identifier: GPL-3.0-or-later
 ***************************************************************************/
`timescale 1 ns / 1 ps

module dvp # (
	// Parameters of Axi Slave Bus Interface S00_AXI
	parameter integer C_S_AXI_DATA_WIDTH = 32,
	parameter integer C_S_AXI_ADDR_WIDTH = 14,
	
	// Parameters of Axi Master Bus Interface M00_AXI
	parameter integer C_M00_AXI_ID_WIDTH	= 1,
	parameter integer C_M00_AXI_ADDR_WIDTH	= 32,
	parameter integer C_M00_AXI_DATA_WIDTH	= 32,
	parameter integer C_M00_AXI_AWUSER_WIDTH	= 0,
	parameter integer C_M00_AXI_ARUSER_WIDTH	= 0,
	parameter integer C_M00_AXI_WUSER_WIDTH	= 0,
	parameter integer C_M00_AXI_RUSER_WIDTH	= 0,
	parameter integer C_M00_AXI_BUSER_WIDTH	= 0
) (
	// Board Interface
	led,
	vrst1_n,
	vrst2_n,
	gpio_in,
	grb_l_done,
	
	// Interrupt
	intr,

	// AXI Slave Interface for Register Access
	s00_axi_aclk,
	s00_axi_aresetn,
	s00_axi_awaddr,
	s00_axi_awprot,
	s00_axi_awvalid,
	s00_axi_awready,
	s00_axi_wdata,
	s00_axi_wstrb,
	s00_axi_wvalid,
	s00_axi_wready,
	s00_axi_bresp,
	s00_axi_bvalid,
	s00_axi_bready,
	s00_axi_araddr,
	s00_axi_arprot,
	s00_axi_arvalid,
	s00_axi_arready,
	s00_axi_rdata,
	s00_axi_rresp,
	s00_axi_rvalid,
	s00_axi_rready,
	
	// AXI Master Interface for DDR Access
	m00_axi_aclk,
	m00_axi_aresetn,
	m00_axi_awid,
	m00_axi_awaddr,
	m00_axi_awlen,
	m00_axi_awsize,
	m00_axi_awburst,
	m00_axi_awlock,
	m00_axi_awcache,
	m00_axi_awprot,
	m00_axi_awqos,
	m00_axi_awuser,
	m00_axi_awvalid,
	m00_axi_awready,
	m00_axi_wdata,
	m00_axi_wstrb,
	m00_axi_wlast,
	m00_axi_wuser,
	m00_axi_wvalid,
	m00_axi_wready,
	m00_axi_bid,
	m00_axi_bresp,
	m00_axi_buser,
	m00_axi_bvalid,
	m00_axi_bready,
	m00_axi_arid,
	m00_axi_araddr,
	m00_axi_arlen,
	m00_axi_arsize,
	m00_axi_arburst,
	m00_axi_arlock,
	m00_axi_arcache,
	m00_axi_arprot,
	m00_axi_arqos,
	m00_axi_aruser,
	m00_axi_arvalid,
	m00_axi_arready,
	m00_axi_rid,
	m00_axi_rdata,
	m00_axi_rresp,
	m00_axi_rlast,
	m00_axi_ruser,
	m00_axi_rvalid,
	m00_axi_rready,
	
	// AXI Stream Input for Video Data
	v1_tvalid,
	v1_tready,
	v1_tuser,
	v1_tlast,
	v1_tdata,
	v1_tdest,
	v2_tvalid,
	v2_tready,
	v2_tuser,
	v2_tlast,
	v2_tdata,
	v2_tdest
);


//==========================================================================
// Parameter Settings
//==========================================================================
// FPGA Version
localparam VERSION = 32'h0101;


//==========================================================================
// Port Declaration
//==========================================================================
// Board Interface
output	[1:0]	led;
output			vrst1_n, vrst2_n;
input	[1:0]	gpio_in;
output          grb_l_done;

// Interrupt
output			intr;

// AXI Slave Interface for Register Access
input			s00_axi_aclk;
input			s00_axi_aresetn;
input	[13:0]	s00_axi_awaddr;
input	[2:0]	s00_axi_awprot;
input			s00_axi_awvalid;
output			s00_axi_awready;
input	[31:0]	s00_axi_wdata;
input	[3:0]	s00_axi_wstrb;
input			s00_axi_wvalid;
output			s00_axi_wready;
output	[1:0]	s00_axi_bresp;
output			s00_axi_bvalid;
input			s00_axi_bready;
input	[13:0]	s00_axi_araddr;
input	[2:0]	s00_axi_arprot;
input			s00_axi_arvalid;
output			s00_axi_arready;
output	[31:0]	s00_axi_rdata;
output	[1:0]	s00_axi_rresp;
output			s00_axi_rvalid;
input			s00_axi_rready;

// AXI Master Interface for DDR Access
input			m00_axi_aclk;
input			m00_axi_aresetn;
output			m00_axi_awid;
output	[31:0]	m00_axi_awaddr;
output	[7:0]	m00_axi_awlen;
output	[2:0]	m00_axi_awsize;
output	[1:0]	m00_axi_awburst;
output			m00_axi_awlock;
output	[3:0]	m00_axi_awcache;
output	[2:0]	m00_axi_awprot;
output	[3:0]	m00_axi_awqos;
output			m00_axi_awuser;
output			m00_axi_awvalid;
input			m00_axi_awready;
output	[31:0]	m00_axi_wdata;
output	[3:0]	m00_axi_wstrb;
output			m00_axi_wlast;
output			m00_axi_wuser;
output			m00_axi_wvalid;
input			m00_axi_wready;
input			m00_axi_bid;
input	[1:0]	m00_axi_bresp;
input			m00_axi_buser;
input			m00_axi_bvalid;
output			m00_axi_bready;
output			m00_axi_arid;
output	[31:0]	m00_axi_araddr;
output	[7:0]	m00_axi_arlen;
output	[2:0]	m00_axi_arsize;
output	[1:0]	m00_axi_arburst;
output			m00_axi_arlock;
output	[3:0]	m00_axi_arcache;
output	[2:0]	m00_axi_arprot;
output	[3:0]	m00_axi_arqos;
output			m00_axi_aruser;
output			m00_axi_arvalid;
input			m00_axi_arready;
input			m00_axi_rid;
input	[31:0]	m00_axi_rdata;
input	[1:0]	m00_axi_rresp;
input			m00_axi_rlast;
input			m00_axi_ruser;
input			m00_axi_rvalid;
output			m00_axi_rready;

// AXI Stream Input for Video Data
input			v1_tvalid;
output			v1_tready;
input			v1_tuser;
input			v1_tlast;
input	[15:0]	v1_tdata;
input	[9:0]	v1_tdest;
input			v2_tvalid;
output			v2_tready;
input			v2_tuser;
input			v2_tlast;
input	[15:0]	v2_tdata;
input	[9:0]	v2_tdest;


//==========================================================================
// Reg/Wire Declaration
//==========================================================================
// AXI Interface
wire			clk, rst_n;
wire	[1:0]	led;
wire	[10:0]	hgt, wdt;
wire	[11:0]	ibus_addr;
wire	[3:0]	ibus_cs;
wire			ibus_wr;
wire	[31:0]	ibus_wrdata;
wire	[31:0]	ibus_rddata;
wire			ibus_cs_arb, ibus_cs_csi_l, ibus_cs_csi_r, ibus_cs_grb;
wire	[10:0]	hgt_m1, wdt_m1;

// CSI Receiver Interface
wire	[31:0]	ibus_rddata_csi_l;
wire			vrst1_n;
wire			v1_tready;
wire			csi_l_tvalid, csi_l_tuser, csi_l_tlast;
wire	[15:0]	csi_l_tdata;
wire	[3:0]	csi_l_tdest, csi_l_tkeep;
wire	[31:0]	ibus_rddata_csi_r;
wire			vrs2_n;
wire			v2_tready;
wire			csi_r_tvalid, csi_r_tuser, csi_r_tlast;
wire	[15:0]	csi_r_tdata;
wire	[3:0]	csi_r_tdest, csi_r_tkeep;

// Frame Grabber
wire	[31:0]	ibus_rddata_grb_l;
wire			csi_l_tready;
wire			grb_l_req;
wire	[31:0]	grb_l_dout;
wire			grb_l_vout;
wire	[31:0]	ibus_rddata_grb_r;
wire			csi_r_tready;
wire			grb_r_req;
wire	[31:0]	grb_r_dout;
wire			grb_r_vout;

// DDR Arbiter
wire	[5:0]	arb_req;
wire			arb_vin;
wire	[31:0]	arb_din;
wire	[3:0]	arb_strb;
wire			grb_r_ack, grb_l_ack;
wire			grb_r_done, grb_l_done;
wire	[31:0]	ibus_rddata_arb;
wire	[5:0]	arb_done;
wire	[5:0]	arb_ack;


//==========================================================================
// AXI Interface
//==========================================================================
// default clock and reset
assign clk   = s00_axi_aclk;
assign rst_n = s00_axi_aresetn;

axi_if #(
	C_S_AXI_DATA_WIDTH,
	C_S_AXI_ADDR_WIDTH,
	VERSION
) axi_if (
	.axi_aclk    (s00_axi_aclk),
	.axi_aresetn (s00_axi_aresetn),
	.axi_awaddr  (s00_axi_awaddr),
	.axi_awprot  (s00_axi_awprot),
	.axi_awvalid (s00_axi_awvalid),
	.axi_awready (s00_axi_awready),
	.axi_wdata   (s00_axi_wdata),
	.axi_wstrb   (s00_axi_wstrb),
	.axi_wvalid  (s00_axi_wvalid),
	.axi_wready  (s00_axi_wready),
	.axi_bresp   (s00_axi_bresp),
	.axi_bvalid  (s00_axi_bvalid),
	.axi_bready  (s00_axi_bready),
	.axi_araddr  (s00_axi_araddr),
	.axi_arprot  (s00_axi_arprot),
	.axi_arvalid (s00_axi_arvalid),
	.axi_arready (s00_axi_arready),
	.axi_rdata   (s00_axi_rdata),
	.axi_rresp   (s00_axi_rresp),
	.axi_rvalid  (s00_axi_rvalid),
	.axi_rready  (s00_axi_rready),
	
	.led     (led),
	.gpio_in (gpio_in),
	.hgt     (hgt),
	.wdt     (wdt),
	
	.addr   (ibus_addr),
	.cs     (ibus_cs),
	.wr     (ibus_wr),
	.wrdata (ibus_wrdata),
	.rddata (ibus_rddata),
	
	// Interrupt
	.grb_r_done (grb_r_done),
	.grb_l_done (grb_l_done),
	.intr     (intr)
);

assign ibus_cs_arb   = (ibus_cs[1] & (ibus_addr[11:8] == 4'h0));
assign ibus_cs_csi_l = (ibus_cs[1] & (ibus_addr[11:8] == 4'h1));
assign ibus_cs_csi_r = (ibus_cs[1] & (ibus_addr[11:8] == 4'h2));
assign ibus_cs_grb_l = (ibus_cs[1] & (ibus_addr[11:8] == 4'h3));
assign ibus_cs_grb_r = (ibus_cs[1] & (ibus_addr[11:8] == 4'h4));

assign ibus_rddata[31:0] = (
	ibus_rddata_arb[31:0] |
	ibus_rddata_csi_l[31:0] |
	ibus_rddata_csi_r[31:0] |
	ibus_rddata_grb_l[31:0] |
	ibus_rddata_grb_r[31:0]
);

// Secondary Parameters
assign wdt_m1[10:0] = wdt - 1'b1;
assign hgt_m1[10:0] = hgt - 1'b1;


//==========================================================================
// CSI Receiver Interface
//==========================================================================
csi_if csi_if_l (
	// Global Control
	.rst_n (rst_n),
	.clk   (clk),
	
	// Internal Bus I/F
	.ibus_cs     (ibus_cs_csi_l),
	.ibus_wr     (ibus_wr),
	.ibus_addr   (ibus_addr[7:0]),
	.ibus_wrdata (ibus_wrdata[31:0]),
	.ibus_rddata (ibus_rddata_csi_l[31:0]),
	
	// CSI Receiver Control
	.vrst_n (vrst1_n),
	
	// AXI Stream Input
	.tdata_in  (v1_tdata[15:0]),
	.tdest_in  (v1_tdest[3:0]),
	.tuser_in  (v1_tuser),
	.tkeep_in  (4'b0),
	.tvalid_in (v1_tvalid),
	.tlast_in  (v1_tlast),
	.tready_in (v1_tready),
	
	// AXI Stream Output
	.tvalid_out (csi_l_tvalid),
	.tready_out (csi_l_tready),
	.tuser_out  (csi_l_tuser),
	.tlast_out  (csi_l_tlast),
	.tdata_out  (csi_l_tdata[15:0]),
	.tdest_out  (csi_l_tdest[3:0]),
	.tkeep_out  (csi_l_tkeep[3:0])
);

csi_if csi_if_r (
	// Global Control
	.rst_n (rst_n),
	.clk   (clk),
	
	// Internal Bus I/F
	.ibus_cs     (ibus_cs_csi_r),
	.ibus_wr     (ibus_wr),
	.ibus_addr   (ibus_addr[7:0]),
	.ibus_wrdata (ibus_wrdata[31:0]),
	.ibus_rddata (ibus_rddata_csi_r[31:0]),
	
	// CSI Receiver Control
	.vrst_n (vrst2_n),
	
	// AXI Stream Input
	.tdata_in  (v2_tdata[15:0]),
	.tdest_in  (v2_tdest[3:0]),
	.tuser_in  (v2_tuser),
	.tkeep_in  (4'b0),
	.tvalid_in (v2_tvalid),
	.tlast_in  (v2_tlast),
	.tready_in (v2_tready),
	
	// AXI Stream Output
	.tvalid_out (csi_r_tvalid),
	.tready_out (csi_r_tready),
	.tuser_out  (csi_r_tuser),
	.tlast_out  (csi_r_tlast),
	.tdata_out  (csi_r_tdata[15:0]),
	.tdest_out  (csi_r_tdest[3:0]),
	.tkeep_out  (csi_r_tkeep[3:0])
);


//==========================================================================
// Frame Grabber
//==========================================================================
grb #(0) grb_l (
	// Global Control
	.rst_n (rst_n),
	.clk   (clk),
	
	// Parameter
	.hgt_m1 (hgt_m1[10:0]),
	.wdt (wdt[10:0]),
	
	// Internal Bus I/F
	.ibus_cs     (ibus_cs_grb_l),
	.ibus_wr     (ibus_wr),
	.ibus_addr   (ibus_addr[7:0]),
	.ibus_wrdata (ibus_wrdata[31:0]),
	.ibus_rddata (ibus_rddata_grb_l[31:0]),
	
	// AXI Stream Input
	.csi_tdata  (csi_l_tdata[15:0]),
	.csi_tdest  (csi_l_tdest[3:0]),
	.csi_tuser  (csi_l_tuser),
	.csi_tkeep  (csi_l_tkeep[3:0]),
	.csi_tvalid (csi_l_tvalid),
	.csi_tlast  (csi_l_tlast),
	.csi_tready (csi_l_tready),
	
	// Arbiter I/F
	.dwr_req  (grb_l_req),
	.dwr_ack  (grb_l_ack),
	.dwr_dout (grb_l_dout[31:0]),
	.dwr_vout (grb_l_vout)
);

grb #(1) grb_r (
	// Global Control
	.rst_n (rst_n),
	.clk   (clk),
	
	// Parameter
	.hgt_m1 (hgt_m1[10:0]),
	.wdt (wdt[10:0]),
	
	// Internal Bus I/F
	.ibus_cs     (ibus_cs_grb_r),
	.ibus_wr     (ibus_wr),
	.ibus_addr   (ibus_addr[7:0]),
	.ibus_wrdata (ibus_wrdata[31:0]),
	.ibus_rddata (ibus_rddata_grb_r[31:0]),
	
	// AXI Stream Input
	.csi_tdata  (csi_r_tdata[15:0]),
	.csi_tdest  (csi_r_tdest[3:0]),
	.csi_tuser  (csi_r_tuser),
	.csi_tkeep  (csi_r_tkeep[3:0]),
	.csi_tvalid (csi_r_tvalid),
	.csi_tlast  (csi_r_tlast),
	.csi_tready (csi_r_tready),
	
	// Arbiter I/F
	.dwr_req  (grb_r_req),
	.dwr_ack  (grb_r_ack),
	.dwr_dout (grb_r_dout[31:0]),
	.dwr_vout (grb_r_vout)
);


//==========================================================================
// DDR Arbiter
//==========================================================================
assign arb_req[5:0] = {
	4'b0,
	grb_r_req,
	grb_l_req
};
assign arb_vin = (
	grb_r_vout | grb_l_vout
);
assign arb_din[31:0] = (
	grb_r_dout[31:0] | grb_l_dout[31:0]
);

assign arb_strb[3:0] = 4'hF; // default high

assign grb_r_ack = arb_ack[1];
assign grb_l_ack = arb_ack[0];
assign grb_r_done = arb_done[1];
assign grb_l_done = arb_done[0];

arb arb (
	// Global Control
	.rst_n (rst_n),
	.clk   (clk),
	
	// Internal Bus I/F
	.ibus_cs     (ibus_cs_arb),
	.ibus_wr     (ibus_wr),
	.ibus_addr   (ibus_addr[7:0]),
	.ibus_wrdata (ibus_wrdata[31:0]),
	.ibus_rddata (ibus_rddata_arb[31:0]),
	
	// Status
	.done (arb_done[5:0]),
	
	// FIFO I/F
	.req (arb_req),
	.ack (arb_ack),
	.valid_in  (arb_vin),
	.data_in   (arb_din),
	.strb_in   (arb_strb),
	.valid_out (),
	.data_out  (),
	
	// AXI I/F
	.axi_aclk    (m00_axi_aclk),
	.axi_awaddr  (m00_axi_awaddr),
	.axi_awlen   (m00_axi_awlen),
	.axi_awvalid (m00_axi_awvalid),
	.axi_awready (m00_axi_awready),
	.axi_wdata   (m00_axi_wdata),
	.axi_wstrb   (m00_axi_wstrb),
	.axi_wvalid  (m00_axi_wvalid),
	.axi_wready  (m00_axi_wready),
	.axi_wlast   (m00_axi_wlast),
	.axi_araddr  (m00_axi_araddr),
	.axi_arlen   (m00_axi_arlen),
	.axi_arvalid (m00_axi_arvalid),
	.axi_arready (m00_axi_arready),
	.axi_rdata   (m00_axi_rdata),
	.axi_rvalid  (m00_axi_rvalid),
	.axi_rready  (m00_axi_rready),
	.axi_rlast   (m00_axi_rlast),
	.axi_bvalid  (m00_axi_bvalid),
	.axi_bready  (m00_axi_bready)
);

assign m00_axi_awid    =  1'b0;
assign m00_axi_awsize  =  3'd2; // 4 bytes
assign m00_axi_awburst =  2'd1; // INCR
assign m00_axi_awlock  =  1'b0;
assign m00_axi_awcache =  4'd2;
assign m00_axi_awprot  =  3'd0; // Data Secure Unprivileged
assign m00_axi_awqos   =  4'd0;
assign m00_axi_awuser  =  1'b0;
assign m00_axi_wuser   =  1'b0;
assign m00_axi_arid    =  1'b0;
assign m00_axi_arsize  =  3'd2; // 4 bytes
assign m00_axi_arburst =  2'd1; // INCR
assign m00_axi_arlock  =  1'b0;
assign m00_axi_arcache =  4'd2;
assign m00_axi_arprot  =  3'd0; // Data Secure Unprivileged
assign m00_axi_arqos   =  4'd0;
assign m00_axi_aruser  =  1'b0;


endmodule
