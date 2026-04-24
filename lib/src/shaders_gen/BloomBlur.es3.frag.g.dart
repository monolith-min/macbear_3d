// Generated file – do not edit.
// ignore: constant_identifier_names
const String BloomBlur_frag = r"""
#version 300 es
// BloomBlur frag-shader ES3 //////////
// Two-pass separable Gaussian blur (9-tap) for bloom.
precision mediump float;

in mediump vec2 TextureCoordOut;
uniform sampler2D SamplerDiffuse;   // input texture
uniform mediump vec2 uDirection;    // (1/w, 0) for horizontal, (0, 1/h) for vertical

out vec4 fragColor;

void main(void)
{
    // 9-tap Gaussian weights (sigma ~= 4)
    float weights[5];
    weights[0] = 0.2270270270;
    weights[1] = 0.1945945946;
    weights[2] = 0.1216216216;
    weights[3] = 0.0540540541;
    weights[4] = 0.0162162162;

    vec3 result = texture(SamplerDiffuse, TextureCoordOut).rgb * weights[0];

    for (int i = 1; i < 5; i++) {
        vec2 offset = uDirection * float(i);
        result += texture(SamplerDiffuse, TextureCoordOut + offset).rgb * weights[i];
        result += texture(SamplerDiffuse, TextureCoordOut - offset).rgb * weights[i];
    }

    fragColor = vec4(result, 1.0);
}

""";
