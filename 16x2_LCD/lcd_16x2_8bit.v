/*
16x2 LCD DRIVER
DESCRIPTION
	Driver for 16X2 LCD.
	Fetch data from the input data port and presents it to the LCD pins with enable latch pulse. cd input pin 
	is used to select whether the data is lcd command data or character data. 
IO DETAILS
  	data	>>	lcd input
	clk		>>	Clock
	rst		>>	Reset
	start	>>	Start process
	cd		>> 	0-LCD Command/1-LCD Char
	rs		>>	LCD Register select
	en		>>	LCD Enable
	done_tick	>>	Process completed clock tick
AUTHOR:	
	Jagadeesh J, Design Engineer.
COMPANY:
	KENOSYS EMBEDDED SOLUTIONS, SALEM, TAMILNADU, INDIA			
 */
 module lcd_16x2_8bit (
	input [7:0]data,			
	input clk, rst, start, cd,	
	output [7:0]lcd_data,
	output rs, en, 
	output reg done_tick
);

localparam [2:0]	idle	=	3'b000,
					load	=	3'b001,
					wait1	=	3'b010,
					wait2 	= 	3'b011,
					done	=	3'b100;

reg [2:0]state_reg,state_next;
reg [15:0]count_reg;
wire [15:0]count_next;
reg [7:0]lcd_data_reg, lcd_data_next;
reg rs_reg, rs_next, en_reg, en_next, c_load_reg, c_load_next;
wire c_1ms, c_h1ms;

always@(posedge clk, negedge rst)
begin
	if(!rst)
	begin
		state_reg <= idle;
		c_load_reg <= 0;
		en_reg <= 0;
		rs_reg <= 0;
		lcd_data_reg <= 0;
		count_reg <= 0;
	end
	else
	begin
		state_reg <= state_next;
		c_load_reg <= c_load_next;
		en_reg <= en_next;
		rs_reg <= rs_next;
		lcd_data_reg <= lcd_data_next;
		count_reg <= count_next;
	end
end

assign count_next = (c_load_reg)?(count_reg + 1'b1):16'd0;

assign c_1ms = (count_reg == 16'd50000);
assign c_h1ms = (count_reg == 16'd25000);

always@*
begin
	state_next = state_reg;
	rs_next = rs_reg;
	en_next = en_reg;
	lcd_data_next = lcd_data_reg;
	done_tick = 0;
	c_load_next = c_load_reg;
	case(state_reg)
		idle:
		begin
			if(start)
				state_next = load;
		end
		load:
		begin
			state_next = wait1;
			lcd_data_next = data;
			rs_next = cd;
		end
		wait1:
		begin
			c_load_next = 1;
			en_next = 1;
			if(c_1ms)
			begin
				state_next = wait2;
				en_next = 0;
				c_load_next = 0;
			end
		end
		wait2:
		begin
			c_load_next= 1;
			if(c_h1ms)
			begin
				state_next = done;
				c_load_next = 0;
			end
		end
		done:
		begin
			done_tick = 1;
			state_next = idle;
		end
endcase
end
assign lcd_data = lcd_data_reg;
assign en = en_reg;
assign rs = rs_reg;
endmodule
