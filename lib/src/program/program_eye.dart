part of 'program.dart';

// add reflection by skybox-cubemap
class M3ProgramEye extends M3Program {
  late UniformLocation uniformEyePosition; // eye position as camera origin
  late UniformLocation uniformEyeColor;
  late UniformLocation uniformEyeParam; // x: Metallic, y: Roughness

  M3ProgramEye(super.strVert, super.strFrag);

  @override
  void initLocation() {
    super.initLocation();

    uniformEyePosition = gl.getUniformLocation(program, "EyePosition");
    uniformEyeColor = gl.getUniformLocation(program, "ColorDiffuse");
    uniformEyeParam = gl.getUniformLocation(program, "uParamPBR");
  }

  // eye position in object-space (model-space)
  void setEye(Vector3 eye) {
    gl.uniform3fv(uniformEyePosition, eye.storage);
  }

  @override
  void setMatrices(M3Camera cam, Matrix4 mMatrix) {
    super.setMatrices(cam, mMatrix);

    if (M3Program.isLocationValid(uniformEyePosition)) {
      // ModelView matrix
      Matrix4 mvMatrix = cam.viewMatrix * mMatrix;

      // object-space position
      Matrix4 matInv = Matrix4.identity();
      double det = matInv.copyInverse(mvMatrix);

      if (det != 0.0) {
        Vector3 posEye = matInv.getTranslation();
        setEye(posEye);
      }
    }
  }

  @override
  void setMaterial(M3Material mtr, Vector4 color) {
    super.setMaterial(mtr, color);

    if (M3Program.isLocationValid(uniformEyeColor)) {
      gl.uniform4fv(uniformEyeColor, mtr.diffuse.storage);
    }
    if (M3Program.isLocationValid(uniformEyeParam)) {
      gl.uniform2f(uniformEyeParam, mtr.metallic, mtr.roughness);
    }
  }
}
