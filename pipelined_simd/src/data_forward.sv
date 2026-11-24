module data_forward(
	input logic [4:0] id_ex_rs1,
	input logic [4:0] id_ex_rs2,
	input logic [4:0] ex_mem_rd,
	input logic [4:0] mem_wb_rd,
	
	input logic id_ex_valid,
	input logic ex_mem_valid,
	input logic ex_mem_reg_write,
	input logic ex_mem_is_load,
	
	input logic mem_wb_valid,
	input logic mem_wb_reg_write,
	
	output logic [1:0] forward_a,
	output logic [1:0] forward_b,
	output logic [1:0] forward_store
	);
	
	always_comb begin
		forward_a = 2'b00;
		forward_b = 2'b00;
		forward_store = 2'b00;
		
		if(id_ex_valid && ex_mem_valid && ex_mem_reg_write && !ex_mem_is_load && (ex_mem_rd != 5'b0) && (id_ex_rs1 == ex_mem_rd))
			forward_a = 2'b01;
		else if(id_ex_valid && mem_wb_valid && mem_wb_reg_write && (mem_wb_rd != 5'b0) && (id_ex_rs1 == mem_wb_rd))
			forward_a = 2'b10;	
		
		if(id_ex_valid && ex_mem_valid && ex_mem_reg_write && !ex_mem_is_load && (ex_mem_rd != 5'b0) && (id_ex_rs2 == ex_mem_rd))
			forward_b = 2'b01;
		else if(id_ex_valid && mem_wb_valid && mem_wb_reg_write && (mem_wb_rd != 5'b0) && (id_ex_rs2 == mem_wb_rd))
			forward_b = 2'b10; 
		
		if(id_ex_valid && ex_mem_valid && ex_mem_reg_write && !ex_mem_is_load && (ex_mem_rd != 5'b0) && (id_ex_rs2 == ex_mem_rd))
			forward_store = 2'b01;
		else if(id_ex_valid && mem_wb_valid && mem_wb_reg_write && (mem_wb_rd != 5'b0) && (id_ex_rs2 == mem_wb_rd))
			forward_store = 2'b10;	 
	end
endmodule
		