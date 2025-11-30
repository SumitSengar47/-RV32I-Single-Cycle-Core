`timescale 1ns/1ps

// This is a self-checking testbench for the instruction_memory.v module.
// It verifies that the memory is correctly initialized from the hex file
// at the expected starting address.

module instruction_memory_tb;

    // --- DUT Interface ---
    reg  [31:0] a;  // The address to read from.
    wire [31:0] rd; // The data read from the DUT.

    
    instruction_memory dut (
        .addr(a), 
        .rd(rd)
    );

    // --- Verification Infrastructure ---
    // A "golden model" of the first four instructions expected in the program file.
    reg [31:0] expected [0:3];

    integer i;
    integer total = 0;
    integer passed = 0;

    // --- Test Sequence ---
    initial begin
        // For this test, we must have a file named "Test_Program.mem"
        
        expected[0] = 32'hABCDE2B7;
        expected[1] = 32'h00000317;
        expected[2] = 32'hF9C00393;
        expected[3] = 32'h03200413;

        // Standard waveform setup.
        $dumpfile("instruction_memory_tb.vcd");
        $dumpvars(0, instruction_memory_tb);

        // --- Test Execution ---
        // This loop iterates through the first four words of the program.
        for (i = 0; i < 4; i = i + 1) begin
            // CRITICAL FIX: The address 'a' must start from the same base address
            // used in the instruction_memory, which is 0x1000.
            a = 32'h1000 + (i * 4); // Generates byte addresses: 0x1000, 0x1004, 0x1008, etc.
            
            #2; // Allow time for the combinational read to settle.
            
            total = total + 1;
            if (rd === expected[i]) begin
                passed = passed + 1;
                $display("%0t | PASS | addr=0x%h rd=0x%h", $time, a, rd);
            end else begin
                $display("%0t | FAIL | addr=0x%h got=0x%h expected=0x%h", $time, a, rd, expected[i]);
            end
            #1;
        end

        // --- Final Summary ---
        $display("=== SUMMARY: %0d / %0d passed ===", passed, total);
        $finish;
    end

endmodule
