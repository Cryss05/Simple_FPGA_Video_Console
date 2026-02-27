`timescale 1ns / 1ps

/**
 * Module: debouncer
 * Description: Filters out mechanical switch bounce from a button input.
 * It requires the signal to remain stable for a specific duration (10ms)
 * before updating the output. It also includes a 2-stage synchronizer
 * to handle metastability from the asynchronous input.
 */
module debouncer(
    input  logic sys_clock,  // System clock (100 MHz)
    input  logic reset,      // Active high reset
    input  logic button_in,  // Raw, noisy asynchronous button input
    output logic button_out  // Stable, synchronized debounced output
);
    // Configuration Parameters
    localparam int DEBOUNCE_TIME_MS = 10;          // Time required for signal stability
    localparam int CLK_FREQ_HZ = 100_000_000;      // 100 MHz system clock frequency
    
    // Calculate the number of clock cycles needed to reach the stability threshold
    localparam int CYCLES_LIMIT = (CLK_FREQ_HZ * DEBOUNCE_TIME_MS) / 1000; 
    
    // Determine the bit width required for the internal counter
    localparam int WIDTH = $clog2(CYCLES_LIMIT + 1); 
    
    // Internal signals
    logic [WIDTH-1:0] counter;
    logic button_in_sync0, button_in_sync1; // Synchronizer flip-flops
    
    /**
     * Stage 1: 2-Stage Synchronizer
     * Prevents metastability by passing the asynchronous input through 
     * two consecutive flip-flops.
     */
    always_ff @(posedge sys_clock) begin
        if(reset) begin
            button_in_sync0 <= 1'b0;
            button_in_sync1 <= 1'b0;
        end    
        else begin
            button_in_sync0 <= button_in;
            button_in_sync1 <= button_in_sync0;
        end
    end
    
    /**
     * Stage 2: Stability Counter
     * Compares the synchronized input with the current stable output.
     * If they differ, it increments a counter. Once the counter reaches 
     * CYCLES_LIMIT, the output is updated.
     */
    always_ff @(posedge sys_clock) begin
        if(reset) begin
            counter <= 0;
            button_out <= 1'b0;
        end 
        else begin
            // Check if the input signal has changed relative to the stable output
            if(button_in_sync1 != button_out) begin
                if(counter < CYCLES_LIMIT) begin
                    counter <= counter + 1; // Increment while signal is stable but different
                end else begin
                    button_out <= button_in_sync1; // Update output after threshold reached
                    counter <= 0;
                end
            end else begin
                // Reset counter if the input matches the output (signal is back to "idle")
                counter <= 0;
            end
        end
    end
     
endmodule