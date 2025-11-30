// alu_tb.v
// Self-checking testbench for the 'alu' module.
// - Verifies the main alu_result and all status flags for a variety of test vectors.
// - Prints a detailed pass/fail log for each test and a final summary.

module alu_tb;

    // --- DUT Interface ---
    // These regs will drive the inputs of our ALU.
    reg  [31:0] src_a;
    reg  [31:0] src_b;
    reg  [3:0]  alu_control;
    // These wires will capture the outputs from our ALU.
    wire [31:0] alu_result;
    wire        zero;
    wire        carry;
    wire        overflow;
    wire        negative;

    // --- DUT Instantiation ---
    // Create an instance of the ALU module to be tested.
    alu dut (
        .src_a(src_a),
        .src_b(src_b),
        .alu_control(alu_control),
        .alu_result(alu_result),
        .zero(zero),
        .carry(carry),
        .overflow(overflow),
        .negative(negative)
    );

    // --- Verification Infrastructure ---
    integer total_tests = 0;
    integer passed_tests = 0;

    // This task runs a single test case. It applies inputs, calculates the
    // expected results locally, and compares them against the DUT's outputs.
    task run_test;
        input [3:0]  ctrl;
        input [31:0] a;
        input [31:0] b;
        input [128:1] desc; // A string to describe the test.

        // Local variables to hold the expected values.
        reg [31:0] expected_result;
        reg        expected_zero;
        reg        expected_carry;
        reg        expected_overflow;

        // Intermediate variables for calculating flags.
        reg [32:0] tmp_add;
        reg [32:0] tmp_sub;

        begin
            // 1. Apply the test vector inputs to the DUT.
            alu_control = ctrl;
            src_a = a;
            src_b = b;
            #5; // Wait a few time units for the combinational logic to settle.

            // 2. Calculate all expected results here inside the testbench.
            // This acts as a "golden model" to compare against.
            tmp_add = {1'b0, a} + {1'b0, b};
            tmp_sub = {1'b0, a} + {1'b0, ~b} + 33'b1;

            // Set default values for flags.
            expected_carry = 1'b0;
            expected_overflow = 1'b0;

            case (ctrl)
                4'b0000: begin // ADD
                    expected_result = tmp_add[31:0];
                    expected_carry = tmp_add[32];
                    expected_overflow = (~a[31] & ~b[31] &  expected_result[31]) | (a[31] & b[31] & ~expected_result[31]);
                end
                4'b0001: begin // SUB
                    expected_result = tmp_sub[31:0];
                    expected_carry = tmp_sub[32];
                    expected_overflow = (~a[31] & b[31] &  expected_result[31]) | (a[31] & ~b[31] & ~expected_result[31]);
                end
                4'b0010: expected_result = a & b;
                4'b0011: expected_result = a | b;
                4'b0100: expected_result = a ^ b;
                4'b0101: expected_result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0; // SLT
                4'b0110: expected_result = (a < b) ? 32'd1 : 32'd0;                   // SLTU
                4'b0111: expected_result = a << b[4:0];
                4'b1000: expected_result = a >> b[4:0];
                4'b1001: expected_result = $signed(a) >>> b[4:0];
                4'b1010: expected_result = b; // LUI
                4'b1011: begin // AUIPC
                    expected_result = tmp_add[31:0];
                    expected_carry = tmp_add[32];
                    expected_overflow = (~a[31] & ~b[31] &  expected_result[31]) | (a[31] & b[31] & ~expected_result[31]);
                end
                default: expected_result = 32'hDEADBEEF;
            endcase
            expected_zero = (expected_result == 32'h0);

            // 3. Compare DUT outputs with expected values and report.
            total_tests = total_tests + 1;
            if (alu_result === expected_result && zero === expected_zero && carry === expected_carry && overflow === expected_overflow) begin
                passed_tests = passed_tests + 1;
                $display("%0t | PASS | %s", $time, desc);
            end else begin
                $display("%0t | FAIL | %s", $time, desc);
                $display("       | ctrl=%b a=0x%h b=0x%h", ctrl, a, b);
                $display("       | Got:  res=0x%h, z=%b, c=%b, ov=%b", alu_result, zero, carry, overflow);
                $display("       | Exp:  res=0x%h, z=%b, c=%b, ov=%b", expected_result, expected_zero, expected_carry, expected_overflow);
            end
            #2; // Small gap for readability in the log.
        end
    endtask

    initial begin
        $dumpfile("alu_tb.vcd");
        $dumpvars(0, alu_tb);

        // --- Test Vectors ---
        // Basic arithmetic and logic
        run_test(4'b0000, 32'd12345678,   32'd87654321,   "ADD: normal numbers");
        run_test(4'b0001, 32'd87654321,   32'd12345678,   "SUB: normal numbers");
        run_test(4'b0010, 32'hF0F0F0F0,   32'h0F0F0F0F,   "AND: pattern test");
        run_test(4'b0011, 32'hF0F0F0F0,   32'h0F0F0F0F,   "OR:  pattern test");
        run_test(4'b0100, 32'hAAAAAAAA,   32'h55555555,   "XOR: pattern test");

        // Comparisons (signed/unsigned)
        run_test(4'b0101, -32'sd5,        32'sd10,        "SLT: signed compare (-5 < 10)");
        run_test(4'b0101, 32'sd5,         -32'sd10,       "SLT: signed compare (5 < -10)");
        run_test(4'b0110, 32'hFFFFFFFF,   32'h00000001,   "SLTU: unsigned compare (MAX_UINT < 1)");

        // Shifts
        run_test(4'b0111, 32'h000000FF,   32'd4,          "SLL: shift left by 4");
        run_test(4'b1000, 32'hF0000000,   32'd4,          "SRL: logical shift right by 4");
        run_test(4'b1001, 32'hF0000000,   32'd4,          "SRA: arithmetic shift right by 4");

        // U-Type instructions
        run_test(4'b1010, 32'hDEADBEEF,   {20'h12345,12'b0}, "LUI: imm=0x12345");
        // *** BUG FIX HERE *** The expected result for AUIPC depends on the PC (src_a).
        run_test(4'b1011, 32'h00001000,   {20'hABCDE,12'b0}, "AUIPC: pc + imm (pc=0x1000, imm=0xABCDE000)");

        // Edge cases for flags
        run_test(4'b0000, 32'h7FFFFFFF,   32'h00000001,   "ADD: signed overflow case");
        run_test(4'b0001, 32'h80000000,   32'h00000001,   "SUB: signed overflow case");
        run_test(4'b0000, 32'hFFFFFFFF,   32'h00000001,   "ADD: unsigned carry-out case");
        run_test(4'b0001, 32'd10,         32'd10,         "SUB: zero result case");

        // --- Final Summary ---
        #5;
        $display("\n---------------------------------------------------------");
        $display("--- ALU Test Summary: %0d / %0d Passed ---", passed_tests, total_tests);
        $display("---------------------------------------------------------");
        if (passed_tests != total_tests) begin
            $display("NOTE: Some tests failed. Check log and waveforms.");
        end else begin
            $display("SUCCESS: All ALU tests passed.");
        end
        $finish;
    end

endmodule
