`timescale 1ns / 1ps



module sig_delay( clk, i_bus, o_bus );

// ---------- INCLUDES ----------


// ---------- PARAMETERS ----------
    parameter BUS_BITS = 1;
    parameter DELAY    = 0;
    

// ---------- LOCAL PARAMETERS ----------


// ---------- INPUTS AND OUTPUTS ----------
    input  wire                 clk;
    input  wire [BUS_BITS-1:0] i_bus;
    output wire [BUS_BITS-1:0] o_bus;


// ---------- MODULE ----------
    
    genvar i;
    generate
        case( DELAY )
        0: begin
            assign o_bus = i_bus;
        end
        1: begin
            reg [BUS_BITS-1:0] shift_reg_1 = 0;
            always @( posedge clk ) begin
                shift_reg_1 <= i_bus;
            end
            assign o_bus = shift_reg_1;
        end
        default: begin // 2 and up
           reg [DELAY-1:0] shift_reg_n [BUS_BITS-1:0];
           for( i = 0; i < BUS_BITS; i = i + 1 ) shift_reg_delay: begin
              always @( posedge clk )
                shift_reg_n[i] <= { shift_reg_n[i][DELAY-2:0], i_bus[i] };
                     
              assign o_bus[i] = shift_reg_n[i][DELAY-1];
           end
        end
        endcase
    endgenerate

endmodule
