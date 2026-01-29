// Macbear3D engine
import '../../macbear_3d.dart';

import '../shaders_gen/Rect.es2.frag.g.dart';
import '../shaders_gen/Rect.es2.vert.g.dart';
import '../shaders_gen/Simple.es2.frag.g.dart';
import '../shaders_gen/Simple.es2.vert.g.dart';
import '../shaders_gen/SimpleLighting.es2.vert.g.dart';
import '../shaders_gen/Skinning.es2.vert.g.dart';
import '../shaders_gen/Skybox.es2.frag.g.dart';
import '../shaders_gen/Skybox.es2.vert.g.dart';
import '../shaders_gen/SkyboxReflect.es2.vert.g.dart';
import '../shaders_gen/TexturedLighting.es2.frag.g.dart';
import '../shaders_gen/TexturedLighting.es2.vert.g.dart';

class M3Resources {
  // ------------------------------
  // Textures
  // ------------------------------
  static final texWhite = M3Texture.createSolidColor(Vector4(1, 1, 1, 1));

  // ------------------------------
  // Geometries: debug
  // ------------------------------
  static final debugAxis = M3DebugAxisGeom(size: 0.5);
  static final debugSphere = M3DebugSphereGeom(radius: 1.0);
  static final debugFrustum = M3BoxGeom(2.0, 2.0, 2.0);
  static final debugDot = M3SphereGeom(0.1, widthSegments: 4, heightSegments: 2);
  static final debugView = M3PlaneGeom(1.6, 1.6, widthSegments: 5, heightSegments: 4);

  // ------------------------------
  // Unit geometries
  // ------------------------------
  static final unitCube = M3BoxGeom(1.0, 1.0, 1.0);
  static final unitSphere = M3SphereGeom(0.5);

  // ------------------------------
  // 2D shapes
  // ------------------------------
  // for dynamic draw: line, triangle
  static M3Shape2D? _line;
  static M3Shape2D? _triangle;

  // text2D from sprite, rectUnit for image
  static M3Text2D? _text2D;
  static M3Rectangle2D? _rectUnit;

  static M3Text2D get text2D {
    return _text2D!;
  }

  static M3Shape2D get line {
    _line ??= M3Shape2D(WebGL.LINES, 2)..createVBO(WebGL.DYNAMIC_DRAW);
    return _line!;
  }

  static M3Shape2D get triangle {
    _triangle ??= M3Shape2D(WebGL.TRIANGLES, 3)..createVBO(WebGL.DYNAMIC_DRAW);
    return _triangle!;
  }

  static M3Rectangle2D get rectUnit {
    _rectUnit ??= M3Rectangle2D()
      ..setRectangle(0, 0, 1, 1)
      ..createVBO(WebGL.STATIC_DRAW);
    return _rectUnit!;
  }

  // ------------------------------
  // Programs
  // ------------------------------
  static M3Program? programSimple;
  static M3Program? programSkybox;
  static M3Program? programRectangle;
  static M3ProgramEye? programSkyboxReflect;
  static M3ProgramLighting? programSimpleLighting;
  static M3ProgramLighting? programTexture;
  static M3ProgramShadowmap? programShadowmap;
  static M3ProgramShadowCSM? programShadowCSM;

  static final _skinNormal = "#define ENABLE_NORMAL \n$Skinning_es2_vert";

  static Future<void> init() async {
    // Textures
    texWhite;

    // Geometries
    debugAxis;
    debugSphere;
    debugFrustum;
    debugDot;
    debugView;

    unitCube;
    unitSphere;

    // 2D
    line;
    triangle;
    rectUnit;
    _text2D = await M3Text2D.createText2D(fontSize: 30);

    // Programs
    programSimple = M3Program(Skinning_es2_vert + Simple_es2_vert, Simple_es2_frag);
    programSkybox = M3Program(Skybox_es2_vert, Skybox_es2_frag);
    programRectangle = M3Program(Rect_es2_vert, Rect_es2_frag);

    programSkyboxReflect = M3ProgramEye(_skinNormal + SkyboxReflect_es2_vert, Skybox_es2_frag);
    programSimpleLighting = M3ProgramLighting(_skinNormal + SimpleLighting_es2_vert, Simple_es2_frag);

    setLightingProgram(M3ShaderOptions());

    debugPrint('+++ M3Resources init done+++');
  }

  static void setLightingProgram(M3ShaderOptions options) {
    programTexture?.dispose();
    programShadowmap?.dispose();
    programShadowCSM?.dispose();

    // texture lighting program
    String strVert = _skinNormal + TexturedLighting_es2_vert;
    String strFrag = TexturedLighting_es2_frag;
    // pixel lighting: phong shading, cartoon
    if (options.perPixel) {
      strVert = "#define ENABLE_PIXEL_LIGHTING \n$strVert";
      strFrag = "#define ENABLE_PIXEL_LIGHTING \n$strFrag";
      if (options.cartoon) {
        strFrag = "#define ENABLE_CARTOON \n$strFrag";
      }
    }
    programTexture = M3ProgramLighting(strVert, strFrag);

    // shadow map program
    String vsShadow = "#define ENABLE_SHADOW_MAP \n$strVert";
    String fsShadow = "#define ENABLE_SHADOW_MAP \n$strFrag";
    if (options.pcf) {
      fsShadow = "#define ENABLE_PCF \n$fsShadow";
    }
    programShadowmap = M3ProgramShadowmap(vsShadow, fsShadow);

    // shadow CSM program
    vsShadow = "#define ENABLE_SHADOW_CSM \n$strVert";
    fsShadow = "#define ENABLE_SHADOW_CSM \n$strFrag";
    if (options.pcf) {
      fsShadow = "#define ENABLE_PCF \n$fsShadow";
    }
    programShadowCSM = M3ProgramShadowCSM(vsShadow, fsShadow);
  }

  static void dispose() {
    // Textures
    texWhite.dispose();

    // Geometries
    debugAxis.dispose();
    debugSphere.dispose();
    debugFrustum.dispose();
    debugDot.dispose();
    debugView.dispose();

    unitCube.dispose();
    unitSphere.dispose();

    // 2D
    _line?.dispose();
    _triangle?.dispose();
    _rectUnit?.dispose();
    _text2D?.dispose();

    // Programs
    programSimple?.dispose();
    programSkybox?.dispose();
    programRectangle?.dispose();
    programSkyboxReflect?.dispose();
    programSimpleLighting?.dispose();

    programTexture?.dispose();
    programShadowmap?.dispose();
    programShadowCSM?.dispose();
  }
}
