module ex_wb_reg(
	input logic clk,
	input logic rst,
	
	input logic [127:0] ex_wb_rd_out_in,
	input logic [4:0] ex_wb_wr_addr_in,
	input logic ex_wb_write_en_in,
	
	output logic [127:0] ex_wb_rd_out_out,
	output logic [4:0] ex_wb_wr_addr_out,
	output logic ex_wb_write_en_out
	);
	
	
	always_ff @(posedge clk or posedge rst) begin
		if(rst) begin
			ex_wb_rd_out_out <= 128'd0;
			ex_wb_wr_addr_out <= 5'd0;
			ex_wb_write_en_out <= 1'b0;
		end
		else begin
		ex_wb_rd_out_out <= ex_wb_rd_out_in;
		ex_wb_wr_addr_out <= ex_wb_wr_addr_in;
		ex_wb_write_en_out <= ex_wb_write_en_in;
		end
	end
endmodule