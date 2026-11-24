module if_id_reg(
	input logic clk,
	input logic rst,	
	input logic [24:0] if_id_instr_in,
	output logic [24:0] if_id_instr_out
	);
	
	always_ff @(posedge clk or posedge rst) begin
		if(rst)
			if_id_instr_out <= 25'd0;
		else
			if_id_instr_out <= if_id_instr_in;
	end
endmodule