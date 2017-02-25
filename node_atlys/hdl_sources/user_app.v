`timescale 1ns / 1ps

module user_app (
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

	// HDMI-IN
	input  wire [3:0]  TMDS_IN,
	input  wire [3:0]  TMDS_INB,
	input  wire        EDID_IN_SCL,
	inout  wire        EDID_IN_SDA,
	// Clocks an timer ticks
	input  wire        app_clk, // Same as vid_clk
	input  wire        app_timer_tick,
	input  wire        mem_clk,
	// Video display (read video line from RAM)
	input  wire                    vid_preload_line,
	input  wire                    vid_active_pix,
	input  wire [10:0]             vid_hpos,
	input  wire [10:0]             vid_vpos,
	output reg  [23:0]             vid_data_out
	);

	// ---------- PARAMETERS ----------

	// ---------- LOCAL PARAMETERS ----------
	localparam VARRAM_VAR_1_MAX_SIZE = 160; // 150 = 600 px; 160 = 640 px
	localparam PIXELS_PER_WORD       = 4;   // 8 bits gray-scale
	localparam H_IMG_RES             = PIXELS_PER_WORD*VARRAM_VAR_1_MAX_SIZE;
	localparam V_IMG_RES             = 480;


	// ---------- MODULE ----------
	// DDR2 INTERFACE
	wire c3_calib_done;
	wire reset;
	wire c3_clk0;

	wire        c3_p0_cmd_en,        c3_p1_cmd_en,        c3_p2_cmd_en,        c3_p3_cmd_en;
	wire [2:0]  c3_p0_cmd_instr,     c3_p1_cmd_instr,     c3_p2_cmd_instr,     c3_p3_cmd_instr;
	wire [5:0]  c3_p0_cmd_bl,        c3_p1_cmd_bl,        c3_p2_cmd_bl,        c3_p3_cmd_bl;
	wire [29:0] c3_p0_cmd_byte_addr, c3_p1_cmd_byte_addr, c3_p2_cmd_byte_addr, c3_p3_cmd_byte_addr;

	wire [7:0]  c3_p0_wr_mask,       c3_p1_wr_mask,       c3_p2_wr_mask,       c3_p3_wr_mask;
	wire [31:0] c3_p0_wr_data,       c3_p1_wr_data,       c3_p2_wr_data,       c3_p3_wr_data;
	wire        c3_p0_wr_full,       c3_p1_wr_full,       c3_p2_wr_full,       c3_p3_wr_full;
	wire        c3_p0_wr_empty,      c3_p1_wr_empty,      c3_p2_wr_empty,      c3_p3_wr_empty;
	wire [6:0]  c3_p0_wr_count,      c3_p1_wr_count,      c3_p2_wr_count,      c3_p3_wr_count;
	wire        c3_p0_wr_en,         c3_p1_wr_en,         c3_p2_wr_en,         c3_p3_wr_en;

	wire [31:0] c3_p0_rd_data,       c3_p1_rd_data,       c3_p2_rd_data,       c3_p3_rd_data;
	wire [6:0]  c3_p0_rd_count,      c3_p1_rd_count,      c3_p2_rd_count,      c3_p3_rd_count;
	wire        c3_p0_rd_en,         c3_p1_rd_en,         c3_p2_rd_en,         c3_p3_rd_en;
	wire        c3_p0_rd_empty,      c3_p1_rd_empty,      c3_p2_rd_empty,      c3_p3_rd_empty;

	// Config
	assign reset = 0;

	assign c3_p0_wr_mask = 0;
	assign c3_p1_wr_mask = 0;
	assign c3_p2_wr_mask = 0;
	assign c3_p3_wr_mask = 0;

	// Ports utilization
	// Port 0: Read
		//assign c3_p0_rd_en = 0;
		assign c3_p0_wr_en = 0;
	// Port 1: Write
		assign c3_p1_rd_en = 0;
		//assign c3_p1_wr_en = 0;
	// Port 2: Not used
		assign c3_p2_rd_en = 0;
		assign c3_p2_wr_en = 0;
	// Port 3: Not used
		assign c3_p3_rd_en = 0;
		assign c3_p3_wr_en = 0;

	///////////////
	reg  [29:0] init_add_rd = 0; // (Dispatcher in?)
	reg         os_start_rd = 0; // (Dispatcher in?)

	ddr2_user_interface
	DDR2_MCB_1 (
		// Physical interface (PINs)
		.DDR2CLK_P           (DDR2CLK_P),
		.DDR2CLK_N           (DDR2CLK_N),
		.DDR2CKE             (DDR2CKE),
		.DDR2RASN            (DDR2RASN),
		.DDR2CASN            (DDR2CASN),
		.DDR2WEN             (DDR2WEN),
		.DDR2RZQ             (DDR2RZQ),
		.DDR2ZIO             (DDR2ZIO),
		.DDR2BA              (DDR2BA),
		.DDR2A               (DDR2A),
		.DDR2DQ              (DDR2DQ),
		.DDR2UDQS_P          (DDR2UDQS_P),
		.DDR2UDQS_N          (DDR2UDQS_N),
		.DDR2LDQS_P          (DDR2LDQS_P),
		.DDR2LDQS_N          (DDR2LDQS_N),
		.DDR2LDM             (DDR2LDM),
		.DDR2UDM             (DDR2UDM),
		.DDR2ODT             (DDR2ODT),
		// Clock
		.clk                 (mem_clk),
		// Status and control
		.c3_calib_done       (c3_calib_done),
		.reset               (reset),
		.c3_clk0             (c3_clk0),
		// Port 0: Bidirectional
		.c3_p0_cmd_en        (c3_p0_cmd_en),
		.c3_p0_cmd_instr     (c3_p0_cmd_instr),
		.c3_p0_cmd_bl        (c3_p0_cmd_bl),
		.c3_p0_cmd_byte_addr (c3_p0_cmd_byte_addr),
		.c3_p0_wr_mask       (c3_p0_wr_mask),
		.c3_p0_wr_data       (c3_p0_wr_data),
		.c3_p0_wr_full       (c3_p0_wr_full),
		.c3_p0_wr_empty      (c3_p0_wr_empty),
		.c3_p0_wr_count      (c3_p0_wr_count), 
		.c3_p0_rd_data       (c3_p0_rd_data),
		.c3_p0_rd_count      (c3_p0_rd_count),
		.c3_p0_rd_en         (c3_p0_rd_en),
		.c3_p0_rd_empty      (c3_p0_rd_empty),
		.c3_p0_wr_en         (c3_p0_wr_en),
		// Port 1: Bidirectional
		.c3_p1_cmd_en        (c3_p1_cmd_en),
		.c3_p1_cmd_instr     (c3_p1_cmd_instr), 
		.c3_p1_cmd_bl        (c3_p1_cmd_bl),
		.c3_p1_cmd_byte_addr (c3_p1_cmd_byte_addr),
		.c3_p1_wr_mask       (c3_p1_wr_mask),
		.c3_p1_wr_full       (c3_p1_wr_full),
		.c3_p1_wr_empty      (c3_p1_wr_empty),
		.c3_p1_wr_count      (c3_p1_wr_count),
		.c3_p1_wr_data       (c3_p1_wr_data),
		.c3_p1_rd_data       (c3_p1_rd_data),
		.c3_p1_rd_count      (c3_p1_rd_count),
		.c3_p1_rd_en         (c3_p1_rd_en),
		.c3_p1_rd_empty      (c3_p1_rd_empty),
		.c3_p1_wr_en         (c3_p1_wr_en),
		// Port 2: Bidirectional
		.c3_p2_cmd_en        (c3_p2_cmd_en),
		.c3_p2_cmd_instr     (c3_p2_cmd_instr),
		.c3_p2_cmd_bl        (c3_p2_cmd_bl),
		.c3_p2_cmd_byte_addr (c3_p2_cmd_byte_addr),
		.c3_p2_wr_mask       (c3_p2_wr_mask),
		.c3_p2_wr_full       (c3_p2_wr_full),
		.c3_p2_wr_empty      (c3_p2_wr_empty),
		.c3_p2_wr_count      (c3_p2_wr_count),
		.c3_p2_wr_data       (c3_p2_wr_data),
		.c3_p2_rd_data       (c3_p2_rd_data),
		.c3_p2_rd_count      (c3_p2_rd_count),
		.c3_p2_rd_en         (c3_p2_rd_en),
		.c3_p2_rd_empty      (c3_p2_rd_empty),
		.c3_p2_wr_en         (c3_p2_wr_en),
		// Port 3: Bidirectional
		.c3_p3_cmd_en        (c3_p3_cmd_en),
		.c3_p3_cmd_instr     (c3_p3_cmd_instr),
		.c3_p3_cmd_bl        (c3_p3_cmd_bl),
		.c3_p3_cmd_byte_addr (c3_p3_cmd_byte_addr),
		.c3_p3_wr_mask       (c3_p3_wr_mask),
		.c3_p3_wr_full       (c3_p3_wr_full),
		.c3_p3_wr_empty      (c3_p3_wr_empty),
		.c3_p3_wr_count      (c3_p3_wr_count),
		.c3_p3_wr_data       (c3_p3_wr_data),
		.c3_p3_rd_data       (c3_p3_rd_data),
		.c3_p3_rd_count      (c3_p3_rd_count),
		.c3_p3_rd_en         (c3_p3_rd_en),
		.c3_p3_rd_empty      (c3_p3_rd_empty),
		.c3_p3_wr_en         (c3_p3_wr_en)
	);



	// Read line-buffer
	//reg [7:0] rd_line_buffer_1 [0:H_IMG_RES-1];
	//reg [7:0] rd_line_buffer_2 [0:H_IMG_RES-1];
	//reg [7:0] Data_OUT_1_GRAY_8;
	//Inserted by me -----------
	reg [7:0] rd_line_buffer_r [0:H_IMG_RES-1];
	reg [7:0] rd_line_buffer_g [0:H_IMG_RES-1];
	reg [7:0] rd_line_buffer_b [0:H_IMG_RES-1];
	reg [7:0] Data_OUT_1_RED_8;
	reg [7:0] Data_OUT_1_GREEN_8;
	reg [7:0] Data_OUT_1_BLUE_8;
	reg [23:0] op_block_buffer [0:4][0:H_IMG_RES-1];
	reg [23:0] op_line_buffer [0:H_IMG_RES-1];
	//--------------------------
	//reg [7:0] Data_OUT_2_GRAY_8;
	wire [9:0] wr_buff_add;
	//reg  [9:0] rd_buff_2_addr = 0;
	wire       wr_en;
	//
	wire [31:0] buff_data_in;
	// RGB888 to GRAY8 conversion
	wire [7:0]  buff_R      = buff_data_in[23:16];
	wire [7:0]  buff_G      = buff_data_in[15:8];
	wire [7:0]  buff_B      = buff_data_in[7:0];
	//wire [9:0]  buff_G_conv = buff_G << 1;
	//wire [7:0]  buff_gray   = (buff_R + buff_G_conv + buff_B) >> 2;
	wire [9:0] r_px = (wr_buff_add == H_IMG_RES-1) ? -10'b1 : 10'b1;
	wire [9:0] l_px = (wr_buff_add == 0) ? -10'b1 : 10'b1;
	// Write buffer from external RAM and RAM clock
	always @( posedge c3_clk0 ) begin
		if( wr_en ) begin
			//rd_line_buffer_1[wr_buff_add] <= buff_gray;
			//rd_line_buffer_2[wr_buff_add] <= buff_gray;
			//Inserted by me ---------------
			op_line_buffer[wr_buff_add] <= buff_data_in[23:0]; //filling line buffer
			//TOO BIG!! use RAM instead
			rd_line_buffer_r[wr_buff_add] <= buff_B;/*
			( op_block_buffer[1][wr_buff_add+r_px][23:16] 
			+ op_block_buffer[3][wr_buff_add+r_px][23:16]
			+ op_block_buffer[2][wr_buff_add+r_px][23:16] << 1
			+ op_block_buffer[2][wr_buff_add-l_px][23:16] << 1
			+ op_block_buffer[1][wr_buff_add-l_px][23:16]
			+ op_block_buffer[3][wr_buff_add-l_px][23:16] ) >> 3;*/
			rd_line_buffer_g[wr_buff_add] <= buff_R;/*
			( op_block_buffer[1][wr_buff_add+r_px][15:8] 
			+ op_block_buffer[3][wr_buff_add+r_px][15:8]
			+ op_block_buffer[2][wr_buff_add+r_px][15:8] << 1
			+ op_block_buffer[2][wr_buff_add-l_px][15:8] << 1
			+ op_block_buffer[1][wr_buff_add-l_px][15:8]
			+ op_block_buffer[3][wr_buff_add-l_px][15:8] ) >> 3;*/
			rd_line_buffer_b[wr_buff_add] <= buff_G;/*
			( op_block_buffer[1][wr_buff_add+r_px][7:0] 
			+ op_block_buffer[3][wr_buff_add+r_px][7:0]
			+ op_block_buffer[2][wr_buff_add+r_px][7:0] << 1
			+ op_block_buffer[2][wr_buff_add-l_px][7:0] << 1
			+ op_block_buffer[1][wr_buff_add-l_px][7:0]
			+ op_block_buffer[3][wr_buff_add-l_px][7:0] ) >> 3;*/

			//------------------------------
		end
	end

	// Read buffer with video clock
	always @( posedge app_clk ) begin
		// First buffer: Display data
		//Data_OUT_1_GRAY_8 <= (vid_hpos < H_IMG_RES) ? (rd_line_buffer_1[vid_hpos]) : (8'd0);
		//Inserted by me ---------------------
		Data_OUT_1_RED_8 <= (vid_hpos < H_IMG_RES) ? (rd_line_buffer_r[vid_hpos]) : (8'd0);
		Data_OUT_1_GREEN_8 <= (vid_hpos < H_IMG_RES) ? (rd_line_buffer_g[vid_hpos]) : (8'd0);
		Data_OUT_1_BLUE_8 <= (vid_hpos < H_IMG_RES) ? (rd_line_buffer_b[vid_hpos]) : (8'd0);
		//------------------------------------
		vid_data_out      <= { Data_OUT_1_RED_8, Data_OUT_1_GREEN_8, Data_OUT_1_BLUE_8 };
		// Second buffer: Send data
		//Data_OUT_2_GRAY_8 <= rd_line_buffer_2[rd_buff_2_addr];
	end

	mem_dispatcher__read #(
		.FIFO_LENGTH    (64),
		.WORDS_TO_READ  (H_IMG_RES),
		.BUFF_ADDR_BITS (10),
		.PORT_64_BITS   (0)
	)
	mem_dispatcher__read_unit (
		// Clock
		.clk                ( c3_clk0 ),
		// Control
		.os_start           ( os_start_rd ),
		.init_mem_addr      ( init_add_rd ),
		.busy_read_unit     (),
		// Data out
		.data_out__we       ( wr_en ),
		.data_out__addr     ( wr_buff_add ),
		.data_out           ( buff_data_in ),
		// Memory interface
		.mem_calib_done     ( c3_calib_done ),
		.port_cmd_en        ( c3_p0_cmd_en ),
		.port_cmd_instr     ( c3_p0_cmd_instr ), 
		.port_cmd_bl        ( c3_p0_cmd_bl ),
		.port_cmd_byte_addr ( c3_p0_cmd_byte_addr ),
		.port_rd_en         ( c3_p0_rd_en ),
		.port_rd_data_in    ( c3_p0_rd_data ),        
		.port_rd_empty      ( c3_p0_rd_empty )    
	);


	localparam INPUT_H_RES_PIX = 640;
	localparam INPUT_V_RES_PIX = 480;
	localparam [12:0] INPUT_H_RES_PIX_FIX = INPUT_H_RES_PIX*4;
	/*
	genvar i, j; //trying some stuff
	generate
		for( i = 0; i < 5; i = i+1 ) begin
			for( j = 0; j < H_IMG_RES; j = j+1 ) begin
				if( i == 0 )
					op_block_buffer[i][j] <= op_line_buffer[j];
				else
					op_block_buffer[i][j] <= op_block_buffer[i-1][j];
			end
		end
	endgenerate
	*/
	always @( posedge app_clk ) begin

		if( vid_preload_line ) begin
			os_start_rd <= 1;
			init_add_rd <= vid_vpos*INPUT_H_RES_PIX_FIX; // TODO: Eliminate multiplier
			//op_block_buffer[1:4] <= op_block_buffer[0:3];
			//op_block_buffer[0] <= op_line_buffer; //this not good...
			/*
			for( integer i = 0; i < 5; i = i+1 ) begin
			for( integer j = 0; j < H_IMG_RES; j = j+1 ) begin
			if( i == 0 )
			op_block_buffer[i][j] <= op_line_buffer[j];
			else
			op_block_buffer[i][j] <= op_block_buffer[i-1][j];
			end
			end
			*/ 
		end
		else
			os_start_rd <= 0;
		/*
		if( app_timer_tick ) begin //pulso en hsync??
			curr_vpos   <= vid_vpos;
			active_line <= active_line__wire;
		end
		*/	
	end // always

	// ----- HDMI video receiver -----
	wire clk_vid_in;
	wire dat_valid_in, line_ready_in, frame_ready_in;
	wire [7:0] R_in, B_in, G_in;
	wire [9:0] h_pos_in;
	wire [8:0] v_pos_in;

	video_receiver #(
		.H_RES_PIX (INPUT_H_RES_PIX),
		.V_RES_PIX (INPUT_V_RES_PIX)
	)
	video_receiver_1 (
		// HDMI PINS
		.TMDS_IN     (TMDS_IN),
		.TMDS_INB    (TMDS_INB),
		.EDID_IN_SCL (EDID_IN_SCL),
		.EDID_IN_SDA (EDID_IN_SDA),
		// Clocks
		.edid_clk    (app_clk), // (in)
		.vid_clk     (clk_vid_in), // (out)
		// Video data
		.data_en     (dat_valid_in),
		.R_out       (R_in),
		.G_out       (G_in),
		.B_out       (B_in),
		.h_pos       (h_pos_in),
		.v_pos       (v_pos_in),
		// Misc signals
		.line_ready  (line_ready_in),
		.frame_ready (frame_ready_in)
	);


	mem_video__writer #(
		.H_RES_PIX (INPUT_H_RES_PIX),
		.V_RES_PIX (INPUT_V_RES_PIX),
		.BASE_ADDR (0)
	)
	mem_video__writer_1(
		// Clocks
		.vid_clk  (clk_vid_in),
		.mem_clk  (c3_clk0),
		// Video receiver interface
		.data_en     (dat_valid_in),
		.h_pos       (h_pos_in),
		.v_pos       (v_pos_in),
		.R_in        (R_in),
		.G_in        (G_in),
		.B_in        (B_in),
		.line_ready  (line_ready_in),
		.frame_ready (frame_ready_in),
		// RAM controller interface
		.mem_calib_done    (c3_calib_done),
		.mem_wr_full       (c3_p1_wr_full),
		.mem_wr_data       (c3_p1_wr_data),
		.mem_wr_en         (c3_p1_wr_en),
		.mem_cmd_instr     (c3_p1_cmd_instr),
		.mem_cmd_bl        (c3_p1_cmd_bl),
		.mem_cmd_en        (c3_p1_cmd_en),
		.mem_cmd_byte_addr (c3_p1_cmd_byte_addr)
	);


endmodule

