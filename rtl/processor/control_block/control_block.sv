`timescale 1ns / 1ps

module control_block(
    input logic sys_clock,
    input logic reset,
    
    // Inputs from Instruction Decoder and Status Flags
    input logic [3:0] opcode,
    input logic [3:0] alu_func,
    input logic zero_flag,
    input logic vsync_pulse,         
    
    // Outputs to Program Counter (PC)
    output logic pc_en,
    output logic do_jump,
    
    // Outputs to RALU (Register File and ALU)
    output logic w_en,
    output logic [3:0] alu_op_sel,
    output logic alu_src,
    output logic [1:0] reg_write_src, 
    
    // Outputs to Data Memory
    output logic data_mem_w_en
    );

    // FSM State Definitions
    typedef enum logic [2:0] {
        FETCH       = 3'd0, // Get instruction from memory
        EXECUTE     = 3'd1, // Decode and calculate
        WRITE_BACK  = 3'd2, // Save results to registers/memory
        WAIT_VSYNC  = 3'd3, // Synchronization state for display refresh          
        HALT        = 3'd4  // Stop execution
    } state_t;
    
    state_t state, next_state;

    // Sequential Logic: State Transitions
    always_ff @(posedge sys_clock) begin
        if (reset == 1'b1) begin
            state <= FETCH;
        end else begin
            state <= next_state;
        end
    end

    // Combinational Logic: Control Signal Generation
    always_comb begin
  
        // Default signal values to prevent latches
        next_state    = state;
        pc_en         = 1'b0;
        do_jump       = 1'b0;
        w_en          = 1'b0;
        data_mem_w_en = 1'b0;
        alu_op_sel    = 4'd0;
        alu_src       = 1'b0;
        reg_write_src = 2'b00;
        
        case(state)
            FETCH: begin
                next_state = EXECUTE;
            end
            
            EXECUTE: begin
                next_state = WRITE_BACK; 
                
                case(opcode)
                    4'd1: begin // Register-to-Register ALU Operation
                        alu_op_sel = alu_func;
                        alu_src    = 1'b0;
                    end
                    
                    4'd3, 4'd4: begin // Branch instructions: BEQ / BNE
                        alu_op_sel = 4'd1; // Force SUB to compare operands 
                        alu_src    = 1'b0;
                    end
                    
                    4'd7: begin // Vertical Sync Synchronization (WVSYNC)
                        next_state = WAIT_VSYNC; 
                    end
                    
                    4'd8: begin // Addition with Immediate (ADDI) 
                        alu_op_sel = 4'd0; // ALU ADD mode
                        alu_src    = 1'b1; // Source B is the Immediate Value
                    end
                    
                    4'd9: begin // Logic AND with Immediate (ANDI) 
                        alu_op_sel = 4'd5; // ALU AND mode
                        alu_src    = 1'b1; // Source B is the Immediate Value
                    end
                    
                    4'd10: begin // Load Constant (LOADI)
                        alu_op_sel = 4'd0; // ADD (R0 + Immediate Value)
                        alu_src    = 1'b1;
                    end
                    
                    4'd13, 4'd14: begin // Memory Access: STORE and LOAD
                        alu_op_sel = 4'd0; // ADD (Address = rA + 0)
                        alu_src    = 1'b1; // Use Immediate (ASM Imm is always 0)
                    end
                    
                    4'd15: begin // End of Program (HALT)
                        next_state = HALT;
                    end
                    
                    default: ; // JMP, MEM, RAND do not utilize the ALU during Execute
                endcase
            end
            
            // ------------------------------------------------
            WAIT_VSYNC: begin // Pause execution until the frame finishes displaying
                if (vsync_pulse == 1'b1) begin
                    next_state = WRITE_BACK;
                end else begin
                    next_state = WAIT_VSYNC;
                end
            end
            
            // ------------------------------------------------
            WRITE_BACK: begin
                next_state = FETCH;
                pc_en = 1'b1; // Increment PC for the next instruction
                
                // Keep ALU on SUB to maintain a valid zero_flag for Branching
                if (opcode == 4'd3 || opcode == 4'd4) begin
                    alu_op_sel = 4'd1; 
                end
                
                case(opcode)
                    4'd1: begin // ALU Result Write-Back
                        w_en = 1'b1;
                        reg_write_src = 2'b00; // Select ALU as source
                        alu_op_sel = alu_func; // Maintain stable ALU operation
                        alu_src    = 1'b0;
                    end
                    
                    4'd8, 4'd10: begin // ADDI / LOADI Results
                        w_en = 1'b1;
                        reg_write_src = 2'b00; 
                        alu_op_sel = 4'd0;     // Maintain stable ADD operation
                        alu_src    = 1'b1;     // Ensure Immediate remains selected as source B
                    end
                    
                    4'd9: begin // ANDI Results
                        w_en = 1'b1;
                        reg_write_src = 2'b00; 
                        alu_op_sel = 4'd5;     // Maintain stable AND operation
                        alu_src    = 1'b1;     // Ensure Immediate remains selected as source B
                    end
                    
                    4'd14: begin // Load from Memory
                        w_en = 1'b1;
                        reg_write_src = 2'b01; // Select Data Memory as source
                        alu_op_sel = 4'd0;     // Maintain stable RAM address (rA + 0)
                        alu_src    = 1'b1;
                    end
                    
                    4'd11: begin // Random Number Generation (RAND)
                        w_en = 1'b1;
                        reg_write_src = 2'b10; // Select LFSR/Random module as source
                    end
                    
                    4'd13: begin // Store to Memory
                        data_mem_w_en = 1'b1;
                        // Keep ALU signals frozen to maintain a stable address bus
                        alu_op_sel = 4'd0;     // Force ADD (rA + 0)
                        alu_src    = 1'b1;     // Keep source B as Immediate
                    end
                endcase
                
                // Program Counter Control: Jump and Conditional Branching
                if (opcode == 4'd2) begin // Unconditional JMP
                    do_jump = 1'b1;
                end else if (opcode == 4'd3 && zero_flag == 1'b1) begin // BEQ (Branch if Equal)
                    do_jump = 1'b1;
                end else if (opcode == 4'd4 && zero_flag == 1'b0) begin // BNE (Branch if Not Equal)
                    do_jump = 1'b1;
                end
            end
            
            // ------------------------------------------------
            HALT: begin // Loop indefinitely in the Halt state
                next_state = HALT;
            end
            
        endcase
    end
endmodule