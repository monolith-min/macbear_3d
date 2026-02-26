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
