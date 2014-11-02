@property( !false )
@property( GL430 )#version 430 core
@end @property( !GL430 )
#version 330 core
#extension GL_ARB_shading_language_420pack: require
@end

layout(std140) uniform;
#define FRAG_COLOR		0
layout(location = FRAG_COLOR, index = 0) out vec4 outColour;

@property( !hlms_shadowcaster )

@property( fresnel_scalar )@piece( FresnelType )vec3@end @piece( FresnelSwizzle )xyz@end @end
@property( !fresnel_scalar ) @piece( FresnelType )float@end @piece( FresnelSwizzle )x@end @end

// START UNIFORM DECLARATION
@insertpiece( PassDecl )
@insertpiece( MaterialDecl )
@insertpiece( InstanceDecl )
in block
{
@insertpiece( VStoPS_block )
} inPs;
// END UNIFORM DECLARATION

@property( detail_offsetsD )
	@foreach( detail_maps_diffuse, n )
		@property( detail_offsetsD@n )
			@piece( offsetDetailD@n ) * detailOffsetScaleD[@value(currOffsetDetailD)].zw + detailOffsetScaleD[@counter(currOffsetDetailD)].xy@end
		@end
	@end
@end
@property( detail_offsetsN )
	@foreach( detail_maps_normal, n )
		@property( detail_offsetsN@n )
			@piece( offsetDetailN@n ) * detailOffsetScaleN[@value(currOffsetDetailN)].zw + detailOffsetScaleN[@counter(currOffsetDetailN)].xy@end
		@end
	@end
@end

@property( !roughness_map )#define ROUGHNESS material.kS.w@end
@property( num_textures )uniform sampler2DArray textureMaps[@value( num_textures )];@end
@property( envprobe_map )uniform samplerCube	texEnvProbeMap;@end

@property( diffuse_map )	uint diffuseIdx;@end
@property( normal_map_tex )	uint normalIdx;@end
@property( specular_map )	uint specularIdx;@end
@property( roughness_map )	uint roughnessIdx;@end
@property( detail_weight_map )	uint weightMapIdx;@end
@foreach( 4, n )
	@property( detail_map@n )uint detailMapIdx@n;@end @end
@foreach( 4, n )
	@property( detail_map_nm@n )uint detailNormMapIdx@n;@end @end
@property( envprobe_map )	uint envMapIdx;@end

@property( !diffuse_map && detail_maps_diffuse )vec4 diffuseCol;@end
@property( diffuse_map )vec4 diffuseCol;
@piece( SampleDiffuseMap )	diffuseCol = texture( textureMaps[@value( diffuse_map )], vec3( psIn.uv@value(uv_diffuse).xy, diffuseIdx ) );
@property( !hw_gamma_read )	//Gamma to linear space
	diffuseCol = diffuseCol * diffuseCol;@end @end
@piece( MulDiffuseMapValue )* diffuseCol.xyz@end@end
@property( specular_map )vec3 specularCol;
@piece( SampleSpecularMap )	specularCol = texture( textureMaps[@value( specular_map )], vec3(psIn.uv@value(uv_specular).xy, specularIdx) ).xyz;@end
@piece( MulSpecularMapValue )* specularCol@end@end
@property( roughness_map )float ROUGHNESS;
@piece( SampleRoughnessMap )ROUGHNESS = material.kS.w * texture( textureMaps[@value( roughness_map )], vec3(psIn.uv@value(uv_roughness).xy, roughnessIdx) ).x;@end
@end

Material material;
@property( hlms_normal || hlms_qtangent )vec3 nNormal;@end

@property( normal_map )
@property( hlms_qtangent )
@piece( tbnApplyReflection ) * inPs.biNormalReflection@end
@end
@end

@property( hlms_num_shadow_maps )
@property( hlms_shadow_uses_depth_texture )@piece( SAMPLER2DSHADOW )sampler2DShadow@end @end
@property( !hlms_shadow_uses_depth_texture )@piece( SAMPLER2DSHADOW )sampler2D@end @end
uniform @insertpiece( SAMPLER2DSHADOW ) texShadowMap[@value(hlms_num_shadow_maps)];

