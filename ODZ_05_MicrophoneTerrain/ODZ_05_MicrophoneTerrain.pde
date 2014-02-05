/**
 * onedotzero 2011 workshop final exercise:
 * Frequency terrain
 *
 * Using the microphone audio input, this example produces
 * a frequency spectrum and displays it as a scrolling 3D terrain.
 * A simple user interface is provided to interactively
 * change various display parameters and allow the user to export
 * the current image and terrain mesh.
 *
 * Usage:
 * 
 * - Hold down Shift + drag mouse to rotate view
 * - Use GUI controllers to adjust other parameters
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

import controlP5.*;

import processing.opengl.*;

import ddf.minim.*;
import ddf.minim.analysis.*;

import toxi.geom.*;
import toxi.geom.mesh.*;
import toxi.processing.*;
import toxi.util.*;

/*************************************************************
 * GLOBAL VISUALIZATION PARAMETERS
 *
 * some of these will be adjustable in realtime via the
 * user interface elements defined in the initGUI() function
 *************************************************************/

// number of strips (frequency bands)
int numStrips = 60;
// number of points per strip
// in other words it's the length of history/timewindow to keep
int numPoints = 60;
// vertical gap between strips
int GAP = 10;

// since very high frequencies usually only have a marginal
// impact on the overall spectrum we can define a
// percentage amount to only visualize the lower
// (more interesting) frequency bands...
// 0.5 here means the lower 50% (with 1.0 = 100%) of the spectrum
float spectrumCoverage=0.5;

// scale factor for elevation
float elevationScale=15;

// the cell size is the number of world units
// a single terrain cell will occupy
int cellSize=10;

// color values used for displaying the mesh
// use a pale yellow as default colour
float colRed=255;
float colGreen=255;
float colBlue=192;

// a flag to indicate we want to export the current frame as image/screenshot
boolean doExportImage;

// a flag to indicate we want to export the current mesh as 3D model
// this model can then be imported into most 3D applications
boolean doExportMesh;

// a flag to indicate if user is currently pressing the Shift key
// we are using this to update the 3D rotation only when this the case
// in order to avoid confusion when using the GUI elements
// (this is an additional feature we didn't manage in time during the workshop)
// see keyPressed() function for more information
boolean isShiftDown;

// 3D rotation settings (rotation angles)
// the function using these values expects them to be
// in units of radians (PI).
// we use the radians() function to convert them from degrees (0...360)
// these 2 initial values define the default perspective
float rotationX=radians(160);
float rotationY=radians(245);

/*************************************************************
 * GLOBAL DATA STRUCTURES AND LIBRARY REFERENCES
 *************************************************************/

// a list to hold our line strips
// this list can ONLY store LineStrip3D instances
ArrayList<LineStrip3D> strips=new ArrayList<LineStrip3D>();

// helper class for drawing toxiclibs geometry elements
ToxiclibsSupport gfx;

// reference to the user interface library
ControlP5 gui;

// audio related datatypes
Minim audio;
AudioInput in;
FFT fft;

// terrain & mesh related variables
Terrain terrain;
TriangleMesh mesh;
float[] el;

// the setup() function is only exectuted ONCE when our sketch
// is starting up. in order to keep the code short & simple
// it delegates various steps to smaller helper functions only
// dealing with individual aspects of the larger initialization tasks
// these functions are defined in the other editor tabs (see above)
void setup() {
  size(1280, 720, OPENGL);
  // disable "tearing" effect (as requested by James :)
  enableVSync();
  
  // connect the rendering helper library to our sketch
  gfx=new ToxiclibsSupport(this);
  // initialize audio
  initAudio();
  // initialize line strips
  initStrips();
  // initialize terrain & mesh
  initTerrain();
  // initialize user interface
  initGUI();
}

