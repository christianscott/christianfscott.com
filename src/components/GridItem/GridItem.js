import React from "react";
import { Link } from "react-router-dom";
import Time from "../../components/Time/Time";
import "./GridItem.css";

const GridItem = ({ title, body, link, linkText, time, color, external }) => (
  <div className="GridItem" style={{ backgroundColor: color }}>
    <Time>{time}</Time>
    <h1>{title}</h1>
    <p>{body}</p>
    {external ? (
      <a href={link} rel="external">
        {linkText}
      </a>
    ) : (
      <Link to={link}>{linkText}</Link>
    )}
  </div>
);

export default GridItem;
