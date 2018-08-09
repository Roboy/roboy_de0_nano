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
reg [31:0] addr_cntr;
//reg [31:0] counter;
parameter IDLE  = 3'b000, WAIT_FOR_TRANSMIT = 3'b001, DATA_TO_REG = 3'b010, FILTER = 3'b011, 
DECIMATION= 3'b100, TRANSMIT = 3'b101;
parameter MEM_SIZE = 23'd4096; // 8 MB
reg [2:0] onchip_state;

reg slow_clk_prev;
reg [8:0] pdm_bit_counter;
reg [7:0] raw_pdm_data [2:0];
reg [48:0] filt_pdm_data_1 [2:0];
reg [48:0] filt_pdm_data_2 [2:0];
reg [48:0] filt_pdm_data_3 [2:0];
reg [48:0] filt_pdm_data_4 [2:0];
reg [48:0] filt_pdm_data_5 [2:0];
reg [48:0] filt_pdm_data_6 [2:0];
reg [48:0] filt_pdm_data_7 [2:0];
//reg pdm_state;
reg [8:0] pdm_sum;
reg [4:0] filter_count;

reg [31:0] b0 [6:0];

reg [31:0] b1 [6:0]; 
reg [31:0] b2 [6:0];
reg [47:0] a0 [6:0];
reg [47:0] a1 [6:0];
reg [47:0] a2 [6:0];
reg [7:0] dec_cnt;

// ---- filter coefficients ----
//	79749	159499	79749	107613222200000	-214748364800000	107167042400000
//	79749	159499	79749	108046436800000	-214748364800000	106733827800000
//	79749	159499	79749	108441509400000	-214748364800000	106338755200000
//	79749	159499	79749	108775479700000	-214748364800000	106004784900000
//	79749	159499	79749	109028938700000	-214748364800000	105751325900000
//	79749	159499	79749	109187156300000	-214748364800000	105593108300000
//	18348550	18348550	0	214748364800000	-211078654700000	0

always @(posedge clock, posedge reset) begin: AVALON_WRITE_ONCHIP_INTERFACE
	// not so smart array filter decleration
	b0[0] <= 32'd79749;
	b0[1] <= 32'd79749;
	b0[2] <= 32'd79749;
	b0[3] <= 32'd79749;
	b0[4] <= 32'd79749;
	b0[5] <= 32'd79749;
	b0[6] <= 32'd18348550;
	
	b1[0] <= 32'd159499;
	b1[1] <= 32'd159499;
	b1[2] <= 32'd159499;
	b1[3] <= 32'd159499;
	b1[4] <= 32'd159499;
	b1[5] <= 32'd159499;
	b1[6] <= 32'd18348550;
	
	b2[0] <= 32'd79749;
	b2[1] <= 32'd79749;
	b2[2] <= 32'd79749;
	b2[3] <= 32'd79749;
	b2[4] <= 32'd79749;
	b2[5] <= 32'd79749;
	b2[6] <= 32'd0;

	a0[0] <= 48'd107613222200000;
	a0[1] <= 48'd108046436800000;
	a0[2] <= 48'd108441509400000;
	a0[3] <= 48'd108775479700000;
	a0[4] <= 48'd109028938700000;
	a0[5] <= 48'd109187156300000;
	a0[6] <= 48'd214748364800000;

	a1[0] <= -48'd214748364800000;
	a1[1] <= -48'd214748364800000;
	a1[2] <= -48'd214748364800000;
	a1[3] <= -48'd214748364800000;
	a1[4] <= -48'd214748364800000;
	a1[5] <= -48'd214748364800000;
	a1[6] <= -48'd211078654700000;

	a2[0] <= 48'd107167042400000;
	a2[1] <= 48'd106733827800000;
	a2[2] <= 48'd106338755200000;
	a2[3] <= 48'd106004784900000;
	a2[4] <= 48'd105751325900000;
	a2[5] <= 48'd105593108300000;
	a2[6] <= 48'd0;
	
	if (reset == 1) begin
