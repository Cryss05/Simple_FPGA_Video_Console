`timescale 1ns / 1ps

/**
 * Module: program_counter
 * Description: 16-bit Program Counter (PC) that manages the execution flow.
 * It tracks the address of the current instruction and handles both 
 * sequential execution and branching (jumps).
 */
module program_counter(
    input  logic sys_clock,    // System clock signal
    input  logic reset,        // Active high reset
    
    // Control signals from the Control Unit
    input  logic pc_en,        // PC Enable: allows the PC to update
    input  logic do_jump,      // Jump Enable: 1 for branching/jumping, 0 for sequential
    
    // Data input
    input  logic [15:0] jump_value, // Target address for jump/branch instructions
    
    // PC Output
    output logic [15:0] pc     // Current instruction address
    );
    
    /**
     * Sequential Logic:
     * Updates the Program Counter on the rising edge of the system clock.
     */
    always_ff @(posedge sys_clock) begin
        if(reset) begin
            // Reset PC to the start of the instruction memory (address 0)
            pc <= 16'b0;
        end else if(pc_en) begin
            // Priority 1: Handle jumps/branches
            if(do_jump == 1'b1) begin
                pc <= jump_value;
            end 
            // Priority 2: Standard sequential increment
            else begin
                pc <= pc + 1;
            end 
        end
    end
    
endmodule