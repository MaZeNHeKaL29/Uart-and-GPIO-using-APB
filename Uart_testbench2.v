`timescale 1ns/10ps
 
`include "uart_transmitter.v"
`include "uart_receiver.v"

module uart_tb ();
  
  parameter c_CLOCK_PERIOD_NS = 100;
  
  reg r_Clock = 1;
  reg rst = 0;
  reg psel = 0;
  reg penable = 0;
  reg pwrite_tx = 0;
  reg pwrite_rx = 0;
  reg [31:0] pstrb = 0;
  wire pready_tx;
  wire pready_rx;
  reg[31:0] pwrite_d = 32'b1111000;
  reg[31:0] padd_d = 32'b1111001;
  wire o_tx_serial;
  wire o_tx_done;
  wire [31:0] prdata;
  reg i_rx_serial;
  wire pslevrr;
  
  always
    #(c_CLOCK_PERIOD_NS/2) r_Clock <= !r_Clock;
    
  
  uart_transmitter #(.CLKS_PER_BIT(8)) UART_Transmitt_INST
    (.pclk(r_Clock),
     .rst(rst),
     .psel(psel),
     .penable(penable),
     .pwrite(pwrite_tx),
     .pstrb(pstrb),
     .pready(pready_tx),
     .pwdata_tx(pwrite_d),
     .padd(padd_d),
     .o_tx_serial(o_tx_serial),
     .o_tx_done(o_tx_done)
     );
     
  uart_receiver #(.CLKS_PER_BIT(8)) UART_Receiver_INST
    (.pclk(r_Clock),
     .rst(rst),
     .psel(psel),
     .penable(penable),
     .pready(pready_rx),
     .pwrite(pwrite_rx),
     .padd(padd_d),
     .i_rx_serial(i_rx_serial),
     .pslevrr(pslevrr),
     .o_rx_prdata(prdata)
    );
     
  
  
  always @(o_tx_serial)
    i_rx_serial <= o_tx_serial;   
     
  always @(posedge r_Clock)
  begin
    if(o_tx_done == 1'b1)
      begin
        psel <= 1'b0;
  
     pwrite_tx <= 1'b0;
  
     penable <= 1'b0;
      end
  end
     
  initial
    begin
      @(posedge r_Clock);
      psel <= 1'b1;
      pwrite_tx <= 1'b1;
      pwrite_rx <= 1'b0;
      @(posedge r_Clock);
      penable <= 1'b1;
    end
    
  
  
endmodule
