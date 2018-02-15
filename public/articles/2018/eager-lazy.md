Today I was surprised to learn that native promises, such as those returned by `fetch`, are eager rather than lazy ([via this tweet](https://twitter.com/BenLesh/status/963822564874190849)). This means that they run as soon as they are defined, changing how I would have previously understood the following code:

```js
const result = conditionalFetch(Math.random() < 0.5)
	.then(r => r.json())

function conditionalFetch(condition) {
	// bad but illustrative
	const fetchIfTrue = fetch(expensiveThing)
	const fetchIfFalse = fetch(otherExpensiveThing)

	if (condition) {
		return fetchIfTrue
	} else {
		return fetchIfFalse
	}
}
```

I would have assumed, perhaps naïvely, that the above code would only load one of the resources. Instead, both are requested as soon as `fetch` is called. This is in contrast to the lazy nature of `Observable` objects from `Rxjs`.  To compare these two methods of asynchronously handling requests, I created a little demo ([source code](https://github.com/chrfrasco/eager-lazy-ajax)). It first creates the object representing the request, then handles the response 3 seconds later.

Here's the meat of it:

```js
import Rx from 'rx-dom'

const url = 'http://localhost:9000/time'

const $time = Rx.DOM.getJSON(url)
const timePromise = fetch(url)

setTimeout(() => {
  $time.subscribe(makePrintTime('observable'))
  timePromise.then(r => r.json()).then(makePrintTime('fetch'))
}, 3000)

function makePrintTime(name) {
  return (time) => {
    console.log(`${name}: requested at ${time.time}, printed at ${new Date().toLocaleTimeString()}`)
  }
}
```

In summary, the objects are instantiated straight away, and then the responses are handled 3 seconds later. Here's what appears in the console:

![fetch vs Rx.dom.getJSON](https://i.imgur.com/sD3b3OAr.png)

As you can see, the `fetch` version makes the request a full 3 seconds before the Observable version, implying that it requests the resource the moment the object is initialised.

The takeaway from this is don't initialise promises until you need them! The code above isn't very sensible but it's illustrative of what can happen if you're not careful. If you need to initialise an async action and pass it around before starting the action, Observables à la `Rxjs` are perfect for this.
