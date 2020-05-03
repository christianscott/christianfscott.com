---
title: Making rust as fast as go
date: "2020-05-03T07:28:52.529Z"
---

Go is garbage collected, rust is not. That means rust is faster than go, right? No! Not always.

Let’s take an example that I stumbled across while playing around with an algorithm that calculates Levenshtein edit distances. I wanted to compare the performance of the same algorithm in a bunch of different languages. Two of these languages were rust and go.

To my surprise, the go version was faster than the rust version. A lot faster. My initial reaction was that I must have implemented the rust version incorrectly. Maybe I was doing some unsafe (but fast) things in go that rust wouldn’t let me do. To account for this, I laid out some ground rules:

1. The more idiomatic the better. Rust, for example, promises zero cost abstractions so we should lean on this & write safe code
2. No static global variables. This means that containers need to be heap allocated & dynamically sized. We don’t know how big the inputs will be!
3. Memory access should be safe. Don’t eliminate bounds checks
4. Assume that text is utf8 encoded

In short, this should be code that you’d happily ship to prod. Here’s what I ended up with:

{{< folded_code filename="content/blog/making-rust-as-fast-as-go/edit_distance.go" >}}

{{< folded_code filename="content/blog/making-rust-as-fast-as-go/edit_distance.rs" >}}

Even with the playing field levelled, go still outperformed rust by 50%. For the dataset I was using to benchmark the programs, the go version to 1.5 seconds and rust 3 seconds.

This was bizarre. As far as I could tell, these programs were identical besides the fact that the go runtime needs to spend precious cycles collecting garbage. That means it should be slower, right?

I took the question to my coworkers, who had some good suggestions. Theories included theories included [escape analysis](https://en.wikipedia.org/wiki/Escape_analysis), string allocation, and the rust implementation being wrong. The last one was true but the performance gap remained once I fixed it (I have tests now!).

The winning suggestion ended up being to switch the allocator in the rust program to `jemalloc`. This was the default allocator used by rust binaries in the past, but it was [removed in favour of using the system allocator instead in late 2018](https://github.com/rust-lang/rust/pull/55238). Read [#36963](https://github.com/rust-lang/rust/issues/36963) to get the full rationale for this change.

To change the allocator, you simply add the following to the start of your program:

```rs
extern crate jemallocator;

#[global_allocator]
static ALLOC: jemallocator::Jemalloc = jemallocator::Jemalloc;
```

This made a huge difference. On my machine, this dropped the execution time from 3 seconds to about 1.8 seconds. Let’s take a look at the flamegraphs (generated with [flamegraph-rs/flamegraph](https://github.com/flamegraph-rs/flamegraph)) to see the change:


![Flamegraph before, with system allocator. Roughly 40% of execution time spent allocating](https://paper-attachments.dropbox.com/s_37D0C8C70724613891307BCE6762349294204ED734B7440F48079DCC0DD663E4_1588496091226_Screenshot+2020-05-03+18.48.43.png)

![Flamegraph after allocator was changed to jemalloc. Time spent allocating dropped to 20%](https://paper-attachments.dropbox.com/s_37D0C8C70724613891307BCE6762349294204ED734B7440F48079DCC0DD663E4_1588496091216_Screenshot+2020-05-03+18.45.57.png)


This means that the time spend allocating has dropped from about 40% to 20%. Keep in mind this is for the full benchmark, including setup, but it gives us a good sense of what changed.

I’m not sure why the change was so severe. I tried searching for things like “macos allocator slow” but didn’t find anything. If you have some information here, please let me know!

Why doesn’t go suffer from the slow system allocator on macos? [Because go uses a custom allocator.](https://golang.org/src/runtime/malloc.go)

So the answer is:

1. The macos allocator is slow
2. Go uses a custom allocator, which is faster than the one that ships with macos

There’s still a small performance gap to explain. My curiosity is pretty much satisfied, but if yours isn’t and you figure out the answer please let me know.

[Check out the whole github repo.](https://github.com/christianscott/levenshtein-distance-benchmarks) It has implementations in several languages, as well as scripts to benchmark + test them. 
[](https://github.com/christianscott/levenshtein-distance-benchmarks)
