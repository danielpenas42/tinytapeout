`default_nettype none

module spiModule (
    input  wire       clk,
    input  wire       rst,
    input  wire       cs,
    input  wire       mosi,
    output wire       miso,
    input  wire       sclk,
    output wire [7:0] data_out,
    output reg        val,
    input  wire       rdy
);

reg [7:0] shift_reg;
reg [2:0] counter;
reg       s1, s2, prev, cs1, cs2;
reg       clk_rise;
reg [7:0] data_send;

assign data_out = data_send;

// syncronize clocks using cross domain crossing
always @(posedge clk) begin
    clk_rise <= 1'b0;
    cs1       <= cs;
    cs2       <= cs1;

    if (rst) begin 
        s1 <= 1'b0;
        s2 <= 1'b0;
        prev <= 1'b0;
    end
    else begin
        s1 <= sclk;
        s2 <= s1;
        prev <= s2;
        if (s2 & ~prev) begin
            clk_rise <= 1'b1;
        end
    end
end

// Counter
always @(posedge clk) begin
    if(rst) begin
        counter <= 3'd0;
    end
    else begin
        if (clk_rise & ~cs2) begin
            counter <= counter + 1;
        end
    end
end


// Shift Register
always @(posedge clk) begin
    if(rst) begin
        shift_reg <= 8'd0;
    end
    else begin
        if (clk_rise & ~cs2) begin
            shift_reg <= {shift_reg[6:0], mosi};
        end
    end
end

// Datapath logic
always @(posedge clk) begin
    if (rst) begin
        val <= 1'b0;
        data_send <= 8'd0;
    end
    else begin
        if (~val & (counter == 3'd7) & clk_rise) begin 
            val <= 1'b1;
            data_send <= {shift_reg[6:0], mosi};
        end
        if (val & rdy) begin
            val <= 1'b0;
        end
    end

end

endmodule