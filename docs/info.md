## How it works

This project implements the RC4 stream cipher in Verilog.

The design performs RC4 key scheduling and generates a pseudorandom
keystream. The keystream is XORed with an input plaintext byte to produce
an encrypted output byte.

The RC4 design uses a 50 MHz clock and is controlled through the
TinyTapeout input and output pins.

The `ui_in` pins provide the 8-bit data bus. The lower three
`uio_in` pins select the command:

| Command | Value | Function |
|---|---:|---|
| Idle | `000` | No operation |
| Set key length | `001` | Sets the key length using `ui_in` |
| Start | `010` | Starts RC4 initialization |
| Stop | `011` | Resets/stops the RC4 operation |
| Load plaintext | `100` | Loads one plaintext byte from `ui_in` |
| Next | `101` | Requests the next encrypted byte |

After the start command, the design initializes the S-array. The key bytes
are then streamed through `ui_in`, one byte per clock cycle. The encrypted
result appears on the 8-bit `uo_out` output.

## How to test

The included Cocotb test performs the following steps:

1. Resets the design.
2. Sets the key length to 3 bytes.
3. Loads the key `"Key"`.
4. Loads the plaintext byte `"P"`.
5. Requests one encrypted byte.
6. Checks that the output is `0xBB`.

The simulation can be run with:

```bash
cd test
make
```

The test should finish with:

```text
TESTS=1 PASS=1 FAIL=0
```

## External hardware

No external hardware is required. The design can be tested using the
TinyTapeout demo board and its standard clock, reset, input, and output
connections.
