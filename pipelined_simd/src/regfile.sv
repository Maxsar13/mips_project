module regfile #(
    parameter int REG_COUNT  = 32,
    parameter int DATA_WIDTH = 128,
    parameter int ADDR_WIDTH = $clog2(REG_COUNT)
) (
    input logic clk,
    input logic rst,

    input logic [ADDR_WIDTH-1:0] rs1,
    input logic [ADDR_WIDTH-1:0] rs2,
    input logic [ADDR_WIDTH-1:0] rs3,

    // Explicit register-write signal for write-back and simulation checks.
    input logic wb_en,
    input logic [DATA_WIDTH-1:0] wb_data,
    input logic [ADDR_WIDTH-1:0] wb_rd,

    output logic [DATA_WIDTH-1:0] rs1_data,
    output logic [DATA_WIDTH-1:0] rs2_data,
    output logic [DATA_WIDTH-1:0] rs3_data
);

    // 32 registers of 128 bits
    logic [DATA_WIDTH-1:0] regs [0:REG_COUNT-1];

    // Write-back occurs on rising edge
    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < REG_COUNT; i++) begin
                regs[i] <= '0;
            end
        end else if (wb_en && (wb_rd != '0)) begin
            regs[wb_rd] <= wb_data;
        end
    end

    // make reads synchronous on falling edge so operands are stable before the next rising id/ex edge capture
    always_ff @(negedge clk) begin
        if (rst) begin
            rs1_data <= '0;
            rs2_data <= '0;
            rs3_data <= '0;
        end else begin
            rs1_data <= (rs1 == '0) ? '0 : ((wb_en && (wb_rd == rs1)) ? wb_data : regs[rs1]);
            rs2_data <= (rs2 == '0) ? '0 : ((wb_en && (wb_rd == rs2)) ? wb_data : regs[rs2]);
            rs3_data <= (rs3 == '0) ? '0 : ((wb_en && (wb_rd == rs3)) ? wb_data : regs[rs3]);
        end
    end

endmodule
