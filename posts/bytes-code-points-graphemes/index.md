---
title: Bytes, Code Points and Grapheme Clusters
date: "2019-04-29"
---

Let's talk about text. Specifically, text encoded using utf8.

How many characters would you consider to be in the string `'a'`? What about `'é'`?

```javascript
$ node
> 'a'.length
1
> 'é'.length
1
```

I'd say that this lines up pretty closely with what I expect. There's some trickery going on here through, which can be revealed if we
use the `Buffer` object in node, which is populated with each of the bytes in a string:

```javascript
$ node
> Buffer.from('a').length
1
> Buffer.from('é').length
2
```

While `é` may be a single character, it's not represented using a single byte, like `a` is. It certainly could be -- all you have to do is declare
some byte to be the byte that represents `é`, as is the case for `a` and `0x3d`. This wouldn't be practical though -- you only have 255 bytes to
choose from. This is serviceable if you speak english & don't care about symbols outside of the latin letters, the numbers and a few symbols. This however
excludes a whole lot of people who don't speak english from being able to use your software in their native language. This is what you're doing if
you use ascii as your encoding.

So what next? Use more bytes? To cut a long story short, utf8 is a defacto solution to this problem. It uses a variable number of bytes to represent
characters -- 1 through 4 bytes. That means any "character" could be represented using 1, 2, 3, or 4 bytes. Conveniently, the designers of utf8 set it up in such a way that ascii is a valid subset of utf8. Nice one.

This is why we got 2 as the length of `Buffer.from('é')`, internally, in a utf8 encoded string, it's stored using two bytes.

```javascript
> [...Buffer.from('é')].map(cc => `b${cc.toString('2')}`)
[ 'b11000011', 'b10101001' ]
```

This works as we'd expect a utf8 string to behave, despite the fact that Javascript stores strings using the utf16 encoding. This is because `Buffer.from` takes
an encoding as a second argument, the default value for which is utf8, so the string is parsed as though it were a utf8 string. I'll be honest, I still don't
really have my head wrapped around how this works, but onwards we go.

With utf8 we have four bytes with 8 bits each, which is $2^{32} = 4,294,967,296$ (4.3 billion) So, end of story right? Surely this is enough room for every single character humans could conceive for the rest of history? Not quite. Look at this nonsense:

```javascript
> '👨‍👩‍👧‍👧'.length
11
> Buffer.from('👨‍👩‍👧‍👧').length
25
```

WTF (paste that line in your terminal -- it will probably mess it up)

11 characters is wild.

The reason this is surprising to me is because I have an english-centric understanding of text. Some Hindi words, for example, are constructed of serveral
characters to form a single "ligature":

```javascript
> 'अनुच्छेद'.length
8
```

These "ligatures" are referred to as _grapheme clusters_. There's an algorithm that you can use to figure out where the boundary between two grapheme clusters (see reading material).

---

### Reading material

- [Joel on Software - The Absolute Minimum Every Software Developer Absolutely, Positively Must Know About Unicode and Character Sets (No Excuses!)](https://www.joelonsoftware.com/2003/10/08/the-absolute-minimum-every-software-developer-absolutely-positively-must-know-about-unicode-and-character-sets-no-excuses/)
- [orling/grapheme-splitter on Github](https://github.com/orling/grapheme-splitter)
- [Unicode standard annex #29](http://www.unicode.org/reports/tr29/#Grapheme_Cluster_Boundaries)
- [Devangari on Wikipedia (script used to write Hindi)](https://en.wikipedia.org/wiki/Devanagari#Compounds)
