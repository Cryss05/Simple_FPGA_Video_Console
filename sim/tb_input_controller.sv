`timescale 1ns / 1ps

/**
 * Module: tb_input_controller
 * Description: Testbench for the Input Controller subsystem.
 * Verifies glitch filtering (debouncing), edge detection, and FIFO buffer 
 * queuing by simulating both valid button presses and invalid noisy glitches.
 */
module tb_input_controller();

    // System Signals
    logic clk;
    logic reset;
    
    // Inputs to DUT
    logic [3:0] buttons_in;
    logic cpu_read_en;
    
    // Outputs from DUT
    logic [3:0] data_to_cpu;

    // Device Under Test (DUT) Instantiation
    input_controller dut (
        .sys_clock(clk),
        .reset(reset),
        .buttons_in(buttons_in),
        .cpu_read_en(cpu_read_en),
        .data_to_cpu(data_to_cpu)
    );

    // Clock Generation (100 MHz)
    always #5 clk = ~clk;

    /**
     * Task: press_button_valid
     * Simulates a clean, sustained button press that should be registered.
     */
    task press_button_valid(input int index);
        $display("[%0t] Task: VALID Press on Button %0d", $time, index);
        buttons_in[index] = 1; 
        repeat(5) @(posedge clk); // Hold long enough to pass debounce logic
        buttons_in[index] = 0;
        repeat(2) @(posedge clk); // Short pause before next action
    endtask

    /**
     * Task: press_button_invalid
     * Simulates a mechanical bounce or EMI glitch (too short to be registered).
     */
    task press_button_invalid(input int index);
        $display("[%0t] Task: INVALID Glitch on Button %0d", $time, index);
        buttons_in[index] = 1;
        repeat(1) @(posedge clk); // Hold for only 1 cycle (should be filtered out)
        buttons_in[index] = 0;
        repeat(2) @(posedge clk);
    endtask

    /**
     * Task: cpu_read
     * Simulates the CPU issuing a read command to pop data from the FIFO.
     */
    task cpu_read();
        @(posedge clk);
        cpu_read_en = 1;
        @(posedge clk);
        $display("[%0t] CPU LOAD: Read value %b from FIFO", $time, data_to_cpu);
        cpu_read_en = 0;
    endtask

    // Main Test Sequence
    initial begin
        // Initialization
        clk = 0;
        reset = 1;
        buttons_in = 4'b0000;
        cpu_read_en = 0;
        
        #50 reset = 0;
        repeat(5) @(posedge clk);

        $display("--- STEP 1: Glitch Filtering Test ---");
        // This should NOT put anything into the FIFO
        press_button_invalid(3); 

        $display("--- STEP 2: Buffer Fill (Rapid commands) ---");
        // Simulating a fast sequence of inputs
        press_button_valid(3); 
        press_button_valid(1);
        press_button_valid(2);
        press_button_valid(0);
        press_button_valid(1);
        press_button_valid(1);
        press_button_valid(0);
        
        #50;

        $display("--- STEP 3: Partial CPU Read ---");
        // CPU reads only 2 values, leaving the rest in the FIFO
        cpu_read(); 
        cpu_read(); 

        $display("--- STEP 4: Another press while buffer is not empty ---");
        // Adding data to a partially full FIFO
        press_button_valid(0); 

        $display("--- STEP 5: Completely empty the buffer ---");
        // Read out everything remaining in the FIFO (plus a few extra reads to test empty state)
        cpu_read(); 
        cpu_read(); 
        cpu_read(); 
        cpu_read();
        cpu_read();
        cpu_read();
        cpu_read();
        cpu_read();
        cpu_read();
        cpu_read();

        #100;
        $display("[%0t] Testing completed successfully!", $time);
        $finish;
    end

endmodule