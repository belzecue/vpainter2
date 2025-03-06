![image](https://github.com/user-attachments/assets/9c588249-d982-4a47-9168-664873a481f9)

# Vpainter
Vertex painter for Godot 4.3 and 4.4
Based on Vpainter v0.5 by https://github.com/tomankirilov/VPainter
and v1.0 by https://github.com/nx7r/Vpainter

## Installation instructions
1. Copy addons folder into your project folder.
2. Open the project settings and activate the plugin in Plugins section.
3. Open test scene or import your own mesh and drag it into a 3d scene.
4. Select the mesh in the scene inspector and press Vpainter button on the top panel.

Things to note:
The button only appears when a valid mesh is selected (type MeshInstance3D).
Plugin does not work with built-in meshes, only with imported from outside. However the built-in meshes can be exported and reimported back as a resource, for painting. Basically any mesh needs to go through Godot's mesh importer for the plugin to work.

## Hotkeys
`Ctrl` - switches subtract mode. Useful for easy paint/erase switching.

`[ ]` - Changes brush size with increments of 0.05. Can be adjusted in the script.

`'\` - Changes brush hardness/softness. Might be different on your keybord depending on your region, but these keys are right under square brackets `[ ]`

More information for tools and features will come later. Any critical bugs - open an issue case.

## Usage
![image](https://github.com/user-attachments/assets/929d4f3d-52b2-4c4d-a849-ea56cad85463)

By default the tool will save all changes into the original resource when the scene is saved. If you have multiple identical meshes that you want to paint differently you need to select the mesh and press Local Copy. This copy will be local to that particular scene and the original resource will not be affected.


![image](https://github.com/user-attachments/assets/7a2391d9-ea87-4374-a1e5-602ba8e0c28c)

Tools are standard: 
1. Brush tool - select the color you need and start painting. If your mesh doesn't have any vertex colors on import, plugin automatically sets black color as a base.
2. Color picker - picks the color and alpha from the mesh. If you're using plugin for texture blending - very useful to pick exactly the kind of blending you need and spread it around the mesh with the brush.
3. Displace tool - adjusts the position of vertices, useful if you're painting something similar to snow or sand on top of a surface and want to give that some thickness (use carefully and with light hardness).
4. Bucket tool - Fills the mesh with chosen color. Set light opacity to fill gradually.


![image](https://github.com/user-attachments/assets/6f1805f4-6a64-4338-bbe9-44edf1d380de)

Color channels. Handy to set pure color channels for texture blending. W is white, which is just RGBA set to 1.0. If you want to paint only alpha channel, check it and press `Ctrl` to surtract alpha from the mesh, by default the alpha is set to 1.0. For the precise color you need use color picker.


![image](https://github.com/user-attachments/assets/e5c59c0b-a387-41f8-ac68-ee9979e971a9)

Pressure settings are useful only to tablet users. Make sure to enable the correct driver in `Project settings > Pen Tablet` section for pressure to work. If you can't find that setting enble Advanced settings.


![image](https://github.com/user-attachments/assets/8b93f701-78c2-4ad2-8657-b14593a7faf7)

The plugin currently only has single undo feature. It is fake and doesn't use the editors undo manager, but instead saves current state of the mesh into a variable and sets it back if needed. Useful if you made a mistake such as filling the mesh with color you didn't want, or displacing the vertices to much.

## Troubleshooting
If you see UID warnings in the output. Disable the plugin in the Project settings, Save All Scenes and Reload current project. 

If you don't see Alpha on your mesh double check that you have transparency enabled in the material.

If the color you paint doesn't look like the color you choose in the color picker, make sure you checked sRGB color space in the material's Vertex color section. In this case the colors painted are actully correct, they just displayed in a different color space. Does not affect texture blending.

Shaders provided with the plugin were not made or tested by me for compatibility with this version of the plugin.

There might be some non critical errors as well. 
