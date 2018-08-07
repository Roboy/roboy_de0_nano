module MEMS_THAT_SHIT(
	input clock,
	input reset,
	input pdm,
	input pdm_clk,
	output pdm_clk_out,
	output reg [31:0] address,
	output reg write,
	output reg [7:0] write_data,
	input waitrequest
);


assign pdm_clk_out = pdm_clk;

always @(posedge clock, posedge reset) begin: AVALON_WRITE_ONCHIP_INTERFACE
	reg [31:0] addr_cntr;
	reg [31:0] counter;
	parameter IDLE  = 3'b000, WAIT_FOR_TRANSMIT = 3'b001, WAIT_FOR_NEXT_FRAME = 3'b010, DELAY = 3'b011, 
	PREPARE_TRANSMIT= 3'b100, DATA_TO_REG = 3'b101, SUM_BITS = 3'b110, TRANSMIT= 3'b111;
	parameter MEM_SIZE = 23'd4096; // 8 MB
	reg [2:0] onchip_state;
	
	reg slow_clk_prev;
	reg [8:0] pdm_bit_counter;
	reg [7:0] raw_pdm_data;
	reg pdm_state;
	reg [8:0] pdm_sum;
	integer i;
	
	if (reset == 1) begin
		counter <= 0;
		pdm_state <= DATA_TO_REG;
		onchip_state <= IDLE;
		pdm_bit_counter <= 0;
	end else begin
		write <= 0;
		slow_clk_prev <= pdm_clk;
////		if(slow_clk_prev == 0 && pdm_clk == 1)begin // rising edge jof pdm_clk
//			case(pdm_state)
//			
//			default: begin
//				pdm_state <= DATA_TO_REG;
//			end
//			endcase
////			end
				
		case(onchip_state)
			IDLE: begin
				if(slow_clk_prev == 0 && pdm_clk == 1)begin 
							onchip_state <= DATA_TO_REG;
						end
			end
			DATA_TO_REG: begin
					onchip_state <= IDLE;
					// low pass filter data preparation
					// store 256 bit in an array that gets summed up afterwards
//					if (pdm_bit_counter< 256) begin 
//						pdm_bit_counter <= pdm_bit_counter + 1;
//						raw_pdm_data[pdm_bit_counter] <= pdm;
//						
//					end else begin 
//						pdm_bit_counter <= 0;
//						onchip_state <= SUM_BITS;
//					end
					if (pdm_bit_counter < 8) begin
						pdm_bit_counter <= pdm_bit_counter +1;
						raw_pdm_data[7 - pdm_bit_counter] <= pdm;
					end else begin
						pdm_bit_counter <= 0;
						onchip_state <= SUM_BITS;
					end
			end
			SUM_BITS: begin
			// low pass filter summation
//				pdm_sum = 0;
//				for(i = 0; i < 256; i = i + 1) begin
//					pdm_sum = pdm_sum + raw_pdm_data[i];
//					end
				write_data = raw_pdm_data;
				onchip_state = TRANSMIT;
				address = addr_cntr;
			end
			TRANSMIT: begin
				write <= 1;
				onchip_state <= WAIT_FOR_TRANSMIT;
			end
			WAIT_FOR_TRANSMIT: begin		
						if(waitrequest==0) begin
							onchip_state <= IDLE;
							addr_cntr <= addr_cntr+1;
							if (addr_cntr >= MEM_SIZE) begin
								addr_cntr <= 0; 
							end
						end	
					end
			default: onchip_state <= IDLE;
		endcase
	end
end


endmodule