/*
 * Copyright (c) 2024 Anton Schreiner
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_aschrein_asic_0 (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
  
  reg [7:0] reg_file[0:7];
  reg [7:0] tmp_reg; // temporary register for common operations
  reg [3:0] reg_dst;
  reg [3:0] state;
  reg [7:0] reg_io;

  localparam STATE_IDLE         = 4'd0;

  localparam INST_MOV_REG_IMM  = 4'd1; // mov_reg_imm tmp_reg, imm[7:4] : 1 byte tmp_reg[3:0] = imm[3:0] the upper 4 bits are as is
  localparam INST_GET_REG      = 4'd2; // get_reg reg                   : 1 byte inst move reg to IO bus register
  localparam INST_ACC_REG      = 4'd3; // acc_reg tmp_reg, reg          : 1 byte: 1 byte tmp_reg += reg
  localparam INST_NEG_REG      = 4'd4; // neg_reg                       : 1 byte: 1 byte tmp_reg = -tmp_reg
  localparam INST_MOV_TMP_REG  = 4'd5; // mov_tmp_reg reg               : 1 byte: 1 byte tmp_reg = reg
  localparam INST_MOV_REG_TMP  = 4'd6; // mov_reg_tmp reg               : 1 byte: 1 byte reg = tmp_reg
  localparam INST_TEST_ZERO    = 4'd7; // test_zero                     : 1 byte: tmp_reg == 1 if tmp_reg == 0 else 0
  localparam INST_SHIFT_LEFT   = 4'd8; // shift_left imm                : 1 byte: tmp_reg <<= imm
  localparam INST_SHIFT_RIGHT  = 4'd9; // shift_right imm               : 1 byte: tmp_reg >>= imm

  wire [3:0] instr_code;
  wire [3:0] instr_imm;
    
  assign instr_code = ui_in[3:0];
  assign instr_imm  = ui_in[7:4];

  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      // reset state
      state   <= STATE_IDLE;
      reg_dst <= 4'b0;
      reg_io  <= 8'hFF;
      for (int i = 0; i < 16; i++) reg_file[i] <= 8'h00; // reset all registers

    end else begin
      case (state)
        STATE_IDLE: begin
          case (instr_code)
            INST_MOV_REG_IMM: begin
              tmp_reg[3:0] <= instr_imm[3:0];
            end
            INST_GET_REG: begin // Throw reg onto the IO bus next cycle
              reg_io <= reg_file[ui_in[7:4]];
            end
            INST_ACC_REG: begin // tmp_reg += reg
              tmp_reg <= tmp_reg + reg_file[ui_in[7:4]];
            end
            INST_NEG_REG: begin // tmp_reg = -tmp_reg
              tmp_reg <= -tmp_reg;
            end
            INST_MOV_TMP_REG: begin
              tmp_reg <= reg_file[instr_imm];
            end
            INST_MOV_REG_TMP: begin
              reg_file[instr_imm] <= tmp_reg;
            end
            INST_TEST_ZERO: begin
              tmp_reg <= (tmp_reg == 0) ? 8'h01 : 8'h00;
            end
            INST_SHIFT_LEFT: begin
              tmp_reg <= tmp_reg << instr_imm;
            end
            INST_SHIFT_RIGHT: begin
              tmp_reg <= tmp_reg >> instr_imm;
            end
            default: begin
              // reg_io <= 8'hFF;
            end
          endcase
        end
        default: begin
          state <= STATE_IDLE;
        end
      endcase

      // Your logic here
    end
  end

  // All output pins must be assigned. If not used, assign to 0.
  // assign uo_out  = ui_in + uio_in;  // Example: ou_out is the sum of ui_in and uio_in
  assign uio_out = 0;
  assign uio_oe  = 0;
  assign uo_out  = reg_io[7:0];
  // List all unused inputs to prevent warnings
  wire _unused = &{ena, clk, rst_n, 1'b0};

endmodule
