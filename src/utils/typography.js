import Typography from "typography"
import Github from "typography-theme-github"
import "typeface-karla";

Github.overrideThemeStyles = () => {
  return {
    h1: {
      borderBottom: "none",
    },
    h2: {
      borderBottom: "none",
    },
  }
}

delete Github.googleFonts

const typography = new Typography({
  ...Github,
  headerFontFamily: ["karla"],
  bodyFontFamily: ["karla"],
})

// Hot reload typography in development.
if (process.env.NODE_ENV !== `production`) {
  typography.injectStyles()
}

export default typography
export const rhythm = typography.rhythm
export const scale = typography.scale
