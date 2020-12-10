//==========================================================================
// Copyright (C) 2020 Nu-Gate Technology. All rights reserved.
// SPDX-License-Identifier: MIT
//==========================================================================
`timescale 1ns / 1ps

module sim_dvp;


//==========================================================================
// Register Map
//==========================================================================
parameter ADR_COM_VER        = 14'h0000;
parameter ADR_COM_TEST_PAD   = 14'h0004;
parameter ADR_COM_LED        = 14'h0008;
parameter ADR_COM_TIMER      = 14'h0010;
parameter ADR_COM_INTR_ENB   = 14'h0014;
parameter ADR_COM_INTR_STS   = 14'h0018;
parameter ADR_COM_VIDEO_CTRL = 14'h0030;

parameter ADR_ARB_CTRL       = 14'h1000;
parameter ADR_ARB_STS        = 14'h1004;

parameter ADR_CSI_L_CTRL     = 14'h1100;
parameter ADR_CSI_L_STS      = 14'h1104;
parameter ADR_CSI_L_SIZE     = 14'h1108;
parameter ADR_CSI_L_PTN_SEL  = 14'h110C;

parameter ADR_CSI_R_CTRL     = 14'h1200;
parameter ADR_CSI_R_STS      = 14'h1204;
parameter ADR_CSI_R_SIZE     = 14'h1208;
parameter ADR_CSI_R_PTN_SEL  = 14'h120C;

parameter ADR_GRB_L_CTRL     = 14'h1300;
parameter ADR_GRB_L_STS      = 14'h1304;
parameter ADR_GRB_L_ADDR_A   = 14'h1308;
parameter ADR_GRB_L_ADDR_B   = 14'h130C;
parameter ADR_GRB_L_ADDR_C   = 14'h1310;
parameter ADR_GRB_L_BST_LEN  = 14'h1314;
parameter ADR_GRB_L_TRIG     = 14'h1318;

parameter ADR_GRB_R_CTRL     = 14'h1400;
parameter ADR_GRB_R_STS      = 14'h1404;
parameter ADR_GRB_R_ADDR_A   = 14'h1408;
parameter ADR_GRB_R_ADDR_B   = 14'h140C;
parameter ADR_GRB_R_ADDR_C   = 14'h1410;
parameter ADR_GRB_R_BST_LEN  = 14'h1414;
parameter ADR_GRB_R_TRIG     = 14'h1418;


//==========================================================================
// Definition
//==========================================================================
parameter SimMode = (
	0 // Frame Grabber
);

parameter WDT = 640;
parameter HGT = 480;


//==========================================================================
// Reg/Wire Declaration
//==========================================================================
// Simulation Control
integer			ADDR, DATA;

// Reset/Clock Generation
reg				clk, rst_n;
wire			s00_axi_aclk;
wire			s00_axi_aresetn;
wire			m00_axi_aclk;
wire			m00_axi_aresetn;

// MIPI CSI2 Receiver Model
reg				csi_rx_enb;
wire			v1_tvalid;
wire			v1_tuser;
wire			v1_tlast;
wire	[31:0]	v1_tdata;
wire	[3:0]	v1_tdest;
wire	[3:0]	v1_tkeep;
wire			v2_tvalid;
wire			v2_tuser;
wire			v2_tlast;
wire	[31:0]	v2_tdata;
wire	[3:0]	v2_tdest;
wire	[3:0]	v2_tkeep;

// DDR Memory Model
wire			m00_axi_awready;
wire			m00_axi_wready;
wire			m00_axi_arready;
wire	[31:0]	m00_axi_rdata;
wire			m00_axi_rvalid;
wire			m00_axi_rlast;
wire			m00_axi_bvalid;

// dvp
wire	[1:0]	led;
wire			v1_rstn, v2_rstn;
reg		[13:0]	s00_axi_awaddr;
reg		[2:0]	s00_axi_awprot;
reg				s00_axi_awvalid;
wire			s00_axi_awready;
reg		[31:0]	s00_axi_wdata;
reg		[3:0]	s00_axi_wstrb;
reg				s00_axi_wvalid;
wire			s00_axi_wready;
wire	[1:0]	s00_axi_bresp;
wire			s00_axi_bvalid;
reg				s00_axi_bready;
reg		[13:0]	s00_axi_araddr;
reg		[2:0]	s00_axi_arprot;
reg				s00_axi_arvalid;
wire			s00_axi_arready;
wire	[31:0]	s00_axi_rdata;
wire	[1:0]	s00_axi_rresp;
wire			s00_axi_rvalid;
reg				s00_axi_rready;
wire			m00_axi_awid;
wire	[31:0]	m00_axi_awaddr;
wire	[7:0]	m00_axi_awlen;
wire	[2:0]	m00_axi_awsize;
wire	[1:0]	m00_axi_awburst;
wire			m00_axi_awlock;
wire	[3:0]	m00_axi_awcache;
wire	[2:0]	m00_axi_awprot;
wire	[3:0]	m00_axi_awqos;
wire			m00_axi_awuser;
wire			m00_axi_awvalid;
wire	[31:0]	m00_axi_wdata;
wire	[3:0]	m00_axi_wstrb;
wire			m00_axi_wlast;
wire			m00_axi_wuser;
wire			m00_axi_wvalid;
reg				m00_axi_bid;
reg		[1:0]	m00_axi_bresp;
reg				m00_axi_buser;
wire			m00_axi_bready;
wire			m00_axi_arid;
wire	[31:0]	m00_axi_araddr;
wire	[7:0]	m00_axi_arlen;
wire	[2:0]	m00_axi_arsize;
wire	[1:0]	m00_axi_arburst;
wire			m00_axi_arlock;
wire	[3:0]	m00_axi_arcache;
wire	[2:0]	m00_axi_arprot;
wire	[3:0]	m00_axi_arqos;
wire			m00_axi_aruser;
wire			m00_axi_arvalid;
reg				m00_axi_rid;
reg		[1:0]	m00_axi_rresp;
reg				m00_axi_ruser;
wire			m00_axi_rready;
wire			v1_tready, v2_tready;


//==========================================================================
// Reset/Clock Generation
//==========================================================================
initial begin
	clk <= 1'b0;
	forever begin
		#5; // 100MHz
		clk <= ~clk;
	end
end

initial begin
	rst_n <= 1'b0;
	repeat (5) @(posedge clk);
	rst_n <= 1'b1;
end

assign s00_axi_aclk    = clk;
assign s00_axi_aresetn = rst_n;
assign m00_axi_aclk    = clk;
assign m00_axi_aresetn = rst_n;


//==========================================================================
// MIPI CSI2 Receiver Model
//==========================================================================
csi_rx_mdl # (WDT, HGT) csi_rx_mdl (
	// Global Control
	.clk (clk),
	
	// Control
	.enb (csi_rx_enb),
	
	// AXI Stream Output
	.tvalid (v1_tvalid),
	.tready (v1_tready),
	.tuser  (v1_tuser),
	.tlast  (v1_tlast),
	.tdata  (v1_tdata[31:0]),
	.tdest  (v1_tdest[3:0]),
	.tkeep  (v1_tkeep[3:0])
);

assign v2_tvalid = v1_tvalid;
assign v2_tuser  = v1_tuser;
assign v2_tlast  = v1_tlast;
assign v2_tdata[31:0] = v1_tdata[31:0];
assign v2_tdest[3:0]  = v1_tdest[3:0];
assign v2_tkeep[3:0]  = v1_tkeep[3:0];


//==========================================================================
// DDR Memory Model
//  16MB Space: 0000_0000 - 00FF_FFFF (16MB)
//--------------------------------------------------------------------------
//  BUF_GRB_A : 0000_0000 - 001F_FFFF (2MB)
//  BUF_GRB_B : 0020_0000 - 003F_FFFF (2MB)
//==========================================================================
ddr_mdl ddr_mdl (
	// AXI I/F
	.axi_aclk    (clk),
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


//==========================================================================
// Target Instance
//==========================================================================
dvp dvp (
	// Board Interface
	.led    (led),
	.vrst1_n (v1_rstn),
	.vrst2_n (v2_rstn),

	// AXI Slave Interface for Register Access
	.s00_axi_aclk    (s00_axi_aclk),
	.s00_axi_aresetn (s00_axi_aresetn),
	.s00_axi_awaddr  (s00_axi_awaddr),
	.s00_axi_awprot  (s00_axi_awprot),
	.s00_axi_awvalid (s00_axi_awvalid),
	.s00_axi_awready (s00_axi_awready),
	.s00_axi_wdata   (s00_axi_wdata),
	.s00_axi_wstrb   (s00_axi_wstrb),
	.s00_axi_wvalid  (s00_axi_wvalid),
	.s00_axi_wready  (s00_axi_wready),
	.s00_axi_bresp   (s00_axi_bresp),
	.s00_axi_bvalid  (s00_axi_bvalid),
	.s00_axi_bready  (s00_axi_bready),
	.s00_axi_araddr  (s00_axi_araddr),
	.s00_axi_arprot  (s00_axi_arprot),
	.s00_axi_arvalid (s00_axi_arvalid),
	.s00_axi_arready (s00_axi_arready),
	.s00_axi_rdata   (s00_axi_rdata),
	.s00_axi_rresp   (s00_axi_rresp),
	.s00_axi_rvalid  (s00_axi_rvalid),
	.s00_axi_rready  (s00_axi_rready),
	
	// AXI Master Interface for DDR Access
	.m00_axi_aclk    (m00_axi_aclk),
	.m00_axi_aresetn (m00_axi_aresetn),
	.m00_axi_awid    (m00_axi_awid),
	.m00_axi_awaddr  (m00_axi_awaddr),
	.m00_axi_awlen   (m00_axi_awlen),
	.m00_axi_awsize  (m00_axi_awsize),
	.m00_axi_awburst (m00_axi_awburst),
	.m00_axi_awlock  (m00_axi_awlock),
	.m00_axi_awcache (m00_axi_awcache),
	.m00_axi_awprot  (m00_axi_awprot),
	.m00_axi_awqos   (m00_axi_awqos),
	.m00_axi_awuser  (m00_axi_awuser),
	.m00_axi_awvalid (m00_axi_awvalid),
	.m00_axi_awready (m00_axi_awready),
	.m00_axi_wdata   (m00_axi_wdata),
	.m00_axi_wstrb   (m00_axi_wstrb),
	.m00_axi_wlast   (m00_axi_wlast),
	.m00_axi_wuser   (m00_axi_wuser),
	.m00_axi_wvalid  (m00_axi_wvalid),
	.m00_axi_wready  (m00_axi_wready),
	.m00_axi_bid     (m00_axi_bid),
	.m00_axi_bresp   (m00_axi_bresp),
	.m00_axi_buser   (m00_axi_buser),
	.m00_axi_bvalid  (m00_axi_bvalid),
	.m00_axi_bready  (m00_axi_bready),
	.m00_axi_arid    (m00_axi_arid),
	.m00_axi_araddr  (m00_axi_araddr),
	.m00_axi_arlen   (m00_axi_arlen),
	.m00_axi_arsize  (m00_axi_arsize),
	.m00_axi_arburst (m00_axi_arburst),
	.m00_axi_arlock  (m00_axi_arlock),
	.m00_axi_arcache (m00_axi_arcache),
	.m00_axi_arprot  (m00_axi_arprot),
	.m00_axi_arqos   (m00_axi_arqos),
	.m00_axi_aruser  (m00_axi_aruser),
	.m00_axi_arvalid (m00_axi_arvalid),
	.m00_axi_arready (m00_axi_arready),
	.m00_axi_rid     (m00_axi_rid),
	.m00_axi_rdata   (m00_axi_rdata),
	.m00_axi_rresp   (m00_axi_rresp),
	.m00_axi_rlast   (m00_axi_rlast),
	.m00_axi_ruser   (m00_axi_ruser),
	.m00_axi_rvalid  (m00_axi_rvalid),
	.m00_axi_rready  (m00_axi_rready),
	
	// AXI Stream Input for Video Data
	.v1_tvalid (v1_tvalid),
	.v1_tready (v1_tready),
	.v1_tuser  (v1_tuser),
	.v1_tlast  (v1_tlast),
	.v1_tdata  (v1_tdata[15:0]),
	.v1_tdest  (9'b0),
	.v2_tvalid (v2_tvalid),
	.v2_tready (v2_tready),
	.v2_tuser  (v2_tuser),
	.v2_tlast  (v2_tlast),
	.v2_tdata  (v2_tdata[15:0]),
	.v2_tdest  (9'b0)
);


//==========================================================================
// Simulation Control
//==========================================================================
task INIT;
	begin
		csi_rx_enb <= 1'b0;
		
		s00_axi_awaddr  <= 14'b0;
		s00_axi_awprot  <=  3'b0;
		s00_axi_awvalid <=  1'b0;
		s00_axi_wdata   <= 32'b0;
		s00_axi_wstrb   <=  8'hF;
		s00_axi_wvalid  <=  1'b0;
		s00_axi_bready  <=  1'b0;
		s00_axi_araddr  <= 14'b0;
		s00_axi_arprot  <=  3'b0;
		s00_axi_arvalid <=  1'b0;
		s00_axi_rready  <=  1'b0;
		
		m00_axi_bid     <=  1'b0;
		m00_axi_bresp   <=  2'b0;
		m00_axi_buser   <=  1'b0;
		m00_axi_rid     <=  1'b0;
		m00_axi_rresp   <=  2'b0;
		m00_axi_ruser   <=  1'b0;
	end
endtask

task REG_WR;
	begin
		repeat (5) @(posedge s00_axi_aclk);
		s00_axi_wvalid <= 1'b1;
		s00_axi_wdata <= DATA;
		repeat (2) @(posedge s00_axi_aclk);
		s00_axi_awvalid <= 1'b1;
		s00_axi_awaddr <= ADDR[13:0];
		
		@(posedge s00_axi_awready);
		@(posedge s00_axi_aclk);
		s00_axi_wvalid <= 1'b0;
		s00_axi_wdata <= 32'h0;
		s00_axi_awvalid <= 1'b0;
		s00_axi_awaddr <= 0;
		
		@(posedge s00_axi_bvalid);
		@(posedge s00_axi_aclk);
		s00_axi_bready <= 1'b1;
		@(posedge s00_axi_aclk);
		s00_axi_bready <= 1'b0;
		
		repeat (5) @(posedge s00_axi_aclk);
	end
endtask

task REG_RD;
	begin
		repeat (5) @(posedge s00_axi_aclk);
		s00_axi_arvalid <= 1'b1;
		s00_axi_araddr <= ADDR[13:0];
		@(posedge s00_axi_arready);
		@(posedge s00_axi_aclk);
		s00_axi_arvalid <= 1'b0;
		s00_axi_araddr <= 0;
		
		@(posedge s00_axi_rvalid);
		@(posedge s00_axi_aclk);
		s00_axi_rready <= 1'b1;
		@(posedge s00_axi_aclk);
		s00_axi_rready <= 1'b0;
		
		repeat (5) @(posedge s00_axi_aclk);
	end
endtask

initial begin
	INIT;
	
	repeat (10) @(posedge clk);
	
	case (SimMode)
	0: begin
		// Parameter
		ADDR = ADR_COM_INTR_ENB;	DATA = 32'h0000_0001;			REG_WR;
		ADDR = ADR_GRB_L_ADDR_A;	DATA = 32'h0000_0000;			REG_WR;
		ADDR = ADR_GRB_L_ADDR_B;	DATA = 32'h0020_0000;			REG_WR;
		
		ADDR = ADR_CSI_L_PTN_SEL;	DATA = 32'h0000_0004;			REG_WR;
		
		// Control
		ADDR = ADR_ARB_CTRL;		DATA = 32'h0000_0001;			REG_WR;
		ADDR = ADR_GRB_L_CTRL;		DATA = 32'h0000_0001;			REG_WR;
		
		// Video Reset
		ADDR = ADR_CSI_L_CTRL;		DATA = 32'h0000_0001;			REG_WR;
		repeat (10) @(posedge clk);
		
		// Start Frame Grabber
		repeat (10) @(posedge clk);
		ADDR = ADR_GRB_L_TRIG;		DATA = 32'h0000_0001;			REG_WR;
		
		repeat (10) @(posedge clk);
		csi_rx_enb <= 1'b1;
		repeat (2) @(posedge v1_tuser);
		repeat (100) @(posedge clk);
	end
	default: begin
	end
	endcase
	
	repeat (10) @(posedge clk);
	
	$finish;
end


endmodule
