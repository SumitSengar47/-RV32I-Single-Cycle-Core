// data_memory.v
// This module implements a word-addressable data memory (RAM).
// It features synchronous writes (on the rising clock edge) and
// asynchronous reads (combinational), which is a standard memory design.

module data_memory #(
    // --- Parameters ---
    parameter DEPTH      = 1024, // The total number of 32-bit words the memory can hold (e.g., 4 KB).
    parameter ADDR_WIDTH = 10    // The number of bits needed to address the memory (log2(DEPTH)).
) (
    // --- Ports ---
    input  wire        clk,  // System clock, used for synchronous writes.
    input  wire        we,   // Write Enable signal. If high, a write occurs on the next posedge clk.
    input  wire [31:0] addr, // The byte address from the ALU (for loads/stores).
    input  wire [31:0] wd,   // The 32-bit data to be written into memory (Write Data).
    output wire [31:0] rd    // The 32-bit data read from memory (Read Data).
);
    // Integer for loop iteration during simulation initialization.
    integer i;
    
    // --- Memory Array ---
    // This declares the actual storage for the data.
    // It's an array of registers, with 'DEPTH' entries, each 32 bits wide.
    reg [31:0] ram [0:DEPTH-1];

    // --- Asynchronous (Combinational) Read Logic ---
    // The read operation is combinational. The output 'rd' will change
    // as soon as the input 'addr' changes.
    // The byte address from the ALU is converted to a word address by selecting the upper bits.
    assign rd = ram[addr[ADDR_WIDTH+1:2]];

    // --- Synchronous Write Logic ---
    // The write operation only occurs on the positive edge of the clock.
    always @(posedge clk) begin
        // The write is only performed if the Write Enable (we) signal is high.
        if (we) begin
            // The specified word in the ram is updated with the write data (wd).
            ram[addr[ADDR_WIDTH+1:2]] <= wd;
        end
    end

    // --- Simulation-Only Initialization ---
    // This block is executed only once at the beginning of a simulation to
    // put the memory into a known state. It is not synthesized into hardware.
    initial begin
        // This loop initializes every word in the memory to zero.
        for (i = 0; i < DEPTH; i = i + 1) begin
            ram[i] = 32'h00000000;
        end

        // You can optionally pre-load some memory locations with non-zero
        // values for more specific testing scenarios.
        ram[0]       = 32'hFACEFACE;
        ram[1]       = 32'h00000002;
        ram[2]       = 32'h00000003;
        ram[DEPTH-1] = 32'h00000063; // Pre-load the last word.
    end

endmodule
