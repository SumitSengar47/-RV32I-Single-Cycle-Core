`timescale 1ns/1ps
// final_verification_tb.v
// This is the final, self-checking testbench for the complete single_cycle_top design.
// It executes a comprehensive test program and verifies the final state of the
// registers and data memory to provide a definitive pass/fail result.

module final_verification_tb;

    // --- DUT Interface ---
    reg  clk = 0;
    reg  reset_n;

    wire [31:0] pc;
    wire [31:0] write_data;
    wire [31:0] data_addr;
    wire        mem_write;

    reg  [4:0]  dbg_reg_addr;
    wire [31:0] dbg_reg_data;

    // --- Instantiate the Top-Level Design ---
    // This connects the testbench to the complete processor system.
    single_cycle_top dut (
        .clk         (clk),
        .reset_n     (reset_n),
        .write_data  (write_data),
        .data_addr   (data_addr),
        .mem_write   (mem_write),
        .pc          (pc),
        .dbg_reg_addr(dbg_reg_addr),
        .dbg_reg_data(dbg_reg_data)
    );

    // --- Clock Generation (100 MHz) ---
    always #5 clk = ~clk;

    // --- Verification Infrastructure ---
    integer total_checks = 0;
    integer passed_checks = 0;
    
    // A non-intrusive monitor for the Store Word (sw) instruction.
    // This is a verification technique that observes the DUT's
    // outputs without interfering with its operation.
    reg [31:0] monitored_sw_addr;
    reg [31:0] monitored_sw_data;
    reg        sw_detected = 1'b0;

    always @(posedge clk) begin
        if (reset_n) begin
            // On any cycle where a memory write occurs, capture the data.
            if (mem_write && !sw_detected) begin // Capture only the first SW
                $display("INFO: SW Monitor detected store at PC=0x%h, Addr=0x%h, Data=0x%h", pc, data_addr, write_data);
                monitored_sw_addr <= data_addr;
                monitored_sw_data <= write_data;
                sw_detected       <= 1'b1;
            end
        end else begin
            // Reset the monitor's state during system reset.
            monitored_sw_addr <= 32'bx;
            monitored_sw_data <= 32'bx;
            sw_detected       <= 1'b0;
        end
    end

    // Helper task to check a register's final value using the debug port.
    task check_reg;
        input [4:0]         addr;
        input signed [31:0] expected_val;
        input [160:1]       desc;
        reg   signed [31:0] got_val;
        begin
            total_checks = total_checks + 1;
            dbg_reg_addr = addr;
            #1; // Allow combinational path for debug read to settle.
            got_val = dbg_reg_data;

            if (got_val === expected_val) begin
                passed_checks = passed_checks + 1;
                $display("%0t | PASS | %s (x%0d) | Expected=%d (0x%h), Got=%d (0x%h)", $time, desc, addr, expected_val, expected_val, got_val, got_val);
            end else begin
                $display("%0t | FAIL | %s (x%0d) | Expected=%d (0x%h), Got=%d (0x%h)", $time, desc, addr, expected_val, expected_val, got_val, got_val);
            end
        end
    endtask

    // Helper task to check a 32-bit value (e.g., from the monitor).
    task check_eq_32;
        input signed [31:0] got;
        input signed [31:0] expected;
        input [160:1]       desc;
        begin
             total_checks = total_checks + 1;
             if (got === expected) begin
                 passed_checks = passed_checks + 1;
                 $display("%0t | PASS | %s | Expected=%d (0x%h), Got=%d (0x%h)", $time, desc, expected, expected, got, got);
             end else begin
                 $display("%0t | FAIL | %s | Expected=%d (0x%h), Got=%d (0x%h)", $time, desc, expected, expected, got, got);
             end
        end
    endtask

    // --- Test Execution and Final Verification ---
    initial begin
        $dumpfile("final_verification_tb.vcd");
        $dumpvars(0, final_verification_tb);
        
        $display("---------------------------------------------------------");
        $display("--- Final RISC-V Core Verification Starting ---");
        $display("---------------------------------------------------------");

        // Assert reset for a few cycles to initialize the processor.
        reset_n = 1'b0;
        repeat (3) @(posedge clk);
        reset_n = 1'b1;
        @(posedge clk);
        
        // The program is ~26 instructions long. We'll run for 40 cycles
        // to ensure it has plenty of time to complete and enter the final halt loop.
        repeat (40) @(posedge clk);
        
        $display("\n---------------------------------------------------------");
        $display("--- Program Execution Finished. Verifying Final State ---");
        $display("---------------------------------------------------------");
        
        // --- Verify Final Register State ---
        // These expected values are calculated based on the program in the Canvas
        // and a standard PC start address of 0x1000.
        check_reg( 5, 32'hABCDE000, "U-Type: LUI result");
        check_reg( 6, 32'h00001004, "U-Type: AUIPC result");
        check_reg( 9, -50,          "R-Type: ADD result");
        check_reg(10, 150,          "R-Type: SUB result");
        check_reg(11, 1,            "R-Type: SLT result");
        check_reg(12, -82,          "R-Type: XOR result");
        check_reg(13, 150,          "I-Type: LW result");
        check_reg( 2, 32'h00001044, "I-Type: JALR link address");    // PC of JALR (0x1040) + 4
        
        // CORRECTED: The JAL instruction is at PC=0x1048, so its link address is 0x104C.
        check_reg( 1, 32'h0000104C, "J-Type: JAL link address");

        // Verify that instructions skipped by branches/jumps were not executed.
        // Their target registers should remain at their reset value of 0.
        check_reg(14, 0, "Branch Skip Check (if taken)");
        check_reg(15, 0, "Branch Skip Check (if taken)");
        check_reg(21, 0, "JALR Skip Check (if taken)");
        check_reg(22, 0, "JAL Skip Check (if taken)");
        
        // Check markers for control flow
        check_reg(16, 1, "Branch was taken marker");
        check_reg(25, 1, "Final instruction reached marker");

        // --- Verify Store Word Operation via Monitor ---
        if (sw_detected) begin
            check_eq_32(monitored_sw_addr, 8,   "S-Type: Store Word address");
            check_eq_32(monitored_sw_data, 150, "S-Type: Store Word data");
        end else begin
            $display("%0t | FAIL | Store Word (sw) was never detected by monitor!", $time);
            total_checks = total_checks + 2; // Account for the two failed checks.
        end

        // --- Final Summary ---
        $display("\n---------------------------------------------------------");
        if (passed_checks == total_checks) begin
            $display("=== SUMMARY: %0d / %0d CHECKS PASSED. ALL INSTRUCTIONS VERIFIED! ===", passed_checks, total_checks);
        end else begin
            $display("=== SUMMARY: %0d / %0d CHECKS PASSED. VERIFICATION FAILED. ===", passed_checks, total_checks);
        end
        $display("---------------------------------------------------------");
        
        $finish;
    end

endmodule

