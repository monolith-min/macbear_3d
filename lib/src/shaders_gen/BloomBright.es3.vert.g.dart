// Generated file – do not edit.
// ignore: constant_identifier_names
const String BloomBright_vert = r"""
#version 300 es
// BloomBright vert-shader ES3 //////////
layout(location = 0) in highp vec3 inVertex;
layout(location = 3) in mediump vec2 inTexCoord;

uniform highp mat4 Projection;
uniform highp mat4 Model;

out mediump vec2 TextureCoordOut;

void main(void)
{
    TextureCoordOut = inTexCoord;
    gl_Position = Projection * Model * vec4(inVertex, 1.0);
}

""";
