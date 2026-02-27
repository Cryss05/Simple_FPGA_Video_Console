`timescale 1ns / 1ps

module fifo_buffer(
    input  logic sys_clock,
    input  logic reset,
    
    // Input Buttons Interface
    input logic [3:0] button_vector,
    input logic button_pulse,
    
    // CPU Interface
    input logic cpu_read_en,
    output logic [3:0] data_to_cpu
);
    
    logic [3:0] mem [0:7]; // 8 Commands Buffer
    logic [3:0] count; // How many commands are in buffer
    logic [2:0] rd_ptr; // The address where CPU reads the command
    logic [2:0] wr_ptr;
    
    always_ff @(posedge sys_clock) begin
        if(reset) begin
            count <= 0;
            rd_ptr <= 0;
            wr_ptr <= 0;
        end else begin
            if(button_pulse && (count < 8)) begin
                mem[wr_ptr] <= button_vector;
                wr_ptr <= wr_ptr + 1;
                if(!cpu_read_en)
                    count <= count + 1;
            end
            
            if(cpu_read_en && (count > 0)) begin
                rd_ptr <= rd_ptr + 1;
                if(!button_pulse)
                    count <= count - 1;
            end
        end
    end
    
    // Buffer empty (count = 0) => CPU reads 0 (no input from buttons)
    assign data_to_cpu = (count == 0) ? 4'b0000 : mem[rd_ptr];
    
    
endmodule