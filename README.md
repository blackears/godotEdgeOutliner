# Edge Outliner

This is a shader that will add outlines to your scene.  It will work in Godot 4.0 and higher.  Since it requires access to the viewport normal buffer, it also requires Forward+ mode to work.

![Dinosaur with black outline](/doc/dino_outline_black.jpg)
![Rabbit with white outline](/doc/rabbit_outline_white.jpg)

## Setup

Copy the `res://shaders/edge_detector_sobel.gdshader` shader into your project.  Then add a `MeshInstance3D` to your scene and add a `QuadMesh` mesh to it.  

![Setup: adding the quad mesh](/doc/setup_add_quad_mesh.jpg)

Then open the `GeometryInstance3D/Geometry` subsection and add a new ShaderMaterial.  Finally, click the `Shader` dropdown and QuickLoad the `edge_detector_sobel.gdshader`.

![Setup: setting the shader material](/doc/setup_shader_material.jpg)


## Usage

When you first set up your shader, the defaults will have it displaying as a sort of 'magic window' that adds outlines to everything when you look through it.  You can use it this way if this is the effect you want, and even apply this shader to any 'window' you want to have this outline effect.

![Usage: outline window](/doc/usage_outline_window.jpg)

If you want to use it as an overlay instead, click the `Map Quad to Viewport` option.  This is meant to work with Godot's default QuadMesh and will alter its vertices to fill the viewport.  If you do this, also make sure to set the MeshIntance3D's Custom AABB to something that will enclose the entire scene area - otherwise the shader will automatically turn off whenever the quad mesh goes outside of the range of the camera.

![Usage: viewport window](/doc/usage_viewport_window.jpg)






