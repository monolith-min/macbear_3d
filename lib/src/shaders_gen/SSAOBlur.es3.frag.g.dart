// SSAO blur fragment shader (simple box blur)
// ignore: constant_identifier_names
const String SSAOBlur_frag = r"""
#version 300 es
// SSAOBlur frag-shader: ES3 //////////
precision highp float;

in mediump vec2 vTexCoord;

uniform sampler2D SamplerDiffuse; // raw SSAO texture
uniform highp vec2 uTexelSize;   // 1.0 / textureSize

out vec4 fragColor;

void main(void)
{
    float result = 0.0;
    // 4x4 box blur
    for (int x = -2; x <= 1; x++) {
        for (int y = -2; y <= 1; y++) {
            vec2 offset = vec2(float(x) + 0.5, float(y) + 0.5) * uTexelSize;
            result += texture(SamplerDiffuse, vTexCoord + offset).r;
        }
    }
    result /= 16.0;
    fragColor = vec4(vec3(result), 1.0);
}

""";
