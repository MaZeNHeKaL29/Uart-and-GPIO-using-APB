
 
`include "uart.v"
`include "uart_apb.v"

module uart_tb ();
  
  parameter c_CLOCK_PERIOD_NS = 100;
  
  reg pclk = 1;
  reg rst = 0;
  reg psel_tx = 0;
  reg psel_rx = 0;
  reg penable_tx = 0;
  reg penable_rx = 0;
  reg pwrite_tx = 0;
  reg pwrite_rx = 0;
  reg [3:0] pstrb_tx = 0;
  reg [3:0] pstrb_rx = 0;
  wire pready_tx;
  wire pready_rx;
  reg[31:0] pwdata_tx;
  reg[31:0] pwdata_rx;
  reg[31:0] padd_tx;
  reg[31:0] padd_rx;
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
  reg [7:0] baud_select = 30;
  
  always
    #(c_CLOCK_PERIOD_NS/2) pclk<= !pclk;
    
  
  uart_apb  UART_Transmitt_INST(
    .pclk(pclk),
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
    .tx_done(tx_done),
    .baud_select(baud_select)
  );
  
  uart_apb  UART_Receive_INST(
    .pclk(pclk),
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
    .rx_done(rx_done),
    .baud_select(baud_select)
  );
     
  initial
    begin
      //reading data from uart receiver
      read_rx();
      //write invalid data to uart transmitter
      write__tx(8'b1110011x);
      //write valid data to uart transmitter
      write__tx(8'b11100111);
      //enable uart transmitter and receiver to start sending and receiving
      uart_tx_rx_enable();
      //reading data from receiver
      read_rx();
      //change baud_select
      baud_select = 50;
      @(posedge rx_done);
      //write valid data to uart transmitter
      write__tx(8'b11100110);
      //enable uart transmitter and receiver to start sending and receiving
      uart_tx_rx_enable();
      //reading data from receiver
      read_rx();
    end
    
    
 
  
  
  //tx and rx of uart are connecting together
  always @(*)
  begin
    ser_in_rx <= ser_out_tx;
    ser_in_tx <= ser_out_rx;
  end
  
  always @(posedge rx_done, posedge tx_done)
  begin
    tx_enable <=  1'b0;
    rx_enable <=  1'b0;
  end
  
 
  
  integer i;
  
    
  task write__tx(input [7:0] w);
    begin
      @(posedge pclk);
      psel_tx <= 1'b1;
      pwrite_tx <= 1'b1;
      pwdata_tx = w ; 
      pstrb_tx[0] = 1'b1;
      for(i=0; i<8; i = i + 1) begin
        if(pwdata_tx[i]===1'bx) pstrb_tx[0] = 1'b0;
        if(pwdata_tx[i]===1'bz) pstrb_tx[0] = 1'b0;
      end
      padd_tx = 32'b1111001;
      @(posedge pclk);
      penable_tx <= 1'b1;
      @(posedge apb_done_tx);
      @(posedge pclk);
      psel_tx <= 1'b0;
      pwrite_tx <= 1'b0;
      penable_tx <= 1'b0;
      @(posedge pclk);
    end
  endtask
  
  task uart_tx_rx_enable();
    begin
       tx_enable <=  1'b1;
      rx_enable <=  1'b1;
    end
  endtask
  
  
  
  task read_rx();
    begin
      @(posedge pclk); 
      psel_rx <= 1'b1;
      pwrite_rx <= 1'b0;
      padd_rx = 32'b1111000;
      @(posedge pclk);
      penable_rx <= 1'b1;
      @(posedge apb_done_rx);
      @(posedge pclk);
      psel_rx <= 1'b0;
      pwrite_rx <= 1'b0;
      penable_rx <= 1'b0;
    end
  endtask
  
endmodule
