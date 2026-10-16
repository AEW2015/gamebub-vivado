package memory_test_pkg;
  typedef enum logic [3:0] {
    PAT_ZERO       = 4'd0,
    PAT_ONES       = 4'd1,
    PAT_AAAA       = 4'd2,
    PAT_5555       = 4'd3,
    PAT_WALK_ONE   = 4'd4,
    PAT_WALK_ZERO  = 4'd5,
    PAT_ADDRESS    = 4'd6,
    PAT_INV_ADDR   = 4'd7,
    PAT_PRBS       = 4'd8
  } pattern_t;

  function automatic logic [15:0] lfsr16_next(input logic [15:0] value);
    lfsr16_next = {value[14:0], value[15] ^ value[13] ^ value[12] ^ value[10]};
  endfunction

  function automatic logic [15:0] pattern_word(
    input logic [3:0] pattern,
    input logic [24:0] address,
    input logic [15:0] prbs
  );
    case (pattern)
      PAT_ZERO:      pattern_word = 16'h0000;
      PAT_ONES:      pattern_word = 16'hffff;
      PAT_AAAA:      pattern_word = 16'haaaa;
      PAT_5555:      pattern_word = 16'h5555;
      PAT_WALK_ONE:  pattern_word = 16'h0001 << address[3:0];
      PAT_WALK_ZERO: pattern_word = ~(16'h0001 << address[3:0]);
      PAT_ADDRESS:   pattern_word = address[15:0] ^ {7'h0, address[24:16]};
      PAT_INV_ADDR:  pattern_word = ~(address[15:0] ^ {7'h0, address[24:16]});
      default:       pattern_word = prbs;
    endcase
  endfunction
endpackage
