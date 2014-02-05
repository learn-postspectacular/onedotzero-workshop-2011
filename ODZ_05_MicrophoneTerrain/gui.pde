void initGUI() {
  // create an instance of the user interface library
  // and connect it to our sketch
  gui = new ControlP5(this);

  // now create various controllers
  // the controller names must match existing parameters/variables
  // in our sketch

  // RGB color sliders
  // parameters for sliders are (in order):
  // name, min, max, x, y, width, height
  gui.addSlider("colRed", 0, 255, 50, 50, 100, 20).setLabel("red");
  gui.addSlider("colGreen", 0, 255, 50, 80, 100, 20).setLabel("green");
  gui.addSlider("colBlue", 0, 255, 50, 110, 100, 20).setLabel("blue");

  // terrain settings
  gui.addSlider("cellSize", 1, 100, 50, 160, 100, 20).setLabel("terrain cell size");
  gui.addSlider("elevationScale", 0, 50, 50, 190, 100, 20).setLabel("elevation scale");

  // line strip configuration
  gui.addSlider("numStrips", 10, 100, 50, 240, 100, 20).setLabel("number of strips");
  gui.addSlider("numPoints", 10, 100, 50, 270, 100, 20).setLabel("number of points");
  
  // export buttons
  // IMPORTANT: the names of these 2 controllers are NOT variable names
  // but names of functions (defined below)
  // the logic is the same however: if these buttons are pressed
  // the ControlP5 library will attempt to find a variable or function with this
  // name in our sketch and manipulate its value (variable) or execute it (function)
  // in this case, it's the latter...
  gui.addBang("triggerImageExport", 50, 320, 50, 50).setLabel("export image");
  gui.addBang("triggerMeshExport", 120, 320, 50, 50).setLabel("export mesh");
}

// this is an optional support function used by the 
// ControlP5 library to allow us to participate directly in any
// user interaction with ANY user interface element/controller.
// this function is executed everytime ANY of the controllers has
// been interacted with. because we only need this feature for
// two of the controllers, we need to first identify which controller
// has been triggered by the user and then take the appropriate actions
void controlEvent(ControlEvent e) {
  // the ControlEvent stores all necessary information about the
  // user interaction just happened.
  // here we only need to ask for the controller's name
  String name=e.controller().name();
  // if the number of strips or number of points has been changed
  // we need to re-create both the line strip & terrain setup using the new value
  // the || operator means OR: If one of the two name comparisons
  // produces a positive outcome (true) then the entire
  // conditional check becomes true
  if (name.equals("numStrips") || name.equals("numPoints")) {
    initStrips();
    initTerrain();
  }
  // if the user has changed the cellSize, we only need to
  // update the setting in the terrain
  if (name.equals("cellSize")) {
    terrain.setScale(cellSize);
  }
}

// this function is called whenever the user clicks
// the "export image" button or pressed Spacebar.
// the doExportImage flag is checked every frame from the draw() function
void triggerImageExport() {
  doExportImage=true;
}

// this function is called whenever the user clicks
// the "export mesh" button or pressed Spacebar.
// the doExportMesh flag is checked every frame from the draw() function
void triggerMeshExport() {
  doExportMesh=true;
}
