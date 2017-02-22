`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////

module I2C_tx_rx_TB;

	// Inputs
	reg start_operation;
	reg generate_ack;
	reg tx_data;
	reg [7:0] data_to_send;
	reg SCL_PIN;
	reg clk;

	// Outputs
	wire [7:0] data_received;
    wire byte_received;
	wire operation_completed;
	wire start_cond;
	wire stop_cond;
	wire line_ack;

	// Bidirs
	wire SDA_PIN;
    reg  SDA_PIN_master;

    assign SDA_PIN = SDA_PIN_master;
    pullup( SDA_PIN );

	// Instantiate the Unit Under Test (UUT)
	I2C_BYTE_TX_RX uut (
		.data_received(data_received),
        .byte_received(byte_received),
		.operation_completed(operation_completed), 
		.start_cond(start_cond), 
		.stop_cond(stop_cond), 
		.line_ack(line_ack), 
		.start_operation(start_operation), 
		.generate_ack(generate_ack), 
		.tx_data(tx_data), 
		.data_to_send(data_to_send), 
		.SCL_PIN(SCL_PIN), 
		.clk(clk), 
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

   integer clk_count, bit_count, bytes_count;

   initial begin
      SCL_PIN = 1'b1;
      #150
      
      for( clk_count = 0; clk_count < 2*30; clk_count = clk_count + 1 )
         #(PERIOD_2/2) SCL_PIN = ~SCL_PIN;

   end
   
   
wire [0:7] byte_send_master = 8'hA1;
////////////////////////////////
	initial begin
		// Initialize Inputs
		start_operation = 0;
		generate_ack = 0;
		tx_data = 0;
		data_to_send = 0;
        SDA_PIN_master = 1'b1;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
        #PERIOD_2
        SDA_PIN_master <= 0; // Señal de comienzo
        
        #(PERIOD_2/2)
        
        for( bit_count = 0; bit_count < 8; bit_count = bit_count + 1 ) begin
            if( tx_data )
                SDA_PIN_master <= 1'bz;
            else
                SDA_PIN_master <= byte_send_master[bit_count];
            #PERIOD_2;
        end
        
        SDA_PIN_master <= 1'bz;
        
         
        
        
	end


    always @( posedge clk ) begin
        
        if( byte_received && ~tx_data ) begin
            generate_ack <= 0;
        end
        
        if( generate_ack )
            generate_ack <= 0;
            
        if( start_operation )
            start_operation <= 0;
            
            
        if( start_cond ) begin
            data_to_send <= 8'hC1;
            tx_data <= 1;
            start_operation <= 1;
        end
    end



endmodule

