`timescale 1ns / 1ps

module ralu(
    input logic sys_clock,
    input logic w_en,
    
    // Register File Address Inputs
    input logic [3:0] addr_operand0,
    input logic [3:0] addr_operand1,
    input logic [3:0] addr_result,
    
    // External Data Inputs
    input logic [15:0] instr_value,        // Immediate Value extracted from instruction
    input logic [15:0] data_mem_data_read, // Data read from RAM (Load instructions)
    input logic [15:0] rand_value,         // Random value from hardware LFSR
    
    // Control Logic Signals
    input logic [3:0] alu_op_sel,          // Operation selector for the ALU
    input logic alu_src,                   // MUX selector: 0 = Register, 1 = Immediate
    input logic [1:0] reg_write_src,       // MUX selector for Write-Back source
    
    // RALU Outputs
    output logic [15:0] operand0,          // Current value of first operand (from RF)
    output logic [15:0] operand1,          // Current value of second operand (from RF)
    output logic [15:0] result,            // Calculated result from ALU
    output logic zero_flag                 // Status flag: 1 if ALU result is zero
    );
    
    // Internal wires for Multiplexers (MUXs)
    logic [15:0] rf_data_write;            // Data to be written back to Register File
    logic [15:0] alu_operand1_in;          // Final value feeding into ALU's second input
    
    // MUX: Selects between Register operand or Immediate value for the ALU
    assign alu_operand1_in = (alu_src == 1'b1) ? instr_value : operand1;
    
    // MUX: Selects the source for the Register File write-back stage
    always_comb begin
        case(reg_write_src)
            2'b00: rf_data_write = result;              // ALU calculation
            2'b01: rf_data_write = data_mem_data_read;  // Memory Load
            2'b10: rf_data_write = rand_value;          // Random Number
            
            default: rf_data_write = 16'd0;             // Safety default
        endcase
    end
    
    // Instantiate the Register File
    register_file reg_inst(
        .sys_clock(sys_clock),
        .w_en(w_en),   
        .addr_operand0(addr_operand0),
        .addr_operand1(addr_operand1),
        .addr_result(addr_result),
        .data_write(rf_data_write),    
        .operand0(operand0), 
        .operand1(operand1)     
    );
    
    // Instantiate the Arithmetic Logic Unit
    alu alu_inst(
        .operand0(operand0),  
        .operand1(alu_operand1_in),  
        .alu_op_sel(alu_op_sel),         
        .result(result),
        .zero(zero_flag)
    );
    
endmodule