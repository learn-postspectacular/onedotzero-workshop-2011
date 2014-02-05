/**
 * onedotzero 2011 workshop exercise:
 * Image terrain
 *
 * This example was used an introduction to the Terrain
 * TriangleMesh classes as well as to the concept of
 * representing a 2D image as 1D data structure (array).
 * The example loads an image and transforms it into a
 * 3D terrain mesh.
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

// mesh container
TriangleMesh mesh;
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
  Terrain terrain = new Terrain(RES, RES, 5);
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
    el[i] = brightness(img.pixels[i])*0.25;
  }
  // now populate the terrain with this elevation data
  terrain.setElevation(el);
  // then convert the terrain into a triangle mesh
  mesh = new TriangleMesh();
  terrain.toMesh(mesh);
  // flip mesh along X axis
  // to compensate for upside-down coordinate system
  mesh.scale(-1,1,1);
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

