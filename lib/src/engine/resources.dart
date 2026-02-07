// Macbear3D engine
import '../../macbear_3d.dart';

import '../shaders_gen/Rect.es2.frag.g.dart';
import '../shaders_gen/Rect.es2.vert.g.dart';
import '../shaders_gen/Simple.es2.frag.g.dart';
import '../shaders_gen/Simple.es2.vert.g.dart';
import '../shaders_gen/SimpleLighting.es2.vert.g.dart';
import '../shaders_gen/Skybox.es2.frag.g.dart';
import '../shaders_gen/Skybox.es2.vert.g.dart';
import '../shaders_gen/SkyboxReflect.es2.vert.g.dart';
import '../shaders_gen/TexturedLighting.es2.frag.g.dart';
import '../shaders_gen/TexturedLighting.es2.vert.g.dart';
// GLSL functions
import '../shaders_gen/glsl/Pixel.es2.frag.g.dart';
import '../shaders_gen/glsl/Skinning.es2.vert.g.dart';

class M3Resources {
  // ------------------------------
  // Textures
  // ------------------------------
  static final texWhite = M3Texture.createSolidColor(Vector4(1, 1, 1, 1));
  static final texNormal = M3Texture.createSolidColor(Vector4(0.5, 0.5, 1, 1));
  static final texDefaultCube = M3Texture.createDefaultIBLCube();

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

  // ignore: non_constant_identifier_names
  static final _SkinNormal_vert = "#define ENABLE_NORMAL \n$Skinning_vert";

  static Future<void> init() async {
    debugPrint('M3Resources: init starting...');
    // Textures
    texWhite;
    texNormal;
    texDefaultCube;
    debugPrint('M3Resources: basic textures initialized');

    // Geometries
    debugAxis;
    debugSphere;
    debugFrustum;
    debugDot;
    debugView;

    unitCube;
    unitSphere;
    debugPrint('M3Resources: unit geometries initialized');

    // 2D
    line;
    triangle;
    rectUnit;
    _text2D = await M3Text2D.createText2D(fontSize: 30);
    debugPrint('M3Resources: text2D initialized');

    // Programs
    debugPrint('M3Resources: initializing shader programs...');
    programSimple = M3Program(Skinning_vert + Simple_vert, Simple_frag);
    programSkybox = M3Program(Skybox_vert, Skybox_frag);
    programRectangle = M3Program(Rect_vert, Rect_frag);

    programSkyboxReflect = M3ProgramEye(_SkinNormal_vert + SkyboxReflect_vert, Skybox_frag);
    programSimpleLighting = M3ProgramLighting(_SkinNormal_vert + SimpleLighting_vert, Simple_frag);

    setLightingProgram(M3ShaderOptions());

    debugPrint('+++ M3Resources init done+++');
  }

  static void setLightingProgram(M3ShaderOptions options) {
    programTexture?.dispose();
    programShadowmap?.dispose();
    programShadowCSM?.dispose();
    programSkyboxReflect?.dispose();

    // texture lighting program
    String strVert = _SkinNormal_vert + TexturedLighting_vert;
    String strFrag = TexturedLighting_frag;

    // pixel lighting: phong shading, cartoon, PBR
    if (options.perPixel) {
      strVert = "#define ENABLE_PIXEL_LIGHTING \n$strVert";
      strFrag = Pixel_frag + strFrag;
      if (options.pbr) {
        strVert = "#define ENABLE_PBR \n$strVert";
        strFrag = "#define ENABLE_PBR \n$strFrag";
        if (options.ibl) {
          strFrag = "#define ENABLE_IBL \n$strFrag";
        }
      } else if (options.cartoon) {
        strFrag = "#define ENABLE_CARTOON \n$strFrag";
      }
    }
    programTexture = M3ProgramLighting(strVert, strFrag);

    // skybox reflect program
    String strReflectVert = _SkinNormal_vert + SkyboxReflect_vert;
    if (options.pbr) {
      strReflectVert = "#define ENABLE_PBR \n$strReflectVert";
    }
    programSkyboxReflect = M3ProgramEye(strReflectVert, Skybox_frag);

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

  static void checkUpdate(M3ShaderOptions options) {
    if (options.isDirty) {
      setLightingProgram(options);
      options.isDirty = false;
    }
  }

  static void dispose() {
    // Textures
    texWhite.dispose();
    texNormal.dispose();
    texDefaultCube.dispose();

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
