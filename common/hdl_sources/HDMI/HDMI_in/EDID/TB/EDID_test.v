`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
module EDID_test;

	// Inputs
	reg clk;
	reg SCL_PIN;

	// Bidirs
	wire SDA_PIN;
    reg  SDA_PIN_master;

    assign SDA_PIN = SDA_PIN_master;
    pullup( SDA_PIN );


	// Instantiate the Unit Under Test (UUT)
	EDID_I2C uut (
		.clk(clk), 
		.SCL_PIN(SCL_PIN), 
		.SDA_PIN(SDA_PIN)
	);




//////////// Reloj sistema
   parameter PERIOD = 4;

   initial begin
      clk = 1'b0;
      #100
      #(PERIOD/2);
      forever
         #(PERIOD/2) clk = ~clk;
   end
////////////////////////////////


//////////// Reloj SCL
   parameter PERIOD_2 = 50;

   integer /*clk_count,*/ bytes_count = 0;

   initial begin
      SCL_PIN = 1'b1;
      #150
      
      //for( clk_count = 0; clk_count < 2*30; clk_count = clk_count + 1 )
      forever begin
         #(PERIOD_2/2) SCL_PIN = ~SCL_PIN;
      end

   end
////////////////////////////////

integer bit_count = 0, byte_count = 0;

wire read_from_EDID = 1;
reg [0:7] ctrl_word_master = 0;
reg [0:7] mem_addr_master = 0;
reg [7:0] master_data_rec = 0;

///////// PIN SDA
initial begin
    // Inicial    
    SDA_PIN_master = 1;
    master_data_rec = 8'hxx;
    
    // Condicion start
    #152
    SDA_PIN_master = 0;
    #(PERIOD_2/2)
    
    // Prueba de lectura
    if( read_from_EDID ) begin
    
        ctrl_word_master = 8'hA1;
        
        // Enviar direccion de lectura
        for( bit_count = 0; bit_count < 8; bit_count = bit_count + 1 ) begin
            SDA_PIN_master <= ctrl_word_master[bit_count];
            #PERIOD_2;
        end
        
        // Esperar ACK
        SDA_PIN_master = 1'bz;
        #PERIOD_2;
        

        // Leer bytes transmitidos
        for( byte_count = 0; byte_count < 8; byte_count = byte_count + 1 ) begin
            SDA_PIN_master = 1'bz;
            
            
            for( bit_count = 0; bit_count < 8; bit_count = bit_count + 1 ) begin
                #(PERIOD_2/2 + 2);
                master_data_rec[7-bit_count] <= SDA_PIN;
                #(PERIOD_2/2 - 2);
            end
            
            SDA_PIN_master = 1'b0;
            #PERIOD_2;
        end

    end
    // Condicion de stop
    //#PERIOD_2
    //SDA_PIN_driver = 1;
    
end
////////////////////////////////


endmodule
