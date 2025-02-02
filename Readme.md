# CircBuf+

**CircBuf+** is a feature-rich, high-performance ring (circular) buffer library written in Zig. It is designed for modern applications that require:

- **High Performance:** Optimizations like bitmask index wrapping when the capacity is a power of two.
- **Concurrency Support:** Optional thread safety using atomic operations for use in multi-threaded contexts.
- **Flexible Behavior on Full Buffers:** Choose between returning a buffer full error or overwriting the oldest element.

Whether you’re building real‑time systems, event queues, streaming data processors, or embedded applications, CircBuf+ is designed to be both fast and versatile.

## Features

- **Generic & Configurable:**
  Write once and use with any element type. Control behavior via compile‑time parameters:
  - `threadSafe`: Enables atomic operations for head/tail pointers.
  - `overwriteOnFull`: Determines if a push to a full buffer overwrites the oldest element.

- **Optimized Index Wrapping:**
  When capacity is a power of two, CircBuf+ uses bitmasking instead of modulo operations for very fast index wrapping.

- **Comprehensive API:**
  Provides a rich set of operations including:
  - `push()`: Insert an element into the buffer.
  - `pop()`: Remove and return the oldest element.
  - `peek()`: Check the next element without removing it.
  - `clear()`: Reset the buffer.
  - `isEmpty()` and `isFull()`: Status queries.
  - `len()`: Number of stored elements.
  - Iteration support via an in‑built iterator.

- **Error Handling:**
  Uses custom error types (`BufferFull`, `BufferEmpty`, `InvalidCapacity`) to make error management clear and idiomatic.

## When to Use CircBuf+

Use CircBuf+ when you need:
- A fixed-size buffer for streaming data that cycles once full.
- A high-performance queue for producer-consumer patterns.
- A robust component in embedded systems or real‑time applications.
- Optional thread safety for concurrent access without sacrificing performance.

## Installation

To include CircBuf+ in your Zig project:

1. **Add zcsv as a dependency in your build.zig.zon:**

   ```bash
   zig fetch --save git+https://github.com/chrischtel/CircBuf+#main

2. **Update Your Build Script:**
   Modify your `build.zig` to import the library. For example:

   ```zig
   const circbuf = b.dependency("CircBuf+", .{
       .target = target,
       .optimize = optimize,
   });

   exe.root_module.addImport("CircBuf+", zcsv.module("CircBuf+"));
   ´´´
