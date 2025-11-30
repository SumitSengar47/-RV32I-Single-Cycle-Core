// pc.v
// This module implements the Program Counter (PC), which is a 32-bit register.
// The PC's primary job is to hold the memory address of the instruction
// that the processor is currently fetching.

module pc #(
    // This parameter sets the address where the processor will fetch its
    // very first instruction after a reset. The standard start address is 0x1000.
    parameter RESET_PC = 32'h0000_1000
) (
    input  wire        clk,       // The main system clock.
    input  wire        reset_n,   // The active-low reset signal.
    input  wire [31:0] pc_next,   // The address of the next instruction to be fetched.
    output wire [31:0] pc         // The current address being fetched.
);

    // This is the internal register that holds the state of the PC.
    reg [31:0] pc_reg;

    // This block describes the behavior of the PC register.
    // It is sensitive to the rising edge of the clock for normal updates,
    // and the falling edge of reset_n for an asynchronous reset.
    always @(posedge clk or negedge reset_n) begin
        // If the active-low reset is asserted (reset_n is 0)...
        if (!reset_n)
            // ...load the PC with the defined starting address.
            pc_reg <= RESET_PC;
        // Otherwise, on the rising edge of the clock...
        else
            // ...update the PC with the address of the next instruction.
            pc_reg <= pc_next;
    end

    // This line continuously connects the internal register's value to the
    // module's output port.
    assign pc = pc_reg;

endmodule

