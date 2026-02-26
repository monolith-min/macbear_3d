## 0.7.0

* Update:
  * **OpenGL ES 3.0 Support**: Upgraded unified shaders from ES2 to ES3 (GLSL 3.00 ES).
  * **ES2 Cleanup**: Moved legacy ES2 shaders to `shaders_discard` directory.
  * **Enhanced Rendering**: Enabled PBR and IBL by default in main examples for superior visual quality.

## 0.6.1

* Add:
  * **Support Web build**: Optimized for WebGL and Flutter Web integration.
  * **Live Demo**: Created automatic deployment to [GitHub Pages](https://macbearchen.github.io/macbear_3d/).

## 0.6.0

* Add:
  * **Terrain System**: Procedural terrain generation using Perlin Noise (`M3TerrainGeom`, `M3PerlinNoise`).
  * **PBR Shading**: Support for Physically Based Rendering (metallic, roughness) in `M3Material`.
  * **IBL (Image-Based Lighting)**: Environment-based realistic lighting using cubemaps.
  * **Shader Refactoring**: Modular shader architecture with unified pixel shader (`Pixel.es2.frag`).
  * **Web Support**: Fixed text rendering alignment and platform-specific WebGL constraints.
  * **Platform Abstraction**: Separated logic for Native and Web (`PlatformInfo`).
  * **GUI System**: Adopted Flutter Widgets for UI.

## 0.5.0

* Add:
  * **Reflection**: Added cubemap-based reflection (`renderReflection`).

## 0.4.0

* Add:
  * **Core Engine**: Refactored `updateRender` to use `delta` duration for precise physics and animation timing.
  * **Skinned Meshes**: Fixed world-space bounding box calculations and improved animation stability.
  * **Resource Management**: Improved handling of font assets and added loading state support.

## 0.3.0

* Add:
  * **Cascaded Shadow Maps (CSM)**: Support for multiple shadow cascades (up to 4) for high-quality shadows over large distances.
  * **Shadow Stability**: Implemented bounding sphere-based cascade calculation and texel snapping to eliminate shadow shimmering.
  * **Shadow Quality**: Improved shadow pass to use front-face (CCW) rendering to prevent edge light leakage.
  * **Dynamic Shadow Mode Switching**: Ability to switch between standard shadow mapping and CSM at runtime.
  * **Performance Optimizations**: Efficient shadow atlas management and reduced draw calls for shadows.

## 0.2.0

* Add: 
  * **Bounding Volumes**: Automatic AABB and Bounding Sphere calculation for all geometries.
  * **Resource Manager**: Centralized system for loading and caching assets (geometries, meshes, textures, fonts).
  * **Font Support**: TrueType (.ttf) and OpenType (.otf) font parsing.
  * **3D Text**: New `M3TextGeom` for generating 3D geometry from text strings.
  * **Render Stats**: Real-time monitoring of engine performance (FPS, vertices, triangles, draw calls).

## 0.1.1

* Add: 
  * UML diagram. https://open-vsx.org/vscode/item?itemName=jebbs.plantuml
  * screenshot images.

## 0.1.0

* Initial release of Macbear 3D engine.
* Features:
  * OpenGL ES support via flutter_angle.
  * Scene graph and entity component system.
  * 3D format support: glTF, OBJ.
  * Physics engine integration (Oimo).
  * Lighting, shadows, and texturing support.
  * Basic primitives and geometry builders.
