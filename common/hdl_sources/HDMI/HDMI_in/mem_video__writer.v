//`default_nettype none
`timescale 1ns / 1ps

module mem_video__writer (
        // Clocks
		mem_clk,
        vid_clk,
        // Video decoder interface
        data_en,
        h_pos,
        v_pos,
		R_in,
        G_in,
        B_in,
        line_ready,
        frame_ready,
        // RAM controller interface
        mem_calib_done,
        mem_wr_full,
        mem_wr_en,
        mem_wr_data,
		mem_cmd_instr,
		mem_cmd_bl,
		mem_cmd_en,
		mem_cmd_byte_addr
	);


  // ---------- PARAMETERS ----------
    parameter        H_RES_PIX  = 640;
    parameter        V_RES_PIX  = 480;
    parameter [29:0] BASE_ADDR  = 0;
    //
    parameter        USE_MULT   = 1;

  // ---------- LOCAL PARAMETERS ----------
    localparam H_ADDR_BITS   = ceil_log2( H_RES_PIX - 1 );
    localparam V_ADDR_BITS   = ceil_log2( V_RES_PIX - 1 );
    localparam MEM_PORT_BITS = 32;
    
    localparam [29:0] H_RES_PIX_FIX = 4*H_RES_PIX; // Bytes per pixel
    
  // ---------- INPUTS AND OUTPUTS ----------
    // Clocks
    input  wire                  mem_clk;
    input  wire                  vid_clk;
    // Video decoder interface
    input wire                   data_en;
    input wire [7:0]             R_in;
    input wire [7:0]             G_in;
    input wire [7:0]             B_in;
    input wire [H_ADDR_BITS-1:0] h_pos;
    input wire [V_ADDR_BITS-1:0] v_pos;
    input wire                   line_ready;
    input wire                   frame_ready;
    // RAM controller interface
    input  wire                     mem_calib_done;
    input  wire                     mem_wr_full;
    output wire                     mem_wr_en;
    output wire [MEM_PORT_BITS-1:0] mem_wr_data;
    output wire [2:0]               mem_cmd_instr;
    output wire [5:0]               mem_cmd_bl;
    output wire                     mem_cmd_en;
    output wire [29:0]              mem_cmd_byte_addr;

  // ---------- MODULE ----------
	
    // Dispatcher write interface
    wire [H_ADDR_BITS-1:0] data_in__addr;
    reg  [23:0]            data_in     = 0; // RGB pixel
    reg                    write_line  = 0; // Start signal
    reg  [29:0]            init_add_wr = 0;


    mem_dispatcher__write #
	(
		.MICRO_TOP        (64),
		.MACRO_TOP        (H_RES_PIX),
		.RAM_ADDR_BITS    (H_ADDR_BITS),
		.DDR_PORT_BITS    (32)
	)
    mem_dispatcher__write_unit 
	(
		.clk                (mem_clk),
        // Interfaz de control
		.os_start           (write_line),
		.init_mem_addr      (init_add_wr),
        .busy_unit          (),
        // Entrada de datos
		.data_in__addr      (data_in__addr),
		.data_in            ({8'd0,data_in}),
        // Interfaz con memoria externa
        .mem_calib_done     (mem_calib_done),
        .port_cmd_en        (mem_cmd_en),
		.port_cmd_instr     (mem_cmd_instr),
		.port_cmd_bl        (mem_cmd_bl),
		.port_cmd_byte_addr (mem_cmd_byte_addr),
        .port_wr_en         (mem_wr_en),
		.port_wr_data_out   (mem_wr_data),
		.port_wr_full       (mem_wr_full)
	);   
   
   
    // Line buffer
    reg [23:0] line_buffer [0:H_RES_PIX-1];
   
    reg [V_ADDR_BITS-1:0] v_count = 0; 
   
    // Read from buffer with memory clock
    always @( posedge mem_clk ) begin
        data_in <= line_buffer[data_in__addr];
    end
   
    // Write to buffer with video clock
    always @( posedge vid_clk ) begin
        if( data_en )
            line_buffer[h_pos] <= { R_in, G_in, B_in };
    end

    
    // Dispatcher control
    reg  start_write;
    wire OS_start_write;
    
    //one_shot one_shot_1( OS_start_write, start_write, mem_clk );
    
    Flag_CrossDomain
    Flag_CrossDomain_1(
        .clkA         (vid_clk),
        .FlagIn_clkA  (start_write),
        .clkB         (mem_clk),
        .FlagOut_clkB (OS_start_write)
    );
    

    generate if( USE_MULT == 1 ) begin
        always @( posedge vid_clk ) begin
            if( start_write )
                start_write <= 0;
            if( line_ready ) begin
                v_count     <= v_pos;
                start_write <= 1;
            end
        end
        //
        always @( posedge mem_clk ) begin
            if( OS_start_write ) begin
                write_line  <= 1;
                init_add_wr <= BASE_ADDR + H_RES_PIX_FIX*v_count;
            end
            else
                write_line <= 0;
        end
    end
    else begin // NO MULT
        reg [1:0] reset_addr_shift = 0;
        
        always @( posedge vid_clk ) begin
            if( start_write )
                start_write <= 0;
            if( line_ready ) begin
                reset_addr_shift <= {reset_addr_shift[0],frame_ready};
                start_write <= 1;
            end
        end
        //
        always @( posedge mem_clk ) begin
            if( OS_start_write ) begin
                write_line  <= 1;
                if( reset_addr_shift[1] )
                    init_add_wr <= BASE_ADDR;
                else
                    init_add_wr <= init_add_wr + H_RES_PIX_FIX;
            end
            else
                write_line <= 0;
        end
    end
    endgenerate
    
    
    
    
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
