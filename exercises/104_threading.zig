//
// Whenever there is a lot to calculate, the question arises as to how
// tasks can be carried out simultaneously. We have already learned about
// one possibility, namely asynchronous processes, in Exercises 84-91.
//
// However, the computing power of the processor is only distributed to
// the started and running tasks, which always reaches its limits when
// pure computing power is called up.
//
// For example, in blockchains based on proof of work, the miners have
// to find a nonce for a certain character string so that the first m bits
// in the hash of the character string and the nonce are zeros.
// As the miner who can solve the task first receives the reward, everyone
// tries to complete the calculations as quickly as possible.
//
// This is where multithreading comes into play, where tasks are actually
// distributed across several cores of the CPU or GPU, which then really
// means a multiplication of performance.
//
// The following diagram roughly illustrates the difference between the
// various types of process execution.
// The 'Overall Time' column is intended to illustrate how the time is
// affected if, instead of one core as in synchronous and asynchronous
// processing, a second core now helps to complete the work in multithreading.
//
// In the ideal case shown, execution takes only half the time compared
// to the synchronous single thread. And even asynchronous processing
// is only slightly faster in comparison.
//
//
// Synchronous  Asynchronous
// Processing   Processing        Multithreading
// ┌──────────┐ ┌──────────┐  ┌──────────┐ ┌──────────┐
// │ Thread 1 │ │ Thread 1 │  │ Thread 1 │ │ Thread 2 │
// ├──────────┤ ├──────────┤  ├──────────┤ ├──────────┤    Overall Time
// └──┼┼┼┼┼───┴─┴──┼┼┼┼┼───┴──┴──┼┼┼┼┼───┴─┴──┼┼┼┼┼───┴──┬───────┬───────┬──
//    ├───┤        ├───┤         ├───┤        ├───┤      │       │       │
//    │ T │        │ T │         │ T │        │ T │      │       │       │
//    │ a │        │ a │         │ a │        │ a │      │       │       │
//    │ s │        │ s │         │ s │        │ s │      │       │       │
//    │ k │        │ k │         │ k │        │ k │      │       │       │
//    │   │        │   │         │   │        │   │      │       │       │
//    │ 1 │        │ 1 │         │ 1 │        │ 3 │      │       │       │
//    └─┬─┘        └─┬─┘         └─┬─┘        └─┬─┘      │       │       │
//      │            │             │            │      5 Sec     │       │
// ┌────┴───┐      ┌─┴─┐         ┌─┴─┐        ┌─┴─┐      │       │       │
// │Blocking│      │ T │         │ T │        │ T │      │       │       │
// └────┬───┘      │ a │         │ a │        │ a │      │       │       │
//      │          │ s │         │ s │        │ s │      │     8 Sec     │
//    ┌─┴─┐        │ k │         │ k │        │ k │      │       │       │
//    │ T │        │   │         │   │        │   │      │       │       │
//    │ a │        │ 2 │         │ 2 │        │ 4 │      │       │       │
//    │ s │        └─┬─┘         ├───┤        ├───┤      │       │       │
//    │ k │          │           │┼┼┼│        │┼┼┼│      ▼       │    10 Sec
//    │   │        ┌─┴─┐         └───┴────────┴───┴─────────     │       │
//    │ 1 │        │ T │                                         │       │
//    └─┬─┘        │ a │                                         │       │
//      │          │ s │                                         │       │
//    ┌─┴─┐        │ k │                                         │       │
//    │ T │        │   │                                         │       │
//    │ a │        │ 1 │                                         │       │
//    │ s │        ├───┤                                         │       │
//    │ k │        │┼┼┼│                                         ▼       │
//    │   │        └───┴────────────────────────────────────────────     │
//    │ 2 │                                                              │
//    ├───┤                                                              │
//    │┼┼┼│                                                              ▼
//    └───┴────────────────────────────────────────────────────────────────
//
//
// The diagram was modeled on the one in a blog in which the differences
// between asynchronous processing and multithreading are explained in detail:
// https://blog.devgenius.io/multi-threading-vs-asynchronous-programming-what-is-the-difference-3ebfe1179a5
//
// Our exercise is essentially about clarifying the approach in Zig and
// therefore we try to keep it as simple as possible.
// Multithreading in itself is already difficult enough. ;-)
//
const std = @import("std");

pub fn main() !void {
    // This is where the preparatory work takes place
    // before the parallel processing begins.
    std.debug.print("Starting work...\n", .{});

    // These curly brackets are very important, they are necessary
    // to enclose the area where the threads are called.
    // Without these brackets, the program would not wait for the
    // end of the threads and they would continue to run beyond the
    // end of the program.
    {
        // Now we start the first thread, with the number as parameter
        const handle = try std.Thread.spawn(.{}, thread_function, .{1});

        // Waits for the thread to complete,
        // then deallocates any resources created on `spawn()`.
        defer handle.join();

        // Second thread
        const handle2 = try std.Thread.spawn(.{}, thread_function, .{2});
        defer handle2.join();

        // Third thread
        const handle3 = try std.Thread.spawn(.{}, thread_function, .{3});
        defer handle3.join; // <-- something is missing

        // After the threads have been started,
        // they run in parallel and we can still do some work in between.
        std.Thread.sleep(1500 * std.time.ns_per_ms);
        std.debug.print("Some weird stuff, after starting the threads.\n", .{});
    }
    // After we have left the closed area, we wait until
    // the threads have run through, if this has not yet been the case.
    std.debug.print("Zig is cool!\n", .{});
}

// This function is started with every thread that we set up.
// In our example, we pass the number of the thread as a parameter.
fn thread_function(num: usize) !void {
    std.Thread.sleep(200 * num * std.time.ns_per_ms);
    std.debug.print("thread {d}: {s}\n", .{ num, "started." });

    // This timer simulates the work of the thread.
    const work_time = 3 * ((5 - num % 3) - 2);
    std.Thread.sleep(work_time * std.time.ns_per_s);

    std.debug.print("thread {d}: {s}\n", .{ num, "finished." });
}
// This is the easiest way to run threads in parallel.
// In general, however, more management effort is required,
// e.g. by setting up a pool and allowing the threads to communicate
// with each other using semaphores.
//
// But that's a topic for another exercise.
