import React from "react"
import { rhythm } from "../utils/typography"

function Bio() {
  return (
    <div
      style={{
        display: `flex`,
        marginBottom: rhythm(2.5),
      }}
    >
      <p>
        I currently work as a frontend software engineer at{" "}
        <a href="https://canva.com">Canva</a> in Sydney, Australia. You can see
        some of my work on{" "}
        <a href="https://github.com/christianscott">github</a>, find me on{" "}
        <a href="https://www.linkedin.com/in/christian-scott-939a0811a/">
          linkedin
        </a>
        , or send me an <a href="mailto:hello@christianfscott.com">email</a>.
      </p>
    </div>
  )
}

export default Bio