//		counter <= 0;
		
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
				raw_pdm_data[2] <= raw_pdm_data[1];
				raw_pdm_data[1] <= raw_pdm_data[0];
				raw_pdm_data[0] <= pdm * 8'hff;
				onchip_state <= FILTER;
				filter_count <= 0;
			end
			
			FILTER: begin
			// row 1
				filt_pdm_data_1[2] = filt_pdm_data_1[1];
				filt_pdm_data_1[1] = filt_pdm_data_1[0];
				filt_pdm_data_1[0] = (b0[filter_count] * raw_pdm_data[0] + b1[filter_count] * raw_pdm_data[1] + b2[filter_count] * raw_pdm_data[2]
										- a1[filter_count] * filt_pdm_data_1[1] - a2[filter_count] * filt_pdm_data_1[2]) / a0[filter_count];
				filter_count = filter_count +1;
			
				// row 2
				filt_pdm_data_1[2] = filt_pdm_data_2[1];
				filt_pdm_data_2[1] = filt_pdm_data_2[0];
				filt_pdm_data_2[0] = (b0[filter_count] * filt_pdm_data_1[0] + b1[filter_count] * filt_pdm_data_1[1] + b2[filter_count] * filt_pdm_data_1[2]
										- a1[filter_count] * filt_pdm_data_2[1] - a2[filter_count] * filt_pdm_data_2[2]) / a0[filter_count];
				
				filter_count = filter_count +1;
			
				// row 3
				filt_pdm_data_1[2] = filt_pdm_data_3[1];
				filt_pdm_data_3[1] = filt_pdm_data_3[0];
				filt_pdm_data_3[0] = (b0[filter_count] * filt_pdm_data_2[0] + b1[filter_count] * filt_pdm_data_2[1] + b2[filter_count] * filt_pdm_data_2[2]
										- a1[filter_count] * filt_pdm_data_3[1] - a2[filter_count] * filt_pdm_data_3[2]) / a0[filter_count];
										
				filter_count = filter_count +1;
			
				// row 4
				filt_pdm_data_1[2] = filt_pdm_data_4[1];
				filt_pdm_data_4[1] = filt_pdm_data_4[0];
				filt_pdm_data_4[0] = (b0[filter_count] * filt_pdm_data_3[0] + b1[filter_count] * filt_pdm_data_3[1] + b2[filter_count] * filt_pdm_data_3[2]
										- a1[filter_count] * filt_pdm_data_4[1] - a2[filter_count] * filt_pdm_data_4[2]) / a0[filter_count];
										
										
				filter_count = filter_count +1;
			
				// row 5
				filt_pdm_data_1[2] = filt_pdm_data_5[1];
				filt_pdm_data_5[1] = filt_pdm_data_5[0];
				filt_pdm_data_5[0] = (b0[filter_count] * filt_pdm_data_4[0] + b1[filter_count] * filt_pdm_data_4[1] + b2[filter_count] * filt_pdm_data_4[2]
										- a1[filter_count] * filt_pdm_data_5[1] - a2[filter_count] * filt_pdm_data_5[2]) / a0[filter_count];
										
				filter_count = filter_count +1;
			
				// row 6
				filt_pdm_data_1[2] = filt_pdm_data_1[1];
				filt_pdm_data_1[1] = filt_pdm_data_1[0];
				filt_pdm_data_6[0] = (b0[filter_count] * filt_pdm_data_5[0] + b1[filter_count] * filt_pdm_data_5[1] + b2[filter_count] * filt_pdm_data_5[2]
										- a1[filter_count] * filt_pdm_data_6[1] - a2[filter_count] * filt_pdm_data_6[2]) / a0[filter_count];
										
				filter_count = filter_count +1;
			
				// row 7
				filt_pdm_data_1[2] = filt_pdm_data_7[1];
				filt_pdm_data_7[1] = filt_pdm_data_7[0];
				filt_pdm_data_7[0] = (b0[filter_count] * filt_pdm_data_6[0] + b1[filter_count] * filt_pdm_data_6[1] + b2[filter_count] * filt_pdm_data_6[2]
										- a1[filter_count] * filt_pdm_data_7[1] - a2[filter_count] * filt_pdm_data_7[2]) / a0[filter_count];
				onchip_state = DECIMATION;
			end
			
			DECIMATION: begin
				if (dec_cnt == 0) begin
					write_data <= filt_pdm_data_7[0];
					onchip_state <= TRANSMIT;
					address <= addr_cntr;
					dec_cnt <= dec_cnt + 1;
				end else if(dec_cnt == 191) begin
					dec_cnt <= 0;
					onchip_state <= IDLE;
				end else begin
					dec_cnt <= dec_cnt + 1;
					onchip_state <= IDLE;
				end
			end
		
//       ---- old version ----		
//			SUM_BITS: begin
//			// low pass filter summation
////				pdm_sum = 0;
////				for(i = 0; i < 256; i = i + 1) begin
////					pdm_sum = pdm_sum + raw_pdm_data[i];
////					end
//				write_data = raw_pdm_data;
//				onchip_state = TRANSMIT;
//				address = addr_cntr;
//			end

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