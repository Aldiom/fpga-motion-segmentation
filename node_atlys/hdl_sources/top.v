//`default_nettype none
`timescale 1ns / 1ps

module top (
	// General
	input  wire        clk100_i,
	input  wire        rst_button_n,
	// HDMI-IN
	input  wire [3:0]  TMDS_IN,
	input  wire [3:0]  TMDS_INB,
	input  wire        EDID_IN_SCL,
	inout  wire        EDID_IN_SDA,
	// HDMI-OUT
	output wire [3:0]  TMDS,
	output wire [3:0]  TMDSB,
	// DDR2
	output wire        DDR2CLK_P,
	output wire        DDR2CLK_N,
	output wire        DDR2CKE,
	output wire        DDR2RASN,
	output wire        DDR2CASN,
	output wire        DDR2WEN,
	inout  wire        DDR2RZQ,
	inout  wire        DDR2ZIO,
	output wire [2:0]  DDR2BA,
	output wire [12:0] DDR2A,
	inout  wire [15:0] DDR2DQ,
	inout  wire        DDR2UDQS_P,
	inout  wire        DDR2UDQS_N,
	inout  wire        DDR2LDQS_P,
	inout  wire        DDR2LDQS_N,
	output wire        DDR2LDM,
	output wire        DDR2UDM,
	output wire        DDR2ODT,
	// LEDS
	output wire [7:0]  led,
	input  wire [7:0]  switch
	);

	// ---------- MODULE ----------
	wire        reset, reset_sync, rst_button;
	wire [10:0] hpos, vpos, hpos_out;
	wire [23:0] disp_pixel_data1, disp_pixel_data2;
	wire [23:0] disp_pixel_data = switch[3] ? disp_pixel_data1 : disp_pixel_data2;

	assign rst_button = ~rst_button_n;

	//assign led = switch;

	// -- Clocks
	wire pll_in_clk, pll_feed_back;
	wire pll_clk_25MHz, pll_clk_50MHz, pll_clk_250MHz, pll_clk_100MHz;
	wire clk_25MHz, clk_50MHz, clk_250MHz, clk_100MHz, pll_locked, serdesstrobe;

	IBUFG pllinibufg_1( .I(clk100_i), .O(pll_in_clk)  );

	// F_VCO must be between 400 MHz and 1000 MHz.
	// F_VCO = F_CLKIN * CLKFBOUT_MULT
	PLL_BASE #(
		.CLKIN_PERIOD   (10),  //(real)[1.408-52.630] input period in ns.
		.CLKFBOUT_MULT  (10),  //(int) [1-64] Feedback multiplier.
		// Outputs clocks, 0 to 5.
		.CLKOUT0_DIVIDE (4),   // (int)[1-128] 10 x Pixel clock
		.CLKOUT1_DIVIDE (20),  // (int)[1-128]  2 x Pixel clock
		.CLKOUT2_DIVIDE (40),  // (int)[1-128]      Pixel clock
		.CLKOUT3_DIVIDE (10),  // (int)[1-128] Memory controller (MCB) clock
		.COMPENSATION("INTERNAL")
	)
	PLL_clocks_gen (
		.CLKIN    (pll_in_clk),
		.CLKFBIN  (pll_feed_back),
		.CLKFBOUT (pll_feed_back),
		.RST      (1'b0),
		// Outputs
		.CLKOUT0  (pll_clk_250MHz), // 10 x Pixel clock
		.CLKOUT1  (pll_clk_50MHz),  //  2 x Pixel clock
		.CLKOUT2  (pll_clk_25MHz),  //      Pixel clock
		.CLKOUT3  (pll_clk_100MHz), // Memory controller (MCB) clock
		// Status
		.LOCKED   (pll_locked)
	);


	BUFG clk_bufg_1 ( .I(pll_clk_25MHz),  .O(clk_25MHz)  );
	BUFG clk_bufg_2 ( .I(pll_clk_50MHz),  .O(clk_50MHz)  );
	BUFG clk_bufg_3 ( .I(pll_clk_100MHz), .O(clk_100MHz) );

	BUFPLL #(
		.DIVIDE(5)
	)
	ioclk_buf (
		.PLLIN        (pll_clk_250MHz),
		.GCLK         (clk_50MHz),
		.IOCLK        (clk_250MHz),
		.LOCKED       (pll_locked),
		.SERDESSTROBE (serdesstrobe),
		.LOCK()
	);
	// -------------------

	debounce
	debounce_1 (
		.reset  (1'b0),      
		.clk    (clk_25MHz),
		.noisy  (rst_button),
		.clean  (reset)
	);


	wire preload_vid_line, vid_active_pix;
	wire vid_HSync, app_timer_tick;
	wire foregnd_px;

	one_shot
	one_shot_1 (
		.sigOut (app_timer_tick),
		.sigIn  (vid_HSync),
		.clk    (clk_25MHz)
	);

	background_substractor
	BG_sub (
		.DDR2CLK_P        (DDR2CLK_P),
		.DDR2CLK_N        (DDR2CLK_N),
		.DDR2CKE          (DDR2CKE),
		.DDR2RASN         (DDR2RASN),
		.DDR2CASN         (DDR2CASN),
		.DDR2WEN          (DDR2WEN),
		.DDR2RZQ          (DDR2RZQ),
		.DDR2ZIO          (DDR2ZIO),
		.DDR2BA           (DDR2BA),
		.DDR2A            (DDR2A),
		.DDR2DQ           (DDR2DQ),
		.DDR2UDQS_P       (DDR2UDQS_P),
		.DDR2UDQS_N       (DDR2UDQS_N),
		.DDR2LDQS_P       (DDR2LDQS_P),
		.DDR2LDQS_N       (DDR2LDQS_N),
		.DDR2LDM          (DDR2LDM),
		.DDR2UDM          (DDR2UDM),
		.DDR2ODT          (DDR2ODT),
		// HDMI-IN
		.TMDS_IN          (TMDS_IN),
		.TMDS_INB         (TMDS_INB),
		.EDID_IN_SCL      (EDID_IN_SCL),
		.EDID_IN_SDA      (EDID_IN_SDA),
		// Clocks an timer ticks
		.app_clk          (clk_25MHz), // Same as vid_clk
		.app_timer_tick   (app_timer_tick),
		.mem_clk          (clk_100MHz),
		// Video display (read video line from RAM)
		.vid_preload_line (preload_vid_line),
		.vid_active_pix   (vid_active_pix),
		.vid_hpos         (hpos),
		.vid_vpos         (vpos),
		.vid_data_out     (disp_pixel_data1),
		.foreground       (foregnd_px),
		// Switches
		.switch           (switch)
	);
	
	blob_analyzer
	blob_analyzer1 (
		.app_clk          (clk_25MHz), // Same as vid_clk
		.app_timer_tick   (app_timer_tick),
		.mem_clk          (clk_100MHz),
		.vid_preload_line (preload_vid_line),
		.vid_active_pix   (vid_active_pix),
		.vid_hpos         (hpos),
		.vid_vpos         (vpos),
		.vid_data_out     (disp_pixel_data2),
		.foregnd_px       (foregnd_px)
	);

	resetsync
	resetsync_1 (
		.iClk     (clk_25MHz),
		.iRst     (reset),
		.oRstSync (reset_sync)
	);

	// -- Video output
	dvi_tx_fixed_res #(
		// Resolution (active pixels)
		.H_RES_PIX  (640),
		.V_RES_PIX  (480),
		// Horizontal timing
		.H_FN_PRCH  (32),
		.H_SYNC_PW  (88),
		.H_BK_PRCH  (32),
		// Vertical timing
		.V_FN_PRCH  (10),
		.V_SYNC_PW  (5),
		.V_BK_PRCH  (10),
		// Signal polarity
		.H_SYNC_POL (0),
		.V_SYNC_POL (0),
		// Data read latency
		.LATENCY    (1)
	)
	HDMI_out_1 (
		// Clocks
		.p_clk_x1         (clk_25MHz),
		.p_clk_x2         (clk_50MHz),
		.p_clk_x10        (clk_250MHz),
		.serdesstrobe     (serdesstrobe),
		// Reset
		.reset            (~pll_locked || reset_sync),
		// Pixel coordinates
		.HPos             (hpos),
		.VPos             (vpos),
		// Video data
		.red_data         (disp_pixel_data[23:16]),
		.green_data       (disp_pixel_data[15:8]),
		.blue_data        (disp_pixel_data[7:0]),
		//
		.active           (vid_active_pix),
		.preload_vid_line (preload_vid_line),
		.h_sync           (vid_HSync),
		// HDMI physical interface
		.TMDS_OUT         (TMDS),
		.TMDS_OUTB        (TMDSB)
	);


endmodule
