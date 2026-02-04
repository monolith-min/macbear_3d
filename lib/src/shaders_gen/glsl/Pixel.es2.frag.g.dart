// Generated file – do not edit.
// ignore: constant_identifier_names
const String Pixel_frag = r"""
#define ENABLE_PIXEL_LIGHTING

// color combined by light and material
uniform lowp vec3 ColorAmbient;		// ambient RGB 
uniform lowp vec4 ColorDiffuse;		// diffuse RGBA
uniform mediump vec4 ColorSpecular;	// specular RGB, w: shininess

uniform mediump vec3 LightPosition;		// parallel light
varying mediump vec3 ObjectspaceN;
varying mediump vec3 ObjectspaceH;		// LightVector + EyeVector
#ifdef ENABLE_PBR
varying mediump vec3 ObjectspaceV;
// ObjectspaceL varying removed to save slots; use LightPosition uniform instead.
uniform mediump vec2 uParamPBR; // x: Metallic, y: Roughness

#ifdef ENABLE_IBL
uniform samplerCube SamplerEnvironment;
#endif // ENABLE_IBL

#endif // ENABLE_PBR

#ifdef ENABLE_PBR
const mediump float PI = 3.14159265359;

// Trowbridge-Reitz GGX
mediump float DistributionGGX(mediump vec3 N, mediump vec3 H, mediump float roughness) {
    mediump float a = roughness * roughness;
    mediump float a2 = a * a;
    mediump float NdotH = max(dot(N, H), 0.0);
    mediump float NdotH2 = NdotH * NdotH;

    mediump float num = a2;
    mediump float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;

    return num / denom;
}

// Smith's method (Schlick-GGX)
mediump float GeometrySchlickGGX(mediump float NdotV, mediump float roughness) {
    mediump float r = (roughness + 1.0);
    mediump float k = (r * r) / 8.0;

    mediump float num = NdotV;
    mediump float denom = NdotV * (1.0 - k) + k;

    return num / denom;
}

mediump float GeometrySmith(mediump vec3 N, mediump vec3 V, mediump vec3 L, mediump float roughness) {
    mediump float NdotV = max(dot(N, V), 0.0);
    mediump float NdotL = max(dot(N, L), 0.0);
    mediump float ggx2 = GeometrySchlickGGX(NdotV, roughness);
    mediump float ggx1 = GeometrySchlickGGX(NdotL, roughness);

    return ggx1 * ggx2;
}

// Schlick's approximation
mediump vec3 fresnelSchlick(mediump float cosTheta, mediump vec3 F0) {
    return F0 + (1.0 - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}
#endif // ENABLE_PBR

// lit result by per-vertex/per-pixel
lowp vec4 ComputePixelLit(in lowp vec4 texDiffuse)
{
	lowp vec4 litResult;
    mediump vec3 N = normalize(ObjectspaceN);

#ifdef ENABLE_PBR
    mediump vec3 V = normalize(ObjectspaceV);
    mediump vec3 L = normalize(LightPosition);
    mediump vec3 H = normalize(V + L);

    // PBR calculations should be done in linear space
    mediump vec3 baseColor = pow(ColorDiffuse.rgb * texDiffuse.rgb, vec3(2.2));
    mediump float alpha = ColorDiffuse.a * texDiffuse.a;

    mediump vec3 F0 = vec3(0.04);
    F0 = mix(F0, baseColor, uParamPBR.x); // Metallic

    // Reflectance equation
    mediump float NDF = DistributionGGX(N, H, uParamPBR.y); // Roughness
    mediump float G = GeometrySmith(N, V, L, uParamPBR.y); // Roughness
    mediump vec3 F = fresnelSchlick(max(dot(H, V), 0.0), F0);

    mediump vec3 kS = F;
    mediump vec3 kD = (vec3(1.0) - kS) * (1.0 - uParamPBR.x); // Metallic

    mediump vec3 numerator = NDF * G * F;
    mediump float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.0001;
    mediump vec3 specular = numerator / denominator;

    mediump float NdotL = max(dot(N, L), 0.0);
    // Correct ambient: ColorAmbient already includes material diffuse, so just multiply by texDiffuse
    mediump vec3 ambient = pow(ColorAmbient, vec3(2.2)) * pow(texDiffuse.rgb, vec3(2.2));

    #ifdef ENABLE_IBL
    // IBL: Sample environment map for ambient reflection
    mediump vec3 reflectDir = reflect(-V, N);
    // Swizzle to match skybox-cubemap orientation (rotXNeg90)
    mediump vec3 sampleDir;
    sampleDir.x = -reflectDir.x;
    sampleDir.y = reflectDir.z;
    sampleDir.z = -reflectDir.y;
    
    mediump vec3 envColor = pow(textureCube(SamplerEnvironment, sampleDir).rgb, vec3(2.2));
    
    // Simple IBL: combine environment reflection with fresnel
    mediump vec3 iblReflection = envColor * F * (1.0 - uParamPBR.y); // Roughness
    ambient += iblReflection * (1.0 - uParamPBR.x * 0.5); // Metals rely more on IBL than ambient
    #endif // ENABLE_IBL

    // Compensate for PI division in diffuse term to match engine's non-PBR brightness
    mediump vec3 color = ambient + (kD * baseColor + specular) * NdotL;

    // HDR tone mapping removed as we use LDR lights; only keep Gamma Correction
    color = pow(color, vec3(1.0 / 2.2));

    litResult = vec4(color, alpha);
#else
    mediump vec3 L = LightPosition;		// parallel light source
    mediump vec3 H = normalize(ObjectspaceH);
    
    lowp float df = max(0.0, dot(N, L));
    lowp float sf = pow(max(0.0, dot(N, H)), ColorSpecular.w);
	
	#ifdef ENABLE_CARTOON
	// segment: 0___0.1___0.3___0.7___1
	// cartoon:   0    0.3  0.7    1
	df = dot(step(vec3(0.1,0.3,0.7), vec3(df)), vec3(0.3, 0.4, 0.3));
	sf = step(0.5, sf);
	#endif // ENABLE_CARTOON
	
	// lit = ambient + diffuse + specular * shininess
	litResult = texDiffuse * vec4((ColorAmbient + ColorDiffuse.rgb * df), ColorDiffuse.a);
	litResult.rgb += (ColorSpecular.rgb * (sf * litResult.a));
#endif // ENABLE_PBR

	return litResult;
}
""";
