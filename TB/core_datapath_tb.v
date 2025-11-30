`timescale 1ns/1ps

// This is a self-checking testbench for the complete core_datapath.v module.
// It acts as a "fake" control unit, providing the necessary control signals
// to stimulate the datapath and execute a sequence of instructions.

module core_datapath_tb;

    // --- DUT Interface Signals ---
    reg  clk = 0;
    reg  reset_n;

    // Control Signals (driven by this testbench)
    reg  [1:0]  result_src;
    reg         pc_src;
    reg         alu_src;
    reg         alu_src_a;    // ADDED: To test AUIPC
    reg         reg_write;
    reg  [2:0]  imm_src;
    reg  [3:0]  alu_control;

    // Data Signals (driven by this testbench)
    reg  [31:0] instr;
    reg  [31:0] read_data;

    // Outputs from the DUT
    wire        zero;
    wire        carry;        // ADDED: To monitor ALU flags
    wire        overflow;     // ADDED: To monitor ALU flags
    wire        negative;     // ADDED: To monitor ALU flags
    wire [31:0] pc;
    wire [31:0] alu_result;
    wire [31:0] write_data;

    // Debug Port Interface
    reg  [4:0]  dbg_reg_addr; // ADDED: To read register values
    wire [31:0] dbg_reg_data; // ADDED: To get data from debug port

    // --- Instantiate the DUT (Device Under Test) ---
    core_datapath dut (
        .clk(clk),
        .reset_n(reset_n),
        .result_src(result_src),
        .pc_src(pc_src),
        .alu_src(alu_src),
        .alu_src_a(alu_src_a),
        .reg_write(reg_write),
        .imm_src(imm_src),
        .alu_control(alu_control),
        .instr(instr),
        .read_data(read_data),
        .zero(zero),
        .carry(carry),
        .overflow(overflow),
        .negative(negative),
        .pc(pc),
        .alu_result(alu_result),
        .write_data(write_data),
        .dbg_reg_addr(dbg_reg_addr),
        .dbg_reg_data(dbg_reg_data)
    );

    // --- Clock Generation (100 MHz) ---
    always #5 clk = ~clk;

    // --- Verification Infrastructure ---
    integer total = 0;
    integer passed = 0;

    // Task for checking equality and reporting results.
    task check_eq;
        input [31:0] got;
        input [31:0] exp;
        input [160:1] desc;
        begin
            total = total + 1;
            if (got === exp) begin
                passed = passed + 1;
                $display("%0t | PASS | %s | got=0x%h", $time, desc, got);
            end else begin
                $display("%0t | FAIL | %s | got=0x%h expected=0x%h",
                         $time, desc, got, exp);
            end
        end
    endtask

    // Task to run one instruction cycle.
    task run_instr;
        input [31:0] t_instr;
        input [3:0]  t_alu_ctrl;
        input [2:0]  t_imm_sel;
        input        t_alu_src_b; // Selects between rs2 and immediate
        input        t_alu_src_a; // Selects between rs1 and PC
        input [1:0]  t_res_src;   // Selects the write-back source
        input        t_reg_we;
        input [31:0] exp_alu_res;
        input [4:0]  check_reg_addr; // Address of register to check after write
        input [31:0] check_reg_exp;  // Expected value in that register
        begin
            // Drive the control signals on the falling edge to ensure they are stable.
            @(negedge clk);
            instr       = t_instr;
            alu_control = t_alu_ctrl;
            imm_src     = t_imm_sel;
            alu_src     = t_alu_src_b;
            alu_src_a   = t_alu_src_a;
            result_src  = t_res_src;
            reg_write   = t_reg_we;
            pc_src      = 1'b0;      // Assume no branches for this simple test.
            read_data   = 32'h0;

            // Wait for the rising edge where the action happens.
            @(posedge clk);
            #1; // Allow combinational logic to settle after the clock edge.

            // --- Perform Checks ---
            check_eq(alu_result, exp_alu_res, "ALU Result Check");

            // If a register write was supposed to happen, check the register file.
            if (t_reg_we && check_reg_addr != 0) begin
                dbg_reg_addr = check_reg_addr;
                #1; // Allow debug read path to settle.
                check_eq(dbg_reg_data, check_reg_exp, "Register Write-Back Check");
            end
        end
    endtask

    // --- Test Sequence ---
    initial begin
        $dumpfile("core_datapath_tb.vcd");
        $dumpvars(0, core_datapath_tb);

        // --- Reset the Processor ---
        reset_n = 1'b0;
        repeat (3) @(posedge clk);
        reset_n = 1'b1;
        
        // --- Test Program ---
        // Instr 1: addi x1, x0, 5
        run_instr(32'h00500093, 4'b0000, 3'd0, 1'b1, 1'b0, 2'b00, 1'b1, 32'd5, 5'd1, 32'd5);

        // Instr 2: addi x2, x1, 7
        run_instr(32'h00708113, 4'b0000, 3'd0, 1'b1, 1'b0, 2'b00, 1'b1, 32'd12, 5'd2, 32'd12);

        // Instr 3: add x3, x1, x2
        run_instr(32'h002081B3, 4'b0000, 3'd5, 1'b0, 1'b0, 2'b00, 1'b1, 32'd17, 5'd3, 32'd17);

        // --- Final Summary ---
        #10;
        $display("=== SUMMARY: %0d / %0d passed ===", passed, total);
        $finish;
    end

endmodule
