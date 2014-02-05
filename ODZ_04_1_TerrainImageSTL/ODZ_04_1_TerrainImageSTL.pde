/**
 * onedotzero 2011 workshop exercise:
 * Image terrain
 *
 * This example is a variation of the ODZ_04_TerrainImage
 * exercise customized for digital fabrication purposes.
 * It introduces several new parameters to define the physical
 * size of the terrain and exports it as STL model ready
 * for fabrication on CNC or 3D printing equipment.
 * Additionally, it introduces the Laplacian Smooth mesh filter
 * which is used to smoothen out some of the potentially
 * harsh slopes in the terrain.
 */
 
/* 
 * Copyright (c) 2011 Karsten Schmidt and workshop crew
 * 
 * This software is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * http://creativecommons.org/licenses/LGPL/2.1/
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public
 * License along with this software; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

import processing.opengl.*;
import toxi.geom.*;
import toxi.geom.mesh.*;
import toxi.processing.*;

// terrain resolution
int RES=100;

// physical terrain size in mm
int TOTAL_WIDTH = 250;
int TOTAL_HEIGHT = 40;
// height of plinth below sea level (elevation=0)
int BASE_HEIGHT = 10;

// compute cell size and scale
float CELL_SIZE = (float)TOTAL_WIDTH/RES;
float ELEVATION_SCALE = (float)(TOTAL_HEIGHT-BASE_HEIGHT)/255;

// mesh container
WETriangleMesh mesh;
// helper class for rendering mesh
ToxiclibsSupport gfx;

PImage img;

void setup() {
  size(1280, 720, OPENGL);
  // load an image from the sketch data folder
  img=loadImage("test.jpg");
  // resize image to terrain size
  img.resize(RES, RES);
  // create terrain
  Terrain terrain = new Terrain(RES, RES, CELL_SIZE);
  // create array to store elevation data
  // both the image's pixels and elevation data are
  // defined as 1D data structures but store
  // as many elements as there are pixels in the image
  float[] el = new float[RES*RES];
  // iterate over all pixels in the image
  // each array has a length property storing its size
  for (int i=0; i<img.pixels.length; i++) {
    // we use the brightness of each pixel
    // as a metric for elevation
    // (however damped down to avoid crazy spikes)
    el[i] = brightness(img.pixels[i])*ELEVATION_SCALE;
  }
  // now populate the terrain with this elevation data
  terrain.setElevation(el);
  // then convert the terrain into a triangle mesh
  mesh = new WETriangleMesh();
  terrain.toMesh(mesh,-BASE_HEIGHT);
  // the laplacian smooth is an operation to smoothen out
  // differences between the mesh vertices
  // the 1 parameter means it should only be applied once
  new LaplacianSmooth().filter(mesh,1);
  // construct filename based on terrain dimensions
  String fileName="terrain-"+TOTAL_WIDTH+"x"+TOTAL_WIDTH+"x"+TOTAL_HEIGHT+"mm.stl";
  // save mesh in STL format in sketch folder
  mesh.saveAsSTL(sketchPath(fileName));
  // attach drawing utils
  gfx = new ToxiclibsSupport(this);
}

void draw() {
  background(0);
  // display the image in the top-left corner
  image(img,0,0);
  // turn on lighting to better observe the terrain features
  lights();
  // switch to 3d coordinate system with its origin
  // at the centre of the screen
  translate(width/2, height/2, 0);
  // use mouse position to rotate the coordinate system
  // around the X and Y axis
  // note: mouseX is linked to rotation around Y
  //       mouseY is linked to rotation around X
  rotateX(mouseY*0.01);
  rotateY(mouseX*0.01);
  // turn off wireframe/outline
  noStroke();
  // draw the mesh
  gfx.mesh(mesh);
}

