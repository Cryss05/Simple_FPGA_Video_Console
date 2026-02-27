`timescale 1ns / 1ps

/**
 * Module: alu
 * Description: 16-bit Arithmetic Logic Unit. 
 * Performs arithmetic, logical, and shift operations based on the 
 * selection signal provided by the control unit.
 */
module alu(
    input  logic [15:0] operand0,   // First 16-bit input operand
    input  logic [15:0] operand1,   // Second 16-bit input operand
    input  logic [ 3:0] alu_op_sel, // Operation selector (opcode/func)
    
    output logic [15:0] result,     // 16-bit computational result
    output logic zero               // Zero flag: High if result is exactly 0
    );
    
    /**
     * Computational Logic:
     * A combinational block that selects the mathematical or logical 
     * operation based on the 'alu_op_sel' signal.
     */
    always_comb begin
        case(alu_op_sel) 
            4'd0: result = operand0 + operand1;                             // Addition (ADD)
            4'd1: result = operand0 - operand1;                             // Subtraction (SUB)
            4'd2: result = operand0 * operand1;                             // Multiplication (MULT)
            4'd3: result = operand1 >> 1;                                   // Logical Shift Right by 1 (SHR)
            4'd4: result = operand1 << 1;                                   // Logical Shift Left by 1 (SHL)
            4'd5: result = operand0 & operand1;                             // Bitwise AND
            4'd6: result = operand0 | operand1;                             // Bitwise OR
            4'd7: result = operand0 ^ operand1;                             // Bitwise XOR
            4'd8: result = ($signed(operand0) < $signed(operand1)) ? 16'd1 : 16'd0; // Set Less Than (SLT - signed)
            default: result = 16'b0;                                        // Default safety case
        endcase
    end
    
    /**
     * Zero Flag Generation:
     * Continuously monitors the result and sets the flag to 1 if all bits are 0.
     * Crucial for conditional branch instructions (BEQ, BNE).
     */
    assign zero = (result == 16'b0);
    
endmodule