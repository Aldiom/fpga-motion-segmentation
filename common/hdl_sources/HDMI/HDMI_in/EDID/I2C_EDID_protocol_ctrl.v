//`default_nettype none
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
module I2C_EDID_protocol_ctrl(
    input wire clk,
    // Interfaz con modulo que controla el envio y recepcion de bytes
    input wire [7:0] data_received,
    input wire byte_received,
    input wire operation_completed,
    input wire start_cond,
    input wire stop_cond,
    input wire line_ack,
    output reg start_operation,
    output reg generate_ack,
    output reg tx_data,
    // Interfaz con memoria
    output reg [7:0] word_offset  // Registro de offset de memoria
    );


    // Inicializar salidas
    initial begin
        // envio y recepcion de bytes
        start_operation <= 0;
        generate_ack    <= 0;
        tx_data         <= 0;
        // Memoria
        word_offset     <= 0;
    end






    // ---- Maquina de estados que controla el modulo
    reg [2:0] state;               // Estado de la maquina
    reg       valid_dev_addr;      // Direccion de dispositivo valida
    reg       operation_started;   // Operacion en el modulo en progreso


    wire ctrl_word__write_mem_addr = (data_received == 8'hA0);
    wire ctrl_word__read_from_mem  = (data_received == 8'hA1);
    wire ctrl_word__write_seg_poin = (data_received == 8'h60);


    initial begin
        state             <= 0;
        word_offset       <= 0;
        valid_dev_addr    <= 0;
        operation_started <= 0;
    end



    always @( posedge clk  ) begin

        // Asegurar que señales de control duren solo un pulso de reloj
        if( start_operation )
            start_operation <= 0;

        if( generate_ack )
            generate_ack <= 0;
            
        if( tx_data )
            tx_data <= 0;
        
        
        
        // Estado 0: Linea desocupada
        // Esperar condicion de START de bus I2C
        // Inicio recepcion palabra de control
        if( state == 0 ) begin
        
            // Señales de control
            start_operation <= 0;
            generate_ack <= 0;
            tx_data <= 0;
            
            // Registros de la maquina de estado
            valid_dev_addr    <= 0;
            operation_started <= 0;
            
            
            // Señal de START I2C
            if( start_cond ) begin
                // Ir a proximo estado
                state <= 1;
             end

        end // Estado 0



        // Estado 1: Esperar fin de palabra de control.
        // Responder con ACK si direccion corresponde
        //  a direcciones EDID (0xA0/0xA1/0x60).
        // Establecer el modo de lectura o escritura
        if( state == 1 ) begin

            if( operation_started == 0 ) begin
                operation_started <= 1;
                start_operation <= 1;
            end

            if( byte_received ) begin
                
                // Condiciones para generar ACK
                if( ctrl_word__write_mem_addr ||
                    ctrl_word__read_from_mem  ||
                    ctrl_word__write_seg_poin  ) begin
                    
                    valid_dev_addr <= 1;
                    generate_ack <= 1;
                end
                else begin
                    generate_ack <= 0;
                    valid_dev_addr <= 0;
                end
                
            end // byte_received
            
            
            if( operation_completed && valid_dev_addr ) begin
                
                operation_started <= 0;
                
                if( ctrl_word__write_mem_addr )
                    state <= 2;
                
                if( ctrl_word__write_seg_poin )
                    state <= 3;
                    
                if( ctrl_word__read_from_mem )
                    state <= 4;
            end
            
            
            // Condicion STOP de I2C
            if( stop_cond ) begin
                state <= 0; // Volver a estado inicial
            end

        end // Estado 1
        
        
        
        // Estado 2: Escribir direccion de memoria
        if( state == 2 ) begin
            
            if( operation_started == 0 ) begin
                operation_started <= 1;
                start_operation <= 1;
            end
        
            if( byte_received ) begin
                word_offset <= data_received;
                generate_ack <= 1;
            end
            
            if( operation_completed )
                state <= 0; // Volver a estado inicial

        end // Estado 2
        
        

        // Estado 3: Escribir valor de "segment pointer"
        if( state == 3 ) begin
            
            if( operation_started == 0 ) begin
                operation_started <= 1;
                start_operation <= 1;
            end
        
            if( byte_received ) begin
                generate_ack <= 1;
            end
            
            if( operation_completed )
                state <= 0; // Volver a estado inicial

        end // Estado 2
        
        
        
        // Estado 4: Leer datos desde la memoria
        if( state == 4 ) begin
            
            // Iniciar transmision por primera vez
            if( operation_started == 0 )begin
                operation_started <= 1;
                // Control modulo
                tx_data <= 1;
                start_operation <= 1;
            end
        
        
            if( byte_received ) begin
                word_offset <= word_offset + 1'b1;
            end
            
        

            if( operation_completed ) begin
        
                // ACK recibido ( señal activa baja )
                if( ~line_ack ) begin
                   tx_data <= 1;
                   start_operation <= 1;
                   // TODO: LEER desde memoria
                end
                else begin
                    state <= 0; // Volver a estado inicial
                end
                
            end
        
            

        end // Estado 4


    end // Maquina estados




endmodule
