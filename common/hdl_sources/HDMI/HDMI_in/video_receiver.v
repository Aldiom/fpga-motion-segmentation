//`default_nettype none
`timescale 1ns / 1ps


module video_receiver(
                       // HDMI PINS
                       TMDS_IN,
                       TMDS_INB,
                       EDID_IN_SCL,
                       EDID_IN_SDA,
                       // Clocks
                       edid_clk, // (in)
                       vid_clk,  // (out)
                       // Video data
                       data_en,
                       R_out,
                       G_out,
                       B_out,
                       h_pos,
                       v_pos,
                       // Misc signals
                       line_ready,
                       frame_ready
    );       
    
    
  // ---------- PARAMETERS ----------
    parameter H_RES_PIX  = 640;
    parameter V_RES_PIX  = 480;

  // ---------- LOCAL PARAMETERS ----------
    localparam H_ADDR_BITS = ceil_log2( H_RES_PIX - 1 );
    localparam V_ADDR_BITS = ceil_log2( V_RES_PIX - 1 );
    
  // ---------- INPUTS AND OUTPUTS ----------
    // HDMI PINS
    input wire [3:0] TMDS_IN;
    input wire [3:0] TMDS_INB;
    input wire       EDID_IN_SCL;
    inout wire       EDID_IN_SDA;
    // Clocks
    inout wire  edid_clk;
    output wire vid_clk;
    // Video data
    output wire                   data_en;
    output wire [7:0]             R_out;
    output wire [7:0]             G_out;
    output wire [7:0]             B_out;
    output wire [H_ADDR_BITS-1:0] h_pos;
    output wire [V_ADDR_BITS-1:0] v_pos;
    // Misc signals
    output wire    line_ready;
    output wire    frame_ready;


  // ---------- MODULE ----------

    // -- EDID --
    EDID_I2C #(
        .rom_init_file("rom_data/edid_2.coe")
    )
    edid_1 (
        .clk     (edid_clk),
        .SCL_PIN (EDID_IN_SCL),
        .SDA_PIN (EDID_IN_SDA)
    );


    // DVI decoder
    wire rx_vsync, rx_hsync, rx_active;
    wire [7:0] R_in, G_in, B_in;
    
    dvi_decoder dvi_decoder_1 (
        .tmdsclk_p (TMDS_IN[3]),  // tmds clock
        .tmdsclk_n (TMDS_INB[3]), // tmds clock
        .blue_p    (TMDS_IN[0]),  // Blue data in
        .green_p   (TMDS_IN[1]),  // Green data in
        .red_p     (TMDS_IN[2]),  // Red data in
        .blue_n    (TMDS_INB[0]), // Blue data in
        .green_n   (TMDS_INB[1]), // Green data in
        .red_n     (TMDS_INB[2]), // Red data in
        .exrst     (1'b0),        // external reset input, e.g. reset button

        .reset   (),        // rx reset
        // (One bit signals)
        .pclk    (vid_clk), // regenerated pixel clock
        .pclkx2  (),        // double rate pixel clock
        .pclkx10 (),        // 10x pixel as IOCLK
        .pllclk0 (),        // send pllclk0 out so it can be fed into a different BUFPLL
        .pllclk1 (),        // PLL x1 output
        .pllclk2 (),        // PLL x2 output
        // (One bit signals)
        .pll_lckd     (),   // send pll_lckd out so it can be fed into a different BUFPLL
        .serdesstrobe (),   // BUFPLL serdesstrobe output
        .tmdsclk      (),   // TMDS cable clock
        // (One bit signals)
        .hsync (rx_hsync),  // hsync data
        .vsync (rx_vsync),  // vsync data
        .de    (rx_active), // data enable
        // (One bit signals)
        .blue_vld  (),
        .green_vld (),
        .red_vld   (),
        .blue_rdy  (),
        .green_rdy (),
        .red_rdy   (),
        .psalgnerr (),
        // (30 bits signals)
        .sdout (),
        // (8 bits signals)
        .red   (R_in),    // pixel data out
        .green (G_in),    // pixel data out
        .blue  (B_in)     // pixel data out
    );

    
    // -- Video data generation --
    Hpos_Vpos_VidEn_gen #(
        .H_RES_PIX       (H_RES_PIX),
        .V_RES_PIX       (V_RES_PIX),
        .BITS_PER_PIXEL  (24),
        .LINE_READY_COMP (600)
    )
    Hpos_Vpos_VidEn_gen_1 (
		.vid_clk     (vid_clk), 
		.reset       (1'b0), 
		.Hsync       (rx_hsync), 
		.Vsync       (rx_vsync), 
		.Active_pix  (rx_active), 
		.pixel_in    ({R_in,G_in,B_in}), 
        //
		.Hpos        (h_pos), 
		.Vpos        (v_pos), 
		.VidEn       (data_en), 
		.pixel_out   ({R_out,G_out,B_out}), 
		.line_ready  (line_ready), 
		.frame_ready (frame_ready)
	);

  // ---------- FUNCTIONS ----------
    // Calculates necessary bits to represent the argument "in_number"
    // Evaluated in synthesis time
	function integer ceil_log2( input [31:0] in_number );
    begin
        for( ceil_log2 = 0; in_number > 0; ceil_log2 = ceil_log2 + 1 )
          in_number = in_number >> 1;
    end
    endfunction

endmodule

//`default_nettype wire // Compatibility