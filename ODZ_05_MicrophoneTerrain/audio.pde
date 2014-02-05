void initAudio() {
  // setup audio library
  // this = a special variable referring to the current sketch (our main program)
  audio=new Minim(this);
  // open an audio stream from the default audio input
  // we want stereo and a buffer of 512 samples
  // (buffer size needs to be a power of 2 -> 2^9 = 512)
  in = audio.getLineIn(Minim.STEREO, 512);

  // FFT = Fast Fourier Transformation
  // turns wave form into frequency spectrum
  // (see other comments in draw() function)
  fft = new FFT(in.bufferSize(), in.sampleRate());
}

