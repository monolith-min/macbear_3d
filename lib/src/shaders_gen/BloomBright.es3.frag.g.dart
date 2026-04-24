// Generated file – do not edit.
// ignore: constant_identifier_names
const String BloomBright_frag = r"""
#version 300 es
// BloomBright frag-shader ES3 //////////
// Extracts bright areas above a luminance threshold for bloom effect.
precision mediump float;

in mediump vec2 TextureCoordOut;
uniform sampler2D SamplerDiffuse;   // scene color texture
uniform lowp float uThreshold;     // brightness threshold (default 0.7)

out vec4 fragColor;

void main(void)
{
    vec4 color = texture(SamplerDiffuse, TextureCoordOut);
    // Calculate luminance (perceived brightness)
    float luminance = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
    // Soft knee: smooth transition around threshold
    float soft = luminance - uThreshold + 0.1;
    soft = clamp(soft / 0.2, 0.0, 1.0);
    soft = soft * soft;
    float contribution = max(soft, step(uThreshold, luminance));
    fragColor = vec4(color.rgb * contribution, 1.0);
}

""";
