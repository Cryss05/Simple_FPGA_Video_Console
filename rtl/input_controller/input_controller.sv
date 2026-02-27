`timescale 1ns / 1ps

/**
 * Module: input_controller
 * Description: Manages physical button inputs by providing hardware debouncing,
 * edge detection, and asynchronous storage via a FIFO buffer.
 */
module input_controller(
    input  logic sys_clock,      // System clock
    input  logic reset,          // System reset
    
    // Physical Input Buttons Interface
    input  logic [3:0] buttons_in,
    
    // CPU Interface
    input  logic cpu_read_en,    // Signal from CPU to pop data from FIFO
    output logic [3:0] data_to_cpu
);
    // Internal signals for processing
    logic [3:0] debounced_btns;  // Cleaned button signals
    logic any_btn_pressed;       // Logic OR of all debounced buttons
    logic write_pulse;           // Pulse generated on a new button press
    
    /**
     * Hardware Debouncing:
     * Generates clean signals for all 4 input buttons to prevent 
     * mechanical contact bounce from triggering multiple events.
     */
    genvar i;
    generate
        for (i = 0; i < 4; i++) begin : db_gen
            debouncer db_inst (
                .sys_clock(sys_clock),
                .reset(reset),
                .button_in(buttons_in[i]),
                .button_out(debounced_btns[i])
            );
        end
    endgenerate
    
    // Combinational logic to detect if any button is currently held down
    assign any_btn_pressed = |debounced_btns;
    
    /**
     * Edge Detection:
     * Generates a single clock-cycle pulse when a button transition is detected.
     * This ensures each physical press results in exactly one entry in the FIFO.
     */
    edge_detector ed_inst (
        .sys_clock(sys_clock),
        .reset(reset),
        .in(any_btn_pressed),
        .pulse_out(write_pulse)
    );
    
    /**
     * FIFO Buffer:
     * Stores debounced button vectors asynchronously. This allows the CPU 
     * to read inputs at its own pace without missing fast button presses.
     */
    fifo_buffer fifo_inst(
        .sys_clock(sys_clock),
        .reset(reset),
        .button_vector(debounced_btns),
        .button_pulse(write_pulse), // Trigger write on edge detection pulse
        .cpu_read_en(cpu_read_en),  // Pop data when CPU performs a read
        .data_to_cpu(data_to_cpu)
    );
    
endmodule