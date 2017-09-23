import React, { Component } from "react";
import { Switch, Route } from "react-router-dom";
import Article from "./components/Article/Article";
import Home from "./routes/Home";
import "./App.css";

const entries = [
  {
    title: "Postie",
    body: "A postfix calculator written in python",
    link: "/articles/2017/postie",
    linkText: "Read the article →",
    time: "23 Sep 2017 at 23:42",
    mdFile: "/articles/2017/postie.md",
    color: "#EDC8CA"
  },
  {
    title: "Virtualized Grid using ReactJS",
    body: "Efficient scrolling using the new IntersectionObserver API",
    link: "/articles/2017/virtualized",
    linkText: "Read the article →",
    time: "12 Sep 2017 at 17:00",
    mdFile: "/articles/2017/virtualized.md",
    color: "#E7EFF6"
  },
  {
    title: "200 Women",
    body:
      "Site for the 200 Women project. Hosted on S3 with cloudfront, build using ReactJS.",
    link: "http://www.twohundredwomen.com",
    linkText: "See the site →",
    time: "1 Sep 2017 at 12:00",
    color: "#EDEBC8",
    external: true
  }
];

const Heading = () => (
  <h1 className="Heading">
    <span className="Heading--bold">Christian Scott </span>
    is a developer and student in Auckland, New Zealand
  </h1>
);

class App extends Component {
  render() {
    return (
      <div className="Page">
        <Heading />
        <p className="Page__body">
          I'm currently studying at the University of Auckland, set to graduate
          in the middle of 2018. You can see some of my work on{" "}
          <a href="https://github.com/chrfrasco" rel="external">
            github
          </a>{" "}
          or send me an <a href="mailto:christianfscott@gmail.com">email</a>.
        </p>

        <Switch>
          <Route exact path="/" component={() => <Home entries={entries} />} />

          {entries
            .filter(entry => !entry.external)
            .map((entry, i) => (
              <Route
                exact
                path={entry.link}
                key={i}
                component={() => <Article {...entry} />}
              />
            ))}
          <Route render={() => <h2>That's not a route :(</h2>} />
        </Switch>
      </div>
    );
  }
}

export default App;
