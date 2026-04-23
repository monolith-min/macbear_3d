// Generated file – do not edit.
// ignore: constant_identifier_names
const String TexturedLighting_frag = r"""
#version 300 es

// TexturedLighting frag-shader: ES3 //////////
#ifndef ENABLE_PIXEL_LIGHTING

precision mediump float;

uniform lowp vec3 ColorAmbient;		// ambient RGB 

in lowp vec4 SpecularOut;	// separate specular added
in lowp vec4 DestinationColor;

// no pre-multiply alpha
// lit result by per-vertex
lowp vec4 ComputePixelLit(in lowp vec4 texDiffuse)
{
	lowp vec4 result = texDiffuse * DestinationColor;
	result.rgb += SpecularOut.rgb;
	return result;
}

lowp vec4 ComputePixelUnlit(in lowp vec4 texDiffuse)
{
	// unlit = ambient 
	return texDiffuse * vec4(ColorAmbient, DestinationColor.a);
}
#endif // ENABLE_PIXEL_LIGHTING

in mediump vec2 TextureCoordOut;
uniform sampler2D SamplerDiffuse;	// GL_TEXTURE0

#ifdef ENABLE_FOG
in mediump float FogDensity;		// fog density [0,1]
uniform lowp vec3 FogColor;
#endif // ENABLE_FOG

#ifdef ENABLE_SHADOW_MAP
in highp vec4 LightcoordShadowmap;	// light-space coordinate-system
#endif // ENABLE_SHADOW_MAP

#ifdef ENABLE_SHADOW_CSM
in highp vec4 LightcoordCSM[4];	// light-space coordinate-system
uniform highp vec4 DepthCSM;			// depth clip-plane
#endif // ENABLE_SHADOW_CSM

#if defined(ENABLE_SHADOW_MAP) || defined(ENABLE_SHADOW_CSM)
uniform highp sampler2D SamplerShadowmap;	// GL_TEXTURE1
uniform highp vec2 ShadowmapSize;		// shadowmap resolution
uniform highp float NormalBias;			// normal bias (for shadow acne)
#endif // ENABLE_SHADOW_MAP or ENABLE_SHADOW_CSM

out vec4 fragColor;

void main(void)
{
	lowp vec4 texResult = texture(SamplerDiffuse, TextureCoordOut);	// tex-lookup

	// material alpha for shadow catcher detection
#ifdef ENABLE_PIXEL_LIGHTING
	lowp float matAlpha = ColorDiffuse.a;
#else
	lowp float matAlpha = DestinationColor.a;
#endif
#ifdef ENABLE_TEXTURE0_BGRA	// iOS, macOS: CVPixelBuffer is BGRA, not RGBA
	texResult = texResult.bgra;
#endif // ENABLE_TEXTURE0_BGRA

#ifdef ENABLE_ALPHA_TEST
	if (texResult.a < 0.5)
		discard;
#endif // ENABLE_ALPHA_TEST
	
	////////// shadow map //////////
#if defined(ENABLE_SHADOW_MAP) || defined(ENABLE_SHADOW_CSM)
	#ifdef ENABLE_SHADOW_CSM
		highp vec4 lCoordShadowmap = LightcoordCSM[3];
		if (gl_FragCoord.z < DepthCSM.x) {
			lCoordShadowmap = LightcoordCSM[0];
		}
		else if (gl_FragCoord.z < DepthCSM.y) {
			lCoordShadowmap = LightcoordCSM[1];
		}
		else if (gl_FragCoord.z < DepthCSM.z) {
			lCoordShadowmap = LightcoordCSM[2];
		}
		else {
			lCoordShadowmap = LightcoordCSM[3];
		}
	#else
		highp vec4 lCoordShadowmap = LightcoordShadowmap;
	#endif // ENABLE_SHADOW_CSM
	
	if (lCoordShadowmap.s < 0.0 || lCoordShadowmap.t < 0.0 || lCoordShadowmap.s > 1.0 || lCoordShadowmap.t > 1.0) {
		texResult = ComputePixelLit(texResult);					// lit-area
		// Shadow catcher: blend material in lit area -> fully transparent
		if (matAlpha < 0.99) {
			texResult.a = 0.0;
		}
	}
	else {

	////////// PCF //////////
	#ifdef ENABLE_PCF
		highp vec2 texelSize = vec2(1.0) / ShadowmapSize;
		highp float bias = 0.0005;
		lowp float shadow = 0.0;

		// 5x5 PCF kernel for smooth shadow edges
		for (int x = -2; x <= 2; x++) {
			for (int y = -2; y <= 2; y++) {
				highp float pcfDepth = texture(SamplerShadowmap, lCoordShadowmap.st + vec2(float(x), float(y)) * texelSize).r;
				shadow += step(lCoordShadowmap.z - bias, pcfDepth);
			}
		}
		lowp float factorLit = shadow / 25.0;

		texResult = mix(ComputePixelUnlit(texResult), ComputePixelLit(texResult), factorLit);
		// Shadow catcher: blend material -> shadow areas visible, lit areas transparent
		if (matAlpha < 0.99) {
			texResult.rgb = vec3(0.0);
			texResult.a = matAlpha * (1.0 - factorLit);
		}

	#else

		highp float depthShadow;
		depthShadow = texture(SamplerShadowmap, lCoordShadowmap.st).r;
		if (depthShadow < lCoordShadowmap.z - 0.0005) {
			texResult = ComputePixelUnlit(texResult);
			// Shadow catcher: in shadow -> show shadow
			if (matAlpha < 0.99) {
				texResult.rgb = vec3(0.0);
				texResult.a = matAlpha;
			}
		}
		else {
			texResult = ComputePixelLit(texResult);
			// Shadow catcher: in lit area -> transparent
			if (matAlpha < 0.99) {
				texResult.a = 0.0;
			}
		}
	#endif // ENABLE_PCF
	}

#else
    texResult = ComputePixelLit(texResult);
#endif // ENABLE_SHADOW_MAP or ENABLE_SHADOW_CSM

#ifdef ENABLE_FOG
	// Perform depth test and clamp the values
	lowp float fFogBlend = clamp(FogDensity + 1.0 - texResult.a, 0.0, 1.0);
	texResult.rgb = mix(texResult.rgb, FogColor, fFogBlend); 
#endif // ENABLE_FOG

	fragColor = texResult;
}

""";
