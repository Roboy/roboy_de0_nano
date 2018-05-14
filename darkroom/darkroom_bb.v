
module darkroom (
	clk_clk,
	reset_reset_n,
	darkroom_0_conduit_end_mosi_o,
	darkroom_0_conduit_end_sck_o,
	darkroom_0_conduit_end_ss_n_o,
	darkroom_0_conduit_end_trigger_me,
	darkroom_0_conduit_end_sync_o,
	darkroom_0_conduit_end_d_io,
	darkroom_0_conduit_end_e_io,
	darkroomootxdecoder_0_conduit_end_led,
	darkroomootxdecoder_0_conduit_end_uart_tx,
	darkroomootxdecoder_0_conduit_end_sensor_signals);	

	input		clk_clk;
	input		reset_reset_n;
	output		darkroom_0_conduit_end_mosi_o;
	output		darkroom_0_conduit_end_sck_o;
	output		darkroom_0_conduit_end_ss_n_o;
	input		darkroom_0_conduit_end_trigger_me;
	output	[11:0]	darkroom_0_conduit_end_sync_o;
	inout	[11:0]	darkroom_0_conduit_end_d_io;
	inout	[11:0]	darkroom_0_conduit_end_e_io;
	output	[7:0]	darkroomootxdecoder_0_conduit_end_led;
	output		darkroomootxdecoder_0_conduit_end_uart_tx;
	input	[11:0]	darkroomootxdecoder_0_conduit_end_sensor_signals;
endmodule
