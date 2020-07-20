---
title: Premature optimization is about delaying solving problems, not about performance
date: "2020-07-20T14:38:57.344Z"
---

> Premature optimization is the root of all evil - Donald Knuth

This is an oft-repeated[^1] and, I would claim, a slightly misunderstood phrase.

It's usually understood to mean *spending time on performance is not worth it until you understand why your software is slow*, when in reality I think the useful lesson is *don't try and solve problems that don't exist yet.*

This is to say that the phrase is not really about performance but is about *resisting the temptation to solve pre-empted problems.* Instead of doing this, you should solve the problems at hand. When (or if) the problem you pre-empted arises, that is the time to solve it. Performance is a great example of this. You should wait until you 1) have reason to spend time making your software faster 2) know why your software is slow. Only then should you invest the time & inflict the architectural damage to make your software faster.

Of course, taken to the extreme, this would lead us to some awful tech debt[^2]. As with all one sentence pieces of advice this should be taken with a grain of salt. We should expand this a little bit – of course there are problems that we should solve up front. For example, it's spending at least a little bit of time on the architecture of your app well before your codebase grows to a size where you realize any benefits.

How are these "worth it" problems different from the kinds of problems that aren't worth it? I'm honestly not sure – but problems that arise from *irreversible* decisions (like the architecture of your software) are problems that are worth trying to solve up front.

This still feels a little unsatisfying to me. There are certainly problems that arise from irreversible decisions

With all that in mind, here's the updated but far less snappy saying:

> To decide if a problem is worth solving prematurely (that is, before the problem has arisen), first consider:
> 1) the cost of solving the problem now
> 2) the cost of solving the problem at the time it would arise 
> 3) the size of the fallout of the problem if it becomes un-solveable

| cost now  | cost later  | potential fallout  | solve when?     |
|-----------|-------------|--------------------|-------------|
| low       | high        | high               | now   |
| low       | low         | high               | later |
| *any*  | *any*    | low                | never?      |

This leaves room for "premature optimizations" that may become existential risks, or cheap architectural decisions early on that will save a lot of problems further down the line. For example, the Canva CTO talks about the decision to add async boundaries between fake "services" that all lived in a single monolith. This achieved two things: 1) enjoyed the low operational complexity of a monolith for as long as possible 2) made it easier to break the fake services out into real services when the time came

[^1]: citation needed :)

[^2]: having said that, I would wager that a team that *only* solved short term problems would outperform a team that strived for perfection up front.