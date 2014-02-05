// initialize line strips
// this function is called once from setup() and
// everytime the user changes the number of strips
void initStrips() {
  // first clear any strips we might have already
  strips.clear();

  // now use double nested loop to create all strips...
  // since we are now displaying only the terrain
  // we only actually use the Y coordinates of all the
  // points in the line strips...
  // therefore we could get rid of all the offset and scale values
  // used in previous examples
  for (int j=0; j<numStrips; j++) {
    LineStrip3D strip=new LineStrip3D();
    for (int i=0; i<numPoints; i++) {
      strip.add(new Vec3D(i, 0, j));
    }
    strips.add(strip);
  }
}

// this function is called from the draw() function
// and is responsible for the scrolling of elevation values
// through the strips and populating the last column with
// new frequency/elevation values
void updateStrips() {
  // compute how many frequency bands are skipped per strip
  // also take into account the coverage setting defined above
  float stripsToBandsRatio=(float)fft.specSize()/strips.size()*spectrumCoverage;

  // shift all points within strip
  // by copying the Y coordinates of each point
  // to the previous point (start at 2nd point within each strip, j=1)
  for (int i=0; i<numStrips; i++) {
    // get the list of points (vertices) for the strip currently processed
    List<Vec3D> vertices=strips.get(i).getVertices();
    for (int j=1; j<numPoints; j++) {
      vertices.get(j-1).y=vertices.get(j).y;
    }

    // get the energy of the strip's related frequency band
    // and turn it into an elevation using the current elevationScale value
    float elevation=fft.getBand((int)(i*stripsToBandsRatio))*elevationScale;
    // update the Y coordinate of the last point in each strip
    vertices.get(numPoints-1).y=elevation;
  }
}

