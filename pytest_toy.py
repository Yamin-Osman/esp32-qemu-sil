import pytest


def wait_for_boot(dut):
    dut.expect_exact('ready', timeout=30)


@pytest.mark.parametrize('inp, expected', [
    ('IN 1', 'OUT 0'),
    ('IN 0', 'OUT 1'),
])
def test_inverter(dut, inp, expected):
    wait_for_boot(dut)
    dut.write(inp + '\n')
    dut.expect_exact(expected, timeout=5)


def test_bad_input_is_rejected(dut):
    wait_for_boot(dut)
    dut.write('hello\n')
    dut.expect_exact('ERROR BAD INPUT', timeout=5)
