// register_file.v
// This module implements a parameterized 32x32 Register File for the RISC-V ISA.
// It features two combinational read ports and one synchronous write port.

module register_file #(
    // --- Parameters ---
    parameter DATA_WIDTH = 32,                 // Defines the width of each register (e.g., 32 bits).
    parameter ADDR_WIDTH = 5,                  // Defines the width of the address bus (e.g., 5 bits for 32 registers).
    parameter NUM_REGS   = 1 << ADDR_WIDTH   // Automatically calculates the total number of registers.
) (
    // --- Ports ---
    input  wire                   clk,         // System clock for synchronous writes.
    input  wire                   reset_n,     // Active-low asynchronous reset.
    input  wire                   we3,         // Write enable for the write port.
    input  wire [ADDR_WIDTH-1:0]  ra1,         // Read address for port 1 (for rs1).
    input  wire [ADDR_WIDTH-1:0]  ra2,         // Read address for port 2 (for rs2).
    input  wire [ADDR_WIDTH-1:0]  wa3,         // Write address for the write port (for rd).
    input  wire [DATA_WIDTH-1:0]  wd3,         // Write data for the write port.
    output wire [DATA_WIDTH-1:0]  rd1,         // Read data from port 1.
    output wire [DATA_WIDTH-1:0]  rd2,         // Read data from port 2.
    
    // Testbench debug port for direct read access.
    input  wire [ADDR_WIDTH-1:0]  dbg_addr,    // Debug read address.
    output wire [DATA_WIDTH-1:0]  dbg_data     // Debug read data.
);

    // --- Storage ---
    // This declares the main storage array for the 32 registers.
    reg [DATA_WIDTH-1:0] regs [0:NUM_REGS-1];

    // Integer for use in the reset loop.
    integer i;

    // --- Write and Reset Logic ---
    // This block handles all state changes (writes and resets).
    // It is sensitive to the clock edge for writes and the reset signal level for reset.
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            // On reset (when reset_n is low), loop through and clear all registers to zero.
            for (i = 0; i < NUM_REGS; i = i + 1)
                regs[i] <= {DATA_WIDTH{1'b0}};
        end else if (we3) begin
            // On a rising clock edge, if write enable is active...
            // ...and the write address is not zero (to protect x0)...
            if (wa3 != {ADDR_WIDTH{1'b0}})
                // ...write the data into the specified register.
                regs[wa3] <= wd3;
        end
    end

    // --- Read Logic ---
    // The read ports are combinational, meaning the output changes as soon as the address changes.
    // This implements the rule that reading from register x0 always returns zero.
    assign rd1 = (ra1 == {ADDR_WIDTH{1'b0}}) ? {DATA_WIDTH{1'b0}} : regs[ra1];
    assign rd2 = (ra2 == {ADDR_WIDTH{1'b0}}) ? {DATA_WIDTH{1'b0}} : regs[ra2];
    
    // The debug port has the same combinational read logic.
    // This assignment was critical to fixing the "zzzzzzzz" error in the testbench.
    assign dbg_data = (dbg_addr == {ADDR_WIDTH{1'b0}}) ? {DATA_WIDTH{1'b0}} : regs[dbg_addr];

endmodule

