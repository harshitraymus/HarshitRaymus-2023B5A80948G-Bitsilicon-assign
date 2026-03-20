Project: Synchronous FIFO Verification

Files
rtl/sync_fifo.v        : FIFO RTL
rtl/sync_fifo_top.v    : Top wrapper
tb/tb_sync_fifo.v      : Self-checking testbench

Features
- Synchronous FIFO
- Parameterized depth and width
- Golden reference model
- Scoreboard verification
- Directed tests
- Manual coverage counters

Run:
- iverilog *.v
- vvp a.out
