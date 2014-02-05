/**
 * onedotzero 2011 workshop exercise:
 * Display a scrolling audio wave as line strip.
 *
 * While there are easier ways to achieve this effect
 * in our case the use of LineStrip2D is used as basis
 * for the next phases/iterations of this mini project.
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

import toxi.geom.*;
import toxi.processing.*;

int NUM_POINTS = 100;

ToxiclibsSupport gfx;

// audio related datatypes
Minim audio;
AudioPlayer player;
LineStrip2D strip;

void setup() {
  size(1280, 720, OPENGL);
  enableVSync();
  
  gfx=new ToxiclibsSupport(this);
  // setup audio & load file
  audio=new Minim(this);
  player = audio.loadFile("groove.mp3", 512);
  player.loop();

  // initialize line strip
  initStrip();
}

void draw() {
  background(255, 255, 0);
  strokeWeight(3);

  // shift all points within strip to the left
  // by copying the Y coordinates of each point
  // to the one on its left (start at 2nd point, i=1)
  for (int i=1; i<NUM_POINTS; i++) {
    strip.getVertices().get(i-1).y=strip.getVertices().get(i).y;
  }

  // compute average volume in current audio time window/buffer
  // this is done by first summing all values and then dividing
  // by the size of the buffer...
  float avgVolume=0;
  for (int i=0; i<player.left.size(); i++) {
    avgVolume+=player.left.get(i);
  }
  avgVolume=avgVolume/player.left.size();
  
  // use average to define new Y position for the last point
  strip.getVertices().get(NUM_POINTS-1).y=avgVolume*10000+height/2;
  
  // all done, now draw everything...
  gfx.lineStrip2D(strip);
  for (Vec2D p : strip.getVertices()) {
    gfx.circle(p, 15);
  }
}

void initStrip() {
  strip=new LineStrip2D();
  // first compute horizontal spacing between points
  float scaleF=(float)width/(NUM_POINTS-1);
  // now add points to the strip
  for (int i=0; i<NUM_POINTS; i=i+1) {
    strip.add(new Vec2D(i*scaleF, height/2));
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
