---
title: "A rule of thumb for explaining a new technology: explain it in terms of what it replaced"
date: "2023-03-28T05:10:25.934Z"
---

Listing features, benefits, and implementation details is an ineffective way of getting someone to understand the significance of a technology. People will understand what these benefits are, and will be able to see that they are desirable, but they’re not going to understand why the technology needs to exist.

Instead, try to explain it in terms of the thing that it replaced. The technology that you’re describing was almost certainly predated by something else. It was probably predated by a different technology, but it might also be predated by practices. By explaining the old way and the problems it had, you can now explain how the new technology solves those problems.

I think this works because it’s hard to understand descriptive words in isolation. If you describe something as “fast”, that doesn’t mean much unless you have something to compare it against.

Let’s illustrate this with a contrived example. Imagine I explained Bazel to you like this, perhaps at greater length:

> Bazel is a scalable build tool used by Google and other companies that have large, polyglot monorepos. By running builds inside a sandbox, it enables you to have builds that are both fast AND correct

Fast relative to what? What does correct mean? How does “sandboxing” make it better? A much more effective way to pitch Bazel would be to describe it thusly:

> Before Bazel, Make was the standard build tool. It does not force you to specify all inputs so you were able to have undeclared dependencies. This could cause your build to go out of date, requiring you to perform clean builds every now and then. In contrast, Bazel uses sandboxing to force you to specify all inputs: if you miss something, the build will fail. This enables lots of cool things like remote caching, remote building, and makes it much less likely that you need to perform clean builds

[The K8s docs](https://kubernetes.io/docs/concepts/overview/#going-back-in-time) do a good job of explaining the history leading up to its inception. It also describes what K8s isn’t, which is another thing that’s useful.

I am not sure why this approach is better, but I have guesses about why it might work:

- It’s easier to understand something explained in relative terms than in absolute terms. I get a better intuitive sense of the size of an elephant when it’s described weighing as much as 75 people rather than weighing 6000kg.
- This explanation provides a narrative, and explaining things via narrative is engaging
- It’s a more accurate representation of what the creators were thinking when they decided a new technology was needed. They probably weren’t after something in isolation: they were probably frustrated with something & wanted a better replacement!

