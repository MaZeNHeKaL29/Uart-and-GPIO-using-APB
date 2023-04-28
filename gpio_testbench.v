`include "gpio_apb.v"

module gpio_tb();
  
  parameter c_CLOCK_PERIOD_NS = 100;
  
  reg pclk = 1;
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
    #(c_CLOCK_PERIOD_NS/2) pclk <= !pclk;
    
    
  gpio_apb GPIO_APB(
    .pclk(pclk),
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
    begin
      write_pin(pin_number, pin_config, 1'b1);
      
        read_pin(pin_number, pin_config);
       write_pin(3'b111, 3'b111, 1'b1);
      read_pin(pin_number, pin_config);
      write_pin(pin_number, pin_config, 1'bx);
      
      
      repeat(5) begin
      
        write_pin(pin_number, pin_config, 1'b1);
      
        read_pin(pin_number, pin_config);
        @(posedge pclk);
       	pin_number = pin_number +1;
        pin_config = pin_config +1;
      end
    end
    
    integer i;
    
    task write_pin(input [2:0] pin_num,input [2:0] pin_config, input data);
      begin
        @(posedge r_Clock);
      	 psel <= 1'b1;
        pwrite <= 1'b1;
        pwdata = data;
        pstrb[0] = 1'b1;
        for(i=0; i<8; i = i + 1) begin
          if(pwdata[i]===1'bx) pstrb[0] = 1'b0;
          if(pwdata[i]===1'bz) pstrb[0] = 1'b0;
        end
        padd = 0;
        padd[2:0] = pin_num;
        padd[5:3] = pin_config;
        @(posedge pclk);
        penable <= 1'b1;
      
        @(posedge apb_done);
        @(posedge pclk);
        psel <= 1'b0;
        penable <= 1'b0;
        pwrite <= 1'b0;
        pstrb = 0;
        @(posedge write_done, pslevrr);
      end
    endtask
    
    task read_pin(input [2:0] pin_num,input [2:0] pin_config);
      begin
        @(posedge pclk);
        psel <= 1'b1;
        pwrite <= 1'b0;
        padd = 0;
        padd[2:0] = pin_number;
        padd[5:3] = pin_config;
        @(posedge r_Clock);
        penable <= 1'b1;
      
        @(posedge apb_done);
        @(posedge pclk);
        psel <= 1'b0;
        penable <= 1'b0;
        pwrite <= 1'b0;
      
        	@(read_done,  pslevrr);
        @(posedge pclk);
        psel <= 1'b0;
        penable <= 1'b0;
        pwrite <= 1'b0;
      end
    endtask
    
    
  
endmodule