float getShadow( @insertpiece( SAMPLER2DSHADOW ) shadowMap, vec4 psPosLN, vec2 invShadowMapSize )
{
@property( !hlms_shadow_usues_depth_texture )
	float fDepth = psPosLN.z;
	vec2 uv = psPosLN.xy / psPosLN.w;
	vec3 o = vec3( invShadowMapSize, -invShadowMapSize.x ) * 0.3;

	// 2x2 PCF
	float c =	(fDepth <= texture(shadowMap, uv - o.xy).r) ? 1 : 0; // top left
	c +=		(fDepth <= texture(shadowMap, uv - o.zy).r) ? 1 : 0; // top right
	c +=		(fDepth <= texture(shadowMap, uv + o.zy).r) ? 1 : 0; // bottom left
	c +=		(fDepth <= texture(shadowMap, uv + o.xy).r) ? 1 : 0; // bottom right

	return c * 0.25;@end
@property( hlms_shadow_usues_depth_texture )
	return texture( shadowMap, psPosLN.xyz, 0 ).x;@end
}
@end

@property( hlms_lights_spot_textured )vec3 zAxis( vec4 qQuat )
{
	Real fTy  = 2.0 * qQuat.y;
	Real fTz  = 2.0 * qQuat.z;
	Real fTwy = fTy * qQuat.w;
	Real fTwz = fTz * qQuat.w;
	Real fTxy = fTy * qQuat.x;
	Real fTxz = fTz * qQuat.x;
	Real fTyy = fTy * qQuat.y;
	Real fTzz = fTz * qQuat.z;

	return vec3( 1.0-(fTyy+fTzz), fTxy+fTwz, fTxz-fTwy );
}
vec3 qmul( vec4 q, vec3 v )
{
	return v + 2.0 * cross( cross( v, q.xyz ) + q.w * v, q.xyz );
}
@end

@property( normal_map_tex )vec3 getTSNormal( sampler2D normalMap, vec2 uv )
{
	vec3 tsNormal;
@property( signed_int_textures )
	//Normal texture must be in U8V8 or BC5 format!
	tsNormal.xy = texture( textureMaps[@value( normal_map_tex )], vec3(uv, normalIdx) ).xy;
@end @property( !signed_int_textures )
	//Normal texture must be in LA format!
	tsNormal.xy = texture( textureMaps[@value( normal_map_tex )], vec3(uv, normalIdx) ).xw * 2.0 - 1.0;
@end
	tsNormal.z	= sqrt( 1.0 - tsNormal.x * tsNormal.x - tsNormal.y * tsNormal.y );

	return tsNormal;
}
@end
@property( detail_maps_normal )vec3 getTSDetailNormal( sampler2DArray normalMap, vec3 uv )
{
	vec3 tsNormal;
@property( signed_int_textures )
	//Normal texture must be in U8V8 or BC5 format!
	tsNormal.xy = texture( normalMap, uv ).xy;
@end @property( !signed_int_textures )
	//Normal texture must be in LA format!
	tsNormal.xy = texture( normalMap, uv ).xw * 2.0 - 1.0;
@end
	tsNormal.z	= sqrt( 1.0 - tsNormal.x * tsNormal.x - tsNormal.y * tsNormal.y );

	return tsNormal;
}

	@property( normal_weight_tex )
		@set( curr_normal_weightA, 1 )
		@set( curr_normal_weightB, 1 )
	@end
	@foreach( 4, n )
		@property( normal_weight_detail@n )
			@piece( detail@n_nm_weight_mulA ) * normalWeights[@counter(curr_normal_weightA)]@end
			@piece( detail@n_nm_weight_mulB ) * normalWeights[@counter(curr_normal_weightB)]@end
		@end
	@end
@end

