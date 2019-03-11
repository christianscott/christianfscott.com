---
title: An Extremely Basic Guide to Writing PDFs by Hand
date: "2019-03-09T22:12:03.284Z"
---

The goal of this post is to teach you how to write a very basic PDF containing some shapes and some text. The goal is not to teach you how PDFs work in any level of detail - I'm certainly not the person to be teaching you that & it's been done well by people before me.

If you want to actually learn how to write PDFs I recommend the following resources:

- Leon Atherton's "[Make your own PDF file](https://blog.idrsolutions.com/2013/01/understanding-the-pdf-file-format-overview/#helloworld)" series. A practical guide to creating PDFs, although it does lack a lot of detail.
- Brendan Zagaeski's "[Hand-coded PDF tutorial](https://brendanzagaeski.appspot.com/0005.html)". This is a great intro to some of the specifics of PDFs, but is a bit heavy on the details if you just want to get your hands dirty.
- Last but not least, [the PDF spec](https://www.adobe.com/content/dam/acom/en/devnet/pdf/pdfs/PDF32000_2008.pdf) is a surprisingly readable document despite being over 700 pages long. It's obviously very thorough, but I found ctrl+F'ing around & using the table of contents made finding relevant information very easy. If you want to do more than just basic shapes and text, this is actually a great next step.

I'll be teaching you how to build a PDF containing text, rectangles and circles. Like I said, very rudimentary. NOTE: all code samples are written in Typescript.

**Here are some important details that I should find a better place for:**

- Coordinates start at the _lower left hand corner_ and go to the _top right hand corner_. This is in contrast with most coordinate systems that I'm familiar with which start from the _top_ left hand corner.
- The "language" used to define PDFs is an ancestor of postscript. If you're not familiar with postscript, it's relatively unique in that function invocations happen after listing arguments — that is, it is a _postfix_ language. Invoking a function in a typical programming language happens the opposite way around

        func(arg1, arg2)

  A postfix language

        arg1 arg2 func

  These languages are typically stack based. When you pass arguments, what you're really doing is pushing them onto a stack. Function invocations then pop a certain number of values off the stack & then do their work with those values. It's really easy to write your own interpreter for a postfix, stack-based language!

  See [stack-oriented programming](https://en.wikipedia.org/wiki/Stack-oriented_programming) and [reverse polish notation](https://en.wikipedia.org/wiki/Reverse_Polish_notation).

# Template

Below is the template that we'll be using. For now, you're safe to ignore everything bar the `{{WHATEVER}}` bits - these are placeholders for the stuff that you'll be writing

```
%PDF-1.1
%¥±ë

1 0 obj
    << /Type /Catalog
        /Pages 2 0 R
    >>
endobj

2 0 obj
    << /Type /Pages
       /Kids [3 0 R]
       /Count 1
       /MediaBox [0 0 {{PAGE_WIDTH}} {{PAGE_HEIGHT}}]
    >>
endobj

3 0 obj
    <<  /Type /Page
        /Parent 2 0 R
        /Resources
        << /Font
            << /F1
                << /Type /Font
                   /Subtype /Type1
                   /BaseFont /ArialMT
                >>
            >>
        >>
        /Contents [ {{OBJECT_REFERENCES}} ]
    >>
endobj

{{OBJECT_DEFINITIONS}}

xref
0 {{NUM_OBJECTS}}
0000000000 65535 f
trailer
    << /Root 1 0 R
       /Size {{NUM_OBJECTS}}
    >>
startxref
0
%%EOF
```

`{{PAGE_WIDTH}}` and `{{PAGE_HEIGHT}}` are the width and height of your document in points (pt). You can convert from px to pt with this helper

```typescript
function pxToPt(px: number): number {
    return (px * 72) / 96
}
```

`{{OBJECT_DEFINITIONS}}` are all of the objects (text and shapes) that you want to define. These look like this

```
4 0 obj
    {{OBJECT_VALUE}}
endobj
```

This says _"create an object with ID 4 and generation 0 and set it's value to whatever_ `{{OBJECT_VALUE}}` _is"._ The generation part doesn't seem to be very important. More on this later.

`{{OBJECT_REFERENCES}}` are "references" to the above objects. You need to explicitly tell the PDF interpreter which objects are in which page via the `/Contents` array. Say we have two objects with IDs 4 and 5 in our page, the references would look like this

```
/Contents [ 4 0 R
            5 0 R ]
```

The line break isn't needed but it makes things a little clearer.

Finally, `{{NUM_OBJECTS}}` is... the number of objects in the document. This is the _number of objects you defined_, including the three object definitions included in the template, plus one. Why the one? Who knows. I'm sure it's in the spec.

# Defining your own object

What your object _is_ depends on what you put into the body of an object declaration. The _stuff_ that comprises an object is defined inside something called a stream

```
4 0 obj
<< /Length {{STREAM_LENGTH_IN_BYTES}} >>
stream
{{STREAM}}
endstream
endobj
```

First we let the PDF interpreter know how long the stream is. This is the length of _every byte inside `stream` and `endstream`,_ bar trailing spaces.

### Trap for young players

There's a good chance that this isn't equal to the length of the string that you dump in there. It needs to be the number of _bytes._ Unicode characters, which count as one character in Javascript strings, are actually made up of multiple bytes. You can count the bytes using a node buffer

```typescript
$ node
> let unicodeString = 'ü'
undefined
> unicodeString.length
1
> Buffer.from(unicodeString).length
2
```

The stream content itself is a sequence of postfix commands. It can also be binary content, but we don't need to worry about that.

## Adding text

The following snippet creates black text with the content `Hello, world!` at coordinates 0, 0 with a font size of 16pt

```
4 0 obj
<< /Length 57 >>
BT
    0 0 0 rg
    /F1 16 Tf
    0 0 Td
    (Hello, world!) Tj
ET
endobj
```

`0 0 0 rg`

The `rg` function in the first line of the body sets the color of the text. PDFs use what's known as the rg color system. It's essentially the same as rgb, but scaled 0 - 1. To convert, just divide each rgb value by 360

```typescript
function rgbColorspaceToRgColorspace(c: Color.Rgb): Color.Rg {
    return { r: c.r / 360, g: c.g / 360, b: c.b / 360 }
}
```

So in the above example, we are setting the color to black.

`/F1 16 Tf`

If you go back to the template, you'll see `/F1` inside object 3 just before we specify the font, which is Arial in this case. The `Tf` command sets the font & the font size — so we're specifying 16 point Arial.

`0 0 Td`

This specifies the location at which we wish to render the text. Again, the origin of the coordinate system in PDFs is the _lower left hand corner_, in contrast with most systems that I'm used to. This means that we're going to draw the text in the lower left hand corner of the page.

`(Hello, world!) Tj`

Finally, this is what actually renders the text. Instead of using quotes to represent strings, PDFs use parentheses. Don't ask me why.

```typescript
const stream = `BT 0 0 0 rg /F1 16 Tf 0 0 Td (Hello, world!) Tj ET`;
console.log(Buffer.from(stream).length); // 57
```

So our above example is 57 bytes — hence the length declaration.
