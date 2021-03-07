const std = @import("std");

const CPU_CLOCK = 16_000_000; // in Hz
const BAUD = 9600;

const DDRB = @intToPtr(*volatile u8, 0x24);
const PORTB = @intToPtr(*volatile u8, 0x25);

const UBRR0L = @intToPtr(*volatile u8, 0xC4);
const UBRR0H = @intToPtr(*volatile u8, 0xC5);

const UCSR0A = @intToPtr(*volatile u8, 0xC0);
const UCSR0B = @intToPtr(*volatile u8, 0xC1);
const UCSR0C = @intToPtr(*volatile u8, 0xC2);

const UDR0 = @intToPtr(*volatile u8, 0xC6);

const Writer = std.io.Writer(void, error{}, write_serial);
const serial: Writer = .{ .context = undefined };

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
    uart_init();
    DDRB.* |= 1 << 5;
    try serial.print("Hello, world!\n", .{});
    var i: usize = 0;
    while (true) {
        PORTB.* &= ~(@as(u8, 1 << 5));
        delay(1000);

        try serial.print("Test {}\n", .{i});

        PORTB.* |= 1 << 5;
        delay(1000);

        i += 1;
    }
}

fn uart_init() void {
    const UBBR_VALUE = (CPU_CLOCK + 4 * BAUD) / (8 * BAUD) - 1;
    UBRR0H.* = UBBR_VALUE >> 8;
    UBRR0L.* = UBBR_VALUE & 0xFF;

    UCSR0A.* |= 1 << 1;
    UCSR0B.* = 1 << 3 | 1 << 4;
    UCSR0C.* = 1 << 1 | 1 << 2;
}

fn put_char(char: u8) void {
    while (UCSR0A.* >> 5 & 1 == 0) {}
    UDR0.* = char;
}

fn write_serial(context: void, bytes: []const u8) error{}!usize {
    for (bytes) |char|
        put_char(char);
    return bytes.len;
}
