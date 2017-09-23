import React from "react";
import { Link } from "react-router-dom";
import Markdown from "react-markdown";
import Time from "../../components/Time/Time";
import "./Article.css";

export default class Article extends React.PureComponent {
  state = { loaded: false };

  componentDidMount() {
    fetch(this.props.mdFile)
      .then(res => res.text())
      .then(md => this.setState({ md, loaded: true }))
      .catch(console.error);
  }

  render() {
    const { title, time } = this.props;
    return ( 
      <article className="Article">
        <Link to="/">← Go Home</Link>
        <h2>{title}</h2>

        <Time>posted {time}</Time>

        {this.state.loaded && <Markdown source={this.state.md} />}
      </article>
    );
  }
};
