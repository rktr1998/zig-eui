# zig-eui

IEEE EUI-48 and EUI-64.

## Usage

```sh
zig fetch --save git+https://github.com/rktr1998/zig-eui
```

Add the module from the dependency in `build.zig`.

```zig
exe.root_module.addImport("eui", b.dependency("eui", .{}).module("eui"));
```

Import the module in `main.zig`.

```zig
const std = @import("std");
const Eui48 = @import("eui").Eui48;

pub fn main(init: std.process.Init) !void {
    _ = init;

    const eui48: Eui48 = .{
        .bytes = [_]u8{ 0x01, 0x23, 0x45, 0x67, 0x89, 0xAB },
    };

    std.debug.print("EUI-48: {f}\n", .{eui48}); // 01-23-45-67-89-AB
}
```

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
