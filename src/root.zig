// advanced_ringbuffer.zig
// A feature-rich, high-performance ring (circular) buffer library.
//
// This library provides a configurable ring buffer implementation that is
// generic over the element type and allows the following compile-time features:
//   - threadSafe: When true, head and tail indexes use atomic operations.
//   - overwriteOnFull: When true, a push() on a full buffer overwrites the oldest element.
// Additionally, if the capacity provided is a power of two, a bitmask is used for
// fast index wrapping, minimizing runtime overhead.

const std = @import("std");

/// AdvancedRingBuffer is a generic ring buffer.
///
/// It is parameterized by:
///   - T: the element type.
///   - threadSafe: if true, head/tail indexes are maintained with atomic operations.
///   - overwriteOnFull: if true, a push() on a full buffer will overwrite the oldest element.
pub fn AdvancedRingBuffer(
    comptime T: type,
    comptime threadSafe: bool,
    comptime overwriteOnFull: bool,
) type {
    return struct {
        pub const Self = @This();

        /// Errors that may occur during buffer operations.
        pub const Error = error{ BufferFull, BufferEmpty, InvalidCapacity };

        /// Iterator type to traverse the elements in the buffer.
        pub const Iterator = struct {
            buffer: *Self,
            index: usize,
            remaining: usize,
            /// Initializes an iterator starting at the current tail.
            pub fn init(buffer: *Self) Iterator {
                return Iterator{
                    .buffer = buffer,
                    .index = buffer.loadTail(),
                    .remaining = buffer.len(),
                };
            }
            /// Returns the next element or null when done.
            pub fn next(self: *Iterator) ?T {
                if (self.remaining == 0) return null;
                const value = self.buffer.data[self.index];
                self.index = self.buffer.advance(self.index);
                self.remaining -= 1;
                return value;
            }
        };

        allocator: *std.mem.Allocator,
        capacity: usize,
        data: []T,
        head: if (threadSafe) std.atomic.AtomicUsize else usize,
        tail: if (threadSafe) std.atomic.AtomicUsize else usize,
        /// If capacity is a power of two, this holds (capacity - 1) to be used as a bitmask.
        mask: ?usize,

        /// Advance an index by 1, using a bitmask if applicable.
        fn advance(self: *Self, index: usize) usize {
            if (self.mask) |mask| {
                return (index + 1) & mask;
            } else {
                return (index + 1) % self.capacity;
            }
        }

        /// Loads the current head index, using atomics if threadSafe.
        fn loadHead(self: *Self) usize {
            if (threadSafe) {
                return std.atomic.load(&self.head, .SeqCst);
            } else {
                return self.head;
            }
        }

        /// Stores the head index, using atomics if threadSafe.
        fn storeHead(self: *Self, value: usize) void {
            if (threadSafe) {
                std.atomic.store(&self.head, value, .SeqCst);
            } else {
                self.head = value;
            }
        }

        /// Loads the current tail index, using atomics if threadSafe.
        fn loadTail(self: *Self) usize {
            if (threadSafe) {
                return std.atomic.load(&self.tail, .SeqCst);
            } else {
                return self.tail;
            }
        }

        /// Stores the tail index, using atomics if threadSafe.
        fn storeTail(self: *Self, value: usize) void {
            if (threadSafe) {
                std.atomic.store(&self.tail, value, .SeqCst);
            } else {
                self.tail = value;
            }
        }

        /// Initialize the ring buffer with a given capacity.
        /// Returns an error if the capacity is zero.
        pub fn init(
            allocator: *std.mem.Allocator,
            capacity: usize,
        ) !Self {
            if (capacity == 0) return Error.InvalidCapacity;
            const buffer = try allocator.alloc(T, capacity);
            return Self{
                .allocator = allocator,
                .capacity = capacity,
                .data = buffer,
                .head = if (threadSafe) std.atomic.AtomicUsize.init(0) else 0,
                .tail = if (threadSafe) std.atomic.AtomicUsize.init(0) else 0,
                .mask = if (std.math.isPowerOfTwo(capacity)) capacity - 1 else null,
            };
        }

        /// Deinitialize the ring buffer and free its memory.
        pub fn deinit(self: *Self) void {
            self.allocator.free(self.data);
        }

        /// Push a value into the ring buffer.
        ///
        /// In non-overwrite mode, if the buffer is full, this returns Error.BufferFull.
        /// In overwrite mode, it will drop the oldest element to make space.
        pub fn push(self: *Self, value: T) !void {
            const head = self.loadHead();
            var tail = self.loadTail();
            const next = self.advance(head);

            if (next == tail) {
                // Buffer is full.
                if (!overwriteOnFull) {
                    return Error.BufferFull;
                } else {
                    // Overwrite mode: advance tail to "drop" the oldest element.
                    tail = self.advance(tail);
                    self.storeTail(tail);
                }
            }
            self.data[head] = value;
            self.storeHead(next);
        }

        /// Pop and return the oldest element in the buffer.
        pub fn pop(self: *Self) !T {
            const tail = self.loadTail();
            const head = self.loadHead();
            if (tail == head) {
                return Error.BufferEmpty;
            }
            const result = self.data[tail];
            self.storeTail(self.advance(tail));
            return result;
        }

        /// Peek at the next element to be popped without removing it.
        pub fn peek(self: *Self) !T {
            const tail = self.loadTail();
            const head = self.loadHead();
            if (tail == head) {
                return Error.BufferEmpty;
            }
            return self.data[tail];
        }

        /// Clear the buffer (reset head and tail positions).
        pub fn clear(self: *Self) void {
            self.storeHead(0);
            self.storeTail(0);
        }

        /// Returns true if the buffer is empty.
        pub fn isEmpty(self: *Self) bool {
            return self.loadHead() == self.loadTail();
        }

        /// Returns true if the buffer is full.
        pub fn isFull(self: *Self) bool {
            const next = self.advance(self.loadHead());
            return next == self.loadTail();
        }

        /// Returns the number of elements currently in the buffer.
        pub fn len(self: *Self) usize {
            const head = self.loadHead();
            const tail = self.loadTail();
            if (head >= tail) {
                return head - tail;
            } else {
                return self.capacity - (tail - head);
            }
        }

        /// Obtain an iterator to traverse the current elements in the buffer.
        pub fn iterator(self: *Self) Iterator {
            return Iterator.init(self);
        }
    };
}
