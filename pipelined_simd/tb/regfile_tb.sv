`timescale 1ns/1ps

module regfile_tb;
    logic clk = 1'b0;
    logic rst = 1'b1;
    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [4:0] rs3;
    logic [4:0] wb_rd;
    logic wb_en;
    logic [127:0] wb_data;
    logic [127:0] rs1_data, rs2_data, rs3_data;
    integer failures;

    regfile dut (
        .clk(clk),
        .rst(rst),
        .rs1(rs1),
        .rs2(rs2),
        .rs3(rs3),
        .wb_en(wb_en),
        .wb_data(wb_data),
        .wb_rd(wb_rd),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .rs3_data(rs3_data)
    );

    always #5 clk = ~clk;

    task automatic check_value(input logic [127:0] actual,
                               input logic [127:0] expected,
                               input string label);
        if (actual !== expected) begin
            failures++;
            $display("FAIL %s: expected %h, got %h", label, expected, actual);
        end
    endtask

    initial begin
        failures = 0;
        rs1 = '0;
        rs2 = '0;
        rs3 = '0;
        wb_en = 1'b0;
        wb_rd = '0;
        wb_data = '0;

        @(posedge clk);
        @(negedge clk);
        #1;
        check_value(rs1_data, '0, "reset read port 1");
        check_value(rs2_data, '0, "reset read port 2");
        check_value(rs3_data, '0, "reset read port 3");

        rst = 1'b0;
        wb_en = 1'b1;
        wb_rd = 5'd5;
        wb_data = 128'h0123_4567_89ab_cdef_fedc_ba98_7654_3210;
        @(posedge clk);
        #1;
        wb_en = 1'b0;
        rs1 = 5'd5;
        rs2 = 5'd5;
        rs3 = 5'd5;
        @(negedge clk);
        #1;
        check_value(rs1_data, 128'h0123_4567_89ab_cdef_fedc_ba98_7654_3210,
                    "read port 1 after write");
        check_value(rs2_data, 128'h0123_4567_89ab_cdef_fedc_ba98_7654_3210,
                    "read port 2 after write");
        check_value(rs3_data, 128'h0123_4567_89ab_cdef_fedc_ba98_7654_3210,
                    "read port 3 after write");

        wb_en = 1'b1;
        wb_rd = 5'd0;
        wb_data = '1;
        @(posedge clk);
        #1;
        wb_en = 1'b0;
        rs1 = '0;
        rs2 = '0;
        rs3 = '0;
        @(negedge clk);
        #1;
        check_value(rs1_data, '0, "r0 write is ignored on port 1");
        check_value(rs2_data, '0, "r0 write is ignored on port 2");
        check_value(rs3_data, '0, "r0 write is ignored on port 3");

        if (failures != 0)
            $fatal(1, "regfile_tb failed with %0d errors", failures);
        $display("PASS: regfile_tb");
        $finish;
    end
endmodule
