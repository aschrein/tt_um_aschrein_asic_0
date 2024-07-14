/*
 * Copyright (c) 2024 Your Name
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

  // All output pins must be assigned. If not used, assign to 0.
  assign uo_out  = ui_in + uio_in;  // Example: ou_out is the sum of ui_in and uio_in
  assign uio_out = 0;
  assign uio_oe  = 0;

  // List all unused inputs to prevent warnings
  // wire _unused = &{ena, clk, rst_n, 1'b0};

  reg [7:0] reg_file [0:15];
  
  reg [3:0] reg_dst;
  reg [7:0] state;
  reg [7:0] reg_io;

  localparam STATE_IDLE         = 0;
  localparam STATE_SET_REG_NEXT = 1;

  localparam MOV_REG_IMM  = 4'd1;
  localparam GET_REG      = 4'd2;
  localparam ACC_REG = 4'd3;

  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      
    end else begin

      case (state)
        STATE_IDLE: begin
          case (ui_in[3:0])
              MOV_REG_IMM: begin
            // reg_file[reg_dst] <= ui_in[7:4];
              reg_dst <= ui_in[7:4];
              state <= STATE_SET_REG_NEXT;
              end
              GET_REG: begin
                reg_io <= reg_file[ui_in[7:4]];
              end
              ACC_REG: begin
                reg_file[ui_in[3:0]] <= reg_file[ui_in[7:4]] + reg_file[ui_in[3:0]];
              end
          endcase
        end
        STATE_SET_REG_NEXT: begin
          reg_file[reg_dst][7:0] <= ui_in[7:0];
          state <= STATE_IDLE;
        end
      endcase

      // Your logic here
    end
  end

  assign uio_out = reg_io[7:0]; 

endmodule
