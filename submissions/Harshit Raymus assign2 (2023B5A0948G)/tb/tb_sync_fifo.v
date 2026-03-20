`timescale 1ns/1ps

module tb_sync_fifo;

parameter DATA_WIDTH = 8;
parameter DEPTH = 16;
parameter ADDR_WIDTH = $clog2(DEPTH);

reg clk;
reg rst_n;

reg wr_en;
reg rd_en;
reg [DATA_WIDTH-1:0] wr_data;

wire [DATA_WIDTH-1:0] rd_data;
wire wr_full;
wire rd_empty;
wire [ADDR_WIDTH:0] count;
integer cycle;

// DUT

sync_fifo_top #(
.DATA_WIDTH(DATA_WIDTH),
.DEPTH(DEPTH)
) dut (
.clk(clk),
.rst_n(rst_n),

.wr_en(wr_en),
.wr_data(wr_data),
.wr_full(wr_full),

.rd_en(rd_en),
.rd_data(rd_data),
.rd_empty(rd_empty),

.count(count)
);

// Golden Model
reg [DATA_WIDTH-1:0] model_mem [0:DEPTH-1];

integer model_wr_ptr;
integer model_rd_ptr;
integer model_count;

reg [DATA_WIDTH-1:0] model_rd_data;

// Coverage Counters
integer cov_full;
integer cov_empty;
integer cov_wrap;
integer cov_simul;
integer cov_overflow;
integer cov_underflow;

// Clock

initial begin
clk = 0;
forever #5 clk = ~clk;
end

// Reset + Test Execution

initial begin

rst_n = 0;
wr_en = 0;
rd_en = 0;
wr_data = 0;

model_wr_ptr = 0;
model_rd_ptr = 0;
model_count = 0;

cov_full = 0;
cov_empty = 0;
cov_wrap = 0;
cov_simul = 0;
cov_overflow = 0;
cov_underflow = 0;

cycle = 0;

#20
rst_n = 1;

basic_test();
fill_test();
drain_test();
simul_test();
overflow_test();
underflow_test();

print_coverage();

$display("Simulation completed successfully");
$finish;

end

// Golden Model Update

always @(posedge clk) begin

if(!rst_n) begin
    model_wr_ptr <= 0;
    model_rd_ptr <= 0;
    model_count <= 0;
end
else begin

case({wr_en && (model_count < DEPTH), rd_en && (model_count > 0)})

2'b10: begin
    model_mem[model_wr_ptr] <= wr_data;
    model_wr_ptr <= (model_wr_ptr == DEPTH-1) ? 0 : model_wr_ptr + 1;
    model_count <= model_count + 1;
end

2'b01: begin
    model_rd_data <= model_mem[model_rd_ptr];
    model_rd_ptr <= (model_rd_ptr == DEPTH-1) ? 0 : model_rd_ptr + 1;
    model_count <= model_count - 1;
end

2'b11: begin
    model_mem[model_wr_ptr] <= wr_data;
    model_rd_data <= model_mem[model_rd_ptr];

    model_wr_ptr <= (model_wr_ptr == DEPTH-1) ? 0 : model_wr_ptr + 1;
    model_rd_ptr <= (model_rd_ptr == DEPTH-1) ? 0 : model_rd_ptr + 1;
end

endcase

// Coverage tracking
if(model_count == DEPTH)
    cov_full = cov_full + 1;

if(model_count == 0)
    cov_empty = cov_empty + 1;

if(wr_en && rd_en && model_count>0 && model_count<DEPTH)
    cov_simul = cov_simul + 1;

if(wr_en && model_count == DEPTH)
    cov_overflow = cov_overflow + 1;

if(rd_en && model_count == 0)
    cov_underflow = cov_underflow + 1;

if(model_wr_ptr == DEPTH-1 || model_rd_ptr == DEPTH-1)
    cov_wrap = cov_wrap + 1;

end

cycle = cycle + 1;

#1 scoreboard();

end

// Scoreboard

task scoreboard;
begin

if(rd_en && !rd_empty) begin
    if(rd_data !== model_rd_data) begin
        $display("ERROR data mismatch cycle=%0d",cycle);
        $finish;
    end
end

if(count !== model_count) begin
    $display("ERROR count mismatch cycle=%0d",cycle);
    $display("Expected=%0d Got=%0d",model_count,count);
    $finish;
end

if(rd_empty !== (model_count==0)) begin
    $display("ERROR empty flag mismatch");
    $finish;
end

if(wr_full !== (model_count==DEPTH)) begin
    $display("ERROR full flag mismatch");
    $finish;
end

end
endtask

// TESTS

task basic_test;
begin
$display("Running basic write/read");

wr_en = 1;
wr_data = 8'hAA;
#10;

wr_en = 0;
rd_en = 1;
#10;

rd_en = 0;

end
endtask


task fill_test;
integer i;
begin

$display("Running fill test");

for(i=0;i<DEPTH;i=i+1) begin
wr_en = 1;
wr_data = i;
#10;
end

wr_en = 0;

end
endtask


task drain_test;
integer i;
begin

$display("Running drain test");

for(i=0;i<DEPTH;i=i+1) begin
rd_en = 1;
#10;
end

rd_en = 0;

end
endtask


task simul_test;
integer i;
begin

$display("Running simultaneous test");

for(i=0;i<10;i=i+1) begin
wr_en = 1;
rd_en = 1;
wr_data = $random;
#10;
end

wr_en = 0;
rd_en = 0;

end
endtask


task overflow_test;
begin

$display("Running overflow test");

wr_en = 1;
repeat(DEPTH+2) begin
wr_data = $random;
#10;
end

wr_en = 0;

end
endtask


task underflow_test;
begin

$display("Running underflow test");

rd_en = 1;
repeat(5) #10;

rd_en = 0;

end
endtask

// Coverage Report

task print_coverage;
begin

$display("Full events: %0d", cov_full);
$display("Empty events: %0d", cov_empty);
$display("Pointer wrap events: %0d", cov_wrap);
$display("Simultaneous read/write: %0d", cov_simul);
$display("Overflow attempts: %0d", cov_overflow);
$display("Underflow attempts: %0d", cov_underflow);
end
endtask
endmodule