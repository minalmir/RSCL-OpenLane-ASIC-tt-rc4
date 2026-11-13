`default_nettype none

module tt_um_minalmir_rc4 (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // Commands placed on uio_in[2:0]
    localparam [2:0]
        CMD_IDLE       = 3'b000,
        CMD_SET_KEYLEN = 3'b001,
        CMD_START      = 3'b010,
        CMD_STOP       = 3'b011,
        CMD_LOAD_PLAIN = 3'b100,
        CMD_NEXT       = 3'b101;

    reg [7:0] key_length_reg;
    reg [7:0] plaintext_reg;
    reg       start_pulse;
    reg       stop_pulse;
    reg       next_pending;

    wire       rc4_start_key_cpy;
    wire       rc4_busy;
    wire       rc4_read_plaintext;
    wire [7:0] rc4_enc_byte;

    // The key byte is streamed directly through ui_in.
    wire [7:0] rc4_key_byte = ui_in;

    // Hold the RC4 core until a new plaintext byte is requested.
    wire rc4_hold = !next_pending;

    always @(posedge clk) begin
        if (!rst_n) begin
            key_length_reg <= 8'd16;
            plaintext_reg  <= 8'd0;
            start_pulse    <= 1'b0;
            stop_pulse     <= 1'b0;
            next_pending   <= 1'b0;
        end
        else begin
            start_pulse <= 1'b0;
            stop_pulse  <= 1'b0;

            case (uio_in[2:0])
                CMD_SET_KEYLEN: begin
                    key_length_reg <= ui_in;
                end

                CMD_START: begin
                    start_pulse <= 1'b1;
                end

                CMD_STOP: begin
                    stop_pulse <= 1'b1;
                end

                CMD_LOAD_PLAIN: begin
                    plaintext_reg <= ui_in;
                end

                CMD_NEXT: begin
                    next_pending <= 1'b1;
                end

                default: begin
                end
            endcase

            // Stop after one plaintext byte has been produced.
            if (rc4_read_plaintext)
                next_pending <= 1'b0;
        end
    end

    rc4_v5 rc4_core (
        .CLK_IN             (clk),
        .RESET_N_IN         (rst_n),
        .KEY_SIZE_IN        (key_length_reg),
        .KEY_BYTE_IN        (rc4_key_byte),
        .PLAIN_BYTE_IN      (plaintext_reg),
        .START_IN           (start_pulse),
        .STOP_IN            (stop_pulse),
        .HOLD_IN            (rc4_hold),
        .START_KEY_CPY_OUT  (rc4_start_key_cpy),
        .BUSY_OUT           (rc4_busy),
        .READ_PLAINTEXT_OUT (rc4_read_plaintext),
        .ENC_BYTE_OUT       (rc4_enc_byte)
    );

    // Encrypted byte output.
    assign uo_out = rc4_enc_byte;

    // Status signals are assigned internally but the bidirectional pins
    // remain inputs for this design.
    assign uio_out = {
        5'b00000,
        rc4_read_plaintext,
        rc4_start_key_cpy,
        rc4_busy
    };

    assign uio_oe = 8'b00000000;

    // Prevent unused-input warnings.
    wire _unused = &{ena, uio_in[7:3], 1'b0};

endmodule
