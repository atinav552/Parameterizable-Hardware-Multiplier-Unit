// ============================================================
// Parameterizable Hardware Multiplier (Sequential Shift-and-Add)
// ============================================================

module seq_multiplier #(
    parameter WIDTH = 16,
    parameter COUNT_WIDTH = 5 // Log2(WIDTH) + 1
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 start,
    input  wire [WIDTH-1:0]     a,
    input  wire [WIDTH-1:0]     b,
    
    output wire [(2*WIDTH)-1:0] product,
    output wire                 done,
    output wire                 busy
);

    // FSM State Encoding
    localparam IDLE = 2'd0;
    localparam CALC = 2'd1;
    localparam FIN  = 2'd2;

    reg [1:0]             state;
    reg [(2*WIDTH)-1:0]   acc;
    reg [WIDTH-1:0]       a_reg;
    reg [(2*WIDTH)-1:0]   b_shifted;
    reg [COUNT_WIDTH-1:0] cnt;
    
    // Anti-Race Condition Register
    reg [WIDTH-1:0]       saved_a;

    // -------------------------------------------------------------------------
    // Sequential Logic & FSM
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            acc       <= 0;
            a_reg     <= 0;
            b_shifted <= 0;
            cnt       <= 0;
            saved_a   <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        saved_a   <= a; // Lock in the current test case operand
                        acc       <= 0;
                        a_reg     <= a;
                        b_shifted <= {{WIDTH{1'b0}}, b}; // Zero-extend B
                        cnt       <= 0;
                        state     <= CALC;
                    end
                end

                CALC: begin
                    // 1. Accumulate if the LSB of the multiplier is 1
                    if (a_reg[0]) begin
                        acc <= acc + b_shifted;
                    end
                    
                    // 2. Shift operands
                    a_reg     <= a_reg >> 1;
                    b_shifted <= b_shifted << 1;
                    cnt       <= cnt + 1'b1;

                    // 3. Loop Check
                    if (cnt == (WIDTH - 1)) begin
                        state <= FIN;
                    end
                end

                FIN: begin
                    // Support back-to-back operations without dropping to IDLE
                    if (start) begin
                        saved_a   <= a;
                        acc       <= 0;
                        a_reg     <= a;
                        b_shifted <= {{WIDTH{1'b0}}, b};
                        cnt       <= 0;
                        state     <= CALC;
                    end else begin
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end

    // -------------------------------------------------------------------------
    // Output Routing
    // -------------------------------------------------------------------------
    assign product = acc;
    assign busy    = (state == CALC);
    
    // Combinationally drop 'done' the instant the testbench changes the 
    // input for the next testcase, forcing wait() to block properly.
    assign done    = (state == FIN) && (a == saved_a);

endmodule