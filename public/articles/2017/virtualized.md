Things can get slow if you're rendering a lot of items in, say, a grid. Rather than rendering every single item in the grid, it'd be much smarter to just render what we can see.

Usually, you'd use `el.getBoundingClientRect()` to figure out where the target DOM node is in relation to the viewport. Unfortunately, each call to `getBoundingClientRect` will trigger a paint. This is awful for the performance of our app, especially if we're calling it on each of the many items in our grid. The way this is solved in several libraries is by knowing the dimensions of each of the elements so that the visibility of each can be calculated quickly. However, if your elements aren't of a fixed size then you're out of luck.

This is a great place for the IntersectionObserver API to help us out. It provides a way of observing _changes in the intersection of a target element with another (ancestor) element or the viewport_. It's used like this:

```jsx
const observer = new IntersectionObserver((entries, observer) => {
  entries.forEach(/* do something */)
})

observer.observe(someDOMNode)
```

So some function can be called every time any of the targets meets the specified threshold. The callback is passed an array of `IntersectionObserverEntry` objects. Each of these has several useful properties, with the most interesting being the `entry.isIntersecting` property. This is pretty self explanatory I think.

Here's a basic class that keeps references to each item in the grid:

```jsx
class Grid extends React.PureComponent {
  state = { items: makeItems(1000) }

  render() {
    return (
      <div>
        {this.state.items.map(this.renderItem)}
      </div>
    )
  }

  // arrow function for binding 'this'
  renderItem = (item, i) => {
    return (
      <div key={i} ref={el => this[`item_${i}`] = el}>
        {item.visible ? 'visible' : 'invisible'}
      </div>
    )
  }

  ...
} 
```

After this has mounted, we should loop over each of the items and `observer.observe` them:

```jsx
class Grid extends React.PureComponent {
  ...
  componentDidMount() {
    if (!('IntersectionObserver' in window)) return;

    this.observer = new IntersectionObserver(this.handleEnter);
    for (let i = 0; i < this.state.items.length; i++) {
      this.observer.observe(this[`item_${i}`]);
    }
  }

  handleEnter(entries) {
    const newItems = [];
    entries.forEach((entry, i) => {
      newItems.push({ visible: entry.isIntersecting })
    })
    this.setState({ items: newItems });
  }
}
```
