//`default_nettype none
`timescale 1ns / 1ps

module Hpos_Vpos_VidEn_gen(
        // Clock and reset
        vid_clk,
        reset, // Synchronous
        // Inputs
        Hsync,
        Vsync,
        Active_pix,
        pixel_in,
        // Outputs
        Hpos,
        Vpos,
        VidEn,
        pixel_out,
        line_ready,
        frame_ready
    );

// ---------- PARAMETERS ----------
    parameter H_RES_PIX       = 640;
    parameter V_RES_PIX       = 480;
    parameter BITS_PER_PIXEL  = 24;
    parameter LINE_READY_COMP = H_RES_PIX-1;

// ---------- LOCAL PARAMETERS ----------
    localparam H_POS_BITS = ceil_log2( H_RES_PIX - 1 );
    localparam V_POS_BITS = ceil_log2( V_RES_PIX - 1 );


// ---------- INPUTS AND OUTPUTS ----------
    // Clock and reset
    input wire                      vid_clk; // Synchronous
    input wire                      reset;
    // Inputs
    input wire                      Hsync;
    input wire                      Vsync;
    input wire                      Active_pix;
    input wire [BITS_PER_PIXEL-1:0] pixel_in;
    // Outputs
    output reg [H_POS_BITS-1:0]     Hpos        = 0;
    output reg [V_POS_BITS-1:0]     Vpos        = 0;
    output reg                      VidEn       = 0;
    output reg [BITS_PER_PIXEL-1:0] pixel_out   = 0;
    output reg                      line_ready  = 0;
    output reg                      frame_ready = 0;


// ---------- MODULE ----------

    reg       waiting_vsync = 1;
    reg       waiting_hsync = 1;
    
    reg [1:0] v_sync_shift      = 0;
    reg [1:0] h_sync_shift      = 0;
    reg       waiting_first_pix = 1;

    always @( posedge vid_clk ) begin
        // Shift registers. Used to detect posedge of signals
        v_sync_shift <= { v_sync_shift[0], Vsync };
        h_sync_shift <= { h_sync_shift[0], Hsync };
        // One clock cycle signals
        if( line_ready == 1 )
            line_ready <= 0;
        if( frame_ready == 1 )
            frame_ready <= 0;
        
        if( reset ) begin
            Hpos          <= 0; // Outputs
            Vpos          <= 0;
            VidEn         <= 0;
            waiting_vsync <= 1; // Internal signals
            waiting_hsync <= 1;
        end
        else if( v_sync_shift == 2'b01 ) begin // Vertical sync
            Vpos              <= 0;
            waiting_vsync     <= 0;
            waiting_hsync     <= 0;
            Hpos              <= 0;
            waiting_first_pix <= 1;
        end
        else if( h_sync_shift == 2'b01 ) begin // Horizontal sync
            Hpos              <= 0;
            waiting_hsync     <= 0;
            waiting_first_pix <= 1;
            if( Vpos != V_RES_PIX-1 ) begin
                if( waiting_first_pix == 0 )
                    Vpos <= Vpos + 1'b1;
            end
            else
                waiting_vsync <= 1;
        end
        else if( (waiting_vsync == 0) && (waiting_hsync == 0) ) begin // Waiting active pixels
            
            if( Active_pix == 1 ) begin
                VidEn     <= 1;
                pixel_out <= pixel_in;
                if( waiting_first_pix == 1 )
                    waiting_first_pix <= 0;
                else begin
                    
                    if( Hpos != H_RES_PIX-1 )
                        Hpos <= Hpos + 1'b1;
                    else begin
                        VidEn         <= 0;
                        waiting_hsync <= 1;
                    end
                    //
                    if( Hpos == LINE_READY_COMP-1 ) begin
                        line_ready    <= 1;
                        if( Vpos == V_RES_PIX-1 )
                            frame_ready <= 1;
                    end
                end
            end
            else
                VidEn <= 0;
            
        end

    end // always


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