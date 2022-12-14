module uart_transmitter
  #(parameter CLKS_PER_BIT = 8)
(
  input wire pclk,  //clock
  input wire rst,   //reset signal
  input wire psel,  //select for the slave in APB
  input wire penable,  //enable signal for APB bus
  input wire pwrite, 
  input wire [31:0] pstrb,  
  output reg pready,  
  input wire [31:0] pwdata_tx,
  input wire [31:0] padd,
  output reg o_tx_serial,
  output o_tx_done
);
  
  //IDLE state
  parameter IDLE = 2'b00;

  //states for APB Bus
  parameter APB_ACCESS = 2'b01;
  
  //states for uart transmitter
  parameter tx_START_BIT = 3'b001;
  parameter tx_DATA_BITS = 3'b010;
  parameter tx_PARITY_EVEN = 3'b011;
  parameter tx_STOP_BIT  = 3'b100;
  parameter tx_DONE   = 3'b101;
  
  reg [1:0]    APB_state = 0;
  reg [2:0]    tx_state = 0;
  reg [31:0]   r_clock_count = 0;
  reg [4:0]    r_bit_index   = 0;
  reg [31:0]   r_tx_data     = 0;
  reg          r_tx_done     = 0;
  
  reg [31:0] padd_reg = 0;
  reg psel_reg = 0;
  reg penable_reg = 0;
  reg pwrite_reg = 0;
  reg [31:0] pstrb_reg = 0;
  reg parity_even = 0;
  
  
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
            o_tx_serial <= 1'b1;
            r_tx_done <= 1'b0;
            r_clock_count <= 0;
            r_bit_index <= 0;
            
            if(psel == 1'b1 && pwrite == 1'b1)
              begin  
                tx_state <= tx_START_BIT;
                psel_reg <= 1'b1;
                padd_reg <= padd;
                pwrite_reg <= 1'b1;
                r_tx_data <= pwdata_tx;
                penable_reg <= 1'b1;
                pready <= 1'b1;
                APB_state <= APB_ACCESS;              
              end    
          end
        
        APB_ACCESS:
          begin
            if(!r_tx_done)
              begin
                
                case(tx_state)
                  //send start bit
                  tx_START_BIT:
                    begin
                      o_tx_serial <= 1'b1;
                      //send data bits
                      r_clock_count <= 0;
                      tx_state <= tx_DATA_BITS;
                    end
                    
                    tx_DATA_BITS:
                      begin
                        //sent desired data bit
                        pstrb_reg[r_bit_index] <= r_tx_data[r_bit_index];
                        o_tx_serial <= r_tx_data[r_bit_index];
                        
                        //check for parity even
                        if(r_tx_data[r_bit_index] == 1)
                          parity_even <= parity_even ^ 1;
                        
                        // Wait CLKS_PER_BIT-1 clock cycles for start bit to finish
                        
                        
                        r_clock_count <= 0;
                            
                        // Check if we have sent out all bits
                        if (r_bit_index < 31)
                          begin
                            r_bit_index <= r_bit_index + 1;
                            tx_state   <= tx_DATA_BITS;
                          end
                            //send stop bit
                        else
                          begin
                            r_bit_index <= 0;
                            tx_state <= tx_PARITY_EVEN;
                          end
                          
                      end
                      
                    tx_PARITY_EVEN:
                      begin
                        o_tx_serial <= parity_even;
                        tx_state <= tx_STOP_BIT;
                      end  
                    
                    //send stop bit 
                    tx_STOP_BIT:
                      begin
                        o_tx_serial <= 1'b1;
                        // Wait CLKS_PER_BIT-1 clock cycles for start bit to finish
                        r_clock_count <= 0;
                        r_tx_done <= 1'b1; 
                        tx_state <= tx_DONE; 
                      end
                endcase
              end
                           
            else
              begin
                pready <= 0; 
                APB_state <= IDLE;
              end
            
          end
          
          
        default :
          APB_state <= IDLE;
          
      endcase
  end
  
  assign o_tx_done = r_tx_done;
  
endmodule

