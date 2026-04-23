// SSAO Depth/Normal prepass vertex shader
// ignore: constant_identifier_names
const String SSAODepthNormal_vert = r"""
#version 300 es
// SSAODepthNormal vert-shader: ES3 //////////
#ifndef ENABLE_SKINNING
layout(location = 0) in highp vec3 inVertex;
layout(location = 2) in mediump vec3 inNormal;
#endif // ENABLE_SKINNING

uniform lowp vec4 uColor;
uniform highp mat4 ModelviewProjection;
uniform highp mat4 Model;
uniform highp mat4 ViewMatrix;

out highp vec3 vViewPos;
out mediump vec3 vViewNormal;

void main(void)
{
    highp vec4 objVert = vec4(inVertex, 1.0);
    mediump vec3 objNormal = inNormal;

#ifdef ENABLE_SKINNING
    if (BoneCount > 0)
    {
        ComputeSkinningVertex(objVert, objNormal);
    }
#endif

    highp vec4 viewPos = ViewMatrix * Model * objVert;
    vViewPos = viewPos.xyz;
    vViewNormal = normalize(mat3(ViewMatrix * Model) * objNormal);

    gl_Position = ModelviewProjection * objVert;
}

""";
