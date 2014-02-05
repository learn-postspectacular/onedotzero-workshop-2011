/**
 * onedotzero 2011 workshop exercise:
 * Visualize the frequency spectrum of an audio signal
 * in 2.5D using a staggered list of line strips.
 * Each vertex is HSB color mapped based on its elevation
 * which in turn is mapped on the intensity of the strip's
 * related frequency band in the spectrum.
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
float HUE_SCALE=0.01;
// hue offset (basically hue at elevation=0)
float HUE_OFFSET=0.0;

// audio related datatypes
Minim audio;
AudioPlayer player;
FFT fft;

// a list to hold our line strips
ArrayList<LineStrip2D> strips=new ArrayList<LineStrip2D>();

// helper class for drawing
ToxiclibsSupport gfx;

void setup() {
  size(1280, 720, OPENGL);
  gfx=new ToxiclibsSupport(this);

  enableVSync();
  
  // setup audio
  audio=new Minim(this);
  player = audio.loadFile("groove.mp3", 512);
  player.loop();
  // FFT = Fast Fourier Transformation
  // turns wave form into frequency spectrum
  fft = new FFT(player.bufferSize(), player.sampleRate());

  // initialize line strips
  initStrips();
}

void draw() {
  background(0);
  strokeWeight(3);
  noFill();

  // switch to HSB colors in 0.0 ... 1.0 interval
  colorMode(HSB, 1.0);

  // transform current wave form into frequency spectrum
  fft.forward(player.mix);

  // how many frequency bands per strip
  float stripsToBandsRatio=(float)fft.specSize()/strips.size();

  // shift all points within strip to the left
  // by copying the Y coordinates of each point
  // to the one on its left (start at 2nd point, i=1)
  for (int i=0; i<strips.size(); i++) {
    LineStrip2D strip = strips.get(i);
    List<Vec2D> verts=strip.getVertices();
    for (int j=1; j<NUM_POINTS; j++) {
      verts.get(j-1).y=verts.get(j).y;
    }

    // compute base Y position for each strip
    float baseY=height/4+i*GAP;
    // get the energy of the strip's related frequency band
    float freq=fft.getBand((int)(i*stripsToBandsRatio));
    // update the Y coordinate of the last point in each strip
    verts.get(NUM_POINTS-1).y=baseY-freq*ELEVATION_SCALE;

    // iterate over all points within each strip
    // and map elevation to color hue, draw as line strip
    beginShape();
    for (Vec2D p : strip) {
      // compute elevation of each point
      float elevation=p.y-baseY;
      // map elevation to hue
      stroke(-elevation*HUE_SCALE+HUE_OFFSET, 1.0, 1.0);
      vertex(p.x, p.y);
    }
    endShape();
  }
}

void initStrips() {
  // first compute horizontal spacing between points
  float scaleF=(float)width/(NUM_POINTS-1);
  // now use double nested loop to create all strips...
  for (int j=0; j<NUM_STRIPS; j++) {
    LineStrip2D strip=new LineStrip2D();
    for (int i=0; i<NUM_POINTS; i++) {
      strip.add(new Vec2D(i*scaleF, height/2));
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
