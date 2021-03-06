const std = @import("std");
const Builder = std.build.Builder;

const device_path = "/dev/ttyACM0";

const object_file = "main.o";
const elf_file = "main.elf";
const hex_file = "main.hex";

pub fn build(b: *Builder) !void {
    const target = try std.zig.CrossTarget.parse(.{
        .arch_os_abi = "avr-freestanding-none",
        .cpu_features = "atmega328p",
    });
    const mode = .ReleaseSmall;

    const build_obj = b.addObject("main", "src/main.zig");
    build_obj.setTarget(target);
    build_obj.setBuildMode(mode);
    build_obj.setOutputDir(".");

    const link = b.addSystemCommand(&[_][]const u8{
        "avr-ld",
        "-o", elf_file,
        object_file,
    });
    link.step.dependOn(&build_obj.step);

    const strip = b.addSystemCommand(&[_][]const u8{
        "avr-objcopy",
        "-j", ".text",
        "-j", ".data",
        "-O", "ihex",
        elf_file,
        hex_file,
    });
    strip.step.dependOn(&link.step);

    const upload = b.addSystemCommand(&[_][]const u8{
        "avrdude",
        "-p", "atmega328p",
        "-c", "arduino",
        "-P", device_path,
        "-D",
        "-U", "flash:w:" ++ hex_file ++ ":i",
    });
    upload.step.dependOn(&strip.step);

    const upload_step = b.step("upload", "Upload to Arduino");
    upload_step.dependOn(&upload.step);

    b.default_step.dependOn(&strip.step);
}
