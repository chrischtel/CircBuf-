# CircBuf+

**CircBuf+** is a feature-rich, high-performance ring (circular) buffer library for Zig. It’s designed for modern applications that demand:

- **High Performance:**
  Benefit from optimizations like bitmask index wrapping (when capacity is a power of two).

- **Concurrency Support:**
  Enable optional thread safety using atomic operations, ideal for multi-threaded contexts.

- **Flexible Full-Buffer Handling:**
  Choose between returning a "buffer full" error or automatically overwriting the oldest element.

Whether you’re building real-time systems, event queues, streaming data processors, or embedded applications, **CircBuf+** is crafted to be both fast and versatile.

## Features

- **Generic & Configurable:**
  Use with any element type. Control behavior via compile-time parameters:
  - `threadSafe`: Enables atomic operations for head/tail pointers.
  - `overwriteOnFull`: Determines whether `push()` overwrites the oldest element when full.

- **Optimized Index Wrapping:**
  For power-of-two capacities, bitmasking replaces modulo operations for ultra-fast index wrapping.

- **Comprehensive API:**
  A robust set of operations including:
  - `push()`: Insert an element.
  - `pop()`: Remove and return the oldest element.
  - `peek()`: View the next element without removing it.
  - `clear()`: Reset the buffer.
  - Status queries: `isEmpty()`, `isFull()`, `len()`.
  - Built-in iterator for traversing elements.

- **Robust Error Handling:**
  Custom error types (`BufferFull`, `BufferEmpty`, `InvalidCapacity`) ensure idiomatic and clear error management.

## When to Use CircBuf+

Use **CircBuf+** when you need:
- A fixed-size buffer for cycling streaming data.
- A high-performance, low-latency queue (ideal for producer-consumer patterns).
- A robust building block in embedded or real-time applications.
- Optional thread safety for concurrent operations without compromising speed.

## Installation

### Using Zig Fetch

1. **Add CircBuf+ as a Dependency:**

   ```bash
   zig fetch --save git+https://github.com/chrischtel/CircBuf+#main
   ```

2. **Update Your Build Script:**

   In your `build.zig` file, import the dependency:

   ```zig
   const Builder = @import("std").build.Builder;

   pub fn build(b: *Builder) void {
       const target = b.standardTargetOptions(.{});
       const optimize = b.standardOptimizeOption(.{});

       // Add CircBuf+ dependency
       const circbuf_dep = b.dependency("CircBuf+", .{
           .target = target,
           .optimize = optimize,
       });

       const exe = b.addExecutable("my_app", "src/main.zig");
       exe.addModule("CircBuf+", circbuf_dep.module("CircBuf+"));
       exe.install();
   }
   ```

## Quick Start

Below is a simple example to get you started using **CircBuf+**:

```zig
const std = @import("std");
const AdvancedRingBuffer = @import("advanced_ringbuffer.zig").AdvancedRingBuffer;

pub fn main() !void {
    // Set up the allocator.
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer gpa.deinit();
    const allocator = gpa.allocator();

    // Create a single-threaded, non-overwriting ring buffer for i32 values.
    const RingBuffer = AdvancedRingBuffer(i32, false, false);
    var rb = try RingBuffer.init(allocator, 8);
    defer rb.deinit();

    // Push values.
    try rb.push(42);
    try rb.push(84);
    std.debug.print("Buffer length after pushes: {}\n", .{rb.len()});

    // Peek at the next value.
    const next_value = try rb.peek();
    std.debug.print("Next value to pop: {}\n", .{next_value});

    // Pop and display values.
    while (!rb.isEmpty()) {
        const value = try rb.pop();
        std.debug.print("Popped value: {}\n", .{value});
    }
}
```

## API Overview

### Initialization & Deinitialization
- **`init(allocator: *std.mem.Allocator, capacity: usize) !Self`**
  Creates a new ring buffer instance. Returns an error if `capacity` is zero.
- **`deinit() void`**
  Frees the allocated buffer memory.

### Core Operations
- **`push(value: T) !void`**
  Inserts an element. If the buffer is full, returns `BufferFull` (unless overwrite mode is enabled).
- **`pop() !T`**
  Removes and returns the oldest element. Returns `BufferEmpty` if the buffer is empty.
- **`peek() !T`**
  Returns the next element to pop without removing it.
- **`clear() void`**
  Resets the buffer by clearing all elements.

### Utility Functions
- **`isEmpty() bool`**
  Checks if the buffer is empty.
- **`isFull() bool`**
  Checks if the buffer is full.
- **`len() usize`**
  Returns the current number of stored elements.
- **`iterator() Iterator`**
  Returns an iterator to traverse the elements.

## Performance & Concurrency Considerations

- **Thread Safety:**
  Set `threadSafe` to `true` to operate with atomic head/tail pointers for multi-threaded access.

- **Overwrite Behavior:**
  With `overwriteOnFull` set to `true`, pushing to a full buffer overwrites the oldest element; otherwise, an error is returned.

- **Optimizations:**
  For capacities that are powers of two, bitmasking is used for efficient index wrapping.

## Roadmap

Planned improvements include:
- Dynamic resizing options.
- More granular concurrency controls (e.g., multi-producer/multi-consumer support).
- Benchmarking and performance metrics.
- Additional API extensions (e.g., batch operations).

## Contributing

Contributions are welcome! To help improve **CircBuf+**:

1. Fork the repository.
2. Create a feature branch.
3. Commit and push your changes.
4. Open a pull request for review.

Please adhere to the existing code style and include tests for new features.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contact

For questions or suggestions, open an issue on GitHub or contact the maintainer at [your.email@example.com](mailto:your.email@example.com).

---

Enjoy using **CircBuf+** and thank you for contributing to the growth of the Zig ecosystem!
