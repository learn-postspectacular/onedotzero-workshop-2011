/**
 * onedotzero 2011 workshop exercise:
 * Visualize the frequency spectrum of an audio signal
 * in 3D using a "landscape" of line strips.
 * Each vertex is HSB color mapped based on its elevation
 * which in turn is mapped on the intensity of the strip's
 * related frequency band in the spectrum. We also added new
 * parameters to constrain the colour range to produce
 * slightly more directed aesthetics...
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

import ddf.minim.*;
import ddf.minim.analysis.*;

import toxi.geom.*;
import toxi.processing.*;

// number of strips
int NUM_STRIPS = 50;
// number of points per strip
int NUM_POINTS = 100;
// vertical gap between strips
int GAP = 10;

// scale factor for elevation
float ELEVATION_SCALE=10;
// scale factor for mapping elevation to hues
float HUE_SCALE=0.0025;
// hue offset (basically hue at elevation=0)
float HUE_OFFSET=0.5;

// audio related datatypes
Minim audio;
AudioInput in;
FFT fft;

// a list to hold our line strips
ArrayList<LineStrip3D> strips=new ArrayList<LineStrip3D>();

// helper class for drawing
ToxiclibsSupport gfx;

void setup() {
  size(1280, 720, OPENGL);
  enableVSync();
  
  gfx=new ToxiclibsSupport(this);
  
  // setup audio
  audio=new Minim(this);
  // open an audio stream from the default input
  in = audio.getLineIn(Minim.STEREO, 512);
  
  // FFT = Fast Fourier Transformation
  // turns wave form into frequency spectrum
  fft = new FFT(in.bufferSize(), in.sampleRate());

  // initialize line strips
  initStrips();
}

void draw() {
  background(0);
  strokeWeight(3);
  noFill();

  translate(width/2,height/2,0);
  rotateX(mouseY*0.01);
  rotateY(mouseX*0.01);
  
  // switch to HSB colors in 0.0 ... 1.0 interval
  colorMode(HSB, 1.0);

  // transform current wave form into frequency spectrum
  fft.forward(in.mix);

  // how many frequency bands per strip
  float stripsToBandsRatio=(float)fft.specSize()/strips.size();

  // shift all points within strip to the left
  // by copying the Y coordinates of each point
  // to the one on its left (start at 2nd point, i=1)
  for (int i=0; i<strips.size(); i++) {
    LineStrip3D strip = strips.get(i);
    List<Vec3D> verts=strip.getVertices();
    for (int j=1; j<NUM_POINTS; j++) {
      verts.get(j-1).y=verts.get(j).y;
    }

    // get the energy of the strip's related frequency band
    float elevation=fft.getBand((int)(i*stripsToBandsRatio))*ELEVATION_SCALE;
    // update the Y coordinate of the last point in each strip
    verts.get(NUM_POINTS-1).y=elevation;

    // iterate over all points within each strip
    // and map elevation to color hue, draw as line strip
    beginShape();
    for (Vec3D p : strip) {
      // map elevation to hue
      stroke(p.y*HUE_SCALE+HUE_OFFSET, 1.0, 1.0);
      vertex(p.x, p.y, p.z);
    }
    endShape();
  }
}

void initStrips() {
  // first compute horizontal spacing between points
  float scaleF=(float)width/(NUM_POINTS-1);
  
  Vec3D offset=new Vec3D(width/2,0,(NUM_STRIPS*GAP)/2);
  
  // now use double nested loop to create all strips...
  for (int j=0; j<NUM_STRIPS; j++) {
    LineStrip3D strip=new LineStrip3D();
    for (int i=0; i<NUM_POINTS; i++) {
      strip.add(new Vec3D(i*scaleF, 0, j*GAP).sub(offset));
    }
    strips.add(strip);
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
