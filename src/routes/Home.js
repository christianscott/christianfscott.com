import React from "react";
import Grid from "../components/Grid/Grid.js";
import GridItem from "../components/GridItem/GridItem.js";

const Home = ({ entries }) =>
  <Grid>
    {entries.map((entry, i) =>
      <GridItem key={i} {...entry} />
    )}
  </Grid>

export default Home;
