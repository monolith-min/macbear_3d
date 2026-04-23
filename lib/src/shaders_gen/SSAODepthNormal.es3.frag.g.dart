// SSAO Depth/Normal prepass fragment shader
// ignore: constant_identifier_names
const String SSAODepthNormal_frag = r"""
#version 300 es
// SSAODepthNormal frag-shader: ES3 //////////
precision highp float;

in highp vec3 vViewPos;
in mediump vec3 vViewNormal;

uniform highp float uNear;
uniform highp float uFar;

out vec4 fragColor;

float linearizeDepth(float depth) {
    return (depth - uNear) / (uFar - uNear);
}

void main(void)
{
    mediump vec3 normal = normalize(vViewNormal);
    // Pack: rgb = view-space normal (remapped 0..1), a = linear depth (0..1)
    float linearDepth = linearizeDepth(-vViewPos.z); // negate because view-space z is negative
    fragColor = vec4(normal * 0.5 + 0.5, linearDepth);
}

""";
