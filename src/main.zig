const CPU_CLOCK = 16_000_000; // in Hz

const DDRB = @intToPtr(*volatile u8, 0x24);
const PORTB = @intToPtr(*volatile u8, 0x25);

fn delay(ms: u32) void {
    const cycles = 3; // Number of cycles per iteration
    var i = @floatToInt(u32, @intToFloat(f32, ms) / 1000.0 / (cycles * 256.0 / @as(f32, CPU_CLOCK)));
    while (i > 0) {
        var c: u8 = 255;
        // We decrement c to 0.
        // This takes cycles * 256 / CPU_CLOCK miliseconds.
        asm volatile (
            \\1:
            \\    dec %[c]
            \\    brne 1b
            :
            : [c] "r" (c)
        );

        i -= 1;
    }
}

export fn main() noreturn {
    DDRB.* |= 1 << 5;
    while (true) {
        PORTB.* &= ~(@as(u8, 1 << 5));
        delay(1000);

        PORTB.* |= 1 << 5;
        delay(1000);
    }
}
