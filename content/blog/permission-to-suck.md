---
title: Permission to suck
date: "2020-11-18T09:18:20.445Z"
---

Teams who build products for their coworkers, internal teams, face a critical problem. Their users are unable to switch from their product to another one. This becomes problematic when the product that the internal team builds sucks. Even if there is a third party who sells something better, there is often no way for them to switch to that product. This gives internal teams permission to suck.

If these internal teams were companies, there would be little room to suck. Users would flee, and the company will go out of business.

Some might see this as an advantage for the internal team. 100% retention is something that even the best products can only dream of! This might be the case if all you care about is keeping your job. If your users can't leave, then you're never out of a job. But what about the long term health of the company? Without a healthy company, there is no internal team. Bad internal tools will rot a company from the inside out. Your users will do less work, leave the company, work around you, et cetera. This in turn rots The Thing That Actually Makes Money

Except for negligence or bad luck, there's no reason a 3rd party product could destroy a company in that way. They would switch to a different solution long before that happens. This threat of switching also has a lovely consequence: it forces the 3rd party to do a better job. The threat of losing the customer forces them to think long and hard about how to make their product suck less.

To recap, there are two sides of the coin here:

1. From the perspective of the user: I can pick the tool that best suits my needs
2. From the perspective of the builder: our tool must be the best, otherwise users will pick a different tool

These both result, on average and over time, with the users selecting the best tools. This allocates more capital to those tools, which use that extra cash to become even better (and are then swiftly punished for their success by anti-trust regulation).

It might seem like this is the best possible outcome, but it's not. [Vertical integration](https://www.investopedia.com/terms/v/verticalintegration.asp) is a strategy whereby you incorporate e.g. a supplier into your business. This incorporation allows you to reduce costs & improve efficiency. A recent example is Apple in-housing the manufacturing of processors. I don't have a lot of insight here but it's plain to see that the 1-2 combo of cost reduction & the ability to tailor the product to their needs will be a winning one.

The same benefits also apply for vertically integrated software products. Take DataDog for example. It's (supposedly) a great product, but it's also [incredibly expensive](https://www.reddit.com/r/devops/comments/7bb2ao/what_are_peoples_opinion_on_datadog_for_monitoring/). By building an alternative in-house we can save an inordinate amount of cash.

The catch is that this takes us back to the start – how do we make sure that this inhouse datapup doesn't suck?

I don't have a good answer, but I have a few ideas:

1. Sell or open source your product. If it performs well on the market, you've got confirmation that you have a winner on your hands. This is allegedly why Bazel (a.k.a. Blaze) was open sourced.
2. Don't force teams to use internal tools. If they want to use Datadog rather than your crappy internal clone, let them!
