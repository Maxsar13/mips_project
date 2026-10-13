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
	logic [31:0] mask_multi;//Mask if needed
	logic [127:0] multi_one;
	logic [127:0] multi_two;
	logic [127:0] product;
	
	//Used for register instructions
	logic [31:0] broadcast;
	assign broadcast = 32'hFFFFFFFF;  
	
	logic [15:0] op;
	logic [16:0] saturated_op;
	
	logic [31:0] rotate; 
	logic [31:0] latch;
	
	
	
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
				rd_out = 128'd0;
				case(instr[18:15]) inside
					4'b0000: begin	//NOP instruction
						write_en = 1'b0;
						end
					4'b0001: begin //Absolute difference of bytes
						for(int i = 0; i < 128; i = i + 16) begin
							op = rs1[i+:16] - rs2[i+:16];
							op = sub[15] ? (~sub + 1) : sub;
							rd_out[i+:16] = sub;
						end	
						write_en = 1'b1;
						end
					4'b0010: begin //Add word unsigned
						rd_out = {rs1[127:96] + rs2[127:96], rs1[95:64] + rs2[95:64], rs1[63:32] + rs2[63:32], rs1[31:0] + rs2[31:0]};
						write_en = 1'b1;
						end
					4'b0011: begin //count 1s in word
						int count;
						for(int i = 0; i < 128; i = i + 32)
							begin
								count = rs1[i:i+1] + rs1[i+2:i+3] + rs1[i+4:i+5] + rs1[i+6:i+7] + rs1[i+8:i+9] + rs1[i+10:i+11] + rs1[i+12:i+13] + rs1[i+14:i+15] + rs1[i+16:i+17] + rs1[i+18:i+19] + rs1[i+20:i+21] + rs1[i+22:i+23] + rs1[i+24:i+25] + rs1[i+26:i+27] + rs1[i+28:i+29] + rs1[i+30:i+31]; 
								rd_out[i+:32] = count;
							end	
						write_en = 1'b1;
						end
					4'b0100: begin	//Add Halfword saturated 
						for(int i = 15; i < 128; i = i + 16)
							begin
								saturated_op = $signed(rs2[i+:16]) + $signed(rs1[i+:16]);
								saturated_op = (saturated_op[16] != saturated_op[15]) ? (saturated_op[16] ? 16'h8000 : 16'h7FFF) : saturated_op;
								rd_out[i+:16] = saturated_op[15:0];
							end	
							write_en = 1'b1;
						end
					4'b0101: begin //AND instruction 
						rd_out = rs2 && rs1;
						end
					4'b0110: begin //broadcast word
						broadcast = broadcast && rs1[31:0];
						for(int i = 0; i < 4; i++) begin 
							rd_out = rd_out || (128'(broadcast) << {i, 5'b00000});
						end
						write_en = 1'b1;
						end
					4'b0111: begin //max signed word
						rd_out[31:0] = ($signed(rs1[31:0]) > ($signed(rs2[31:0])) ? rs1[31:0] : rs2[31:0]; 
						rd_out[63:32] = ($signed(rs1[63:32]) > ($signed(rs2[63:32])) ? rs1[63:32] : rs2[63:32]; 
						rd_out[95:64] = ($signed(rs1[95:64]) > ($signed(rs2[95:64])) ? rs1[95:64] : rs2[95:64]; 
						rd_out[127:96] = ($signed(rs1[127:96]) > ($signed(rs2[127:96])) ? rs1[127:96] : rs2[127:96]; 
						write_en = 1'b1;
						end
					4'b1000: begin //min signed word
						rd_out[31:0] = ($signed(rs1[31:0]) < ($signed(rs2[31:0])) ? rs1[31:0] : rs2[31:0]; 
						rd_out[63:32] = ($signed(rs1[63:32]) < ($signed(rs2[63:32])) ? rs1[63:32] : rs2[63:32]; 
						rd_out[95:64] = ($signed(rs1[95:64]) < ($signed(rs2[95:64])) ? rs1[95:64] : rs2[95:64]; 
						rd_out[127:96] = ($signed(rs1[127:96]) < ($signed(rs2[127:96])) ? rs1[127:96] : rs2[127:96]; 
						write_en = 1'b1;
					4'b1001: begin	//Multiply low unsigned
						for(int i = 0; i < 128; i = i + 32)
							begin
								rd_out[i+:32] = 32'(rs1[i+:16] * rs2[i+:16]);
							end
						write_en = 1'b1;
						end
					4'b1010: begin //multiply low by constant unsigned
						for(int i = 0; i < 128; i = i + 32)
							begin
								rd_out[i+:32] = 32'(rs1[i+:16] * instr[14:10]);
							end
						write_en = 1'b1;							   
						end
					4'b1011: begin //OR Instruction
						rd_out = rs2 || rs1;
						write_en = 1'b1;
						end
					4'b1100: begin //Count leading zeroes in words 
						for(int i = 0; i < 128; i = i + 32)
							begin
								int count = 0;
								int j = i + 32;
								while(count != 32 || rs1[j] == 1) begin
									count++;
									j--;
								end
								rd_out[i+:32] = count;
							end						   
							write_en = 1'b1;						
						end
					4'b1101: begin //Rotate bits in word
						for(int i = 0; i < 128; i = i + 32)
							begin
								latch = rs1[i +: 32];
								latch = (latch << (32 - instr[14:10]));
								rd_out[i +: 32] = latch | (rs1[i:prev] >> rs2[14:10]);	
							end
						end
					4'b1110: begin //Subtract from word unsigned
						rd_out = {rs2[127:96] - rs1[127:96], rs2[95:64] - rs1[95:64], rs2[63:32] - rs1[63:32], rs2[31:0] - rs1[31:0]};
						write_en = 1'b1;
						end
					4'b1111: begin //subtract from halfword saturated
						for(int i = 0; i < 128; i = i + 16)
							begin
								saturated_op = $signed(rs2[i+:16]) - $signed(rs1[i+:16]);
								saturated_op = (saturated_op[16] != saturated_op[15]) ? (saturated_op[16] ? 16'h8000 : 16'h7FFF) : saturated_op;
								rd_out[i+:16] = saturated_op[15:0];
							end	
							write_en = 1'b1;
						end	
			end		
		endcase
	end			
endmodule