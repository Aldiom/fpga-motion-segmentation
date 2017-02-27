//`default_nettype none
`timescale 1ns / 1ps

module mem_dispatcher__read
	(
	// Reloj
	clk,

	// Interfaz de control
	os_start,         // Señal de inicio de lectura
	init_mem_addr,    // Direccion externa de inicio de lectura
	busy_read_unit,

	// Salida de datos
	data_out__we,
	data_out__addr,
	data_out,

	// Interfaz con memoria externa
	mem_calib_done,
	port_cmd_en,
	port_cmd_instr,
	port_cmd_bl,
	port_cmd_byte_addr,
	port_rd_en,
	port_rd_data_in,
	port_rd_empty
	);



	// ---------- PARAMETROS ----------
	parameter       FIFO_LENGTH    = 64;   // Longitud de la cola FIFO del controlador
	parameter       WORDS_TO_READ  = 640;  // Cantidad de palabras a recibir (de 32 0 64 bits)
	parameter       BUFF_ADDR_BITS = 0;
	parameter [0:0] PORT_64_BITS   = 0;    // 



	// ---------- PARAMETROS LOCALES ----------
	// Bits necesarios para puertos
	localparam ADDR_OUT_BITS = (BUFF_ADDR_BITS>0)? (BUFF_ADDR_BITS) : (ceil_log2(WORDS_TO_READ-1));
	localparam MEM_PORT_BITS = 32 + PORT_64_BITS*32;
	// Comandos a la memoria
	localparam READ_CMD = 3'b001;
	// Varios (misc)
	localparam ADDR_STEP = PORT_64_BITS? 10'd512: 10'd256;


	// ---------- ENTRADAS Y SALIDAS ----------
	// Reloj
	input  wire                     clk;

	// Interfaz de control
	input  wire                     os_start;         // Señal de inicio de lectura
	input  wire [29:0]              init_mem_addr; // Direccion externa de lectura
	output reg                      busy_read_unit;


	// Salida de datos
	output wire                     data_out__we;
	output reg  [ADDR_OUT_BITS-1:0] data_out__addr;
	output wire [MEM_PORT_BITS-1:0] data_out;

	// Interfaz con memoria externa
	input  wire                     mem_calib_done;
	output reg                      port_cmd_en;
	output wire [2:0]               port_cmd_instr;
	output reg  [5:0]               port_cmd_bl;
	output reg  [29:0]              port_cmd_byte_addr;
	output wire                     port_rd_en;
	input  wire [MEM_PORT_BITS-1:0] port_rd_data_in;
	input  wire                     port_rd_empty;

	initial busy_read_unit <= 1'b1;

	// ---------- MÓDULO ----------
	assign port_rd_en = pn_rd_en_state & (~port_rd_empty);
	assign data_out = port_rd_data_in;
	assign data_out__we = port_rd_en;

	assign port_cmd_instr = READ_CMD; // Comando constante de lectura

	//??n_data_rd
	localparam n_data_rd_bits = 16; // Valor real y necesario???
	localparam [n_data_rd_bits-1:0] FIFO_LENGTH_FIXED = FIFO_LENGTH;


	reg [1:0]                state           = 0; // Estado actual maquina de estados
	reg                      pn_rd_en_state  = 0; // ??
	reg [ADDR_OUT_BITS-1:0]  buff_add        = 0; // Direccion 
	reg [6:0]                fifo_count      = 0; // Contador de la cola FIFO
	reg [16:0]               rec_words_count = 0; // Contador de palabras recibidos
	reg [n_data_rd_bits-1:0] n_data_rd       = 0; // ??
	reg                      lock            = 0; // ??

	initial port_cmd_en = 0; // Salida

	always @( posedge clk ) begin
    
		data_out__addr <= buff_add;

		// Estado 0: Esperar que memoria esté calibrada
		//           No hacer nada hasta entonces
		if( state == 0 ) begin
		
			busy_read_unit <= 1'b1;
			if( mem_calib_done )
				state <= 1;
			
		end


		// Estado 1: En espera de señal de control
		//            para iniciar lectura
		if( state == 1 ) begin
			if( os_start ) begin
				busy_read_unit     <= 1;
				state              <= 2;
				lock               <= 0;
				buff_add           <= 0;
				port_cmd_byte_addr <= init_mem_addr - ADDR_STEP;
				rec_words_count    <= 0;
				n_data_rd          <= WORDS_TO_READ;
			end
			else begin
				pn_rd_en_state  <= 0;
				port_cmd_en     <= 0;
				busy_read_unit  <= 0;
			end
		end // Estado 1


		// Estado 2: 
		if( state == 2 ) begin
			busy_read_unit <= 1'b1;
			if( n_data_rd > FIFO_LENGTH ) begin
				port_cmd_bl <= FIFO_LENGTH - 1;
				n_data_rd   <= n_data_rd - FIFO_LENGTH_FIXED;
			end
			else
				port_cmd_bl <= n_data_rd[5:0] - 1'b1;

			lock             <= 0;
			fifo_count       <= 0;
			state            <= 3;

			port_cmd_byte_addr <= port_cmd_byte_addr + ADDR_STEP; // incrementos en direcciones de 64 words
			port_cmd_en        <= 1;
		end // Estado 2


		// Estado 3: 
		if( state == 3 ) begin
			busy_read_unit <= 1'b1;
			port_cmd_en    <= 0;
			if( ~port_rd_empty ) begin
				pn_rd_en_state     <= 1;
				buff_add           <= buff_add + 1'b1;
				fifo_count         <= fifo_count + 1'b1;
				rec_words_count    <= rec_words_count + 1'b1;
				lock               <= 1;
			end
			else begin
				pn_rd_en_state <= 0;
				if( fifo_count == FIFO_LENGTH + 1 ) begin
					state     <= 2;
				end
				if( rec_words_count == WORDS_TO_READ + 1 ) begin
					state     <= 1;
				end
				if( lock ) begin
					buff_add        <= buff_add - 1'b1;
					fifo_count      <= fifo_count - 1'b1;
					rec_words_count <= rec_words_count - 1'b1;
					lock            <= 0;
				end // lock
			end
		end // Estado 3


		//end // mem_calib_done
		//else
			//busy_read_unit   <= 1;

	end // always
    
    
    
	// ---------- FUNCIONES ----------
	// calcula bits necesarios para representar el argumento "in_number"
	// Evaluada en tiempo de sintesis
	function integer ceil_log2( input [31:0] in_number );
		for( ceil_log2 = 0; in_number > 0; ceil_log2 = ceil_log2 + 1 )
			in_number = in_number >> 1;
	endfunction

endmodule
