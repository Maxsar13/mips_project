module data_forward(
	input logic [4:0] id_ex_rs1,
	input logic [4:0] id_ex_rs2,
	input logic [4:0] id_ex_rs3,
	input logic [4:0] ex_wb_rd,
	
	input logic id_ex_valid,
	input logic ex_wb_valid,
	input logic ex_wb_reg_write,

	
	output logic forward_a,
	output logic forward_b,
	output logic forward_c
	);
	
	always_comb begin
		forward_a = 1'b0;
		forward_b = 1'b0;
		forward_c = 1'b0;
		
		if(id_ex_valid && ex_wb_valid && ex_wb_reg_write && (ex_wb_rd != 5'b0) && (id_ex_rs1 == ex_wb_rd))
			forward_a = 1'b1;	
			
		if(id_ex_valid && ex_wb_valid && ex_wb_reg_write && (ex_wb_rd != 5'b0) && (id_ex_rs2 == ex_mem_rd))
			forward_b = 1'b1;
		
		if(id_ex_valid && ex_wb_valid && ex_wb_reg_write && (ex_wb_rd != 5'b0) && (id_ex_rs3 == ex_mem_rd))
			forward_c = 1'b1;
	end
endmodule
		