// initialize terrain & mesh
// this function is called once from setup() and
// everytime the user changes the number of strips
void initTerrain() {
  // create an empty mesh container
  mesh=new TriangleMesh();
  // create an array for the elevation values
  el=new float[numStrips*numPoints];
  // create the terrain structure using the
  // current number of points, strips & cell size
  terrain=new Terrain(numPoints, numStrips, cellSize);
}

// this function is called from the draw() function
// and is responsible for computing the new state
// of the terrain and eventually convert it into a
// renderable triangle mesh
void updateTerrain() {
  // the following nested loops turn the 2D setup
  // of line strips and points (within each strip)
  // into a 1D array of elevations.
  // this is in principle much like working with pixels
  // of an bitmap image. we're using the index variable
  // to increase its value for every point processed
  int index=0;
  // for each strip in the list of strips...
  for (LineStrip3D strip : strips) {
    // process all points within each strip
    for (Vec3D v : strip.getVertices()) {
      // elevation of each point is its Y value
      el[index++]=v.y;
    }
  }
  // at this point we have a fully populated array
  // of elevation data
  
  // now clear the previous mesh
  mesh.clear();
  // set the new new elevations
  terrain.setElevation(el);
  // convert the terrain into an actual mesh
  terrain.toMesh(mesh);

  // finally compute the normal vectors for all of the
  // mesh's faces (triangles) and vertices (points).
  // conceptually, normal vectors are standing perpendicular
  // on top of each triangle/vertex and are used to compute
  // how much light can hit each element
  mesh.computeFaceNormals();
  mesh.computeVertexNormals();
}

