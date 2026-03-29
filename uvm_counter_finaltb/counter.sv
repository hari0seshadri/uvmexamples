//=============================================================================
// counter.sv  (unchanged from Lab11)
//
// Parameterised loadable up/down counter — the Device Under Test (DUT).
//
// Features:
//   - WIDTH-bit count register (default 8 bits, set by COUNTER_WIDTH in pkg).
//   - Four operating modes selected by the 'mode' input each clock cycle:
//       MODE_HOLD      – retain current value
//       MODE_LOAD      – parallel-load from load_data port
//       MODE_COUNT_UP  – increment; sets overflow flag when 255 → 0
//       MODE_COUNT_DN  – decrement; sets underflow flag when 0 → 255
//   - Active-low asynchronous reset (rst_n) clears count and flags to 0.
//   - All outputs registered on posedge clk for clean, glitch-free signals.
//
// Port connection:
//   The DUT connects to the testbench exclusively through counter_if using
//   the 'dut' modport, keeping the port list concise and interface-driven.
//=============================================================================
import counter_pkg::*;   // MODE_* constants, COUNTER_WIDTH, counter_mode_t

module counter #(parameter WIDTH = COUNTER_WIDTH) (
  counter_if.dut intf    // all signals via the shared interface
);

  //--------------------------------------------------------------------------
  // Internal signals — next-state combinational values
  //--------------------------------------------------------------------------
  logic [WIDTH-1:0] counter_reg;   // registered count value
  logic [WIDTH-1:0] next_count;    // combinational next count
  logic             next_ovf;      // combinational overflow flag
  logic             next_unf;      // combinational underflow flag

  //--------------------------------------------------------------------------
  // Combinational next-state logic
  // Computes next_count, next_ovf, and next_unf based on current mode.
  //--------------------------------------------------------------------------
  always_comb begin
    // Default: hold current value, no flags
    next_count = counter_reg;
    next_ovf   = 0;
    next_unf   = 0;

    case (intf.mode)
      // Parallel load — next count equals the load_data input
      MODE_LOAD:     next_count = intf.load_data;

      // Increment — wrap to 0 and assert overflow on max→0 transition
      MODE_COUNT_UP: if (counter_reg == {WIDTH{1'b1}}) begin
                       next_count = 0;
                       next_ovf   = 1;
                     end else
                       next_count = counter_reg + 1;

      // Decrement — wrap to max and assert underflow on 0→max transition
      MODE_COUNT_DN: if (counter_reg == 0) begin
                       next_count = {WIDTH{1'b1}};
                       next_unf   = 1;
                     end else
                       next_count = counter_reg - 1;

      // Hold — no change (default already covers this, explicit for clarity)
      MODE_HOLD:     next_count = counter_reg;
    endcase
  end

  //--------------------------------------------------------------------------
  // Sequential logic — register next-state values on clock edge.
  // Asynchronous active-low reset clears all outputs.
  //--------------------------------------------------------------------------
  always_ff @(posedge intf.clk or negedge intf.rst_n) begin
    if (!intf.rst_n) begin
      counter_reg    <= 0;
      intf.overflow  <= 0;
      intf.underflow <= 0;
    end else begin
      counter_reg    <= next_count;
      intf.overflow  <= next_ovf;
      intf.underflow <= next_unf;
    end
  end

  // Drive the count output continuously from the internal register
  assign intf.count = counter_reg;

endmodule
