const std = @import("std");

const avr = @import("atmega328p.zig");

pub const Writer = std.io.Writer(void, error{}, write);

pub fn init(comptime baud: comptime_int) void {
    avr.UBRR0.write(.{ .USART = (avr.F_CPU + 4 * baud) / (8 * baud) - 1 });

    avr.UCSR0A.modify(.{ .U2X0 = 1 });
    avr.UCSR0B.modify(.{ .TXEN0 = 1, .RXEN0 = 1 });
    avr.UCSR0C.modify(.{ .UCSZ0 = 0b11 });
}

fn put_char(char: u8) void {
    while (avr.UCSR0A.read().UDRE0 == 0) {}
    avr.UDR0.write(.{ .TXB = char });
}

fn write(context: void, bytes: []const u8) error{}!usize {
    for (bytes) |char|
        put_char(char);
    return bytes.len;
}
