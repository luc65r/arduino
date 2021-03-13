const std = @import("std");
const Builder = std.build.Builder;

const device_path = "/dev/ttyACM0";

pub fn build(b: *Builder) !void {
    const target = try std.zig.CrossTarget.parse(.{
        .arch_os_abi = "avr-freestanding-none",
        .cpu_features = "atmega328p",
    });
    const mode = .ReleaseSmall;

    const libgcc = b.addObject("libgcc", null);
    libgcc.addCSourceFile("src/libgcc.S", &[_][]const u8{"-mmcu=avr5"});
    libgcc.setTarget(target);
    libgcc.setBuildMode(mode);
    libgcc.strip = true;

    const exe = b.addExecutable("main", "src/start.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.setOutputDir(".");
    exe.strip = true;
    exe.single_threaded = true;
    exe.bundle_compiler_rt = false;
    exe.setLinkerScriptPath("src/linker.ld");
    exe.addObject(libgcc);
    exe.install();

    const bin_path = b.getInstallPath(exe.install_step.?.dest_dir, exe.out_filename);

    const objdump = b.addSystemCommand(&[_][]const u8{
        "avr-objdump",
        "-D",
        bin_path,
    });
    objdump.step.dependOn(&exe.install_step.?.step);

    const objdump_step = b.step("objdump", "Show disassembly of the code");
    objdump_step.dependOn(&objdump.step);

    const upload = b.addSystemCommand(&[_][]const u8{
        "sudo",
        "avrdude",
        "-p",
        "atmega328p",
        "-c",
        "arduino",
        "-P",
        device_path,
        "-D",
        "-U",
        try std.mem.concat(b.allocator, u8, &[_][]const u8{
            "flash:w:",
            bin_path,
            ":e",
        }),
    });
    upload.step.dependOn(&exe.install_step.?.step);

    const upload_step = b.step("upload", "Upload to Arduino");
    upload_step.dependOn(&upload.step);

    const setup_tty = b.addSystemCommand(&[_][]const u8{
        "sudo",
        "stty",
        "-F",
        device_path,
        "9600",
        "raw",
        "-clocal",
        "-echo",
        "icrnl",
    });
    setup_tty.step.dependOn(&upload.step);

    const watch_serial = b.addSystemCommand(&[_][]const u8{
        "sudo",
        "cat",
        device_path,
    });
    watch_serial.step.dependOn(&setup_tty.step);

    const serial_step = b.step("serial", "Watch serial output");
    serial_step.dependOn(&watch_serial.step);

    b.default_step.dependOn(&exe.step);
}
