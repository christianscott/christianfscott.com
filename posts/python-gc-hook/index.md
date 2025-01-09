---
title: Garbage Collection Hook in Python
date: "2019-04-29"
---

Credit to Jake VanderPlas for triggering this discovery with [this tweet](https://twitter.com/jakevdp/status/1120898594519650304).

Turns out there's a data model method (aka dunder method) that's called when an object is deleted in python. This includes when the object is garbage collected. We can expand on the thing Jake was trying to do in the above tweet by decrementing the instance count in the "destructor" method

```python
class InstanceCounter:
  _num_instances = 0

  def __init__(self):
    InstanceCounter._num_instances += 1

  def __del__(self):
    InstanceCounter._num_instances -= 1
```

No guarantees that this is in any way safe or reliable, but it will illustrate the point nicely.

```python
>>> ic1 = InstanceCounter()
>>> InstanceCounter._num_instances
1
>>> del ic1
>>> InstanceCounter._num_instances
0
```

So it works as expected with `del`.

We can trigger GC by creating an instance inside of a function and letting it fall out of scope.

```python
>>> def test_gc():
...   ic = InstanceCounter()
...   print(InstanceCounter._num_instances)
...
>>> test_gc()
1
>>> test_gc()
1
```

We can see that each time `ic` falls out of scope, GC is triggered, `__del__` is called & `_num_instances` is decremented.

Maybe I'm not creative enough, but I can't imagine any good reasons to use this. Anything to do with "cleaning up" after
usage should be covered using a `with` statement, but I'm sure there are some cool use cases out there in the wild.
