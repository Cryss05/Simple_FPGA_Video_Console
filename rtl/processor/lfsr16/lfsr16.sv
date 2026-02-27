`timescale 1ns / 1ps

/**
 * Module: lfsr16
 * Description: 16-bit Linear Feedback Shift Register (LFSR).
 * Provides a pseudo-random 16-bit value used by the CPU for game logic, 
 * such as generating random positions for game objects.
 */
module lfsr16(
    input  logic sys_clock,   // System clock (100MHz)
    input  logic reset,       // Active high reset
    output logic [15:0] rand_out // 16-bit pseudo-random output
    );
    
    // Internal shift register
    logic [15:0] lfsr_reg;
    
    // Feedback bit calculation
    // Taps are placed at positions 15, 13, 12, and 10 to ensure a maximal length 
    // sequence (Fibonacci LFSR configuration).
    logic feedback;
    assign feedback = lfsr_reg[15] ^ lfsr_reg[13] ^ lfsr_reg[12] ^ lfsr_reg[10];
    
    /**
     * Shift Register Logic:
     * On every clock cycle, the register shifts left and the calculated 
     * feedback bit is inserted at the least significant bit (LSB).
     */
    always_ff @(posedge sys_clock) begin
        if(reset) begin
            // Non-zero seed value (0xDEAD). 
            // An LFSR must never be initialized to 0, as it would get stuck.
            lfsr_reg <= 16'hDEAD;
        end else begin
            // Shift left and append feedback
            lfsr_reg <= {lfsr_reg[14:0], feedback};
        end
    end
    
    // Output the current state of the shift register as the random value
    assign rand_out = lfsr_reg;
    
endmodule