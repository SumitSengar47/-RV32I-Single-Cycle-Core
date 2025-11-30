// single_cycle_top.v
// This is the top-level wrapper for the entire single-cycle processor system.
// It instantiates the processor core and connects it to the instruction and data memories.

module single_cycle_top (
    // --- System Ports ---
    input  wire        clk,          // System clock.
    input  wire        reset_n,      // Active-low reset.

    // --- Data Memory Interface (for observation by the testbench) ---
    output wire [31:0] write_data,   // Data being written to data memory.
    output wire [31:0] data_addr,    // Address for data memory access.
    output wire        mem_write,    // Write enable signal for data memory.
    
    // --- Observation Ports ---
    output wire [31:0] pc,           // The current program counter.
    
    // --- Debug Ports (for the testbench) ---
    input  wire [4:0]  dbg_reg_addr, // Address for the debug register read port.
    output wire [31:0] dbg_reg_data  // Data from the debug register read port.
);

    // --- Internal Wires ---
    // These wires connect the processor core to the memory modules.
    wire [31:0] instr;      // The instruction fetched from instruction memory.
    wire [31:0] read_data;  // The data read from data memory.

    // -------------------------
    // Processor Core Instantiation
    // -------------------------
    single_cycle_core core_u (
        // System inputs
        .clk        (clk),
        .reset_n    (reset_n),
        
        // Memory interface
        .instr      (instr),      // Input: Receives instruction from imem.
        .read_data  (read_data),  // Input: Receives data from dmem.
        .mem_write  (mem_write),  // Output: Controls dmem writes.
        .write_data (write_data), // Output: Provides data for dmem stores.
        
        // The ALU result from the core is used as the address for data memory.
        .alu_result (data_addr),
        
        // Observation and debug ports
        .pc           (pc),
        .dbg_reg_addr (dbg_reg_addr),
        .dbg_reg_data (dbg_reg_data)
    );

    // -------------------------
    // Instruction Memory Instantiation
    // -------------------------
    // The instruction memory is a simple ROM. Its address input is driven by the PC.
    instruction_memory imem_u (
        .addr (pc),    // The Program Counter provides the address.
        .rd   (instr)  // The instruction at that address is read out.
    );

    // -------------------------
    // Data Memory Instantiation
    // -------------------------
    // The data memory is a RAM with synchronous writes and asynchronous reads.
    data_memory dmem_u (
        .clk  (clk),        // The clock for synchronous writes.
        .we   (mem_write),  // The write enable signal from the core.
        .addr (data_addr),   // The memory address from the core's ALU result.
        .wd   (write_data), // The data to be written, from the core.
        .rd   (read_data)   // The data read out, which is fed back to the core.
    );

endmodule
