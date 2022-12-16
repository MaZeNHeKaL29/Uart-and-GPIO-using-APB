module uart
(   input clk,
    input rst,
    input [10:0] data_in,
    output reg [31:0] data_out,
    input [31:0] baud_select,
    input tx_enable,
    input rx_enable,
    
    input ser_in,
    output reg ser_out,
    
    output reg tx_done,
    output reg rx_done
  );
  
  reg [31:0] baudrategen = 1;
  reg tick = 0;
  
  always @(posedge clk or rst)
  begin
    if(rst)
      begin
        baudrategen <= 1'b1;
      end
    else if(tick)
      begin
        baudrategen <= 1'b1;
      end
    else
      begin
        baudrategen <= baudrategen + 1'b1;
      end
    tick <= (baudrategen == baud_select);
  end
    
  
  
  //cases for TX
  parameter tx_IDLE = 3'b000;
  parameter tx_START_BIT = 3'b001;
  parameter tx_DATA_BITS = 3'b010;
  parameter tx_PARITY_EVEN_BIT = 3'b011;
  parameter tx_STOP_BIT = 3'b100;
  
  //cases for RX
  parameter rx_IDLE = 3'b000;
  parameter rx_START_BIT = 3'b001;
  parameter rx_DATA_BITS = 3'b010;
  parameter rx_PARITY_EVEN_BIT = 3'b011;
  parameter rx_STOP_BIT = 3'b100;
  
  reg [2:0] tx_state = tx_IDLE;
  reg [2:0] rx_state = rx_IDLE;
  reg [4:0] tx_bit_index = 0;
  reg [4:0] rx_bit_index = 0;
  reg parity_even = 0;
  
  always @(posedge clk)
  begin
    case(tx_state)
    tx_IDLE:
      begin
        ser_out <= 1'b1;
        tx_bit_index <= 1'b0;
        if(tx_enable && !tx_done)
          begin
            data_out <= 0;
            tx_state <= tx_START_BIT;
          end
        else
          begin
            tx_done <= 1'b0;
          end
      end
    tx_START_BIT:
      begin
        ser_out <= 1'b0;
        tx_state <= tx_DATA_BITS;
      end
      
    tx_DATA_BITS:
      begin
        if(tick)
          begin
            ser_out <= data_in[tx_bit_index];
            data_out[tx_bit_index] <= data_in[tx_bit_index];
            if(data_in[tx_bit_index] == 1'b1)
              begin
                parity_even = parity_even ^ 1'b1;
              end
            if(tx_bit_index < 7)
              begin
                tx_bit_index <= tx_bit_index + 1'b1;
                tx_state <= tx_DATA_BITS;
              end
            else
              begin
                tx_state <= tx_PARITY_EVEN_BIT;
              end
          end
      end
      
    tx_PARITY_EVEN_BIT:
      begin
        if(tick)
          begin
            ser_out <= parity_even;
            tx_state <= tx_STOP_BIT;
          end
      end
    tx_STOP_BIT:
      begin
        if(tick)
          begin
            ser_out <= 1'b1;
            tx_done <= 1'b1;
            tx_state <= tx_IDLE;
          end
      end
    endcase
  end
  
  always @(posedge clk)
  begin
    case(rx_state)
    rx_IDLE:
      begin
        rx_bit_index <= 1'b0;
        rx_done <= 1'b0;
        if(rx_enable)
          begin
            data_out <= 0;
            rx_state <= rx_START_BIT;
          end
      end
      
    rx_START_BIT:
      begin
        if(tick)
          begin
            rx_state <= rx_DATA_BITS;
          end
      end
      
    rx_DATA_BITS:
      begin
        if(tick)
          begin
            data_out[rx_bit_index] <= ser_in;
            if(ser_in == 1'b1)
              begin
                parity_even = parity_even ^ 1'b1;
              end
            if(rx_bit_index < 7)
              begin
                rx_bit_index <= rx_bit_index + 1'b1;
                rx_state <= rx_DATA_BITS;
              end
            else
              begin
                rx_state <= rx_PARITY_EVEN_BIT;
              end
          end
      end
      
    rx_PARITY_EVEN_BIT:
      begin
        if(tick)
          begin
            if(ser_in != parity_even)
              begin
              end
            else
              rx_state <= rx_STOP_BIT;
          end
      end
      
      
    rx_STOP_BIT:
      begin
        if(tick)
          begin
            if(ser_in != 1'b1)
              begin
              end
            rx_done <= 1'b1;
            rx_state <= rx_IDLE;
          end
      end
      
    endcase
  end
  
endmodule
