`timescale 1ns / 1ps

/**
 * Module: edge_detector
 * Description: Detects a rising edge (0 to 1 transition) on the input signal
 * and generates a single clock-cycle pulse as an output. 
 * * In this project, it is used to ensure that a single button press results 
 * in only one entry being written to the input FIFO, regardless of how long 
 * the button is held.
 */
module edge_detector(
    input  logic sys_clock,  // System clock
    input  logic reset,      // Active high reset
    input  logic in,         // Synchronized/Debounced input signal
    output logic pulse_out   // Single-cycle output pulse on rising edge
);
    // Register to store the state of the input from the previous clock cycle
    logic prev_in;
    
    /**
     * Sequential Logic:
     * Updates the 'prev_in' register on every rising edge of the clock.
     * This allows the module to compare the current input state with the past state.
     */
    always_ff @(posedge sys_clock) begin
        if(reset) begin
            prev_in <= 1'b0; // Reset state to 0
        end
        else begin
            prev_in <= in;   // Capture current state for the next cycle
        end
    end
    
    /**
     * Combinational Logic (Rising Edge Detection):
     * The pulse is high ONLY when:
     * 1. The current input 'in' is high (1)
     * 2. The previous input 'prev_in' was low (0)
     */
    assign pulse_out = in && !prev_in;
    
endmodule