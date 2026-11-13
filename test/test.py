import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge

CMD_IDLE = 0
CMD_SET_KEYLEN = 1
CMD_START = 2
CMD_STOP = 3
CMD_LOAD_PLAIN = 4
CMD_NEXT = 5


async def command(dut, cmd, data=0):
    dut.ui_in.value = data
    dut.uio_in.value = cmd
    await RisingEdge(dut.clk)
    dut.uio_in.value = CMD_IDLE


@cocotb.test()
async def test_project(dut):
    dut._log.info("Starting RC4 TinyTapeout test")

    cocotb.start_soon(Clock(dut.clk, 10, unit="us").start())

    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = CMD_IDLE
    dut.rst_n.value = 0

    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    # RC4 key: "Key"
    key = [0x4B, 0x65, 0x79]

    # Tell the wrapper the key length.
    await command(dut, CMD_SET_KEYLEN, 3)

    # Start RC4 initialization.
    await command(dut, CMD_START)

    # Wait for the 256-cycle S-array initialization.
    await ClockCycles(dut.clk, 258)

    # Stream the key bytes into the RC4 core.
    for key_byte in key:
        dut.ui_in.value = key_byte
        await RisingEdge(dut.clk)

    # Plaintext: "P"
    await command(dut, CMD_LOAD_PLAIN, 0x50)

    # Request one encrypted byte.
    await command(dut, CMD_NEXT)

    # Wait for KSA and PRGA to finish.
    await ClockCycles(dut.clk, 2300)

    result = int(dut.uo_out.value)
    dut._log.info(f"Encrypted output: 0x{result:02X}")

    # First RC4 byte for key "Key" and plaintext "P" is 0xEB.
    assert result == 0xBB, f"Expected 0xBB, got 0x{result:02X}"
