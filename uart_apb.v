`include "uart.v"

module uart_apb(
  input wire pclk,  //clock
  input wire rst,   //reset signal
  input wire psel,  //select for the slave in APB
  input wire penable,  //enable signal for APB bus
  input wire pwrite, 
  input wire [31:0] pstrb,  
  output reg pready,  
  input wire [31:0] pwdata,
  input wire [31:0] padd,
  output reg pslevrr,
  output reg [31:0] prdata,
  input tx_enable,
  input rx_enable,
  input ser_in,
  output ser_out,
  output reg apb_done
);

reg [10:0] data_bits = 0;
wire [31:0] data_out;



//cases for APB Bus

  //IDLE state
  parameter APB_IDLE = 2'b00;

  parameter APB_WRITE = 2'b01;
  
  parameter APB_READ = 2'b10;
  
  parameter APB_DONE = 2'b11;
  
  reg[1:0] APB_state = APB_IDLE;
  
  uart #(.CLK_PERIOD(100)) UART
  (
    .clk(pclk),
    .rst(rst),
    .data_in(data_bits),
    .data_out(data_out),
    .baud_select(50),
    .tx_enable(tx_enable),
    .rx_enable(rx_enable),
    .ser_in(ser_in),
    .ser_out(ser_out)
  );
  
  always @(posedge pclk)
  begin
    prdata <= data_out;
    case(APB_state)
      APB_IDLE:
        begin
          pready <= 0;
          pslevrr <= 0;
          if(psel == 1'b1)
            begin
              pready <= 1'b1;
              if(pwrite == 1'b1)
                begin
                  APB_state <= APB_WRITE;
                end
              else
                begin
                  APB_state <= APB_READ;
                end
            end
        end
        
        APB_WRITE:
        begin
          data_bits <= pwdata[10:0];
          apb_done <= 1'b1;
          APB_state <= APB_DONE;          
        end
        
        APB_READ:
        begin
          //prdata <= data_bits;
          APB_state <= APB_DONE;
        end
        
        APB_DONE:
        begin
          pready <= 0;
          APB_state <= APB_IDLE;
        end
        
    endcase
  end
endmodule