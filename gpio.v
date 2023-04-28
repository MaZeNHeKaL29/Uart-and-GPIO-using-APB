
/*
8 pins GPIO Controller
every pin has 5 regs
bit 0(DIR) -> GPIO direction (0 -> Input |||||| 1 -> Output)
bit 1(DATA) -> GPIO Data 
bit 2(INTS0) -> Interrupt Sense 1
bit 3(INTS1) -> Interrupt Sense 2
___________________________________________________________

INTS1 | INTS0  | Function                                 |
  0   |   0    |  Interrupt is disabled                   |
  0   |   1    |  Interrupt is triggered at rising edge   |
  1   |   0    |  Interrupt is triggered at falling edge  |
  1 	 |   1    |  Interrupt is triggered at both edges    |
___________________________________________________________


bit 4(PUR) -> Enable Pull Up Resistor
bit 5(PDR) -> Enable Pull Down Resistor

*/

module gpio(
    input clk,
    input rst,
    input write,
    input read,
    input [2:0] add_pin_number,
    input [2:0] add_config,
    input data_in,
    output reg [31:0] data_out,
    output reg write_done,
    output reg read_done
  );
  
  reg [7:0] gpio_pins [0:5];
  
  
  // pin number is determined from first 3 bits of paddr in APB Bus
  integer pin_number;
  // pin configuration is determined from second 3 bits of paddr in APB Bus
  integer pin_config;
  
  always @(*)
  begin
    pin_number <= add_pin_number;
    pin_config <= add_config;
  end
  
  parameter GPIO_IDLE = 2'b00;
  parameter GPIO_WRITE = 2'b01;
  parameter GPIO_READ = 2'b10;
  
  reg [1:0] gpio_state = GPIO_IDLE;
  
  always @(posedge clk or rst)
  begin
    if(rst)
      begin
        gpio_state = GPIO_IDLE;
      end
    case(gpio_state)
      
      GPIO_IDLE:
      begin
        if(write && !write_done)
          begin
            gpio_state <= GPIO_WRITE;
          end
        else if(read && !read_done)
          begin
            gpio_state <= GPIO_READ;
            data_out <= 0;
            data_out[2:0] <= pin_number;
            data_out[5:3] <= pin_config;
            if(data_out[6] === 1'bx)
              data_out[6] <= 1'b0;
            else
              data_out[6] <= gpio_pins[pin_number][pin_config];
          end
        else
          begin
            gpio_state <= GPIO_IDLE;
            write_done <= 1'b0;
            read_done <= 1'b0;
          end
      end
      
      GPIO_WRITE:
      begin
        gpio_pins[pin_number][pin_config] <= data_in;
        write_done <= 1'b1;
        gpio_state <= GPIO_IDLE;
      end
      
      GPIO_READ:
      begin
        read_done <= 1'b1;
        gpio_state <= GPIO_IDLE;
      end
    endcase
  end
  
endmodule
