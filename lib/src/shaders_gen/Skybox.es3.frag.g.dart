// Generated file – do not edit.
// ignore: constant_identifier_names
const String Skybox_frag = r"""
#version 300 es
// Skybox frag-shader ES3 //////////
precision mediump float;
in lowp vec4 DestinationColor;
in mediump vec3 TexCoordDirOut;
uniform samplerCube SamplerDiffuse;		// cubemap texture
out vec4 fragColor;

void main(void)
{
    fragColor = texture(SamplerDiffuse, TexCoordDirOut) * DestinationColor;
}

""";
