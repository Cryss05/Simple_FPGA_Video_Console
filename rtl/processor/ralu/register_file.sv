`timescale 1ns / 1ps

module register_file(
    input logic sys_clock,
    input logic w_en,               // Write Enable signal
    
    // Register Address Inputs
    input logic [3:0] addr_operand0, // Address for first read port (Source A)
    input logic [3:0] addr_operand1, // Address for second read port (Source B)
    input logic [3:0] addr_result,   // Address for the write port (Destination)
    
    // Data Input
    input logic [15:0] data_write,   // Data to be written into the register
    
    // Data Outputs (Read Ports)
    output logic [15:0] operand0,    // Data output for Source A
    output logic [15:0] operand1     // Data output for Source B
    );
    
    // Internal Storage: 16 registers, each 16 bits wide
    logic [15:0] memorie [0:15];
    
    // Initial State: Ensure Register 0 (R0) starts at zero
    initial begin
        memorie[0] = 16'd0;
    end

    // Sequential Write Logic
    always_ff @(posedge sys_clock) begin
        // Write only if w_en is active AND the destination is not R0
        // This reinforces R0 as a constant zero register at the hardware level
        if(w_en == 1 && addr_result != 4'd0) begin
            memorie[addr_result] <= data_write;
        end
    end
    
    // Combinational Read Logic (Asynchronous Read)
    // If address 0 is requested, return constant 0. Otherwise, read from memory.
    assign operand0 = (addr_operand0 != 4'd0) ? memorie[addr_operand0] : 16'd0;
    assign operand1 = (addr_operand1 != 4'd0) ? memorie[addr_operand1] : 16'd0;
    
endmodule