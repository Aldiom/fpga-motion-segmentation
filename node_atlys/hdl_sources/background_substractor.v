`timescale 1ns / 1ps

module background_substractor (
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
	input  wire        vid_preload_line,
	input  wire        vid_active_pix,
	input  wire [10:0] vid_hpos,
	input  wire [10:0] vid_vpos,
	output reg  [23:0] vid_data_out,
	// Switches
	input  wire [7:0]  switch
	);

	// ---------- PARAMETERS ----------
	//none
	
	// ---------- LOCAL PARAMETERS ----------
	localparam VARRAM_VAR_1_MAX_SIZE = 160; // 150 = 600 px; 160 = 640 px
	localparam PIXELS_PER_WORD       = 4;   // 8 bits gray-scale
	localparam H_IMG_RES             = PIXELS_PER_WORD*VARRAM_VAR_1_MAX_SIZE;
	localparam V_IMG_RES             = 480;
	localparam FG_TRESHOLD           = 60;

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
	// Port 2: Read
		//assign c3_p2_rd_en = 0;
		assign c3_p2_wr_en = 0;
	// Port 3: Write
		assign c3_p3_rd_en = 0;
		//assign c3_p3_wr_en = 0;

	///////////////
	reg [29:0] init_add_rd = 0; // (Dispatcher in?)
	reg        os_start_rd = 0; // (Dispatcher in?)
	
	reg [29:0] bg_init_add_rd = BG_MEM_OFFSET; // Bg read dispatcher
	reg        bg_start_rd = 0;
	
	reg [29:0] bg_init_add_wr = BG_MEM_OFFSET; // Bg write dispatcher
	reg        bg_start_wr = 0;

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
	reg [7:0] line_buffer_r [0:H_IMG_RES-1];
	reg [7:0] line_buffer_g [0:H_IMG_RES-1];
	reg [7:0] line_buffer_b [0:H_IMG_RES-1];
	// Background line-buffer
	reg [7:0] bg_buffer_r [0:H_IMG_RES-1];
	reg [7:0] bg_buffer_g [0:H_IMG_RES-1];
	reg [7:0] bg_buffer_b [0:H_IMG_RES-1];
	// Diff line-buffer
	reg [7:0] diff_buffer_r [0:H_IMG_RES-1];
	reg [7:0] diff_buffer_g [0:H_IMG_RES-1];
	reg [7:0] diff_buffer_b [0:H_IMG_RES-1];
	// Update line_buffer
	//reg [7:0] updt_buffer_r [0:H_IMG_RES-1];
	//reg [7:0] updt_buffer_g [0:H_IMG_RES-1];
	//reg [7:0] updt_buffer_b [0:H_IMG_RES-1];
	
	reg [7:0] Data_OUT_1_RED_8;
	reg [7:0] Data_OUT_1_GREEN_8;
	reg [7:0] Data_OUT_1_BLUE_8;
	//reg [23:0] op_block_buffer [0:4][0:H_IMG_RES-1];
	//reg [23:0] op_line_buffer [0:H_IMG_RES-1];
	wire [9:0] wr_buff_add;
	wire       wr_en;
	wire [9:0] bg_wr_buff_add;
	wire       bg_wr_en;
	wire [9:0] bg_rd_buff_add;
	//
	wire [31:0] buff_data_in;
	wire [31:0] bg_buff_data_in;
	// RGB888 from read byte
	wire [7:0]  buff_R = buff_data_in[23:16];
	wire [7:0]  buff_G = buff_data_in[15:8];
	wire [7:0]  buff_B = buff_data_in[7:0];
	wire [7:0]  bg_R   = bg_buff_data_in[23:16];
	wire [7:0]  bg_G   = bg_buff_data_in[15:8];
	wire [7:0]  bg_B   = bg_buff_data_in[7:0];	
	
	//wire [9:0] r_px = (wr_buff_add == H_IMG_RES-1) ? -10'b1 : 10'b1;//this was for filter
	//wire [9:0] l_px = (wr_buff_add == 0) ? -10'b1 : 10'b1;
	// Write buffer from external RAM and RAM clock
	reg [15:0] diff_pipe_r;
	reg [15:0] diff_pipe_g;
	reg [15:0] diff_pipe_b;
	always @( posedge c3_clk0 ) begin
		if( wr_en ) begin
			line_buffer_r[wr_buff_add] <= buff_R;
			line_buffer_g[wr_buff_add] <= buff_G;
			line_buffer_b[wr_buff_add] <= buff_B;
		end
		
		if( bg_wr_en ) begin
			bg_buffer_r[bg_wr_buff_add] <= bg_R;
			bg_buffer_g[bg_wr_buff_add] <= bg_G;
			bg_buffer_b[bg_wr_buff_add] <= bg_B;
		end 
		
		//pipeline for splitting time delay of critical path
		diff_pipe_r <= (line_buffer_r[vid_hpos] > bg_buffer_r[vid_hpos]) ?
							{line_buffer_r[vid_hpos], bg_buffer_r[vid_hpos]}: 
							{bg_buffer_r[vid_hpos], line_buffer_r[vid_hpos]};
		diff_pipe_g <= (line_buffer_g[vid_hpos] > bg_buffer_g[vid_hpos]) ?
							{line_buffer_g[vid_hpos], bg_buffer_g[vid_hpos]}: 
							{bg_buffer_g[vid_hpos], line_buffer_g[vid_hpos]};
		diff_pipe_b <= (line_buffer_b[vid_hpos] > bg_buffer_b[vid_hpos]) ?
							{line_buffer_b[vid_hpos], bg_buffer_b[vid_hpos]}: 
							{bg_buffer_b[vid_hpos], line_buffer_b[vid_hpos]};
		diff_buffer_r[vid_hpos] <= diff_pipe_r[15:8] - diff_pipe_r[7:0];
		diff_buffer_g[vid_hpos] <= diff_pipe_g[15:8] - diff_pipe_g[7:0];
		diff_buffer_b[vid_hpos] <= diff_pipe_b[15:8] - diff_pipe_b[7:0];
							
	end
	
	//Compare Img with Bg using manhattan (L1) distance *changed for pipelined process*
	/*
	wire [7:0] diff_r = (line_buffer_r[vid_hpos] > bg_buffer_r[vid_hpos]) ?
	(line_buffer_r[vid_hpos] - bg_buffer_r[vid_hpos]): 
	(bg_buffer_r[vid_hpos] - line_buffer_r[vid_hpos]);
	wire [7:0] diff_g = (line_buffer_g[vid_hpos] > bg_buffer_g[vid_hpos]) ?
	(line_buffer_g[vid_hpos] - bg_buffer_g[vid_hpos]): 
	(bg_buffer_g[vid_hpos] - line_buffer_g[vid_hpos]);
	wire [7:0] diff_b = (line_buffer_b[vid_hpos] > bg_buffer_b[vid_hpos]) ?
	(line_buffer_b[vid_hpos] - bg_buffer_b[vid_hpos]): 
	(bg_buffer_b[vid_hpos] - line_buffer_b[vid_hpos]);
	*/
	
	wire [9:0] total_diff = diff_buffer_r[vid_hpos] + diff_buffer_g[vid_hpos] + diff_buffer_b[vid_hpos];
	
	wire foreground = (total_diff > FG_TRESHOLD);
	
	// Read buffer with video clock
	always @( posedge app_clk ) begin
		// Display data
		if( switch[1:0] == 2'b00 ) begin
			Data_OUT_1_RED_8 <= (vid_hpos < H_IMG_RES) ? {8{foreground}} : (8'd0);
			Data_OUT_1_GREEN_8 <= (vid_hpos < H_IMG_RES) ? {8{foreground}} : (8'd0);
			Data_OUT_1_BLUE_8 <= (vid_hpos < H_IMG_RES) ? {8{foreground}} : (8'd0);
		end
		else if( switch[1:0] == 2'b01 ) begin
			Data_OUT_1_RED_8 <= (vid_hpos < H_IMG_RES) ? (line_buffer_r[vid_hpos]) : (8'd0);
			Data_OUT_1_GREEN_8 <= (vid_hpos < H_IMG_RES) ? (line_buffer_g[vid_hpos]) : (8'd0);
			Data_OUT_1_BLUE_8 <= (vid_hpos < H_IMG_RES) ? (line_buffer_b[vid_hpos]) : (8'd0);	
		end
		else begin
			Data_OUT_1_RED_8 <= (vid_hpos < H_IMG_RES) ? (bg_buffer_r[vid_hpos]) : (8'd0);
			Data_OUT_1_GREEN_8 <= (vid_hpos < H_IMG_RES) ? (bg_buffer_g[vid_hpos]) : (8'd0);
			Data_OUT_1_BLUE_8 <= (vid_hpos < H_IMG_RES) ? (bg_buffer_b[vid_hpos]) : (8'd0);
		end
		vid_data_out      <= { Data_OUT_1_RED_8, Data_OUT_1_GREEN_8, Data_OUT_1_BLUE_8 };
	end
	
	// Line buffer RAM reader
	mem_dispatcher__read #(
		.FIFO_LENGTH    (64),
		.WORDS_TO_READ  (H_IMG_RES),
		.BUFF_ADDR_BITS (10),
		.PORT_64_BITS   (0)
	)
	mem_dispatcher_read_frame (
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
	
	// Background RAM reader
	mem_dispatcher__read #(
		.FIFO_LENGTH    (64),
		.WORDS_TO_READ  (H_IMG_RES),
		.BUFF_ADDR_BITS (10),
		.PORT_64_BITS   (0)
	)
	mem_dispatcher_read_bg (
		// Clock
		.clk                ( c3_clk0 ),
		// Control
		.os_start           ( bg_start_rd ),
		.init_mem_addr      ( bg_init_add_rd ),
		.busy_read_unit     (),
		// Data out
		.data_out__we       ( bg_wr_en ),
		.data_out__addr     ( bg_wr_buff_add ),
		.data_out           ( bg_buff_data_in ),
		// Memory interface
		.mem_calib_done     ( c3_calib_done ),
		.port_cmd_en        ( c3_p2_cmd_en ),
		.port_cmd_instr     ( c3_p2_cmd_instr ), 
		.port_cmd_bl        ( c3_p2_cmd_bl ),
		.port_cmd_byte_addr ( c3_p2_cmd_byte_addr ),
		.port_rd_en         ( c3_p2_rd_en ),
		.port_rd_data_in    ( c3_p2_rd_data ),        
		.port_rd_empty      ( c3_p2_rd_empty )    
	);
	/*	
	wire [7:0] bg_rd_r = bg_buffer_r[bg_rd_buff_add];
	wire [7:0] bg_rd_g = bg_buffer_g[bg_rd_buff_add];
	wire [7:0] bg_rd_b = bg_buffer_b[bg_rd_buff_add];
	wire [7:0] ln_rd_r = line_buffer_r[bg_rd_buff_add];
	wire [7:0] ln_rd_g = line_buffer_g[bg_rd_buff_add];
	wire [7:0] ln_rd_b = line_buffer_b[bg_rd_buff_add];
	wire [9:0] sum_r = bg_rd_r + bg_rd_r + bg_rd_r + ln_rd_r;
	wire [9:0] sum_g = bg_rd_g + bg_rd_g + bg_rd_g + ln_rd_g;
	wire [9:0] sum_b = bg_rd_b + bg_rd_b + bg_rd_b + ln_rd_b;
	*/
	wire [7:0] bg_update_r = (15 * bg_buffer_r[bg_rd_buff_add] + line_buffer_r[bg_rd_buff_add]) >> 4;
	wire [7:0] bg_update_g = (15 * bg_buffer_g[bg_rd_buff_add] + line_buffer_g[bg_rd_buff_add]) >> 4;
	wire [7:0] bg_update_b = (15 * bg_buffer_b[bg_rd_buff_add] + line_buffer_b[bg_rd_buff_add]) >> 4;
	
	// Background RAM updater
	mem_dispatcher__write #
	(
		.MICRO_TOP        (64),
		.MACRO_TOP        (H_IMG_RES),
		.RAM_ADDR_BITS    (10),
		.DDR_PORT_BITS    (32)
	)
	mem_dispatcher_write_unit 
	(
		.clk                ( c3_clk0 ),
		// Interfaz de control
		.os_start           ( bg_start_wr ),
		.init_mem_addr      ( bg_init_add_wr ),
		.busy_unit          (),
		// Entrada de datos
		.data_in__addr      ( bg_rd_buff_add ),
		.data_in            ( {8'd0, bg_update_r, bg_update_g, bg_update_b} ),
		// Interfaz con memoria externa
		.mem_calib_done     ( c3_calib_done ),
		.port_cmd_en        ( c3_p3_cmd_en ),
		.port_cmd_instr     ( c3_p3_cmd_instr ),
		.port_cmd_bl        ( c3_p3_cmd_bl ),
		.port_cmd_byte_addr ( c3_p3_cmd_byte_addr ),
		.port_wr_en         ( c3_p3_wr_en ),
		.port_wr_data_out   ( c3_p3_wr_data ),
		.port_wr_full       ( c3_p3_wr_full )
	);   
	
	localparam INPUT_H_RES_PIX = 640;
	localparam INPUT_V_RES_PIX = 480;
	localparam [12:0] INPUT_H_RES_PIX_FIX = INPUT_H_RES_PIX*4;
	localparam [29:0] BG_MEM_OFFSET = INPUT_H_RES_PIX*INPUT_V_RES_PIX*4 + 30'd256;
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
	
	reg        updating_bg     = 0;
	reg  [5:0] delay_counter   = 0;
	reg  [9:0] update_bg_count = 0;
	wire       active_line     = (vid_preload_line) & (vid_vpos < V_IMG_RES);
	wire [9:0] refresh_rate    = (switch[2]) ? 10'd9 : 10'd599;

	always @( posedge app_clk ) begin
	
		if( vid_preload_line ) begin
			os_start_rd <= 1;
			init_add_rd <= vid_vpos * INPUT_H_RES_PIX_FIX; // TODO: Eliminate multiplier
			bg_start_rd <= 1;
			bg_init_add_rd <= vid_vpos * INPUT_H_RES_PIX_FIX + BG_MEM_OFFSET;
		end
		else begin
			os_start_rd <= 0;
			bg_start_rd <= 0;
		end
		
		// Waiting start signal
		if( ~updating_bg ) begin
			delay_counter <= 0;
			bg_start_wr   <= 0;
			//
			if( app_timer_tick ) begin
				if( vid_vpos == (V_IMG_RES-1) )
					update_bg_count <= (update_bg_count < refresh_rate) ? update_bg_count + 10'b1 : 10'b0;
				if( update_bg_count == 0 ) begin
					// Por alguna razon hay un offset adicional en la escritura
					bg_init_add_wr <= vid_vpos * INPUT_H_RES_PIX_FIX + BG_MEM_OFFSET + 4;
					updating_bg    <= active_line;
				end
			end
		end
		// Wait for read buffers to update
		else begin
			delay_counter <= delay_counter + 1;
			if( delay_counter == 30 ) begin
				bg_start_wr <= 1;
				updating_bg <= 0;
			end
		end
		
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