void draw() {
  background(0);
  // set the fill color use for rendering the mesh
  // based on the slider values of the GUI.
  // these variables are automatically changed whenever
  // the user manipulates their related sliders
  fill(colRed, colGreen, colBlue);
  // turn on lighting
  lights();
  // disable wireframe/outlines
  noStroke();
  
  // switch to 3D coordinate system
  // with the new origin at the centre of screen
  translate(width/2, height/2, 0);
  
  // if user is holding down the Shift key AND (&&) the mouse button
  // is pressed, then update 3D rotation based on mouse position
  if (isShiftDown && mousePressed) {
    rotationX=mouseY*0.01;
    rotationY=mouseX*0.01;
  }
  
  // apply current rotation angles
  rotateX(rotationX);
  rotateY(rotationY);
  
  // FFT = Fast-Fourier Transformation
  // http://en.wikipedia.org/wiki/Fast_Fourier_Transformation
  // computes the frequency spectrum of the current chunk of the audio signal.
  // in our case that chunk is only approx. 11 milliseconds long:
  // 512 samples of 44100 samples per second ~= 11ms
  // the process creates a spectrum of 256 different frequency bands
  // each band/slot gives us an indication of how much this individual frequency
  // contributes to the current audio signal.
  // if the audio signal would only contain a single frequency, only one
  // of these slots would have a value > 0 with all others remaining at 0.
  // however, this is NEVER the case for non-synthetic audio.
  fft.forward(in.mix);

  // update line strips based on new spectrum data
  // (moved to its own function for clarity)
  updateStrips();

  // now update elevation data & terrain based on new line strips
  // also computes the new result mesh
  updateTerrain();

  // this rendering hint is only needed because of our user interface
  // it turns on depth testing which is needed to correctly display 3d geometry
  // on a 2D screen. (see also comments further below)
  hint(ENABLE_DEPTH_TEST);
  // now draw the resulting terrain mesh
  // the "true" parameter means we want to use smooth shading
  // using the computed mesh vertex normals
  // (see updateTerrain() function for more info)
  gfx.mesh(mesh, true);

  // reset the Processing coordinate system into a virgin 2D state:
  // origin is back in top-left corner and no rotations used
  // also temporarily disable depth testing so that the user interface elements
  // are always drawn on top of the 3D mesh
  camera();
  perspective();
  hint(DISABLE_DEPTH_TEST);

  // the doExportImage variable is a boolean value and can only be true or false.
  // if its value is true, we save the current frame as screenshot
  // in the sketch folder. each image will be saved with an unique filename
  // based on the current date & time.
  // we also immediately reset the export flag to avoid repeated exports
  if (doExportImage) {
    saveFrame("terrain-"+DateUtils.timeStamp()+".png");
    doExportImage=false;
  }
  
  // similar to exporting screenshots, this conditional checks if the
  // the user triggered mesh exporting and if so the current mesh will
  // be exported in OBJ format to the sketch folder
  // this mesh model can then be imported into most common 3D applications
  // if you'd want to get the mesh fabricated as physical model
  // use the mesh.saveAsSTL function instead to write the model in STL format
  // which is the industry standard for digital fabrication contexts
  if (doExportMesh) {
    mesh.saveAsOBJ(sketchPath("terrain-"+DateUtils.timeStamp()+".obj"));
    //mesh.saveAsSTL(sketchPath("terrain-"+DateUtils.timeStamp()+".obj"));
    doExportMesh=false;
  }
}

// this (optional) function is being exectuted by Processing
// everytime a key has been pressed
// we use conditionals to check which key it was and do
// specific things we want to have changed in our sketch
void keyPressed() {
  // pressing Space will trigger image export
  if (key==' ') {
    triggerImageExport();
  }
  // pressing the x key will trigger mesh export
  if (key=='x') {
    triggerMeshExport();
  }
  // here we check if the user pressed shift and
  // we keep track of this in its dedicated variable
  // for use in the draw() function to update the
  // camera rotation
  if (key == CODED && keyCode==SHIFT) {
    isShiftDown=true;
  }
}

// just like keyPressed() this function is executed
// the moment a key has been released again
// here we only care about the shift key being
// released again so that we can clear the related flag
void keyReleased() {
  if (key == CODED && keyCode==SHIFT) {
    isShiftDown=false;
  }
}

// configures OpenGL to synchronize the frame
// drawing with the actual screen updates on the hardware side
// (this should be done automatically by Processing, but isn't...)
void enableVSync() {
  PGraphicsOpenGL pgl = (PGraphicsOpenGL) g;
  javax.media.opengl.GL gl = pgl.beginGL();
  gl.setSwapInterval(1);
  pgl.endGL();
}