vec3 cookTorrance( vec3 lightDir, vec3 viewDir, float NdotV, vec3 lightDiffuse, vec3 lightSpecular )
{
	vec3 halfWay= normalize( lightDir + viewDir );
	float NdotL = clamp( dot( nNormal, lightDir ), 0.0, 1.0 );
	float NdotH = clamp( dot( nNormal, halfWay ), 0.001, 1.0 );
	float VdotH = clamp( dot( viewDir, halfWay ), 0.001, 1.0 );

	float sqR = ROUGHNESS * ROUGHNESS;

	//Roughness term (Beckmann distribution)
	//Formula:
	//	Where alpha = NdotH and m = roughness
	//	R = [ 1 / (m^2 x cos(alpha)^4 ] x [ e^( -tan(alpha)^2 / m^2 ) ]
	//	R = [ 1 / (m^2 x cos(alpha)^4 ] x [ e^( ( cos(alpha)^2 - 1 )  /  (m^2 cos(alpha)^2 ) ]
	float NdotH_sq = NdotH * NdotH;
	float roughness_a = 1.0 / ( 3.141592654 * sqR * NdotH_sq * NdotH_sq );//( 1 / (m^2 x cos(alpha)^4 )
	float roughness_b = NdotH_sq - 1.0;	//( cos(alpha)^2 - 1 )
	float roughness_c = sqR * NdotH_sq;		//( m^2 cos(alpha)^2 )

	//Avoid Inf * 0 = NaN; we need Inf * 0 = 0
	float R = min( roughness_a, 65504.0 ) * exp( roughness_b / roughness_c );

	//Geometric term
	float shared_geo = 2.0 * NdotH / VdotH;
	float geo_b	= shared_geo * NdotV;
	float geo_c	= shared_geo * NdotL;
	float G	 	= min( 1.0, min( geo_b, geo_c ) );

	//Fresnel term (Schlick's approximation)
	//Formula:
	//	fresnelS = lerp( (1 - V*H)^5, 1, F0 )
	//	fresnelD = lerp( (1 - N*L)^5, 1, 1 - F0 )
	@insertpiece( FresnelType ) fresnelS = material.F0.@insertpiece( FresnelSwizzle ) + pow( 1.0 - VdotH, 5.0 ) * (1.0 - material.F0.@insertpiece( FresnelSwizzle ));
	@insertpiece( FresnelType ) fresnelD = 1.0 - material.F0.@insertpiece( FresnelSwizzle ) + pow( 1.0 - NdotL, 5.0 ) * material.F0.@insertpiece( FresnelSwizzle );

	//Avoid very small denominators, they go to NaN or cause aliasing artifacts
	@insertpiece( FresnelType ) Rs = ( fresnelS * (R * G)  ) / max( 4.0 * NdotV * NdotL, 0.01 );

	return NdotL * (material.kS.xyz * lightSpecular * Rs @insertpiece( MulSpecularMapValue ) +
					material.kD.xyz * lightDiffuse * fresnelD @insertpiece( MulDiffuseMapValue ));
}

@property( hlms_num_shadow_maps )@piece( DarkenWithShadow ) * getShadow( texShadowMap[@value(CurrentShadowMap)], inPs.posL@value(CurrentShadowMap), invShadowMapSize[@counter(CurrentShadowMap)] )@end @end

