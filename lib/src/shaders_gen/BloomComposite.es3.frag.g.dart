// Generated file – do not edit.
// ignore: constant_identifier_names
const String BloomComposite_frag = r"""
#version 300 es
// BloomComposite frag-shader ES3 //////////
// Combines original scene with bloom (additive blend).
precision mediump float;

in mediump vec2 TextureCoordOut;
uniform sampler2D SamplerDiffuse;   // original scene texture (TEXTURE0)
uniform sampler2D SamplerBloom;     // blurred bloom texture (TEXTURE1)
uniform lowp float uBloomIntensity; // bloom strength (default 1.0)

out vec4 fragColor;

void main(void)
{
    vec4 sceneColor = texture(SamplerDiffuse, TextureCoordOut);
    vec3 bloomColor = texture(SamplerBloom, TextureCoordOut).rgb;
    // Additive bloom
    sceneColor.rgb += bloomColor * uBloomIntensity;
    fragColor = sceneColor;
}

""";
