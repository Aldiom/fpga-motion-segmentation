//`default_nettype none
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module I2C_BYTE_TX_RX(
    output reg [7:0] data_received,
    output reg byte_received,
    output reg operation_completed,
    output wire start_cond,
    output wire stop_cond,
    output reg line_ack,
    input wire start_operation,
    input wire generate_ack,
    input wire tx_data,
    input wire [7:0] data_to_send,
    input wire SCL_PIN,
    input wire clk,
    inout wire SDA_PIN
    );


// Inicializar registros de salida
initial begin
    data_received <= 0;
    byte_received <= 0;
    line_ack <= 0;
    operation_completed <= 0;
end



// ---- Buffer triestado para SDA_PIN
reg SDA_PIN_driver;
reg SDA_PIN_enable_out;
assign SDA_PIN = (SDA_PIN_enable_out)? SDA_PIN_driver : 1'bz;

initial begin
    SDA_PIN_enable_out <= 1'b0;
    SDA_PIN_driver <= 1'b1;
end



// ---- Muestras de los pines. Para detectar cantos de subida y bajada
reg [1:0] scl_pin_reg;
reg [1:0] sda_pin_reg;

initial begin
    scl_pin_reg <= 2'b11;
    sda_pin_reg <= 2'b11;
end
 
// Registros de desplazamiento con estado actual y pasado de los pines
always @( posedge clk ) begin
    scl_pin_reg <= { scl_pin_reg[0], SCL_PIN };
    sda_pin_reg <= { sda_pin_reg[0], SDA_PIN };
end

// Identificar cantos positivos y negativos de PIN SCL
wire posedge_scl_pin = (scl_pin_reg == 2'b01 );
wire negedge_scl_pin = (scl_pin_reg == 2'b10 );


// ---- Estado del bus
// START: PIN SCL en alto y canto de bajada de PIN SDA
assign start_cond = ( (scl_pin_reg[0]) && (sda_pin_reg[1:0] == 2'b10) );


// STOP: PIN SCL en alto y canto de subida de PIN SDA
assign stop_cond  = ( (scl_pin_reg[0]) && (sda_pin_reg[1:0] == 2'b01) );





// ---- Maquina de estados que controla la entrada/salida del byte
reg [1:0] state; // Estado de la maquina
reg [2:0] bit_counter; // Contador de bits recibidos en el bus
reg write_op;
reg send_ack;
reg [7:0] data_out;

reg byte_received_ret;


initial begin
    state <= 0;
    bit_counter <= 0;
    write_op <= 0;
    send_ack <= 0;
    data_out <= 0;
    byte_received_ret <= 0;
end



always @( posedge clk  ) begin

    // Generar retraso de 1 ciclo la señal de byte recibido
    byte_received_ret <= byte_received;


    // Estado 0: En espera por instrucciones
    if( state == 0 ) begin
        //salidas
        byte_received <= 0;
        operation_completed <= 0;
        data_received <= 0;
        line_ack <= 0;
        SDA_PIN_enable_out <= 1'b0; // SDA en alta impedancia
        
        // Maquina de estados
        bit_counter <= 0;
        send_ack <= 0;
        
        
        if( start_operation ) begin
            // Tomar una muestra de las entradas de control
            write_op <= tx_data;
            
            if( tx_data && (SCL_PIN == 0) ) begin
                data_out <= {data_to_send[6:0],1'b0};
                SDA_PIN_enable_out <= 1'b1; // PIN SDA comandado por esclavo
                SDA_PIN_driver <= data_to_send[7];
            end
            else
                data_out <= data_to_send;
            // Pasar a siguiente estado
            state <= 1;
        end
    end // Estado 0
    
    
    
    // Estado 1: Recibir o enviar 8 bits
    if( state == 1 ) begin


        // Enviar 8 bits
        if( negedge_scl_pin && write_op ) begin
            SDA_PIN_enable_out <= 1'b1; // PIN SDA comandado por esclavo
            
            SDA_PIN_driver <= data_out[7];
            
            data_out[7:0] <= { data_out[6:0], 1'b0 };
            
        end

        // Recibir 8 bits
        if( posedge_scl_pin && ~write_op ) begin
            SDA_PIN_enable_out <= 1'b0; // PIN SDA en alta impedancia
            
            data_received[7:0] <= { data_received[6:0], SDA_PIN };
        end

        // Contador de bits
        if( posedge_scl_pin ) begin
            if( bit_counter == 7 ) begin
                bit_counter <= 0;
                byte_received <= 1;
            end
            else
                bit_counter <= bit_counter + 1'b1;
        end

        // Muestrear respuesta del módulo superior
        if( byte_received ) begin
            byte_received <= 0;
            state <= 2; //Salto a proximo estado
        end


    end // Estado 1
    
    
    
    // Estado 2: Inicio de ACK si es requerido
    // Recibir respuesta de módulo superior sobre generación de ACK
    if( state == 2 ) begin
        
        // Muestrear entrada desde modulo superior
        if( byte_received_ret ) begin
            send_ack <= generate_ack;
        end
        
        // Generar ACK si es necesario o dejar linea en alta impedancia para recibir
        if( negedge_scl_pin ) begin
        
            if( send_ack ) begin
                SDA_PIN_enable_out <= 1'b1;
                SDA_PIN_driver <= 1'b0;
            end
            else
                SDA_PIN_enable_out <= 1'b0; // PIN SDA en alta impedancia
                
            state <= 3;
        end
        
        
    end  // Estado 2
    
    
    // Estado 3: Fin de ACK y muestreo del mismo
    if( state == 3 ) begin

        // Muestrear ACK sea recibido o enviado
        if( posedge_scl_pin ) begin
            line_ack <= SDA_PIN;
        end
        
        // Dejar PIN SDA como entrada y finalizar
        if( negedge_scl_pin ) begin
            SDA_PIN_enable_out <= 1'b0;
            SDA_PIN_driver <= 1'b1;
            operation_completed <= 1;
            state <= 0;
        end
        
        //if( operation_completed ) begin
        //    operation_completed <= 0;
        //    state <= 0; //Pasar a siguiente estado
        //end
        
        
        
    end // Estado 3


end // Always


endmodule
