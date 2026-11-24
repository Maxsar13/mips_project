module id_ex_reg(
	input logic clk,
	input logic rst,
	
	input logic [24:0] id_ex_instr_in,
	input logic [127:0]	id_ex_rs1_in,
	input logic [127:0] id_ex_rs2_in,
	input logic [127:0] id_ex_rs3_in,
	input logic [127:0] id_ex_rd_in,
	
	output logic [24:0] id_ex_instr_out,
	output logic [127:0] id_ex_rs1_out,
	output logic [127:0] id_ex_rs2_out,
	output logic [127:0] id_ex_rs3_out,
	output logic [127:0] id_ex_rd_out
	); 
	
	always_ff @(posedge clk or posedge rst) begin
		if(rst) begin
			id_ex_instr_out <= 25'd0;
			id_ex_rs1_out <= 128'd0;
			id_ex_rs2_out <= 128'd0;
			id_ex_rs3_out <= 128'd0;
			id_ex_rd_out <= 128'd0; 
		end
		else begin
			id_ex_instr_out <= id_ex_instr_in;
			id_ex_rs1_out <= id_ex_rs1_in;
			id_ex_rs2_out <= id_ex_rs2_in;
			id_ex_rs3_out <= id_ex_rs3_in;
			id_ex_rd_out <= id_ex_rd_in;
		end
	end
endmodule
			