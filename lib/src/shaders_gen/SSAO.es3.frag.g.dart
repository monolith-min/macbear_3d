// SSAO calculation fragment shader
// ignore: constant_identifier_names
const String SSAO_frag = r"""
#version 300 es
// SSAO frag-shader: ES3 //////////
precision highp float;

in mediump vec2 vTexCoord;

uniform sampler2D SamplerDiffuse; // G-Buffer (normal.xyz remapped, linearDepth)
uniform sampler2D SamplerNoise;   // 4x4 rotation noise
uniform highp vec3 uSamples[16]; // hemisphere sample kernel
uniform highp mat4 uProjection;  // camera projection matrix
uniform highp vec2 uNoiseScale;  // screen / noiseSize
uniform highp float uRadius;
uniform highp float uBias;
uniform highp float uNear;
uniform highp float uFar;

out vec4 fragColor;

// Reconstruct view-space position from linear depth and screen UV
highp vec3 reconstructViewPos(vec2 uv, float linearDepth) {
    // Convert linear depth back to actual view-space Z
    float viewZ = -(uNear + linearDepth * (uFar - uNear));
    // Unproject using inverse projection
    vec4 clipPos = vec4(uv * 2.0 - 1.0, 0.0, 1.0);
    vec4 viewPos = inverse(uProjection) * clipPos;
    vec3 viewDir = viewPos.xyz / viewPos.w;
    // Scale ray direction by actual depth
    return viewDir * (viewZ / viewDir.z);
}

void main(void)
{
    // Read G-Buffer
    vec4 gbuffer = texture(SamplerDiffuse, vTexCoord);
    vec3 normal = normalize(gbuffer.rgb * 2.0 - 1.0); // unpack normal
    float linearDepth = gbuffer.a;

    // Skip background (depth ~= 0 or ~= 1)
    if (linearDepth <= 0.001 || linearDepth >= 0.999) {
        fragColor = vec4(1.0);
        return;
    }

    vec3 fragPos = reconstructViewPos(vTexCoord, linearDepth);

    // Random rotation from noise texture
    vec3 randomVec = texture(SamplerNoise, vTexCoord * uNoiseScale).xyz * 2.0 - 1.0;

    // Gram-Schmidt to build TBN from normal + random
    vec3 tangent = normalize(randomVec - normal * dot(randomVec, normal));
    vec3 bitangent = cross(normal, tangent);
    mat3 TBN = mat3(tangent, bitangent, normal);

    // Accumulate occlusion
    float occlusion = 0.0;
    for (int i = 0; i < 16; i++) {
        // Sample position in view space
        vec3 samplePos = fragPos + TBN * uSamples[i] * uRadius;

        // Project sample to screen space
        vec4 offset = uProjection * vec4(samplePos, 1.0);
        offset.xy /= offset.w;
        offset.xy = offset.xy * 0.5 + 0.5;

        // Sample depth at that screen position
        float sampleDepth = texture(SamplerDiffuse, offset.xy).a;
        float sampleViewZ = -(uNear + sampleDepth * (uFar - uNear));

        // Range check: avoid occlusion from far-away geometry
        float rangeCheck = smoothstep(0.0, 1.0, uRadius / abs(fragPos.z - sampleViewZ));
        occlusion += step(samplePos.z, sampleViewZ - uBias) * rangeCheck;
    }

    float ao = 1.0 - (occlusion / 16.0);
    fragColor = vec4(vec3(ao), 1.0);
}

""";
