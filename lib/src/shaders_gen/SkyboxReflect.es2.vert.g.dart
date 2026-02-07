// Generated file – do not edit.
// ignore: constant_identifier_names
const String SkyboxReflect_vert = r"""
// Skybox Reflect vert-shader: via cubemap //////////
// NOTICE 1: ENABLE_NORMAL must be defined first
// NOTICE 2: "Skinning.es2.vert" must be added for skinning
#ifndef ENABLE_SKINNING
attribute highp vec3 inVertex;		// vertex-data
attribute mediump vec3 inNormal;
#endif // ENABLE_SKINNING

// object space
uniform mediump vec3 EyePosition;			// eye as camera origin
uniform lowp vec4 uColor;

varying lowp vec4 DestinationColor;
varying mediump vec3 TexCoordDirOut;

// space transformation
uniform highp mat4 Model;
uniform highp mat4 ModelviewProjection;

#ifdef ENABLE_PBR
uniform lowp vec4 ColorDiffuse;
uniform mediump vec2 uParamPBR; // x: Metallic, y: Roughness

// Schlick's approximation for Fresnel
mediump float fresnelSchlick(mediump float cosTheta, mediump float F0) {
    return F0 + (1.0 - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}
#endif // ENABLE_PBR

void main(void)
{
	highp vec4 objVert = vec4(inVertex, 1.0);
	mediump vec3 objNormal = inNormal;

#ifdef ENABLE_SKINNING
	if (BoneCount > 0)
	{
		ComputeSkinningVertex(objVert, objNormal);
	}
#endif // ENABLE_SKINNING

	mediump vec3 eyeDir = normalize(objVert.xyz - EyePosition);	// by object-space
	mediump vec3 reflectDir = reflect(eyeDir, objNormal);		// by object-space
	reflectDir = mat3(Model) * reflectDir;						// by world-space

	// Swizzle to match skybox-cubemap orientation (rotXNeg90)
	TexCoordDirOut.x = -reflectDir.x;
	TexCoordDirOut.y = reflectDir.z;
	TexCoordDirOut.z = -reflectDir.y;

#ifdef ENABLE_PBR
    // Fresnel-based reflection intensity
    mediump float cosTheta = max(dot(-eyeDir, objNormal), 0.0);
    mediump float F0 = mix(0.04, 1.0, uParamPBR.x); // Metallic
    mediump float F = fresnelSchlick(cosTheta, F0);
    
    // Metallic reflection is tinted by base color
    mediump vec3 tint = mix(vec3(1.0), ColorDiffuse.rgb, uParamPBR.x); // Metallic
    DestinationColor = vec4(uColor.rgb * tint * F, uColor.a);
#else
    DestinationColor = uColor;
#endif // ENABLE_PBR

    gl_Position = ModelviewProjection * objVert;	// pre-compute Projection * Modelview
}

""";
