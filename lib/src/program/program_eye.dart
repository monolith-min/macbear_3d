part of 'program.dart';

// add reflection by skybox-cubemap
class M3ProgramEye extends M3Program {
  late UniformLocation uniformEyePosition; // eye position as camera origin
  late UniformLocation uniformDiffuse;
  late UniformLocation uniformParamPBR; // x: Metallic, y: Roughness

  M3ProgramEye(super.strVert, super.strFrag);

  @override
  void initLocation() {
    super.initLocation();

    uniformEyePosition = gl.getUniformLocation(program, "EyePosition");
    uniformDiffuse = gl.getUniformLocation(program, "ColorDiffuse");
    uniformParamPBR = gl.getUniformLocation(program, "uParamPBR");
  }

  // eye position in object-space (model-space)
  void setEye(Vector3 eye) {
    gl.uniform3fv(uniformEyePosition, eye.storage);
  }

  @override
  void setMatrices(M3Camera cam, Matrix4 mMatrix) {
    super.setMatrices(cam, mMatrix);

    // ModelView matrix
    Matrix4 mvMatrix = cam.viewMatrix * mMatrix;

    // object-space position
    Matrix4 matInv = Matrix4.inverted(mvMatrix);
    Vector3 posEye = matInv.getTranslation();

    setEye(posEye);
  }

  @override
  void setMaterial(M3Material mtr, Vector4 color) {
    super.setMaterial(mtr, color);

    if (uniformDiffuse.id >= 0) {
      gl.uniform4fv(uniformDiffuse, mtr.diffuse.storage);
    }
    if (uniformParamPBR.id >= 0) {
      gl.uniform2f(uniformParamPBR, mtr.metallic, mtr.roughness);
    }
  }
}
