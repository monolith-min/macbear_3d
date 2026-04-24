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

#ifdef ENABLE_SSAO
in mediump vec2 ScreenUV;
uniform sampler2D SamplerSSAO;	// GL_TEXTURE3
#endif // ENABLE_SSAO

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

		// 32-tap Poisson Disk PCF for high-quality soft shadow edges
		highp vec2 poissonDisk[32];
		poissonDisk[0]  = vec2(-0.9420, -0.3991);
		poissonDisk[1]  = vec2( 0.9456, -0.7689);
		poissonDisk[2]  = vec2(-0.0942, -0.9293);
		poissonDisk[3]  = vec2( 0.3448,  0.9291);
		poissonDisk[4]  = vec2(-0.9159,  0.4577);
		poissonDisk[5]  = vec2(-0.8154, -0.8790);
		poissonDisk[6]  = vec2(-0.3826,  0.2740);
		poissonDisk[7]  = vec2( 0.5740,  0.2131);
		poissonDisk[8]  = vec2( 0.0568, -0.3571);
		poissonDisk[9]  = vec2( 0.5380, -0.2847);
		poissonDisk[10] = vec2(-0.3286, -0.1570);
		poissonDisk[11] = vec2( 0.1379,  0.3403);
		poissonDisk[12] = vec2( 0.8589,  0.5737);
		poissonDisk[13] = vec2(-0.5906,  0.8043);
		poissonDisk[14] = vec2(-0.2276, -0.6207);
		poissonDisk[15] = vec2( 0.3647, -0.0146);
		poissonDisk[16] = vec2(-0.4839,  0.6365);
		poissonDisk[17] = vec2( 0.7256, -0.1439);
		poissonDisk[18] = vec2(-0.1612,  0.9520);
		poissonDisk[19] = vec2( 0.2093, -0.7571);
		poissonDisk[20] = vec2(-0.6892, -0.5574);
		poissonDisk[21] = vec2( 0.4431,  0.6091);
		poissonDisk[22] = vec2(-0.7652,  0.1230);
		poissonDisk[23] = vec2( 0.8875,  0.2064);
		poissonDisk[24] = vec2(-0.3913, -0.7831);
		poissonDisk[25] = vec2( 0.1501,  0.7511);
		poissonDisk[26] = vec2( 0.6710, -0.5265);
		poissonDisk[27] = vec2(-0.5524, -0.0243);
		poissonDisk[28] = vec2( 0.0790,  0.1175);
		poissonDisk[29] = vec2(-0.2110,  0.4046);
		poissonDisk[30] = vec2( 0.3842, -0.4672);
		poissonDisk[31] = vec2(-0.9017,  0.7614);

		// Spread radius in texels (wider = softer edge)
		highp float spreadRadius = 5.0;

		for (int i = 0; i < 32; i++) {
			highp float pcfDepth = texture(SamplerShadowmap, lCoordShadowmap.st + poissonDisk[i] * texelSize * spreadRadius).r;
			shadow += step(lCoordShadowmap.z - bias, pcfDepth);
		}
		lowp float factorLit = shadow / 32.0;

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

#ifdef ENABLE_SSAO
	// Apply SSAO: darken ambient-lit areas
	if (matAlpha >= 0.99) {
		lowp float ao = texture(SamplerSSAO, ScreenUV).r;
		texResult.rgb *= ao;
	}
#endif // ENABLE_SSAO

	fragColor = texResult;
}

""";
