`include "gpio_apb.v"

module gpio_tb();
  
  parameter c_CLOCK_PERIOD_NS = 100;
  
  reg r_Clock = 1;
  reg rst = 0;
  reg psel = 0;
  reg penable = 0;
  reg pwrite = 0;
  reg [3:0] pstrb = 0;
  wire pready;
  reg[31:0] pwdata;
  reg[31:0] padd;
  wire [31:0] prdata;
  wire pslevrr;
  wire apb_done;
  wire write_done;
  wire read_done;
  
  always
    #(c_CLOCK_PERIOD_NS/2) r_Clock <= !r_Clock;
    
    
  gpio_apb GPIO_APB(
    .pclk(r_Clock),
    .rst(rst),
    .psel(psel),
    .penable(penable),
    .pwrite(pwrite),
    .pstrb(pstrb),
    .pready(pready),
    .pwdata(pwdata),
    .padd(padd),
    .pslevrr(pslevrr),
    .prdata(prdata),
    .apb_done(apb_done),
    .write_done(write_done),
    .read_done(read_done)
  );
  
  integer pin_number = 0;
  integer pin_config = 0;
  
   initial
    repeat(5) begin
      @(posedge r_Clock);
      psel <= 1'b1;
      pwrite <= 1'b1;
      pwdata = 32'b1;
      pstrb[0] = 1;
      padd = 0;
      padd[2:0] = pin_number;
      padd[5:3] = pin_config;
      @(posedge r_Clock);
      penable <= 1'b1;
      
      @(posedge apb_done);
      @(posedge r_Clock);
      psel <= 1'b0;
      penable <= 1'b0;
      pwrite <= 1'b0;
      pstrb = 0;
      
      @(posedge write_done);
      @(posedge r_Clock);
      psel <= 1'b1;
      pwrite <= 1'b0;
      pwdata = 32'b1;
      padd = 0;
      padd[2:0] = pin_number;
      padd[5:3] = pin_config;
      @(posedge r_Clock);
      penable <= 1'b1;
      
      @(posedge apb_done);
      @(posedge r_Clock);
      psel <= 1'b0;
      penable <= 1'b0;
      pwrite <= 1'b0;
      
      @(read_done);
      @(posedge r_Clock);
      psel <= 1'b0;
      penable <= 1'b0;
      pwrite <= 1'b0;
      pin_number = pin_number;
      pin_config = pin_config;
      @(posedge r_Clock);
    end
    
    always @(posedge r_Clock)
    begin
      if(read_done)
        begin
          
        end
    end
  
endmodule
