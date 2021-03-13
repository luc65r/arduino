const std = @import("std");

const avr = @import("atmega328p.zig");
const uart = @import("uart.zig");

const serial: uart.Writer = .{ .context = undefined };

pub fn main() void {
    avr.DDRB.modify(.{ .DDB5 = 1 });
    uart.init(9600);
    avr.sei();
    try serial.print("Hello, world!\n", .{});
    var i: usize = 0;
    while (i < 25) : (i += 1) {
        avr.PORTB.modify(.{ .PORTB5 = 0 });
        avr.delay(100);

        try serial.print("Test {}\n", .{i});

        avr.PORTB.modify(.{ .PORTB5 = 1 });
        avr.delay(100);
    }

    @panic("test");
}
