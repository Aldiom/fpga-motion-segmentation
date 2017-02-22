//`default_nettype none
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module EDID_I2C( input wire clk, input wire SCL_PIN, inout wire SDA_PIN );


    // Archivo con el contenido de la memoria
    parameter rom_init_file = "\"ERROR=PLEASE_SPECIFY_INIT_ROM_FILE\"";



    // Cables/Buses para interconectar modulos
    wire [15:0] ctrl_to_I2Cbus;
    wire [7:0]  ctrl_to_ROM;
    wire [7:0]  ROM_to_I2Cbus;





// --- Modulo de control

    I2C_EDID_protocol_ctrl I2C_EDID_protocol_ctrl__1 (
            .data_received( ctrl_to_I2Cbus[7:0] ), 
            .byte_received( ctrl_to_I2Cbus[8] ), 
            .operation_completed( ctrl_to_I2Cbus[9] ),
            .start_cond( ctrl_to_I2Cbus[10] ),
            .stop_cond( ctrl_to_I2Cbus[11] ),
            .line_ack( ctrl_to_I2Cbus[12] ),
            .start_operation( ctrl_to_I2Cbus[13] ),
            .generate_ack( ctrl_to_I2Cbus[14] ),
            .tx_data( ctrl_to_I2Cbus[15] ),
            .word_offset( ctrl_to_ROM[7:0] ),
            .clk( clk )
        );




// --- Modulo de envio/recepcion de byte I2C

    I2C_BYTE_TX_RX I2C_BYTE_TX_RX__1 (
        .data_received( ctrl_to_I2Cbus[7:0] ),
        .byte_received( ctrl_to_I2Cbus[8] ),
        .operation_completed( ctrl_to_I2Cbus[9] ), 
        .start_cond( ctrl_to_I2Cbus[10] ), 
        .stop_cond( ctrl_to_I2Cbus[11] ), 
        .line_ack( ctrl_to_I2Cbus[12] ), 
        .start_operation( ctrl_to_I2Cbus[13] ), 
        .generate_ack( ctrl_to_I2Cbus[14] ), 
        .tx_data( ctrl_to_I2Cbus[15] ), 
        .data_to_send( ROM_to_I2Cbus[7:0] ), 
        .SCL_PIN( SCL_PIN ),
        .SDA_PIN( SDA_PIN ),
        .clk( clk )
    );





// --- Modulo memoria ROM

    ROM_8x256 #( .rom_init_file(rom_init_file) ) ROM_8x256__1 (
        .data_out( ROM_to_I2Cbus[7:0] ),
        .enable( 1'b1 ),
        .data_address( ctrl_to_ROM[7:0] ),
        .clk( clk )
    );



endmodule
