`timescale 1ns/1ps

module pipeline_registers_tb;
    logic clk = 1'b0;
    logic rst = 1'b1;
    logic [24:0] if_instr;
    logic [24:0] if_out;
    logic [24:0] id_instr;
    logic [24:0] id_out;
    logic [127:0] id_rs1;
    logic [127:0] id_rs2;
    logic [127:0] id_rs3;
    logic [127:0] id_rd;
    logic [127:0] ex_rs1;
    logic [127:0] ex_rs2;
    logic [127:0] ex_rs3;
    logic [127:0] ex_rd;
    logic [127:0] wb_data_in;
    logic [127:0] wb_data_out;
    logic [4:0] wb_addr_in;
    logic [4:0] wb_addr_out;
    logic wb_en_in;
    logic wb_en_out;
    integer failures;

    if_id_reg if_id (
        .clk(clk),
        .rst(rst),
        .if_id_instr_in(if_instr),
        .if_id_instr_out(if_out)
    );

    id_ex_reg id_ex (
        .clk(clk),
        .rst(rst),
        .id_ex_instr_in(id_instr),
        .id_ex_rs1_in(id_rs1),
        .id_ex_rs2_in(id_rs2),
        .id_ex_rs3_in(id_rs3),
        .id_ex_rd_in(id_rd),
        .id_ex_instr_out(id_out),
        .id_ex_rs1_out(ex_rs1),
        .id_ex_rs2_out(ex_rs2),
        .id_ex_rs3_out(ex_rs3),
        .id_ex_rd_out(ex_rd)
    );

    ex_wb_reg ex_wb (
        .clk(clk),
        .rst(rst),
        .ex_wb_rd_out_in(wb_data_in),
        .ex_wb_wr_addr_in(wb_addr_in),
        .ex_wb_write_en_in(wb_en_in),
        .ex_wb_rd_out_out(wb_data_out),
        .ex_wb_wr_addr_out(wb_addr_out),
        .ex_wb_write_en_out(wb_en_out)
    );

    always #5 clk = ~clk;

    task automatic check_value(input logic [127:0] actual, input logic [127:0] expected,
                               input string label);
        if (actual !== expected) begin
            failures++;
            $display("FAIL %s: expected %h, got %h", label, expected, actual);
        end
    endtask

    initial begin
        failures = 0;
        if_instr = '0;
        id_instr = '0;
        id_rs1 = '0;
        id_rs2 = '0;
        id_rs3 = '0;
        id_rd = '0;
        wb_data_in = '0;
        wb_addr_in = '0;
        wb_en_in = 1'b0;
        @(posedge clk);
        #1;
        check_value({103'd0, if_out}, '0, "IF/ID reset");
        check_value({103'd0, id_out}, '0, "ID/EX instruction reset");
        check_value(ex_rs1, '0, "ID/EX data reset");
        check_value(wb_data_out, '0, "EX/WB data reset");
        check_value({123'd0, wb_addr_out}, '0, "EX/WB address reset");
        check_value({127'd0, wb_en_out}, '0, "EX/WB write-enable reset");

        rst = 1'b0;
        if_instr = 25'h1abcde;
        id_instr = 25'h12345;
        id_rs1 = 128'h1;
        id_rs2 = 128'h2;
        id_rs3 = 128'h3;
        id_rd = 128'h4;
        wb_data_in = 128'h5;
        wb_addr_in = 5'd6;
        wb_en_in = 1'b1;
        @(posedge clk);
        #1;
        check_value({103'd0, if_out}, {103'd0, 25'h1abcde}, "IF/ID captures instruction");
        check_value({103'd0, id_out}, {103'd0, 25'h12345}, "ID/EX captures instruction");
        check_value(ex_rs1, 128'h1, "ID/EX captures rs1");
        check_value(ex_rs2, 128'h2, "ID/EX captures rs2");
        check_value(ex_rs3, 128'h3, "ID/EX captures rs3");
        check_value(ex_rd, 128'h4, "ID/EX captures rd");
        check_value(wb_data_out, 128'h5, "EX/WB captures result");
        check_value({123'd0, wb_addr_out}, {123'd0, 5'd6}, "EX/WB captures destination");
        check_value({127'd0, wb_en_out}, {127'd0, 1'b1}, "EX/WB captures write enable");

        if (failures != 0)
            $fatal(1, "pipeline_registers_tb failed with %0d errors", failures);
        $display("PASS: pipeline_registers_tb");
        $finish;
    end
endmodule
