---
title: A more compact encoding for Bazel digests
date: "2025-01-09"
---

> TL;DR: The typical `hash/size` digest string is easy to read but wasteful: a 32-byte SHA-256 plus size typically requires 74+ characters. If we encode the 32-byte hash followed by a minimal-length size and then base64url the result (without padding), we get 44–48 characters—about 35% shorter—without losing reversibility.

Bazel uses "[digests](https://github.com/bazelbuild/remote-apis/blob/9a0af1d31814bfcbd16dce545d10899bfc2445b7/build/bazel/remote/execution/v2/remote_execution.proto#L983-L990)" to identify objects in the CAS like output files. These digests are made up of two parts: the sha256 hash of the contents of the object, and the size in bytes. Typically, they are represented as strings by hex encoding the hash and appending the size:

```proto
message Digest {
  string hash = 1;
  int64 size_bytes = 2;
}
// 12afe81ce1bbb143967661b4a78170c21818480cd8361964578ec312fab0dec7/938291175
```

This encoding scheme is simple and human readable but it isn't very compact. 40 bytes (256 bits for the hash, up to 64 for the size) worth of information is represented using at least 66 characters, which means it wastes about 40% of the space.

Space efficiency likely wasn't one of the goals of that encoding scheme, but what if we want to do better? I'm currently building a service at work that enables engineers to preview the output of Bazel builds in a web UI. The URLs include the digest of the output that they want to view. They end up being quite long, and I wondered if I could make them shorter:

```
https://previews.corp-internal.com/v/12afe81ce1bbb143967661b4a78170c21818480cd8361964578ec312fab0dec7/938291175/
```

I *could* do this by generating random IDs and storing them somewhere, but I am lazy and don't want to maintain a database. I would much prefer to own a stateless service, and so it would be much better if we could deterministically retrieve the digest from the URL.

<details style="border: 1px solid black">
  <summary><em>An aside about lossless compression schemes like run-length encoding</em></summary>

  <p>
    Using a lossless compression scheme like run-length encoding is tempting to a fool like me but works very poorly. In brief, lossless compression schemes work well when the data they are compressing exhibits *statistical redundancy*, or repeated patterns. This might work well if the data that was encoded in the hexadecimal exhibited some pattern that we could exploit, like most of the bytes being 0, but SHA functions are intentionally designed so that their outputs look like random data (*"uniformly distributed over the output space"*).
  </p>

  <p>
    As a result, RLE does a horrible job of compressing hex-encoded SHA-256 hashes. Even if you cheat by dropping the run length of 1-byte runs, you still don't make the string any shorter on average.
  </p>
</details>

## What data is actually being encoded?

It's easy to mistake the human-readble digest for the data, but it's just the format we've chosen to represent the data. In the case of a SHA-256, the *actual* data is 256 bits of information. This can be represented in memory using 32 bytes:

```c
#include <stdint.h>
int main() {
  uint8_t sha256sum[32];
}
```

This is fine for a CPU, but for our purposes we need a string, so we have to pick some way to *encode* the data. One way to do this is to represent it as a string of bits:

```
100111111000110111101010001001000111111111111010111001011010000111111101111000110000001011010111110011001101110010010001001100010110100111101101101000111101110111101110100001011111010000101110111111101111111001001010111110000
```

That's clearly a pretty bad idea. It's an enormously wasteful encoding since each 0 and 1 needs a full *byte* to represent it, so we're using 256 bytes to represent 32 bytes of data (8.5x larger).

Instead, the standard way to encode a SHA256 digest is to use hexadecimal encoding. Instead of just using zeros and ones, we use the characters 0-9 and a-f to represent the values 0-15. This is a much more compact way to represent the data, as each character represents 4 bits of information. This means that we can represent 256 bits of information using 64 characters.

## A More Compact Encoding

But we can do even better. Hexadecimal uses 16 symbols (0-9, a-f) to encode 4 bits per character. What if we used more symbols? Base64url encoding uses 64 symbols (A-Z, a-z, 0-9, -, \_) to encode 6 bits per character. This is URL-safe and reduces the 32-byte SHA256 hash from 64 characters down to just 43 characters.

The size field is more interesting. While we need to support sizes up to 2³² bytes (4GB), most files are much smaller. Rather than always using the full 10 decimal digits, we can encode the size as a little-endian 32-bit integer and then trim trailing zero bytes. This variable-length encoding means:

- Files up to 255 bytes: 1 byte needed
- Files up to ~64 KB: 2 bytes needed
- Files up to ~16 MB: 3 bytes needed
- Larger files: 4 bytes needed

The complete digest is then encoded as the 32-byte SHA256 hash followed by 0-4 bytes for the size, all converted to base64url. This gives us 44-48 characters total, compared to the original 74+ characters. For example:

- Original: `12afe81ce1bbb143967661b4a78170c21818480cd8361964578ec312fab0dec7/938291175` (74 characters)

- Compact: `Eq_oHOG7sUOWdmG0p4FwwhgYSAzYNhlkV47DEvqw3sc4AOBb` (48 characters - 35% shorter!)

The compact encoding sacrifices human readability for space efficiency. You can't eyeball the hash or size anymore, but for URL parameters where every character counts, this is often worth it. And since the encoding is deterministic and reversible, you can always convert back to the human-readable format when needed. For my use case—embedding digests in preview URLs—this cuts URL length significantly without requiring any server-side state.
