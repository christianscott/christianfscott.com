---
title: Big Red Buttons
date: "2019-12-08"
---

A lot of "good advice" that's easy to internalise is also easy to ignore. A classic example of this is *"correlation does not imply causation"*. Every nerd worth their salt knows this, but falls victim to it all the time. This [bloomberg article is a classic example.](https://www.bloomberg.com/news/articles/2019-07-03/move-when-you-are-young-to-boost-your-salary-most-chart) It claims that moving overseas when you're young boosts your salary. Young people who have moved overseas may have higher salaries, but there's no reason to believe that the moving *caused* their salaries to be higher.

I hear it all the time while working, too — users who perform action A do thing B at a rate that's higher than the baseline, so action A must increase the probability that people do B. This is not the correct conclusion, and is very easy to miss.

It seems correct on the surface, but in reality you're *making up information.* The information you actually have is very simple — users who do A are more likely to do B. That's it. Saying that doing A *causes* them to do B is *adding* *more information to the story.* The reality could just as easily be that some of your users have an attribute Z that causes them to do A *and* B more often.

As a practical example, let's imagine that you run an ecommerce site. The analytics tell you that users who click the big red button in the middle of the home page buy something 6% more often than users who don't. It's very tempting to conclude that clicking on the button *made* them more likely to buy something. Because of this conclusion, you want more people to click on the button. Maybe you make it even bigger and even redder. More people click on it, and sales go up, right? In reality, there's no reason to believe that this is the case. Sales may go up after the embiggening of the button, but you still can't attribute that to the changes you made to the button. Maybe the fiscal year ended around the same time and all of your users got big tax returns.

The only way to know what impact the button has on your users is to perform an *experiment.* This is very simple to set up — put a subset of your users into two equally sized buckets, at random. Show half of them the bigger, redder button, and change nothing for the other half. After some time, check how much each of the two groups bought. If the first group bought more things than the second group, *now* you can be confident that clicking the button caused them to buy more things.
