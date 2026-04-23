// SSAO blur vertex shader (reuses Rect pattern)
// ignore: constant_identifier_names
const String SSAOBlur_vert = r"""
#version 300 es
// SSAOBlur vert-shader: ES3 //////////
layout(location = 0) in highp vec3 inVertex;
layout(location = 3) in mediump vec2 inTexCoord;

uniform lowp vec4 uColor;
uniform highp mat4 Projection;
uniform highp mat4 Model;

out mediump vec2 vTexCoord;

void main(void)
{
    vTexCoord = inTexCoord;
    gl_Position = Projection * Model * vec4(inVertex, 1.0);
}

""";
