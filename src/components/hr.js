import React from "react"
import "./hr.css"

export const Hr = () => (
  <hr
    className="wiggle"
    style={{
      border: "none",
      height: 6,
      background: "currentColor",
      opacity: 0.75,
      margin: "2em 0",
    }}
  />
)
