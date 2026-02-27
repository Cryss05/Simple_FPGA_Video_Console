`timescale 1ns / 1ps

/**
 * Module: instr_mem
 * Description: Synchronous Instruction Memory (ROM).
 * Stores the 32-bit compiled instructions for the CPU. 
 * The memory is initialized from an external HEX file.
 */
module instr_mem(
    input  logic sys_clock,       // System clock signal
    
    // Memory Interface Signals
    input  logic [15:0] addr_read, // 16-bit Instruction Address (from Program Counter)
    output logic [31:0] data_read  // 32-bit Instruction output bus
    );
    
    /** * Internal Storage: 16,384 words (32-bit wide).
     * This provides 16K of instruction space.
     */
    logic [31:0] memorie [0:16383];
    
    /**
     * Initialization:
     * Loads the "program.hex" file into the memory array at the start of simulation 
     * or during FPGA configuration.
     */
    initial begin
        $readmemh("program.hex", memorie);
    end
    
    /**
     * Synchronous Read Logic:
     * The instruction is fetched on the rising edge of the system clock.
     * Uses bits [13:0] of the address to index the 16K memory range.
     */
    always_ff @(posedge sys_clock) begin
        data_read <= memorie[addr_read[13:0]];  
    end
    
endmodule