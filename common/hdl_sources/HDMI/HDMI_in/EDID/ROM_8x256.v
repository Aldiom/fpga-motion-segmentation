//`default_nettype none
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////
module ROM_8x256( output reg [7:0] data_out,
                  input wire clk, input wire enable, input wire [7:0] data_address
                 );

    // Archivo con el contenido de la memoria
    parameter rom_init_file = "rom_data/rom_ATLYS_sample.coe";

    // Definir ROM
    reg [7:0] EDID_ROM [255:0];


    // Inicializarla
    initial
    begin
        $readmemh( rom_init_file, EDID_ROM, 0, 255 );
    end

      
    // Leer si está habilitada
    always @( posedge clk )
    begin
       if( enable )
       begin
          data_out <= EDID_ROM[data_address];
       end
    end


endmodule
