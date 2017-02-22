//`default_nettype none
`timescale 1ns / 1ps

module h_sync__v_sync__gen(
		h_count_req,
        v_count_req,
        active_req_data, // Active para realizar requests de datos
        active_send,     // Active realmente enviado
        blanking_active_line, // Blanking de la linea activa 
        
		h_sync,
		v_sync,
        

		restart,
		clk
    );


    // ----- PARAMETROS -----
    // Resolucion
    parameter H_PIXELS  = 640;
    parameter V_LINES   = 480;
    // Duracion pulsos de sincronismo horizontal (pixels)
    parameter H_FN_PRCH = 16; // Front porch
    parameter H_SYNC_PW = 96; // Pulse width
    parameter H_BK_PRCH = 48; // Back porch
    // Duracion pulsos de sincronismo vertical (lineas)
    parameter V_FN_PRCH = 10; // Front porch
    parameter V_SYNC_PW = 2;  // Pulse width
    parameter V_BK_PRCH = 33; // Back porch
    // Polaridad de señales de sincronismo
    parameter [0:0] H_SYNC_POL = 1;
    parameter [0:0] V_SYNC_POL = 1;


    
    // Periodos de los pulsos de sincronismo horizontal y vertical
    // Valor está retrasado un pulso de reloj con respecto a H_ACTIVE_END
    // Por lo que se genera un flip flop que atrase la señal del comparador
    localparam H_SYNC_PER = H_FN_PRCH + H_SYNC_PW + H_BK_PRCH + H_PIXELS - 1; // pixels
    localparam V_SYNC_PER = V_FN_PRCH + V_SYNC_PW + V_BK_PRCH + V_LINES - 1; // lineas
    
    // Inicio del video activo
    localparam H_ACTIVE_START = H_FN_PRCH + H_SYNC_PW + H_BK_PRCH - 3; // pixels
    localparam V_ACTIVE_START = V_FN_PRCH + V_SYNC_PW + V_BK_PRCH - 1; // lineas
    
    // Fin del video activo
    localparam H_ACTIVE_END   = H_FN_PRCH + H_SYNC_PW + H_BK_PRCH + H_PIXELS - 2; // pixel
    localparam V_ACTIVE_END   = V_FN_PRCH + V_SYNC_PW + V_BK_PRCH + V_LINES - 2; // linea
    
    
    // Inicio de h_sync y v_sync
    localparam H_SYNC_START   = H_FN_PRCH - 1; // pixels
    localparam V_SYNC_START   = V_FN_PRCH - 1; // lineas
    
    // Fin de h_sync y v_sync
    localparam H_SYNC_END     = H_FN_PRCH + H_SYNC_PW - 1; // pixels
    localparam V_SYNC_END     = V_FN_PRCH + V_SYNC_PW - 1; // lineas
    
    
    
    // Calcular bits necesarios para registros de los contadores
    // Totales
    localparam  H_BIG_COUNT_BITS = ceil_log2(H_SYNC_PER-1); // pixels
    localparam  V_BIG_COUNT_BITS = ceil_log2(V_SYNC_PER-1); // lineas 
    // Video activo
    localparam  H_COUNT_BITS = ceil_log2(H_PIXELS-1); // pixels
    localparam  V_COUNT_BITS = ceil_log2(V_LINES-1);  // lineas
    
    
    // ----- Salidas y entradas del módulo -----
    output reg [H_COUNT_BITS-1:0]  h_count_req       = 0;
    output reg [V_COUNT_BITS-1:0]  v_count_req       = 0;
    output reg                     h_sync            = ~H_SYNC_POL;
    output reg                     v_sync            = ~V_SYNC_POL;
    output reg                     active_req_data   = 0;
    output reg                     active_send       = 0;
    output reg                     blanking_active_line = 0;
    
    input wire                     restart;
    input wire                     clk;
    
    
    
    
    //  Registros de contadores usados
    reg [H_BIG_COUNT_BITS-1:0] h_sync_per_counter = 0;
    reg [V_BIG_COUNT_BITS-1:0] v_sync_per_counter = 0;

   
    // -- Comparadores usados --
    // final periodo grande
    wire h_count_end_comp    = (h_sync_per_counter == H_SYNC_PER);
    wire v_count_end_comp    = (v_sync_per_counter == V_SYNC_PER);
    // h_sync
    wire h_sync_start_comp   = (h_sync_per_counter == H_SYNC_START);
    wire h_sync_end_comp     = (h_sync_per_counter == H_SYNC_END);
    // v_sync
    wire v_sync_start_comp   = (v_sync_per_counter == V_SYNC_START);
    wire v_sync_end_comp     = (v_sync_per_counter == V_SYNC_END);   
   
    // video activo horizontal
    wire h_active_start_comp = (h_sync_per_counter > H_ACTIVE_START);
    wire h_active_end_comp   = (h_sync_per_counter < H_ACTIVE_END);
    wire h_active_comp       = (h_active_start_comp && h_active_end_comp);
    // video activo vertical
    wire v_active_start_comp = (v_sync_per_counter > V_ACTIVE_START);
    // Video activo total
    wire active_video_comp   = (h_active_comp && v_active_start_comp);
    // Blanking si es linea activa
    //wire blanking_active_line_comp = (v_active_start_comp && ~h_active_comp );
    wire blanking_active_line_comp = (v_active_start_comp && ~h_active_start_comp);
    
    
    
    reg h_active_comp_d;
    
    always @( posedge clk ) begin
        
        h_active_comp_d <= h_active_comp;

        if( restart ) begin
            h_count_req <= 0;
            v_count_req <= 0;
            h_sync  <= ~H_SYNC_POL;
            v_sync  <= ~V_SYNC_POL;
            active_req_data  <= 0;
            active_send <= 0;
            h_sync_per_counter <= 0;
            v_sync_per_counter <= 0;
        end
        else begin
        
            // -- Generación h_sync --
            if( h_sync_start_comp ) begin
                h_sync <= H_SYNC_POL;
            end
            if( h_sync_end_comp ) begin
                h_sync <= ~H_SYNC_POL;
            end

            
            // -- Contadores grandes ( incluyen blanking )
            // Incrementar contador horizontal
            h_sync_per_counter <= #1 h_sync_per_counter + 1'b1;

            // Linea completada
            if( h_count_end_comp ) begin
                h_sync_per_counter <= #1 0;
                
                // Incrementar contador de lineas
                if( v_count_end_comp ) begin
                    v_sync_per_counter <= #1 0;
                end
                else begin
                    v_sync_per_counter <= #1 v_sync_per_counter + 1'b1;
                end
                
                
                // Cuenta vertical
                if( v_active_start_comp ) begin
                    if( v_count_req == (V_LINES-1) ) begin
                        v_count_req <= #1 0;
                    end
                    else begin
                       v_count_req <= #1 v_count_req + 1'b1;
                    end
                end
                
                
                
                
                // -- Generación v_sync --
                if( v_sync_start_comp ) begin
                    v_sync <= V_SYNC_POL;
                end
                if( v_sync_end_comp ) begin
                    v_sync <= ~V_SYNC_POL;
                end

                
            end
            
            
            // -- Video activo --
            active_req_data <= #1 active_video_comp;
            // 1 ciclo de retraso (el ciclo que se demora en llegar los datos)
            active_send <= #1 active_req_data;
            // Blanquing de linea activa
            blanking_active_line <= #1 blanking_active_line_comp;
            
            // Cuenta horizontal
            if( h_active_comp_d ) begin
            
                if( h_count_req == (H_PIXELS-1) ) begin
                    h_count_req <= #1 0;
                end
                else begin
                    h_count_req <= #1 h_count_req + 1'b1;
                end
            end

   
        end

    end
    
    
    
    // calcula bits necesarios para representar el argumento "in_number"
    // Evaluada en tiempo de sintesis
	function integer ceil_log2( input [31:0] in_number );
    begin
        for( ceil_log2 = 0; in_number > 0; ceil_log2 = ceil_log2 + 1 )
          in_number = in_number >> 1;
    end
    endfunction

endmodule
