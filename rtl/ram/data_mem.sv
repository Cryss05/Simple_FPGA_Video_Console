`timescale 1ns / 1ps

/**
 * Module: data_mem
 * Description: General-purpose synchronous Data Memory (RAM) for the RISC CPU.
 * It provides 32,768 words (16-bit wide) of storage.
 */
module data_mem(
    input  logic sys_clock,       // System clock signal
   
    // Control and Data signals
    input  logic mem_w_en,        // Memory Write Enable (1: Write, 0: Read)
    input  logic [15:0] addr_read,   // 16-bit Memory Address bus
    input  logic [15:0] data_write,  // 16-bit Data input bus (for Store instructions)
    output logic [15:0] data_read    // 16-bit Data output bus (for Load instructions)
    );
    
    // Internal Memory Storage: 32k words (16-bit depth)
    // Range: 0 to 32767
    logic [15:0] memorie [0:32767];
    
    /**
     * Synchronous Memory Access:
     * Reads and Writes are synchronized with the rising edge of the system clock.
     * This module implements a "Read-First" or "Write-Through" behavior depending 
     * on the synthesizer, but standard synchronous RAM logic is maintained.
     */
    always_ff @(posedge sys_clock) begin
        if(mem_w_en) begin
            // Write operation: Using bits [14:0] to index 32,768 addresses
            memorie[addr_read[14:0]] <= data_write;
        end
        // Read operation: Synchronous data output update
        data_read <= memorie[addr_read[14:0]];
    end
    
endmodule