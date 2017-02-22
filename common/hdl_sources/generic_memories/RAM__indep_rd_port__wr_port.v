`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
//
// Revisions:
// + 2014/07/14: File Created
// + 2014/07/15: Added RAM initialization file
//
//////////////////////////////////////////////////////////////////////////////////

module RAM__indep_rd_port__wr_port (
        // Write port
        wr_port_clk,
        wr_port_addr,
        wr_port_we,
        wr_port_din,
        // Read port
        rd_port_clk,
        rd_port_addr,
        rd_port_dout        
    );


// ---------- INCLUDES ----------
`include "verilog_utils.vh"


// ---------- PARAMETERS ----------
    // Total elements for the memory
    parameter WORDS_COUNT = 512;
    // Bits per element
    parameter WORDS_BITS  = 8;
    // (OPTIONAL) Default value (0) will automatically calculate the port width. 
    parameter ADDR_BITS  = 0;
    // (OPTIONAL)
    // RAM init file: Relative path from current working directory.
    parameter RAM_INIT_FILE = "";


// ---------- LOCAL PARAMETERS ----------
    localparam LOC_ADDR_BITS = (ADDR_BITS!=0)? (ADDR_BITS) : (ceil_log2(WORDS_COUNT-1));


// ---------- INPUTS AND OUTPUTS ----------
    // Write port
    input wire                     wr_port_clk;
    input wire [LOC_ADDR_BITS-1:0] wr_port_addr;
    input wire                     wr_port_we;
    input wire [WORDS_BITS-1:0]    wr_port_din;
    // Read port
    input wire                     rd_port_clk;
    input wire [LOC_ADDR_BITS-1:0] rd_port_addr;
    output reg [WORDS_BITS-1:0]    rd_port_dout;
    


// ---------- MODULE ----------
    // Memory data
    reg [WORDS_BITS-1:0] memory_data [0:WORDS_COUNT-1];
    
    generate if( RAM_INIT_FILE != "" ) begin
        initial $readmemh( RAM_INIT_FILE, memory_data, 0, WORDS_COUNT-1 );
    end
    endgenerate
    
    // Write
    always @( posedge wr_port_clk ) begin
        if( wr_port_we )
            memory_data[wr_port_addr] <= wr_port_din;
    end

    // Read
    always @( posedge rd_port_clk ) begin
        rd_port_dout <= memory_data[rd_port_addr];
    end



endmodule
