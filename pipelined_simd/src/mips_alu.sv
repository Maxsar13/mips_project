module alu(
	input logic [24:0] instr,
	input logic [127:0] rs1,
	input logic [127:0] rs2,
	input logic [127:0] rs3,
	input logic [127:0] rd_in,
	
	output logic [127:0] rd_out,
	output logic [4:0] wr_addr,
	output logic write_en
	); 
	
	//Used for load immediate instruction
	logic [6:0] shift_imm; 
	logic [127:0] imm_load;	
	
	//Used for multi-add instructions  
	logic [31:0] mask_multi//Mask if needed
	logic [127:0] multi_one;
	logic [127:0] multi_two;
	logic [127:0] product;
	
	
	
	always_comb begin		
		case(instr[24:23]) inside  
			2'b0?: begin	 //Load Immediate instruction
				shift_imm = {instr[23:21], 4'b0000};   //Shift used to replace section of rd
				imm_load = 128'hFFFF << shift_imm; //Shift mask to replaced section
				rd_out = (rd_in && ~imm_load) || (128'instr[20:5] << shift);   //Using mask to replace bits
				wr_addr = instr[4:0]; 	  //Setting write address to rd
			end
			2'b10: begin   //Multi Intstruction
					mask_multi = instr[22] ? 32'hFFFFFFFF : instr[20] ? 32'hFFFF0000 : 32'h0000FFFF; //Shifting masks based off of long/int and high/low
					for(int i = 0; i < 4; i = instr[22] ? i = i + 2 : i++) begin //For loop as theres always 4 segments we multiply
						if(instr[22]) begin			//For long multiplications										
							multi_one = rs3 && (128'mask_multi << {i, 6'b000000});
							multi_two = rs2 && (128'mask_multi << {i, 6'b000000)); 
						end
						else begin					//For int multiplications	
							multi_one = rs3 && (128'mask_multi << {i, 5'b00000});
							multi_two = rs2 && (128'mask_multi << {i, 5'b00000)); 
						end
						product = product || (multi_one * multi_two);  //ORing products so it keeps the values of each chunk each iteration
					end
					rd_out = instr[21] ? rs1 - product : product + rs1;		//If instr[21] is 1, we subtract, else we add							
				end	
			2'b11: begin //R3 instructions	   
				case(instr[19:15]) inside
					5'b?0000:
					5'b?0001:
					5'b?0010:
					5'b?0011:
					5'b?0100:
					5'b?0101:
					5'b?0110:
					5'b?0111:
					5'b01000:
					5'b?1001:
					5'b?1010:
					5'b?1011:
					5'b?1100:
					5'b?1101:
					5'b?1110:
					5'b?1111:
					
			end		
		endcase
	end			
endmodule