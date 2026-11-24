module if_id_reg(
	input logic clk,
	input logic rst,	
	output logic [24:0] instr_in,
	output logic [24:0] instr_out
	);
	
	always_ff @(posedge clk or posedge rst) begin
		if(rst)
			instr_out <= 25'd0;
		else
			instr_out <= instr_in;
	end
endmodule