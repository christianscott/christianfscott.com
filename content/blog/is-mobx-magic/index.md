---
title: Is mobx magic?
date: "2020-05-02T08:26:05.556Z"
---

When I was first introduced to mobx about a year and half ago, you probably could have convinced me that it was magic. The idea that my react components knew how to update when I mutated properties on an object was bizarre. Since then, I’ve been introduced to a few techniques and javascript features that made it click. I don’t know how mobx actually works, but I can now see how it’s possible.

The goal of this post is to introduce you to those techniques and features so you can also get a feel for how it’s possible. This means that I won’t be focusing on things like performance or async, just the basics. I’ll gradually introduce more & more “magical” parts of the library until we the get to the most bewildering part. By the end of this article, you should understand how the following snippet is possible:

```js
const library = mobx.observable.shallow({})
mobx.autorun(() => console.log(library.name))
library.name = 'mobx'
// log: undefined
// log: mobx
```

If you’re not familiar with mobx, the docs have a fantastic [10 minute introduction to the library](https://mobx.js.org/getting-started.html). If that didn’t exist I would want to give an explanation here but there’s no way I’m going to beat that.

The most basic thing we can do with mobx is observe … observables. By “observing” a value we are essentially subscribing to updates to that value. When I say “observe” I mean “provide a function that is called when an observable changes”. For example, we can observe a `box`:

```js
const box = mobx.observable.box(true);
box.observe(value => console.log(value));
box.set(false);
// log: false
```

*Note: for the sake of simplicity I have changed the signature of `observer` from `{ newValue: boolean, ... } -> void` to `boolean -> void`*

Hopefully this doesn’t seem too surprising. This is very similar to the “event emitter” pattern that most javascript programmers will be familiar with. We can emulate this behaviour with a single function:

```js
function box(initialValue) {
  let value = initialValue
  const observers = new Set()
  return {
    get: () => value,
    set: (newValue) => {
      value = newValue
      for (const observer of observers) {
        observer(newValue)
      }
    },
    observe: (observer) => {
      observers.add(observer)
    }
  }
}
```

Simple enough. Let’s introduce a little more magic. Mobx exposes a function called `autorun`, which is very similar to `observable.observe`. The major difference with `autorun` is that unlike `observe`, *there is no explicit dependency between the observable and the observer!* In other words, mobx figures out what observables an observer depends on & calls the observer any time those observables are updated. This might be a little confusing, so an example will help:

```js
const isActive = mobx.observable.box(true);
mobx.autorun(() => console.log(isActive.get()));
isActive.set(false);
// log: true
// log: false
```

*Note: if you’re familiar with mobx you might have noticed that I’m not updating `box` inside an [action](https://mobx.js.org/refguide/action.html). I’ve omitted actions since they’re out of scope for this article, and not strictly necessary. You should use them in your app however.*

Two interesting things have happened:

1. Mobx somehow knew that the function passed to `autorun` depends on `box` & re-ran it when `box` was updated
2. In contrast to `box.observe`, the callback was called twice

This works because the `.get` method *registers the current observer as being dependent on* `*box*`. This means that `.get` is not [pure](https://en.wikipedia.org/wiki/Pure_function), like we would normally assume for a getter. This also means that there is some global state inside the mobx library.

We can emulate this with a global variable and two functions. Let’s update what we’ve got so far to support this:

```js
let currentObserver = undefined

function reaction(observer) {
  currentObserver = observer
  observer()
  currentObserver = undefined
}

function box(initialValue) {
  let value = initialValue
  const observers = new Set()
  return {
    get: () => {
      if (currentObserver !== undefined) {
        observers.add(currentObserver)
      }
      return value
    },
    set: (newValue) => {
      value = newValue
      for (const observer of observers) {
        observer(newValue)
      }
    },
    observe: (observer) => {
      observers.add(observer)
    },
  }
}
```

Two things have changed:

1. When `autorun` is called with an observer, the `currentObserver` global variable is updated with that observer. It then runs the observer and then resets `currentObserver`
2. `box.get` checks if `currentObserver` is set. If it is, it adds it as an observer

To figure out what observables an observer depends on, `autorun` *must* call the observer straight away to get a chance to register them before they’re updated. This is why we saw two things logged to the console rather than one. When we interact with those observables, they take note of the current observer & call that observer when they are updated.

So far this isn’t too strange. Side effects inside a getter, while unusual, aren’t hard to understand. Things get a little weirder once we start observing objects.

```js
let point = mobx.observable.shallow({ x: 0, y: 0 })
mobx.autorun(() => console.log({ x: point.x, y: point.y }))
point.y = 1
// log: { x: 0, y: 0 }
// log: { x: 0, y: 1 }
```

Somehow mobx is able to figure out that you’re accessing plain properties on an object. This should be impossible if we’re not calling a method, right? That would be true is these really were plain properties. This isn’t the case here – mobx is “upgrading” these properties to something called *“property accessors”.* These provide a way to customise setting and getting properties. To create an accessor, we can put the `get`  or `set` keywords in front of a method. For example, let’s log something every time a property is accessed:

```js
const o = {
  get property() {
    console.log('hello!')
    return 1
  }
}
o.property
// log: hello!
```

Unfortunately, property accessors alone aren’t enough to emulate the behaviour of `mobx.observable.shallow`. We need to be able to create these property accessors *dynamically*, based on the supplied object, without relying on the user to create the accessors themselves. Each of the keys present in the original property need to be “upgraded” to property accessors.

Let’s see why this won’t work. In the following snippet we iterate over the keys of a `source` object and use `Object.assign` to attempt to add that accessor to a target object:

```js
const source = { foo: 'foo', bar: 'bar' }
const observable = {}
for (const key in source) {
  Object.assign(observable, {
    get [key]() {
      console.log('getting ' + key)
      return false
    },
  })
}
// log: getting foo
// log: getting bar
observable.foo
observable.bar
// nothing logged to console ☹️
```

The accessors are run while we’re copying over the properties to `observable`, but not when we eventually access them. We can assume this happens because `Object.assign` will be running the accessor internally, something like `target.prop = source.prop`.

Ok, `Object.assign` is out because the property accessor is lost when copying the properties over. What about a really long prototype chain? [*See “Object prototypes” on MDN if you’re unfamiliar with how inheritance works in JS*](https://developer.mozilla.org/en-US/docs/Learn/JavaScript/Objects/Object_prototypes)

```js
> const getterWithKey = (key) => ({
  get [key]() {
    console.log('getting ' + key)
    return false 
  }
})
> const foo = getterWithKey('foo')
> const bar = getterWithKey('bar')
> bar.__proto__ = foo
Object <[Object: null prototype] {}> { foo: [Getter] }
> const baz = getterWithKey('baz')
{ baz: [Getter] }
> baz.__proto__ = bar
Object <Object <[Object: null prototype] {}>> { bar: [Getter] }
> baz.baz
getting baz
false
> baz.bar
getting bar
false
> baz.foo
getting foo
false
```

This works! It’s disgusting, but it works. The performance implications are pretty bad though: any time your want to access a property, you need to walk up N prototypes (where N is the number of properties) in the worst case. Accessing properties on an observable object definitely is not `O(N)` so there has to be another way.

*Note: even though I did say that I wouldn’t talk about performance, this solution is so egregious that I had to reject it*

Is there another way to define property accessors? Underneath the hood, properties are defined using something called *descriptors.* [From MDN:](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/defineProperty)


> Property descriptors present in objects come in two main flavors: data descriptors and accessor descriptors. A data descriptor is a property that has a value, which may or may not be writable. An accessor descriptor is a property described by a getter-setter pair of functions. A descriptor must be one of these two flavors; it cannot be both.

This means that so called “property accessors” are actually just syntactic sugar for *accessor descriptors.* We can use `Object.defineProperty` to manually create these descriptors, like so:

```js
Object.defineProperty(o, 'k', {
  get: () => value,
  set: (newValue) => (value = newValue),
});
```

Let’s update our script to take advantage of this:

```js
let currentObserver = undefined

function autorun(observer) {
  currentObserver = observer
  observer()
  currentObserver = undefined
}

function shallow(source) {
  if (
    source.__proto__ != null
    || source.__proto__ === Object.prototype
  ) {
    throw new Error(
      'can\'t make an observer from an object with a prototype',
    )
  }

  const values = {}
  const observers = new Map()

  const makeGetter = (key) => () => {
    if (currentObserver != null) {
      let observersForKey = observers.get(key)
      if (observersForKey == null) {
        observersForKey = new Set()
        observers.set(key, observersForKey)
      }
      observersForKey.add(currentObserver)
    }

    return values[key]
  }

  const makeSetter = (key) => (newValue) => {
    if (observers.has(key)) {
      for (const observer of observers.get(key)) {
        observer(newValue)
      }
      values[key] = newValue
    }
  }

  const observable = {}
  // we can look at all the keys since we know this object
  // does not have a prototype
  for (const key in source) {
    values[key] = source[key]
    Object.defineProperty(observable, key, {
      get: makeGetter(key),
      set: makeSetter(key),
      enumerable: true,
      configurable: false,
    })
  }

  return observable
}

function box(initialValue) {
  let value = initialValue
  const observers = []
  return {
    get: () => {
      if (currentObserver !== undefined) {
        observers.push(currentObserver)
      }
      return value
    },
    set: (newValue) => {
      value = newValue
      for (const observer of observers) {
        observer(newValue)
      }
    },
    observe: (observer) => {
      observers.push(observer)
    },
  }
}
```

For each of the properties in the object that we want to upgrade to an observable, we create an *accessor descriptor* that performs the familiar side effects of registering & notifying observers.

If we were still on mobx v4, this would be the end. As of mobx v5 we can take this a step further:

```js
const library = mobx.observable.shallow({})
mobx.autorun(() => console.log(library.name))
library.name = 'mobx'
// log: undefined
// log: mobx
```

*Note: this is the code snippet I promised you’d understand at the start of the article*

The “magic” thing here is that mobx is able to react to properties being mutated even when it doesn’t know about the properties in the first place. In the previous step we needed to enumerate all the keys to set up the shallow object (via `for key in object`). In this example, the property `.name` is only used *after* the observable is created.

The secret sauce here is a new javascript feature called *Proxies.* [MDN has a good intro to proxies](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Proxy), but in short they provide the ability to customise fundamental object behaviour, including property lookup and property assignment. The following example logs every time a property is read:

```js
const o = new Proxy({ foo: 1 }, {
  get(object, key) {
    console.log('getting ' + key)
    return object[key]
  }
})
o.foo
// log: getting foo
o.bar
// log: getting bar
```

This will actually be simpler than the last version. We just need to create a `handler` that performs side effects every time we read or write a property:

```js
let currentObserver = undefined

function autorun(observer) {
  currentObserver = observer
  observer()
  currentObserver = undefined
}

function shallow(source) {
  if (
    source.__proto__ != null
    && source.__proto__ !== Object.prototype
  ) {
    throw new Error(
      'can\'t make an observer from an object with a prototype',
    )
  }

  const observers = new Map()

  const addObserver = (key, observer) => {
    let observersForKey = observers.get(key)
    if (observersForKey == null) {
      observersForKey = new Set()
      observers.set(key, observersForKey)
    }
    observersForKey.add(observer)
  }

  const handler = {
    get: (object, key) => {
      if (currentObserver != null) {
        addObserver(key, currentObserver)
      }
      return object[key]
    },
    set: (object, key, value) => {
      object[key] = value
      for (const observer of (observers.get(key) || [])) {
        observer()
      }
    },
  }

  return new Proxy(source, handler)
}

function box(initialValue) {
  let value = initialValue
  const observers = []
  return {
    get: () => {
      if (currentObserver !== undefined) {
        observers.push(currentObserver)
      }
      return value
    },
    set: (newValue) => {
      value = newValue
      for (const observer of observers) {
        observer(newValue)
      }
    },
    observe: (observer) => {
      observers.push(observer)
    },
  }
}
```

I hope you now have a feel for how the functionality that mobx provides is possible. To drive it home, let’s do a quick summary:

1. When you call `mobx.autorun`, a global `currentObserver` variable is set to the supplied callback
2. If any observable objects are used inside the callback, the object will register the callback as an “observer” of itself
3. Any time an observable object is updated, all observers are notified
4. Mobx v5 uses proxies to intercept all property reads & writes
