const DDRB = @intToPtr(*volatile u8, 0x24);
const PORTB = @intToPtr(*volatile u8, 0x25);

export fn main() noreturn {
    DDRB.* |= 1 << 5;
    while (true) {
        PORTB.* &= ~(@as(u8, 1 << 5));
        var i: u32 = 0;
        while (i < 500000) {
            asm volatile ("nop");
            i += 1;
        }

        PORTB.* |= 1 << 5;
        i = 0;
        while (i < 500000) {
            asm volatile ("nop");
            i += 1;
        }
    }
}
