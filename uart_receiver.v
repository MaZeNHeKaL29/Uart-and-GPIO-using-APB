module uart_receiver
#(parameter CLKS_PER_BIT = 8)
(
  input wire pclk,  //clock
  input wire rst,   //reset signal
  input wire psel,  //select for the slave in APB
  input wire penable,  //enable signal for APB bus 
  output reg pready, 
  input wire pwrite, 
  input wire [31:0] padd,
  input i_rx_serial,
  output reg pslevrr,     //signal to check if there is an error during reading
  output reg [31:0] o_rx_prdata
  );
  
  //IDLE state
  parameter IDLE = 2'b00;

  //states for APB Bus
  parameter APB_SETUP  = 2'b01;
  parameter APB_ACCESS = 2'b10;
  
  //states for uart transmitter
  parameter rx_START_BIT = 3'b001;
  parameter rx_DATA_BITS = 3'b010;
  parameter rx_PARITY_EVEN = 3'b011;
  parameter rx_STOP_BIT  = 3'b100;
  parameter rx_DONE   = 3'b101;
  
  reg [31:0] padd_reg = 0;
  reg psel_reg = 0;
  reg penable_reg = 0;
  reg pwrite_reg = 0;
  
  reg [1:0]    APB_state = 0;
  reg [2:0]    rx_state = 0;
  reg [31:0]   r_clock_count = 0;
  reg [4:0]    r_bit_index   = 0;
  reg          r_rx_serial   = 0;
  reg          parity_even   = 0;
  reg          r_rx_done     = 0;
  
 
    
    always @(posedge pclk, posedge rst)
    begin
      if(rst)
        APB_state <= IDLE;
      case(APB_state)
        IDLE:
          begin
            //set all values to initial values
            pready <= 0;
            padd_reg <= 0;
            psel_reg <= 0;
            penable_reg <= 0;
            pwrite_reg <= 1;
            r_clock_count <= 0;
            r_bit_index <= 0;
            pslevrr <= 1'b0;
            parity_even <= 1'b0;
            if(psel == 1'b1 && pwrite == 1'b0)
              begin
                pready <= 1'b1;
                APB_state <= APB_SETUP;
                psel_reg <= 1'b1;
                padd_reg <= padd;
                pwrite_reg <= 0;
                rx_state <= rx_START_BIT;
              end 
          end
        
        APB_SETUP:
          begin
            APB_state <= APB_ACCESS;
          end 
        
        
        APB_ACCESS:
          begin
            penable_reg <= 1'b1;
            if(!r_rx_done)
              begin
                case(rx_state)
                  rx_START_BIT:
                    begin
                      r_rx_serial = i_rx_serial;
                      if(r_rx_serial == 1'b1)
                        begin
                          rx_state <= rx_DATA_BITS;
                        end
                      else
                        begin
                          pslevrr <= 1'b1;  //error
                          APB_state <= IDLE;
                        end
                    end
                    
                    rx_DATA_BITS:
                      begin
                        r_rx_serial = i_rx_serial;
                        o_rx_prdata[r_bit_index] <= r_rx_serial;
                        
                        if(r_rx_serial == 1)
                          parity_even = parity_even ^ 1;
                        
                        if(r_bit_index < 31)
                          begin
                            r_bit_index <= r_bit_index + 1;
                            rx_state <= rx_DATA_BITS;
                          end
                        else
                          begin
                            r_bit_index <= 0;
                            rx_state <= rx_PARITY_EVEN;
                          end
                      end
                      
                      rx_PARITY_EVEN:
                        begin
                          r_rx_serial = i_rx_serial;
                          if(r_rx_serial == parity_even)
                            begin
                              r_rx_done <= 1'b1;
                              rx_state <= rx_STOP_BIT;                             
                            end
                          else
                            begin
                              pslevrr <= 1'b1;  //error
                              APB_state <= IDLE;
                            end
                        end
                      
                      
                      //check stop bit
                      rx_STOP_BIT:                    
                        begin
                          r_rx_serial = i_rx_serial;
                          if(r_rx_serial == 1'b1)
                            begin
                              r_rx_done <= 1'b1;
                              rx_state <= rx_DONE;                             
                            end
                          else
                            begin
                              pslevrr <= 1'b1;  //error
                              APB_state <= IDLE;
                            end
                        end
                endcase
              end
                
              else
                begin
                  APB_state <= IDLE;
                end
              end
              
        default :
          APB_state <= IDLE;
        
      endcase  
        
    end     

endmodule