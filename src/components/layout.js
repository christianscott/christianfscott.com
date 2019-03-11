import React from "react"
import { Link } from "gatsby"

import { rhythm, scale } from "../utils/typography"

const RootHeader = ({ title }) => (
  <h1
    style={{
      ...scale(1.5),
      marginBottom: rhythm(1.5),
      marginTop: 0,
    }}
  >
    <Link
      style={{
        boxShadow: `none`,
        textDecoration: `none`,
        color: `inherit`,
      }}
      to={`/`}
    >
      {title}
    </Link>
  </h1>
)

const Header = ({ title }) => (
  <h3
    style={{
      marginTop: 0,
    }}
  >
    <Link
      style={{
        boxShadow: `none`,
        textDecoration: `none`,
        color: `inherit`,
      }}
      to={`/`}
    >
      {title}
    </Link>
  </h3>
)

class Layout extends React.Component {
  render() {
    const { location, title, children } = this.props
    const rootPath = `${__PATH_PREFIX__}/`

    return (
      <div
        style={{
          marginLeft: `auto`,
          marginRight: `auto`,
          maxWidth: rhythm(28),
          padding: `${rhythm(1.5)} ${rhythm(3 / 4)}`,
        }}
      >
        <header>
          {location.pathname === rootPath ? (
            <RootHeader title={title} />
          ) : (
            <Header title={title} />
          )}
        </header>
        <main>{children}</main>
      </div>
    )
  }
}

export default Layout
