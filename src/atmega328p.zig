const std = @import("std");
const assert = std.debug.assert;

pub const F_CPU = 16_000_000; // in Hz

pub const PINB = MMIO(0x23, u8, packed struct {
    PINB0: u1,
    PINB1: u1,
    PINB2: u1,
    PINB3: u1,
    PINB4: u1,
    PINB5: u1,
    PINB6: u1,
    PINB7: u1,
});
pub const DDRB = MMIO(0x24, u8, packed struct {
    DDB0: u1 = 0,
    DDB1: u1 = 0,
    DDB2: u1 = 0,
    DDB3: u1 = 0,
    DDB4: u1 = 0,
    DDB5: u1 = 0,
    DDB6: u1 = 0,
    DDB7: u1 = 0,
});
pub const PORTB = MMIO(0x25, u8, packed struct {
    PORTB0: u1 = 0,
    PORTB1: u1 = 0,
    PORTB2: u1 = 0,
    PORTB3: u1 = 0,
    PORTB4: u1 = 0,
    PORTB5: u1 = 0,
    PORTB6: u1 = 0,
    PORTB7: u1 = 0,
});

pub const UCSR0A = MMIO(0xC0, u8, packed struct {
    MPCM0: u1 = 0,
    U2X0: u1 = 0,
    UPE0: u1 = 0,
    DOR0: u1 = 0,
    FE0: u1 = 0,
    UDRE0: u1 = 1,
    TXC0: u1 = 0,
    RXC0: u1 = 0,
});

pub const UCSR0B = MMIO(0xC1, u8, packed struct {
    TXB80: u1 = 0,
    RXB80: u1 = 0,
    UCSZ02: u1 = 0,
    TXEN0: u1 = 0,
    RXEN0: u1 = 0,
    UDRIE0: u1 = 0,
    TXCIE0: u1 = 0,
    RXCIE0: u1 = 0,
});

pub const UCSR0C = MMIO(0xC2, u8, packed struct {
    UCPOL0: u1 = 0,
    UCSZ0: u2 = 0b11,
    USBS0: u1 = 0,
    UPM0: u2 = 0,
    UMSEL0: u2 = 0,
});

pub const UBRR0 = MMIO(0xC4, u16, packed struct {
    USART: u12 = 0,
    reserved: u4 = 0,
});

pub const UDR0 = MMIO(0xC6, u8, packed union {
    RXB: u8,
    TXB: u8,
});

pub fn sei() callconv(.Inline) void {
    asm volatile ("sei" ::: "memory");
}

pub fn cei() callconv(.Inline) void {
    asm volatile ("cei" ::: "memory");
}

fn MMIO(comptime addr: usize, comptime Int: type, comptime Packed: type) type {
    comptime {
        assert(@bitSizeOf(Int) == @bitSizeOf(Packed));
    }
    return struct {
        const Self = @This();

        pub fn ptr() *volatile Int {
            return @intToPtr(*volatile Int, addr);
        }

        pub fn read() Packed {
            const val = ptr().*;
            return @bitCast(Packed, val);
        }

        pub fn write(val: Packed) void {
            ptr().* = @bitCast(Int, val);
        }

        pub fn modify(new_val: anytype) void {
            const fields = @typeInfo(@TypeOf(new_val)).Struct.fields;
            if (fields.len == 1) {
                const field = fields[0];
                @field(@ptrCast(*volatile Packed, Self.ptr()), field.name) = @field(new_val, field.name);
            } else {
                var old_val = Self.read();
                inline for (fields) |field| {
                    @field(old_val, field.name) = @field(new_val, field.name);
                }
                Self.write(old_val);
            }
        }
    };
}

pub fn delay(ms: u32) void {
    // const cycles = 4; // Number of cycles per iteration
    // var i = @floatToInt(u32, @intToFloat(f32, ms) / 1000.0 / (cycles * 256.0 / @as(f32, F_CPU)));
    var i: u32 = ms << 4;
    while (i > 0) {
        var c: u8 = 255;
        // We decrement c to 0.
        // This takes cycles * 256 / F_CPU miliseconds.
        asm volatile (
            \\1:
            \\    dec %[c]
            \\    nop
            \\    brne 1b
            :
            : [c] "r" (c)
        );

        i -= 1;
    }
}
