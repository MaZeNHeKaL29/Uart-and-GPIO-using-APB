`include "gpio.v"

module gpio_apb(
  input wire pclk,  //clock
  input wire rst,   //reset signal
  input wire psel,  //select for the slave in APB
  input wire penable,  //enable signal for APB bus
  input wire pwrite, 
  input wire [3:0] pstrb,  
  output reg pready,  
  input wire [31:0] pwdata,
  input wire [31:0] padd,
  output reg pslevrr,
  output  [31:0]  prdata,
  output reg apb_done,
  output write_done,
  output read_done
);


reg data_in;

reg write;
reg read;

gpio GPIO(
  .clk(pclk),
  .rst(rst),
  .write(write),
  .read(read),
  .add_pin_number(padd[2:0]),
  .add_config(padd[5:3]),
  .data_in(data_in),
  .data_out(prdata),
  .write_done(write_done),
  .read_done(read_done)
);


//cases for APB Bus

  parameter APB_IDLE = 3'b000;

  parameter APB_WRITE = 3'b001;
  
  parameter APB_READ = 3'b010;
  
   parameter APB_ERROR = 3'b011;
  
  parameter APB_DONE = 3'b100;
  
 
  
  
  reg[2:0] APB_state = APB_IDLE;
  
  //GPIO pins enable clock reg, requires sending address 111111
  reg RCGCGPIO = 0;
  
  
  
  always @(posedge pclk, posedge rst)
  begin
    if(rst)
      begin
        APB_state <= APB_IDLE;
      end
    case(APB_state)
      APB_IDLE:
        begin
          apb_done <= 0;
          pready <= 0;
          pslevrr <= 0;
          write <= 1'b0;
          read <= 1'b0;
          if(psel == 1'b1)
            begin
              if(RCGCGPIO == 0)
                begin
                  if(padd == 32'b111111)
                    begin
                      RCGCGPIO <= 1'b1;
                    end
                  else
                    begin
                      pready <= 1'b1;
                      APB_state <= APB_ERROR;
                    end
                end
              else
                begin
                  pready <= 1'b1;
                	if(pwrite == 1'b1)
                   begin
                    APB_state <= APB_WRITE;
                    write <= 1'b1;
                  end
                	else
                  begin
                    APB_state <= APB_READ;
                    read <= 1'b1;
                  end
                end
            end
        end
        
        APB_WRITE:
        begin
          if(pstrb[0] != 1)
            begin
              pslevrr <= 1'b1;
            end
          else
            begin
              data_in <= pwdata[0];
            end    
          apb_done <= 1'b1;
          write <= 1'b0;
          APB_state <= APB_DONE;          
        end
        
        APB_READ:
        begin
          apb_done <= 1'b1;
          APB_state <= APB_DONE;
        end
        
        APB_ERROR:
        begin
           pready <= 1'b1;
          pslevrr = 1'b1;
          apb_done <= 1'b1;
          APB_state <= APB_DONE;
        end
        
        
        APB_DONE:
        begin
          pslevrr <= 1'b0;
          pready <= 0;
          apb_done <= 0;
          read <= 1'b0;
          APB_state <= APB_IDLE;
        end
        
    endcase
  end
endmodule