void main()
{
	uint materialId	= instance.worldMaterialIdx[inPs.drawId] & 0x1FF;
	material = materialArray.m[materialId];
@property( diffuse_map )	diffuseIdx			= material.indices0_3.x & 0x0000FFFF;@end
@property( normal_map_tex )	normalIdx			= material.indices0_3.x >> 16;@end
@property( specular_map )	specularIdx			= material.indices0_3.y & 0x0000FFFF;@end
@property( roughness_map )	roughnessIdx		= material.indices0_3.y >> 16;@end
@property( detail_weight_map )	weightMapIdx		= material.indices0_3.z & 0x0000FFFF;@end
@property( detail_map0 )	detailMapIdx0		= material.indices0_3.z >> 16;@end
@property( detail_map1 )	detailMapIdx1		= material.indices0_3.w & 0x0000FFFF;@end
@property( detail_map2 )	detailMapIdx2		= material.indices0_3.w >> 16;@end
@property( detail_map3 )	detailMapIdx3		= material.indices4_7.x & 0x0000FFFF;@end
@property( detail_map_nm0 )	detailNormMapIdx0	= material.indices4_7.x >> 16;@end
@property( detail_map_nm1 )	detailNormMapIdx1	= material.indices4_7.y & 0x0000FFFF;@end
@property( detail_map_nm2 )	detailNormMapIdx2	= material.indices4_7.y >> 16;@end
@property( detail_map_nm3 )	detailNormMapIdx3	= material.indices4_7.z & 0x0000FFFF;@end
@property( envprobe_map )	envMapIdx			= material.indices4_7.z >> 16;@end

@property( detail_maps_diffuse || detail_maps_normal )
	@property( detail_weight_map )
		vec4 detailWeights = texture( textureMaps[@value(detail_weight_map)], vec3(psIn.uv@value(uv_detail_weight).xy, weightMapIdx) );
		@property( detail_weights )detailWeights *= cDetailWeights;@end
	@end @property( !detail_weight_map )
		@property( detail_weights )vec4 detailWeights = cDetailWeights;@end
		@property( !detail_weights )vec4 detailWeights = vec4( 1.0 );@end
	@end
	//Group all texture loads together to help the GPU hide the
	//latency (bad GL ES2 drivers won't optimize this automatically)
@end

@foreach( detail_maps_diffuse, n )
	vec4 detailCol@n	= texture( textureMaps[@value(detail_map@n)], vec3( psIn.uv@value(uv_detail@n).xy@insertpiece( offsetDetailD@n ), detailMapIdx@n ) );
	@property( !hw_gamma_read )//Gamma to linear space
		detailCol@n.xyz = detailCol@n.xyz * detailCol@n.xyz;@end
	detailWeights.@insertpiece(detail_diffuse_swizzle@n) *= detailCol@n.w;
	detailCol@n.w = detailWeights.@insertpiece(detail_diffuse_swizzle@n);
@end
@foreach( detail_maps_normal, n )
	vec3 vDetail@n	= getTSDetailNormal( textureMaps[@value(detail_map_nm@n)], vec3( psIn.uv@value(uv_detail_nm@n).xy@insertpiece( offsetDetailN@n ), detailNormMapIdx@n ) ) * detailWeights.@insertpiece(detail_normal_swizzle@n) @insertpiece( detail@n_nm_weight_mulA );@end

@property( !normal_map )
	nNormal = normalize( inPs.normal );
@end @property( normal_map )
	vec3 geomNormal = normalize( inPs.normal );
	vTangent = normalize( inPs.tangent );

	//Get the TBN matrix
	vec3 vBinormal	= cross( vTangent, geomNormal )@insertpiece( tbnApplyReflection );
	mat3 TBN		= mat3( vTangent, vBinormal, geomNormal );

	@property( normal_map_tex )nNormal = getTSNormal( texNormalMap, psIn.uv@value(uv_normal).xy );@end
	@property( normal_weight_tex )nNormal = mix( vec3( 0.0, 0.0, 1.0 ), nNormal, normalWeights[0] );@end
@end

@property( hlms_pssm_splits )
	float fShadow = 1.0;
	if( inPs.depth <= pass.pssmSplitPoints@value(CurrentShadowMap) )
		fShadow = getShadow( texShadowMap[@value(CurrentShadowMap)], inPs.posL0, invShadowMapSize[@counter(CurrentShadowMap)] );@end
@foreach( hlms_pssm_splits, n, 1 )	else if( inPs.depth <= pass.pssmSplitPoints@value(CurrentShadowMap) )
		fShadow = getShadow( texShadowMap[@value(CurrentShadowMap)], inPs.posL@n, invShadowMapSize[@counter(CurrentShadowMap)] );
@end

@insertpiece( SampleDiffuseMap )
@insertpiece( SampleSpecularMap )
@insertpiece( SampleRoughnessMap )

	@property( !diffuse_map && detail_maps_diffuse )diffuseCol = vec4( 0.0, 0.0, 0.0, 0.0 );@end

@foreach( detail_maps_diffuse, n )
	@insertpiece( blend_mode_idx@n ) @end

@property( normal_map_tex )
	@piece( detail0_nm_op_sum )+=@end
	@piece( detail0_nm_op_mul )*=@end
@end @property( !normal_map_tex )
	@piece( detail0_nm_op_sum )=@end
	@piece( detail0_nm_op_mul )=@end
@end

@property( detail_maps_normal )
	nNormal.xy	@insertpiece( detail0_nm_op_sum ) vDetail0.xy;
	nNormal.z	@insertpiece( detail0_nm_op_mul ) vDetail0.z + 1.0 - detailWeights.@insertpiece(detail_normal_swizzle0) @insertpiece( detail0_nm_weight_mulB );@end
@foreach( detail_maps_normal, n, 1 )
	nNormal.xy	+= vDetail@n.xy;
	nNormal.z	*= vDetail@n.z + 1.0 - detailWeights.@insertpiece(detail_normal_swizzle@n) @insertpiece( detail@n_nm_weight_mulB );@end

@property( normal_map )
	nNormal = normalize( TBN * nNormal );
@end

	//Everything's in Camera space, we use Cook-Torrance lighting
@property( hlms_lights_spot || envprobe_map )
	vec3 viewDir	= normalize( -inPs.pos );
	float NdotV		= clamp( dot( nNormal, viewDir ), 0.0, 1.0 );@end

	vec3 finalColour = vec3(0);
@property( hlms_lights_directional )
	finalColour += cookTorrance( pass.lights[0].position, viewDir, NdotV, pass.lights[0].diffuse, pass.lights[0].specular );
@property( hlms_num_shadow_maps )	finalColour *= fShadow;	//1st directional light's shadow@end
@end
@foreach( hlms_lights_directional, n, 1 )
	finalColour += cookTorrance( pass.lights[@n].position, viewDir, NdotV, pass.lights[@n].diffuse, pass.lights[@n].specular )@insertpiece( DarkenWithShadow );@end

@property( hlms_lights_point || hlms_lights_spot )	vec3 lightDir;
	float fDistance;
	vec3 tmpColour;
	float spotCosAngle;@end

	//Point lights
@foreach( hlms_lights_point, n, hlms_lights_directional )
	lightDir = pass.lights[@n].position - inPs.pos;
	fDistance= length( lightDir );
	if( fDistance <= pass.lights[@n].attenuation.x )
	{
		lightDir *= 1.0 / fDistance;
		tmpColour = cookTorrance( lightDir, viewDir, NdotV, pass.lights[@n].diffuse, pass.lights[@n].specular )@insertpiece( DarkenWithShadow );
		float atten = 1.0 / (1.0 + pass.lights[@n].attenuation.y * fDistance + pass.lights[@n].attenuation.z * fDistance * fDistance );
		finalColour += tmpColour * atten;
	}@end

	//Spot lights
	//spotParams[@value(spot_params)].x = 1.0 / cos( InnerAngle ) - cos( OuterAngle )
	//spotParams[@value(spot_params)].y = cos( OuterAngle / 2 )
	//spotParams[@value(spot_params)].z = falloff
@foreach( hlms_lights_spot, n, hlms_lights_point )
	lightDir = pass.lights[@n].position - inPs.pos;
	fDistance= length( lightDir );
@property( !hlms_lights_spot_textured )	spotCosAngle = dot( normalize( inPs.pos - pass.lights[@n].position ), pass.lights[@n].spotDirection );@end
@property( hlms_lights_spot_textured )	spotCosAngle = dot( normalize( inPs.pos - pass.lights[@n].position ), zAxis( pass.lights[@n].spotQuaternion ) );@end
	if( fDistance <= pass.lights[@n].attenuation.x && spotCosAngle >= pass.lights[@n].spotParams.y )
	{
		lightDir *= 1.0 / fDistance;
	@property( hlms_lights_spot_textured )
		vec3 posInLightSpace = qmul( spotQuaternion[@value(spot_params)], inPs.pos );
		float spotAtten = texture( texSpotLight, normalize( posInLightSpace ).xy ).x;
	@end
	@property( !hlms_lights_spot_textured )
		float spotAtten = clamp( (spotCosAngle - pass.lights[@n].spotParams.y) * pass.lights[@n].spotParams.x, 0.0, 1.0 );
		spotAtten = pow( spotAtten, pass.lights[@n].spotParams.z );
	@end
		tmpColour = cookTorrance( lightDir, viewDir, NdotV, lightDiffuse[@n], lightSpecular[@n] )@insertpiece( DarkenWithShadow );
		float atten = 1.0 / (1.0 + pass.lights[@n].attenuation.y * fDistance + pass.lights[@n].attenuation.z * fDistance * fDistance );
		finalColour += tmpColour * (atten * spotAtten);
	}@end

@property( envprobe_map )
	vec3 reflDir = 2.0 * dot( viewDir, nNormal ) * nNormal - viewDir;
	vec3 envColour = textureLod( texEnvProbeMap, invViewMatCubemap * reflDir, ROUGHNESS * 12.0 ).xyz;
	@property( !hw_gamma_read )//Gamma to linear space
	envColour = envColour * envColour;@end
	finalColour += cookTorrance( reflDir, viewDir, NdotV, envColour, envColour * (ROUGHNESS * ROUGHNESS) );@end

@property( !hw_gamma_write )
	//Linear to Gamma space
	outColour.xyz	= sqrt( finalColour );
@end @property( hw_gamma_write )
	outColour.xyz	= finalColour;
@end
	outColour.w		= 1.0;
}
@end
@property( hlms_shadowcaster )
void main()
{
@property( GL3+ )
	outColour = inPs.depth;@end
@property( !GL3+ )
	gl_FragColor.x = inPs.depth;@end
}
@end
@end

@property( false )
#version 330

// START UNIFORM DECLARATION
@insertpiece( PassDecl )
@insertpiece( MaterialDecl )
@insertpiece( InstanceDecl )
in block
{
@insertpiece( VStoPS_block )
} inPs;
// END UNIFORM DECLARATION

Material material;

void main()
{
	//uint materialId	= instance.worldMaterialIdx[inPs.drawId] & 0x1FF;
	//material = materialArray.m[materialId];
	material = materialArray.m[0];
	//gl_FragColor = texture2D( tex, psUv0 );
	//gl_FragColor = vec4( 0, 1, 0, 1 );
	//float v = float(material.indices0_3.y & 0x0000FFFF) * 0.25f;
	//float v = float(material.indices0_3.y >> 16) * 0.25f;
	//gl_FragColor = vec4( v, v, v, 1 );
	//gl_FragColor = vec4( materialArray.m[1].kD.x, materialArray.m[1].kD.y, materialArray.m[1].kD.z, 1 );
	gl_FragColor = vec4( inPs.normal, 1.0f );
}
@end