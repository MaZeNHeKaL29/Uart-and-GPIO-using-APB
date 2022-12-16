
 
`include "uart.v"
`include "uart_apb.v"

module uart_tb ();
  
  parameter c_CLOCK_PERIOD_NS = 100;
  
  reg r_Clock = 1;
  reg rst = 0;
  reg psel_tx = 0;
  reg psel_rx = 0;
  reg penable_tx = 0;
  reg penable_rx = 0;
  reg pwrite_tx = 0;
  reg pwrite_rx = 0;
  reg [31:0] pstrb_tx = 0;
  reg [31:0] pstrb_rx;
  wire pready_tx;
  wire pready_rx;
  reg[31:0] pwdata_tx = 32'b10101010101010;
  reg[31:0] pwdata_rx = 0;
  reg[31:0] padd_tx = 32'b1111001;
  reg[31:0] padd_rx = 32'b1111000;
  wire [31:0] prdata_tx;
  wire [31:0] prdata_rx; 
  wire ser_out_tx;
  wire ser_out_rx;
  reg ser_in_tx;
  reg ser_in_rx;
  wire pslevrr_tx;
  wire pslevrr_rx;
  reg tx_enable = 0;
  reg rx_enable = 0;
  wire apb_done_tx;
  wire apb_done_rx;
  wire tx_done;
  wire rx_done;
  
  always
    #(c_CLOCK_PERIOD_NS/2) r_Clock <= !r_Clock;
    
  
  uart_apb  UART_Transmitt_INST(
    .pclk(r_Clock),
    .rst(rst),
    .psel(psel_tx),
    .penable(penable_tx),
    .pwrite(pwrite_tx),
    .pstrb(pstrb_tx),
    .pready(pready_tx),
    .pwdata(pwdata_tx),
    .padd(padd_tx),
    .pslevrr(pslevrr_tx),
    .prdata(prdata_tx),
    .ser_in(ser_in_tx),
    .ser_out(ser_out_tx),
    .tx_enable(tx_enable),
    .apb_done(apb_done_tx),
    .tx_done(tx_done)
  );
  
  uart_apb  UART_Receive_INST(
    .pclk(r_Clock),
    .rst(rst),
    .psel(psel_rx),
    .penable(penable_rx),
    .pwrite(pwrite_rx),
    .pstrb(pstrb_rx),
    .pready(pready_rx),
    .pwdata(pwdata_rx),
    .padd(padd_rx),
    .pslevrr(pslevrr_rx),
    .prdata(prdata_rx),
    .ser_in(ser_in_rx),
    .ser_out(ser_out_rx),
    .rx_enable(rx_enable),
    .apb_done(apb_done_rx),
    .rx_done(rx_done)
  );
     
  initial
    begin
      @(posedge r_Clock);
      psel_tx <= 1'b1;
      pwrite_tx <= 1'b1;
      @(posedge r_Clock);
      penable_tx <= 1'b1;
    end
    
  always @(posedge r_Clock)
  begin
    if(apb_done_tx ||  tx_done)
      begin
        psel_tx <= 1'b0;
        pwrite_tx <= 1'b0;
        penable_tx <= 1'b0;
        tx_enable <= tx_enable ^ 1'b1;
        rx_enable <= rx_enable ^ 1'b1;
      end
    if(rx_done)
      begin
        psel_rx <= 1'b1;
        pwrite_rx <= 1'b0;
        @(posedge r_Clock);
        penable_rx <= 1'b1;
        tx_enable <= 1'b0;
       
 rx_enable <= 1'b0;
      end
    if(apb_done_rx)
      begin
        psel_rx <= 1'b0;
        pwrite_rx <= 1'b0;
        penable_rx <= 1'b0;
        tx_enable <= 1'b0;
       
 rx_enable <= 1'b0;
      end
  end
  
  always @(*)
  begin
    ser_in_rx <= ser_out_tx;
    ser_in_tx <= ser_out_rx;
  end
    
  
  
endmodule

