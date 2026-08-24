module multiplier_tb;

    reg         clk;
    reg         rst_n;
    reg         start;
    reg  [15:0] a;
    reg  [15:0] b;
    
    wire [31:0] product;
    wire        done;
    wire        busy;
    
    integer p, f;

    initial clk = 0;
    always #5 clk = ~clk;

    // Instantiate DUT
    seq_multiplier #(
        .WIDTH(16),
        .COUNT_WIDTH(5)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .a(a),
        .b(b),
        .product(product),
        .done(done),
        .busy(busy)
    );

    // Test verification task
    task check_mult;
        input integer tc_num;
        input [31:0]  exp;
        begin
            // Drive start on negedge to prevent simulator race conditions
            @(negedge clk);
            start = 1; 
            @(negedge clk); 
            start = 0;
            
            wait (done);
            @(negedge clk);
            
            if (product === exp) begin
                p = p + 1;
                $display("PASS: TC%0d | Expected: %0d", tc_num, exp);
            end else begin
                f = f + 1;
                $display("FAIL: TC%0d | Expected: %0d | Got: %0d", tc_num, exp, product);
            end
        end
    endtask

    initial begin
        p = 0; f = 0;
        rst_n = 0; start = 0;
        a = 0; b = 0;
        
        @(posedge clk); @(posedge clk);
        rst_n = 1; @(posedge clk);

        // =========================================================
        // TC1 — Basic Multiplication (3 * 7 = 21)
        // =========================================================
        a = 3;   b = 7;   check_mult(1, 21);

        // =========================================================
        // TC2 — Zero Operand (0 * 255 = 0)
        // =========================================================
        a = 0;   b = 255; check_mult(2, 0);

        // =========================================================
        // TC3 — Maximum Values (255 * 255 = 65025)
        // =========================================================
        a = 255; b = 255; check_mult(3, 65025);

        // =========================================================
        // TC4 — Back-to-Back Operations
        // =========================================================
        a = 5; b = 4;
        @(negedge clk); start = 1; @(negedge clk); start = 0;
        wait (done); 
        
        a = 6; b = 3;
        @(negedge clk); start = 1; @(negedge clk); start = 0;
        wait (done);
        @(negedge clk);
        
        if (product == 18) begin 
            p = p + 1; $display("PASS: TC4 | Back-to-back second result: product=18"); 
        end else begin 
            f = f + 1; $display("FAIL: TC4 | Back-to-back: expected product=18 got %0d", product); 
        end

        // =========================================================
        // TC5 — Power of Two (16 * 4 = 64)
        // =========================================================
        a = 16;  b = 4;   check_mult(5, 64);

        $display("\n=== %0d passed %0d failed ===", p, f);
        $finish;
    end

    // Waveform Dumping
    initial begin
        $dumpfile("mult_waves.vcd");
        $dumpvars(0, multiplier_tb);
    end

endmodule