---
title: A quick follow up to “Making rust as fast as go”
date: 2020-05-10T12:57:50.288Z
---

A week ago I posted an article called [“Making rust as fast as go”]({{< ref "/making-rust-as-fast-as-go" >}}) to Hacker News. It compared two simple programs, one written in rust and one in go. In the benchmark I performed, the rust program was slower. I dove into the cause of the performance gap, and concluded that it was the fault of the macos system allocator. I suggested that you might want to use a custom allocator (like jemalloc) for allocation-heavy workloads.

Unfortunately, there were a few mistakes in that post that called the validity of that conclusion in to question. The mistakes fell into four categories:

1. The implementation was wrong. I used the number of bytes in a string in some places where I should have been using the number of code points[^1]
2. The implementations were not the same. The rust version of the program parsed the `target` string on every loop, whereas the go version only parsed the `target` string once.
3. The implementation was not optimal. Since this was being used in a single-threaded context, there was no reason to reallocate the `cache`, `targetChars` and `sourceChars` objects every time the distance function was called.
4. The benchmark was not valid. In particular, the go benchmark may not triggered a GC. If the benchmark did not fill a sufficient portion of the heap, the go runtime would not perform an deallocation at all (see snej’s comment on lobste.rs)

This leads me to two interesting questions:

1. Does the conclusion hold up once the mistakes are corrected?
2. What would a more realistic attempt at improving the performance of the rust program look like? (since this is the one that drew the most attention)

I'll answer the first one in this post. I'd like to dive into the second question at some point in the future. I've received [a few interesting PRs](https://github.com/christianscott/levenshtein-distance-benchmarks/pulls) that have given me some great performance pointers. Thanks to everyone who opened a PR!

# Does the conclusion hold up once the mistakes are corrected?

In other words, once the mistakes are fixed, is the rust program still slower? And do we believe that the cause is still the system allocator?

## Mistake 1: bugs in the implementation

One of the requirements I stated was that we should assume that the input strings are encoded using utf8. In rust and go, you need to be very deliberate about whether you’re dealing with bytes or runes[^2]. In rust, for example, `string.len()` will return the number of bytes and `string.chars().len()` will return the number of runes. For ascii strings, these operations will return the same number. Non-ascii strings will not – `"föö".len() == 5` whereas `"föö".chars().len() == 3`.

In each of the implementations, I was using a mix of both of these counts. The reason I didn’t notice is that I was only using ascii data to test them – if I’d used test data that contained non-acsii chars, the following snippet (pseudo-code, adapted from the actual implementation) would have caused a bounds check to fail at runtime in both languages:

```rust
fn borked(a: string) {
  let cache: Vec<usize> = (0..=a.chars().count()).collect();
  // since `a.chars().count() <= a.len()`, the next line will
  // panic if `a` contains any non-ascii chars
  cache[a.len()] = 0;
}
```

This was a simple fix. It just required making sure that I was using runes everywhere. It still worked as expected after this fix, and had the added bonus of being able to accept strings with non-ascii chars.

Before _(tested with [0278565](https://github.com/christianscott/levenshtein-distance-benchmarks/commit/02785654075e37feb731552c02ee7ac48f245fe9))_:

```sh
$ node run.js bench
go: 1.399890
rust: 2.602080818
```

After _(tested with [8d94524](https://github.com/christianscott/levenshtein-distance-benchmarks/commit/8d94524792ac2f5fd6cc6eed0a78160c7e2de815))_:

```sh
$ node run.js bench
go: 1.553361
rust: 2.566104955
```

As you can see, this doesn't make a whole lot of difference. The go program is slightly slower, but not significantly. This isn't surprising. I wasn't expecting a lot of difference here, unless the rust compiler could somehow avoid a bounds check since we're now using the correct length (this doesn't seem to be the case).

## Mistake 2: the implementations aren't equivalent

The main source of concern among commenters was the fact that the programs were not

## Mistake 3: the benchmark might not be measuring what I hoped

[^1]: Rust `char`s are _Unicode Scalar Values_, whereas go `rune`s are _Unicode Code Points_. These are very similar – [I’ve explored the difference in another post]({{< ref "/rust-chars-vs-go-runes" >}}), but they are similar enough to be treated as the same for purpose of this post.

[^2]: I will refer to code points and scalar values as runes for the sake of convenience
