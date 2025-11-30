// result_mux.v
// This module implements the write-back result multiplexer for the processor.
// It selects the final value that will be written back into the register file.

module result_mux #(
    parameter WIDTH = 32
) (
    // --- Ports ---
    input  wire [WIDTH-1:0] alu_result, // Input from the ALU.
    input  wire [WIDTH-1:0] read_data,  // Input from Data Memory (for loads).
    input  wire [WIDTH-1:0] pc_plus4,   // The value of PC + 4 (for JAL/JALR).
    input  wire [1:0]       result_src, // The 2-bit control signal that selects the input.
    output reg  [WIDTH-1:0] result      // The final, selected result.
);

    // --- Combinational Logic for Multiplexer ---
    // This block is always active and will update the output whenever an input changes.
    // It uses a case statement to select one of the three data sources.
    always @(*) begin
        case (result_src)
            // If result_src is 2'b10, select PC+4 (for JAL/JALR link address).
            2'b10: result = pc_plus4;
            
            // If result_src is 2'b01, select data from memory (for LW).
            2'b01: result = read_data;
            
            // If result_src is 2'b00, select the result from the ALU.
            2'b00: result = alu_result;
            
            // A defensive default case to prevent inferring a latch.
            // In a correct design, this case should not be reached.
            default: result = alu_result;
        endcase
    end

endmodule

