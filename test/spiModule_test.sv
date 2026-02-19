`default_nettype none
`timescale 1ns / 1ps


module spiModule_test ();

  logic clk;
  logic rst;
  logic sclk;
  TestUtilsClkRst t(
    .clk(clk),
    .rst(rst)
  ); // clk in util is 10 units
  always #50 sclk = ~sclk; // safe assumption to assume that clk will have 10x freq of sclk

  // Wire up the inputs and outputs:

  logic cs;
  logic mosi;
  logic [7:0] data_out;
  logic val;
  logic rdy;

  spiModule dut (
      .clk(clk),
      .rst(rst),
      .cs(cs),
      .mosi(mosi),
      .miso(/*unused*/),
      .sclk(sclk),
      .data_out(data_out),
      .val(val),
      .rdy(rdy)
  );

  task automatic init_signals();
    begin
      cs   = 1'b1;
      mosi = 1'b0;
      rdy  = 1'b1;
    end
  endtask

  task automatic send_byte(input logic [7:0] value);
    begin

      for (int i = 7; i >= 0; i--) begin
        @(negedge sclk);
        mosi = value[i];
        @(posedge sclk);
      end

    end

  endtask

  task automatic start_frame();
    begin
      cs = 0;
    end
  endtask

    task automatic end_frame();
    begin
      cs = 1;
    end
  
  endtask

  task automatic test1();
  begin
    init_signals();
    start_frame()
    
  end
  endtask

initial begin
    t.test_bench_begin();
    t.test_suite_begin("spiModule_test");

    if (t.n == 0 || t.n == 1) test1();
    if (t.n == 0 || t.n == 2) test2();
    if (t.n == 0 || t.n == 3) test3();
    if (t.n == 0 || t.n == 4) test4();


    t.test_suite_end();
    t.test_bench_end();
end



endmodule
