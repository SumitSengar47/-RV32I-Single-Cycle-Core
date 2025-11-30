// instruction_memory.v
// This module implements a word-addressable, asynchronous Read-Only Memory (ROM)
// for storing the processor's program. It is initialized from a hex file.
// This version is optimized for simulation performance with a smaller memory depth.

module instruction_memory #(
    // --- Parameters ---
    // The DEPTH has been reduced to make the memory easier to view in a waveform.
    parameter DEPTH      = 256, // The total number of 32-bit words the memory can hold.
    parameter ADDR_WIDTH = 8    // The number of bits needed to address the memory (log2(DEPTH)).
) (
    // --- Ports ---
    input  wire [31:0] addr, // The byte address from the Program Counter (PC).
    output wire [31:0] rd    // The 32-bit instruction read from memory.
);

    // --- Memory Array ---
    // This declares the actual storage for the instructions.
    // With DEPTH=256, the valid indices are now [0:255].
    reg [31:0] imem [0:DEPTH-1];

    // --- Combinational Read Logic ---
    // The memory is read asynchronously. The output 'rd' will change
    // as soon as the input 'addr' changes.
    // The byte address from the PC is converted to a word address by selecting the upper bits.
    // For addr=0x0, addr[9:2] correctly calculates the word index as 0.
    assign rd = imem[addr[ADDR_WIDTH+1:2]];

    // --- Simulation Initialization ---
    // This block is executed only once at the beginning of a simulation.
    initial begin
        // The $readmemh system task reads a hex file ("Test_Program.mem")
        // and loads its contents into the 'imem' array.
        //
        // The starting address for loading is now 0 to match the new memory map.
        $readmemh("program.mem", imem, 0);
    end

endmodule

