const main = @import("main.zig");
const vectors = @import("vectors.zig");

const avr = @import("atmega328p.zig");

pub export fn _start() callconv(.Naked) noreturn {
    // At startup the stack pointer is at the end of RAM
    // so, no need to set it manually!

    // Reference this such that the file is analyzed and the vectors
    // are added.
    _ = vectors;

    copy_data_to_ram();
    clear_bss();

    main.main();

    while (true) {}
}

fn copy_data_to_ram() void {
    asm volatile (
        \\  ; load Z register with the address of the data in flash
        \\  ldi r30, lo8(__data_load_start)
        \\  ldi r31, hi8(__data_load_start)
        \\  ; load X register with address of the data in ram
        \\  ldi r26, lo8(__data_start)
        \\  ldi r27, hi8(__data_start)
        \\  ; load address of end of the data in ram
        \\  ldi r24, lo8(__data_end)
        \\  ldi r25, hi8(__data_end)
        \\  rjmp .L2
        \\
        \\.L1:
        \\  lpm r18, Z+ ; copy from Z into r18 and increment Z
        \\  st X+, r18  ; store r18 at location X and increment X
        \\
        \\.L2:
        \\  cp r26, r24
        \\  cpc r27, r25 ; check and branch if we are at the end of data
        \\  brne .L1
    );
    // Probably a good idea to add clobbers here, but compiler doesn't seem to care
}

fn clear_bss() void {
    asm volatile (
        \\  ; load X register with the beginning of bss section
        \\  ldi r26, lo8(__bss_start)
        \\  ldi r27, hi8(__bss_start)
        \\  ; load end of the bss in registers
        \\  ldi r24, lo8(__bss_end)
        \\  ldi r25, hi8(__bss_end)
        \\  ldi r18, 0x00
        \\  rjmp .L4
        \\
        \\.L3:
        \\  st X+, r18
        \\
        \\.L4:
        \\  cp r26, r24
        \\  cpc r27, r25 ; check and branch if we are at the end of bss
        \\  brne .L3
    );
    // Probably a good idea to add clobbers here, but compiler doesn't seem to care
}

pub fn panic(msg: []const u8, error_return_trace: ?*@import("builtin").StackTrace) noreturn {
    avr.DDRB.modify(.{ .DDB5 = 1 });
    while (true) {
        var i: u8 = 0;
        while (i < 3) : (i += 1) {
            avr.PORTB.modify(.{ .PORTB5 = 1 });
            avr.delay(50);
            avr.PORTB.modify(.{ .PORTB5 = 0 });
            avr.delay(50);
        }
        avr.delay(200);
    }
}
