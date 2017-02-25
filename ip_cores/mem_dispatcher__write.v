`timescale 1ns / 1ps
module mem_dispatcher__write #(
	parameter MICRO_TOP = 32,
	parameter MACRO_TOP = 640,
	parameter RAM_ADDR_BITS = 10,
	parameter DDR_PORT_BITS = 32
	)
	(
	// Reloj
	input wire clk,

	// Interfaz de control y estado
	input wire        os_start,
	input wire [29:0] init_mem_addr,
	output reg        busy_unit,


	// Entrada de datos
	output  reg [RAM_ADDR_BITS-1:0] data_in__addr,
	input  wire [DDR_PORT_BITS-1:0] data_in,

	// Interfaz con memoria externa
	input  wire                     mem_calib_done,
	output reg                      port_cmd_en,
	output reg  [2:0]               port_cmd_instr,
	output reg  [5:0]               port_cmd_bl,
	output reg  [29:0]              port_cmd_byte_addr,
	output wire                     port_wr_en,
	output wire [DDR_PORT_BITS-1:0] port_wr_data_out,
	input  wire                     port_wr_full
	);

	initial busy_unit <= 1'b1;


	reg pn_wr_en_state;
	reg [6:0] micro_count; // tiene que llegar a 64 (con 5 bits solo llega a 63)
	reg [16:0] macro_count; /*cambiado*/
	reg lock;
	reg top;
	reg [1:0] state;

	assign port_wr_en = (~port_wr_full) & pn_wr_en_state;
	assign port_wr_data_out = data_in;

	initial state = 0;
	initial port_cmd_en = 0;
	initial data_in__addr = 0;
	initial micro_count = 0;
	initial macro_count = 0;
	initial pn_wr_en_state = 0;
	initial lock = 0;
	initial top = 0;
	reg os_start_past = 0;
	reg first_burst = 1;


	always@(posedge clk) begin

		os_start_past  <= os_start;


		// Estado 0: Esperar que memoria esté calibrada
		//           No hacer nada hasta entonces
		if( state == 0 ) begin

			busy_unit <= 1'b1;

			if( mem_calib_done )
				state <= 1;
		end


		// Estado 1: En espera de señal de control
		//            para iniciar escritura
		if( state == 1 ) begin

			if( os_start ) begin
				busy_unit          <= 1'b1;
				port_cmd_byte_addr <= init_mem_addr;
				state              <= 2;
				first_burst        <= 1;
			end
			else begin
				busy_unit      <= 1'b0;
				port_cmd_en    <= 0;
				data_in__addr  <= 0;
				micro_count    <= 0;
				macro_count    <= 0;
				pn_wr_en_state <= 0;
				lock           <= 0; // asi no entra a add-1 si es que parte y esta full
				top            <= 0;
			end

		end

		// Estado 2:
		if( state == 2 ) begin
			busy_unit   <= 1'b1;
			port_cmd_en <= 0;

			if( ~port_wr_full ) begin
				if( macro_count == MACRO_TOP ) begin // siempre llega este antes que el MACRO_TOP+1
					top            <= 1;              // no es necesario ponerlo en el port_wr_full = 1 (port_wr_full se atiende un ciclo retardado)
					pn_wr_en_state <= 0;
					state          <= 3;
				end
				else begin
					pn_wr_en_state <= 1;
					micro_count    <= micro_count   + 1'b1;
					macro_count    <= macro_count   + 1'b1;
					data_in__addr  <= data_in__addr + 1'b1;
					lock           <= 1;
				end
			end
			else begin
				pn_wr_en_state <= 0;
				if( micro_count > MICRO_TOP )
					state <= 3;
				if( lock ) begin
					data_in__addr <= data_in__addr - 1'b1;
					micro_count   <= micro_count   - 1'b1;
					macro_count   <= macro_count   - 1'b1;
					lock          <= 0;
				end
			end
		end

		// Estado 3:
		if( state == 3 )begin
			busy_unit   <= 1'b1;
			lock        <= 0; // no debería ser necesario
			micro_count <= 0;
			if( top )
				state <= 1; // Escritura terminada
			else
				state <= 2;

			port_cmd_instr <= 3'b000;             // comando de escritura
			port_cmd_bl    <= micro_count - 1'b1; // numero de palabras (0 es considerado como 1 dato)
			port_cmd_en    <= 1;

			if( first_burst )
				first_burst <= 0;
			else
				port_cmd_byte_addr <= port_cmd_byte_addr + 10'd256; // incrementos en direcciones de 8 bytes
		end

	end // always

endmodule
