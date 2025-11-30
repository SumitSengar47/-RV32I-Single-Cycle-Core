`timescale 1ns/1ps

// This is a self-checking testbench for the register_file.v module.
// It verifies the core functionality including writes, reads, and handling of x0.

module register_file_tb;

    // --- Parameters ---
    // These must match the defaults in the DUT for a correct test.
    localparam DATA_WIDTH = 32;
    localparam ADDR_WIDTH = 5;

    // --- Testbench Signals ---
    reg clk = 0;
    reg reset_n;
    reg we3;
    reg [ADDR_WIDTH-1:0] ra1, ra2, wa3;
    reg [DATA_WIDTH-1:0] wd3;
    wire [DATA_WIDTH-1:0] rd1, rd2;

    // --- Signals for Debug Port ---
    reg [ADDR_WIDTH-1:0] dbg_addr;
    wire [DATA_WIDTH-1:0] dbg_data;

    // --- Instantiate the DUT (Device Under Test) ---
    register_file #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .clk(clk),
        .reset_n(reset_n),
        .we3(we3),
        .ra1(ra1),
        .ra2(ra2),
        .wa3(wa3),
        .wd3(wd3),
        .rd1(rd1),
        .rd2(rd2),
        .dbg_addr(dbg_addr),
        .dbg_data(dbg_data)
    );

    // --- Clock Generation ---
    // Creates a clock with a 10 ns period (100 MHz).
    always #5 clk = ~clk;

    // --- Verification Infrastructure ---
    integer total = 0;
    integer passed = 0;

    // Helper task to check for equality and print results.
    task check_eq(input [DATA_WIDTH-1:0] got, input [DATA_WIDTH-1:0] exp, input [128:1] desc);
        begin
            total = total + 1;
            if (got === exp) begin
                passed = passed + 1;
                $display("%0t | PASS | %s | got=0x%h expected=0x%h", $time, desc, got, exp);
            end else begin
                $display("%0t | FAIL | %s | got=0x%h expected=0x%h", $time, desc, got, exp);
            end
        end
    endtask

    // --- Test Sequence ---
    initial begin
        $dumpfile("register_file_tb.vcd");
        $dumpvars(0, register_file_tb);

        // 1. Apply reset
        reset_n = 1'b0;
        we3 = 1'b0;
        ra1 = 5'd0; ra2 = 5'd0; wa3 = 5'd0; wd3 = 32'd0; dbg_addr = 5'd0;
        #12; // Wait for at least one clock edge while reset is active.
        reset_n = 1'b1;
        @(posedge clk);

        // 2. Check if x0 is zero after reset.
        ra1 = 5'd0;
        #2;
        check_eq(rd1, 32'h00000000, "x0 reads zero after reset");

        // 3. Write a value to register x1.
        @(negedge clk);
        we3 = 1'b1;
        wa3 = 5'd1; 
        wd3 = 32'hA5A5A5A5;
        @(negedge clk); // The write happens on the posedge before this.
        we3 = 1'b0;     // De-assert signals for the next cycle.
        #2;

        // 4. Read back the value from x1.
        ra1 = 5'd1;
        #2;
        check_eq(rd1, 32'hA5A5A5A5, "read back x1 after write");

        // 5. Attempt to write to x0 (should be ignored).
        @(negedge clk);
        we3 = 1'b1;
        wa3 = 5'd0; 
        wd3 = 32'hDEADBEEF;
        @(negedge clk);
        we3 = 1'b0;
        #2;
        ra1 = 5'd0;
        #2;
        check_eq(rd1, 32'h00000000, "write to x0 ignored");

        // 6. Overwrite the value in x1.
        @(negedge clk);
        we3 = 1'b1;
        wa3 = 5'd1; 
        wd3 = 32'h11112222;
        @(negedge clk);
        we3 = 1'b0;
        #2;
        ra1 = 5'd1;
        #2;
        check_eq(rd1, 32'h11112222, "overwrite x1 value");

        // 7. Test simultaneous read and write.
        @(negedge clk);
        we3 = 1'b1;
        wa3 = 5'd2; 
        wd3 = 32'hCAFEBABE;
        @(negedge clk);
        we3 = 1'b0;
        #2;
        ra1 = 5'd2; ra2 = 5'd1; // Read x2 and x1
        #2;
        check_eq(rd1, 32'hCAFEBABE, "x2 written correctly");
        check_eq(rd2, 32'h11112222, "x1 value is still correct");

        // 8. Test Debug Port
        @(negedge clk);
        we3 = 1'b1;
        wa3 = 5'd3; 
        wd3 = 32'hFEEDF00D;
        @(negedge clk);
        we3 = 1'b0;
        #2;
        dbg_addr = 5'd3; // Use the debug port to read x3
        #2;
        check_eq(dbg_data, 32'hFEEDF00D, "read back x3 via debug port");

        // --- Final Summary ---
        #5;
        $display("=== SUMMARY: %0d / %0d passed ===", passed, total);
        if (passed != total) $display("Some tests FAILED.");
        else $display("All tests passed.");
        $finish;
    end

endmodule

