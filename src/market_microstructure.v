/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */


 /*
  
  * Project description:
  * This project will aim to tackle three main modules. 
  * - SPI module to receive tick data
  * - Feature extraction engine that maintains top-of-book state and computes
  *   fixed-point metrics including order book imbalance and EWMA-based
  *   momentum signals.
  * - VGA rendering module that generates real-time visualizations of price,
  *  liquidity depth, and breakout indicators using pixel-level combinational
  
*/
`default_nettype none
module market_microstructure (
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
  assign uo_out  = 0;
  assign uio_out = 0;
  assign uio_oe  = 8'b00000000;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, ui_in};

  // Currently we have unused miso. Could use if have extra gates and time. 
  // assign uio_out[2] = miso;

  wire cs   = uio_in[0];
  wire mosi = uio_in[1];
  wire sclk = uio_in[3];
  wire rst  = ~rst_n; // High reset

  wire       spi2m_val; // note for variable can only be reg if assigned in the module
  wire       spi2m_rdy = 1'b1;
  wire [7:0] spi2m_data;

  spiModule spi(
    .clk(clk),
    .rst(rst),
    .cs(cs),
    .mosi(mosi),
    .miso(/*unused*/),
    .sclk(sclk),
    .data_out(spi2m_data),
    .val(spi2m_val),
    .rdy(spi2m_rdy)
  );



endmodule
