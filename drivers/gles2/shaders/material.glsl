[vertex]


#ifdef USE_GLES_OVER_GL
#define mediump
#define highp
#else
precision mediump float;
precision mediump int;
#endif
/*
from VisualServer:

ARRAY_VERTEX=0,
ARRAY_NORMAL=1,
ARRAY_TANGENT=2,
ARRAY_COLOR=3,
ARRAY_TEX_UV=4,
ARRAY_TEX_UV2=5,
ARRAY_BONES=6,
ARRAY_WEIGHTS=7,
ARRAY_INDEX=8,
*/

/* INPUT ATTRIBS */

attribute highp vec4 vertex_attrib; // attrib:0
attribute vec3 normal_attrib; // attrib:1
attribute vec4 tangent_attrib; // attrib:2
attribute vec4 color_attrib; // attrib:3
attribute vec2 uv_attrib; // attrib:4
attribute vec2 uv2_attrib; // attrib:5

#ifdef USE_SKELETON
attribute vec4 bone_indices; // attrib:6
attribute vec4 bone_weights; // attrib:7
uniform highp sampler2D skeleton_matrices; // texunit:6
uniform highp float skeltex_pixel_size;
#endif

#ifdef USE_ATTRIBUTE_INSTANCING

attribute highp vec4 instance_row0; // attrib:8
attribute highp vec4 instance_row1; // attrib:9
attribute highp vec4 instance_row2; // attrib:10
attribute highp vec4 instance_row3; // attrib:11

#endif

#ifdef USE_TEXTURE_INSTANCING

attribute highp vec3 instance_uv; // attrib:6
uniform highp sampler2D instance_matrices; // texunit:6

#endif

uniform highp mat4 world_transform;
uniform highp mat4 camera_inverse_transform;
uniform highp mat4 projection_transform;

#ifdef USE_UNIFORM_INSTANCING
//shittiest form of instancing (but most compatible)
uniform highp mat4 instance_transform;
#endif

/* Varyings */

varying vec3 vertex_interp;
varying vec3 normal_interp;

#if defined(ENABLE_COLOR_INTERP)
varying vec4 color_interp;
#endif

#if defined(ENABLE_UV_INTERP)
varying vec2 uv_interp;
#endif

#if defined(ENABLE_UV2_INTERP)
varying vec2 uv2_interp;
#endif

#if defined(ENABLE_VAR1_INTERP)
varying vec4 var1_interp;
#endif

#if defined(ENABLE_VAR2_INTERP)
varying vec4 var2_interp;
#endif

#if defined(ENABLE_TANGENT_INTERP)
varying vec3 tangent_interp;
varying vec3 binormal_interp;
#endif

#ifdef USE_FOG

varying vec4 fog_interp;
uniform highp vec3 fog_params;
uniform vec3 fog_color_begin;
uniform vec3 fog_color_end;

#endif

#ifdef USE_VERTEX_LIGHTING

uniform vec3 light_pos;
uniform vec3 light_direction;
uniform vec3 light_attenuation;
uniform vec3 light_spot_attenuation;
uniform vec3 light_ambient;
uniform vec3 light_diffuse;
uniform vec3 light_specular;



#endif

varying vec4 diffuse_interp;
varying vec3 specular_interp;
//intended for static branching
//pretty much all meaningful platforms support
//static branching

uniform float time;
uniform float instance_id;


#if !defined(USE_DEPTH_SHADOWS) && defined(USE_SHADOW_PASS)

varying vec4 position_interp;

#endif

#ifdef LIGHT_USE_SHADOW

uniform highp mat4 shadow_matrix;
varying highp vec4 shadow_coord;
#ifdef LIGHT_USE_PSSM
uniform highp mat4 shadow_matrix2;
varying highp vec4 shadow_coord2;
#endif


#endif

#ifdef USE_SHADOW_PASS

uniform highp float shadow_z_offset;
uniform highp float shadow_z_slope_scale;

#endif

#ifdef USE_DUAL_PARABOLOID
uniform highp vec2 dual_paraboloid;
varying float dp_clip;
#endif



VERTEX_SHADER_GLOBALS




void main() {
#ifdef USE_UNIFORM_INSTANCING

	highp mat4 modelview = (camera_inverse_transform * (world_transform * instance_transform));
#else

#ifdef USE_ATTRIBUTE_INSTANCING

	highp mat4 minst=mat4(instance_row0,instance_row1,instance_row2,instance_row3);
	highp mat4 modelview = (camera_inverse_transform * (world_transform * minst));

#else

#ifdef USE_TEXTURE_INSTANCING

	highp vec2 ins_ofs=vec2(instance_uv.z,0.0);

	highp mat4 minst=mat4(
		texture2D(instance_matrices,instance_uv.xy),
		texture2D(instance_matrices,instance_uv.xy+ins_ofs),
		texture2D(instance_matrices,instance_uv.xy+ins_ofs*2.0),
		texture2D(instance_matrices,instance_uv.xy+ins_ofs*3.0)
	);

	/*highp mat4 minst=mat4(
		vec4(1.0,0.0,0.0,0.0),
		vec4(0.0,1.0,0.0,0.0),
		vec4(0.0,0.0,1.0,0.0),
		vec4(0.0,0.0,0.0,1.0)
	);*/

	highp mat4 modelview = (camera_inverse_transform * (world_transform * minst));

#else
	highp mat4 modelview = (camera_inverse_transform * world_transform);
#endif

#endif

#endif
	highp vec4 vertex_in = vertex_attrib; // vec4(vertex_attrib.xyz * data_attrib.x,1.0);
	vec3 normal_in = normal_attrib;
#if defined(ENABLE_TANGENT_INTERP)
	vec3 tangent_in = tangent_attrib.xyz;
#endif

#ifdef USE_SKELETON

	{
		//skeleton transform
		highp mat4 m=mat4(texture2D(skeleton_matrices,vec2((bone_indices.x*3.0+0.0)*skeltex_pixel_size,0.0)),texture2D(skeleton_matrices,vec2((bone_indices.x*3.0+1.0)*skeltex_pixel_size,0.0)),texture2D(skeleton_matrices,vec2((bone_indices.x*3.0+2.0)*skeltex_pixel_size,0.0)),vec4(0.0,0.0,0.0,1.0))*bone_weights.x;
		m+=mat4(texture2D(skeleton_matrices,vec2((bone_indices.y*3.0+0.0)*skeltex_pixel_size,0.0)),texture2D(skeleton_matrices,vec2((bone_indices.y*3.0+1.0)*skeltex_pixel_size,0.0)),texture2D(skeleton_matrices,vec2((bone_indices.y*3.0+2.0)*skeltex_pixel_size,0.0)),vec4(0.0,0.0,0.0,1.0))*bone_weights.y;
		m+=mat4(texture2D(skeleton_matrices,vec2((bone_indices.z*3.0+0.0)*skeltex_pixel_size,0.0)),texture2D(skeleton_matrices,vec2((bone_indices.z*3.0+1.0)*skeltex_pixel_size,0.0)),texture2D(skeleton_matrices,vec2((bone_indices.z*3.0+2.0)*skeltex_pixel_size,0.0)),vec4(0.0,0.0,0.0,1.0))*bone_weights.z;
		m+=mat4(texture2D(skeleton_matrices,vec2((bone_indices.w*3.0+0.0)*skeltex_pixel_size,0.0)),texture2D(skeleton_matrices,vec2((bone_indices.w*3.0+1.0)*skeltex_pixel_size,0.0)),texture2D(skeleton_matrices,vec2((bone_indices.w*3.0+2.0)*skeltex_pixel_size,0.0)),vec4(0.0,0.0,0.0,1.0))*bone_weights.w;

		vertex_in = vertex_in * m;
		normal_in = (vec4(normal_in,0.0) * m).xyz;
#if defined(ENABLE_TANGENT_INTERP)
		tangent_in = (vec4(tangent_in,0.0) * m).xyz;
#endif
	}

#endif

	vertex_interp = (modelview * vertex_in).xyz;
	normal_interp = normalize((modelview * vec4(normal_in,0.0)).xyz);

#if defined(ENABLE_COLOR_INTERP)
	color_interp = color_attrib;
#endif

#if defined(ENABLE_TANGENT_INTERP)
	tangent_interp=normalize(tangent_in);
	binormal_interp = normalize( cross(normal_interp,tangent_interp) * tangent_attrib.a );
#endif

#if defined(ENABLE_UV_INTERP)
	uv_interp = uv_attrib;
#endif
#if defined(ENABLE_UV2_INTERP)
	uv2_interp = uv2_attrib;
#endif

	float vertex_specular_exp = 40.0; //material_specular.a;



VERTEX_SHADER_CODE


#ifdef USE_DUAL_PARABOLOID
//for dual paraboloid shadow mapping
        highp vec3 vtx = vertex_interp;
        vtx.z*=dual_paraboloid.y; //side to affect
        vtx.z+=0.01;
        dp_clip=vtx.z;
        highp float len=length( vtx );
        vtx=normalize(vtx);
        vtx.xy/=1.0+vtx.z;
        vtx.z = len*dual_paraboloid.x; // it's a reciprocal(len - z_near) / (z_far - z_near);
        vtx+=normalize(vtx)*0.025;
        vtx.z = vtx.z * 2.0 - 1.0; // fit to clipspace
        vertex_interp=vtx;

        //vertex_interp.w = z_clip;

#endif

#ifdef USE_SHADOW_PASS

	float z_ofs = shadow_z_offset;
	z_ofs += (1.0-abs(normal_interp.z))*shadow_z_slope_scale;
	vertex_interp.z-=z_ofs;
#endif

#ifdef LIGHT_USE_SHADOW

        shadow_coord = shadow_matrix * vec4(vertex_interp,1.0);
	shadow_coord.xyz/=shadow_coord.w;

#ifdef LIGHT_USE_PSSM
	shadow_coord.y*=0.5;
	shadow_coord.y+=0.5;
	shadow_coord2 = shadow_matrix2 * vec4(vertex_interp,1.0);
	shadow_coord2.xyz/=shadow_coord2.w;
	shadow_coord2.y*=0.5;
#endif
#endif

#ifdef USE_FOG

	fog_interp.a = pow( clamp( (-vertex_interp.z-fog_params.x)/(fog_params.y-fog_params.x), 0.0, 1.0 ), fog_params.z );
	fog_interp.rgb = mix( fog_color_begin, fog_color_end, fog_interp.a );
#endif

#ifndef VERTEX_SHADER_WRITE_POSITION
//vertex shader might write a position
	gl_Position = projection_transform * vec4(vertex_interp,1.0);
#endif



#if !defined(USE_DEPTH_SHADOWS) && defined(USE_SHADOW_PASS)

    position_interp=gl_Position;

#endif


#ifdef USE_VERTEX_LIGHTING

	vec3 eye_vec = -normalize(vertex_interp);

#ifdef LIGHT_TYPE_DIRECTIONAL

	vec3 light_dir = -light_direction;
	float attenuation = light_attenuation.r;


#endif

#ifdef LIGHT_TYPE_OMNI
	vec3 light_dir = light_pos-vertex_interp;
	float radius = light_attenuation.g;
	float dist = min(length(light_dir),radius);
	light_dir=normalize(light_dir);
	float attenuation = pow( max(1.0 - dist/radius, 0.0), light_attenuation.b ) * light_attenuation.r;

#endif

#ifdef LIGHT_TYPE_SPOT

	vec3 light_dir = light_pos-vertex_interp;
	float radius = light_attenuation.g;
	float dist = min(length(light_dir),radius);
	light_dir=normalize(light_dir);
	float attenuation = pow(  max(1.0 - dist/radius, 0.0), light_attenuation.b ) * light_attenuation.r;
	vec3 spot_dir = light_direction;
	float spot_cutoff=light_spot_attenuation.r;
	float scos = max(dot(-light_dir, spot_dir),spot_cutoff);
	float rim = (1.0 - scos) / (1.0 - spot_cutoff);
	attenuation *= 1.0 - pow( rim, light_spot_attenuation.g);


#endif

#if defined(LIGHT_TYPE_DIRECTIONAL) || defined(LIGHT_TYPE_OMNI) || defined(LIGHT_TYPE_SPOT)

	//process_shade(normal_interp,light_dir,eye_vec,vertex_specular_exp,attenuation,diffuse_interp,specular_interp);
	{
		float NdotL = max(0.0,dot( normal_interp, light_dir ));
		vec3 half_vec = normalize(light_dir + eye_vec);
		float eye_light = max(dot(normal_interp, half_vec),0.0);
		diffuse_interp.rgb=light_diffuse * NdotL * attenuation;// + light_ambient;
		diffuse_interp.a=attenuation;
		if (NdotL > 0.0) {
			specular_interp=light_specular * pow( eye_light, vertex_specular_exp ) * attenuation;
		} else {
			specular_interp=vec3(0.0);
		}
	}
#else

#ifdef SHADELESS

	diffuse_interp=vec4(vec3(1.0),0.0);
	specular_interp=vec3(0.0);
# else

	diffuse_interp=vec4(0.0);
	specular_interp=vec3(0.0);
# endif

#endif




#endif


}


[fragment]


#ifdef USE_GLES_OVER_GL
#define mediump
#define highp
#else

precision mediump float;
precision mediump int;

#endif

/* Varyings */

#if defined(ENABLE_COLOR_INTERP)
varying vec4 color_interp;
#endif

#if defined(ENABLE_UV_INTERP)
varying vec2 uv_interp;
#endif

#if defined(ENABLE_UV2_INTERP)
varying vec2 uv2_interp;
#endif

#if defined(ENABLE_TANGENT_INTERP)
varying vec3 tangent_interp;
varying vec3 binormal_interp;
#endif

#if defined(ENABLE_VAR1_INTERP)
varying vec4 var1_interp;
#endif

#if defined(ENABLE_VAR2_INTERP)
varying vec4 var2_interp;
#endif

#ifdef LIGHT_USE_PSSM
uniform float light_pssm_split;
#endif

varying vec3 vertex_interp;
varying vec3 normal_interp;

#ifdef USE_FOG

varying vec4 fog_interp;

#endif

/* Material Uniforms */

#ifdef USE_VERTEX_LIGHTING

varying vec4 diffuse_interp;
varying vec3 specular_interp;

#endif

#if !defined(USE_DEPTH_SHADOWS) && defined(USE_SHADOW_PASS)

varying vec4 position_interp;

#endif



uniform vec3 light_pos;
uniform vec3 light_direction;
uniform vec3 light_attenuation;
uniform vec3 light_spot_attenuation;
uniform vec3 light_ambient;
uniform vec3 light_diffuse;
uniform vec3 light_specular;


#ifdef USE_FRAGMENT_LIGHTING



vec3 process_shade(in vec3 normal, in vec3 light_dir, in vec3 eye_vec, in vec3 diffuse, in vec3 specular, in float specular_exp, in float attenuation) {

	float NdotL = max(0.0,dot( normal, light_dir ));
	vec3 half_vec = normalize(light_dir + eye_vec);
	float eye_light = max(dot(normal, half_vec),0.0);

	vec3 ret = light_ambient *diffuse + light_diffuse * diffuse * NdotL * attenuation;
        if (NdotL > 0.0) {
		ret+=light_specular * specular * pow( eye_light, specular_exp ) * attenuation;
	}
        return ret;
}

# ifdef USE_DEPTH_SHADOWS
# else
# endif

#endif

uniform float const_light_mult;
uniform float time;



FRAGMENT_SHADER_GLOBALS



#ifdef LIGHT_USE_SHADOW

varying highp vec4 shadow_coord;
#ifdef LIGHT_USE_PSSM
varying highp vec4 shadow_coord2;
#endif
uniform highp sampler2D shadow_texture;
uniform highp vec2 shadow_texel_size;

uniform float shadow_darkening;

#ifdef USE_DEPTH_SHADOWS

#define SHADOW_DEPTH(m_tex,m_uv) (texture2D((m_tex),(m_uv)).z)

#else

//#define SHADOW_DEPTH(m_tex,m_uv) dot(texture2D((m_tex),(m_uv)),highp vec4(1.0 / (256.0 * 256.0 * 256.0),1.0 / (256.0 * 256.0),1.0 / 256.0,1)  )
#define SHADOW_DEPTH(m_tex,m_uv) dot(texture2D((m_tex),(m_uv)),vec4(1.0 / (256.0 * 256.0 * 256.0),1.0 / (256.0 * 256.0),1.0 / 256.0,1)  )

#endif

#ifdef USE_SHADOW_PCF


float SAMPLE_SHADOW_TEX( highp vec2 coord, highp float refdepth) {

	float avg=(SHADOW_DEPTH(shadow_texture,coord) < refdepth ?  0.0 : 1.0);
	avg+=(SHADOW_DEPTH(shadow_texture,coord+vec2(shadow_texel_size.x,0.0)) < refdepth ?  0.0 : 1.0);
	avg+=(SHADOW_DEPTH(shadow_texture,coord+vec2(-shadow_texel_size.x,0.0)) < refdepth ?  0.0 : 1.0);
	avg+=(SHADOW_DEPTH(shadow_texture,coord+vec2(0.0,shadow_texel_size.y)) < refdepth ?  0.0 : 1.0);
	avg+=(SHADOW_DEPTH(shadow_texture,coord+vec2(0.0,-shadow_texel_size.y)) < refdepth ?  0.0 : 1.0);
        return avg*0.2;
}


/*
	16x averaging
float SAMPLE_SHADOW_TEX( highp vec2 coord, highp float refdepth) {

	vec2 offset = vec2(
		lessThan(vec2(0.25),fract(gl_FragCoord.xy * 0.5))
		);
	offset.y += offset.x;  // y ^= x in floating point

	if (offset.y > 1.1)
		offset.y = 0.0;
	float avg = step( refdepth, SHADOW_DEPTH(shadow_texture, coord+ (offset + vec2(-1.5, 0.5))*shadow_texel_size) );
	avg+=step(refdepth, SHADOW_DEPTH(shadow_texture, coord+ (offset + vec2(0.5, 0.5))*shadow_texel_size) );
	avg+=step(refdepth, SHADOW_DEPTH(shadow_texture, coord+ (offset + vec2(-1.5, -1.5))*shadow_texel_size) );
	avg+=step(refdepth, SHADOW_DEPTH(shadow_texture, coord+ (offset + vec2(0.5, -1.5))*shadow_texel_size) );
	return avg * 0.25;
}
*/

/*
float SAMPLE_SHADOW_TEX( highp vec2 coord, highp float refdepth) {

	vec2 offset = vec2(
		lessThan(vec2(0.25),fract(gl_FragCoord.xy * 0.5))
		);
	offset.y += offset.x;  // y ^= x in floating point

	if (offset.y > 1.1)
		offset.y = 0.0;
	return step( refdepth, SHADOW_DEPTH(shadow_texture, coord+ offset*shadow_texel_size) );

}

*/
/* simple pcf4 */
//#define SAMPLE_SHADOW_TEX(m_coord,m_depth) ((step(m_depth,SHADOW_DEPTH(shadow_texture,m_coord))+step(m_depth,SHADOW_DEPTH(shadow_texture,m_coord+vec2(0.0,shadow_texel_size.y)))+step(m_depth,SHADOW_DEPTH(shadow_texture,m_coord+vec2(shadow_texel_size.x,0.0)))+step(m_depth,SHADOW_DEPTH(shadow_texture,m_coord+shadow_texel_size)))/4.0)

#endif

#ifdef USE_SHADOW_ESM


float SAMPLE_SHADOW_TEX(vec2 p_uv,float p_depth) {

	vec2 unnormalized = p_uv/shadow_texel_size;
	vec2 fractional = fract(unnormalized);
	unnormalized = floor(unnormalized);

	vec4 exponent;
	exponent.x = SHADOW_DEPTH(shadow_texture, (unnormalized + vec2( -0.5, 0.5 )) * shadow_texel_size );
	exponent.y = SHADOW_DEPTH(shadow_texture, (unnormalized + vec2( 0.5, 0.5 )) * shadow_texel_size );
	exponent.z = SHADOW_DEPTH(shadow_texture, (unnormalized + vec2( 0.5, -0.5 )) * shadow_texel_size );
	exponent.w = SHADOW_DEPTH(shadow_texture, (unnormalized + vec2( -0.5, -0.5 )) * shadow_texel_size );

	highp float occluder = (exponent.w + (exponent.x - exponent.w) * fractional.y);
	occluder = occluder + ((exponent.z + (exponent.y - exponent.z) * fractional.y) - occluder)*fractional.x;
	return clamp(exp(28.0 * ( occluder - p_depth )),0.0,1.0);

}


#endif

#if !defined(USE_SHADOW_PCF) && !defined(USE_SHADOW_ESM)

#define SAMPLE_SHADOW_TEX(m_coord,m_depth) (SHADOW_DEPTH(shadow_texture,m_coord) < m_depth ?  0.0 : 1.0)

#endif


#endif

#ifdef USE_DUAL_PARABOLOID

varying float dp_clip;

#endif

uniform highp mat4 camera_inverse_transform;

#if defined(ENABLE_TEXSCREEN)

uniform vec2 texscreen_screen_mult;
uniform sampler2D texscreen_tex;

#endif

#if defined(ENABLE_SCREEN_UV)

uniform vec2 screen_uv_mult;

#endif

void main() {

#ifdef USE_DUAL_PARABOLOID
        if (dp_clip<0.0)
            discard;
#endif

	//lay out everything, whathever is unused is optimized away anyway
        vec3 vertex = vertex_interp;
	vec4 diffuse = vec4(0.9,0.9,0.9,1.0);
	vec3 specular = vec3(0.0,0.0,0.0);
	vec3 emission = vec3(0.0,0.0,0.0);
	float specular_exp=1.0;
	float glow=0.0;
	float shade_param=0.0;
	float side=float(gl_FrontFacing)*2.0-1.0;
#if defined(ENABLE_TANGENT_INTERP)
	vec3 binormal = normalize(binormal_interp)*side;
	vec3 tangent = normalize(tangent_interp)*side;
#endif
//	vec3 normal = abs(normalize(normal_interp))*side;
	vec3 normal = normalize(normal_interp)*side;
#if defined(ENABLE_SCREEN_UV)
	vec2 screen_uv = gl_FragCoord.xy*screen_uv_mult;
#endif

#if defined(ENABLE_UV_INTERP)
	vec2 uv = uv_interp;
#endif

#if defined(ENABLE_UV2_INTERP)
	vec2 uv2 = uv2_interp;
#endif

#if defined(ENABLE_COLOR_INTERP)
	vec4 color = color_interp;
#endif




#ifdef FRAGMENT_SHADER_CODE_USE_DISCARD
	float discard_=0.0;
#endif


FRAGMENT_SHADER_CODE


#ifdef FRAGMENT_SHADER_CODE_USE_DISCARD
	if (discard_>0.0) {
	//easy to eliminate dead code
		discard;
	}
#endif


        float shadow_attenuation = 1.0;


#ifdef LIGHT_USE_SHADOW
#ifdef LIGHT_TYPE_DIRECTIONAL

#ifdef LIGHT_USE_PSSM


//	if (vertex_interp.z > light_pssm_split) {
#if 0
	highp vec3 splane = vec3(0.0,0.0,0.0);

	if (gl_FragCoord.w > light_pssm_split) {

		splane = shadow_coord.xyz;
		splane.y+=1.0;
	} else {
		splane = shadow_coord2.xyz;
	}
	splane.y*=0.5;
	shadow_attenuation=SAMPLE_SHADOW_TEX(splane.xy,splane.z);

#else
/*
	float sa_a = SAMPLE_SHADOW_TEX(shadow_coord.xy,shadow_coord.z);
	float sa_b = SAMPLE_SHADOW_TEX(shadow_coord2.xy,shadow_coord2.z);
	if (gl_FragCoord.w > light_pssm_split) {
		shadow_attenuation=sa_a;
	} else {
		shadow_attenuation=sa_b;
	}
*/

	if (gl_FragCoord.w > light_pssm_split) {
		shadow_attenuation=SAMPLE_SHADOW_TEX(shadow_coord.xy,shadow_coord.z);
	} else {
		shadow_attenuation=SAMPLE_SHADOW_TEX(shadow_coord2.xy,shadow_coord2.z);
	}


#endif

#else

	shadow_attenuation=SAMPLE_SHADOW_TEX(shadow_coord.xy,shadow_coord.z);
#endif
#endif

#ifdef LIGHT_TYPE_OMNI

        vec3 splane=shadow_coord.xyz;///shadow_coord.w;
        float shadow_len=length(splane);
        splane=normalize(splane);
        float vofs=0.0;

        if (splane.z>=0.0) {

                splane.z+=1.0;
        } else {

                splane.z=1.0 - splane.z;
                vofs=0.5;
        }
        splane.xy/=splane.z;
        splane.xy=splane.xy * 0.5 + 0.5;
	float lradius = light_attenuation.g;
        splane.z = shadow_len / lradius;
        splane.y=clamp(splane.y,0.0,1.0)*0.5+vofs;

        shadow_attenuation=SAMPLE_SHADOW_TEX(splane.xy,splane.z);
#endif

#ifdef LIGHT_TYPE_SPOT

	shadow_attenuation=SAMPLE_SHADOW_TEX(shadow_coord.xy,shadow_coord.z);
#endif

	shadow_attenuation=mix(shadow_attenuation,1.0,shadow_darkening);
#endif


#ifdef USE_FRAGMENT_LIGHTING

	vec3 eye_vec = -normalize(vertex);

#ifdef LIGHT_TYPE_DIRECTIONAL

	vec3 light_dir = -light_direction;
	float light_attenuation = light_attenuation.r;

	diffuse.rgb=process_shade(normal,light_dir,eye_vec,diffuse.rgb,specular,specular_exp,shadow_attenuation)*light_attenuation;

#endif

#ifdef LIGHT_TYPE_OMNI

	vec3 light_dir = light_pos-vertex;
	float radius = light_attenuation.g;
	float dist = min(length(light_dir),radius);
	light_dir=normalize(light_dir);
	float attenuation = pow( max(1.0 - dist/radius, 0.0), light_attenuation.b ) * light_attenuation.r;

	diffuse.rgb=process_shade(normal,light_dir,eye_vec,diffuse.rgb,specular,specular_exp,shadow_attenuation)*attenuation;
#endif


#ifdef LIGHT_TYPE_SPOT

	vec3 light_dir = light_pos-vertex;
	float radius = light_attenuation.g;
	float dist = min(length(light_dir),radius);
	light_dir=normalize(light_dir);
	float attenuation = pow(  max(1.0 - dist/radius, 0.0), light_attenuation.b ) * light_attenuation.r;
	vec3 spot_dir = light_direction;
	float spot_cutoff=light_spot_attenuation.r;
	float scos = max(dot(-light_dir, spot_dir),spot_cutoff);
	float rim = (1.0 - scos) / (1.0 - spot_cutoff);
	attenuation *= 1.0 - pow( rim, light_spot_attenuation.g);

	diffuse.rgb=process_shade(normal,light_dir,eye_vec,diffuse.rgb,specular,specular_exp,shadow_attenuation)*attenuation;

#endif


# if !defined(LIGHT_TYPE_DIRECTIONAL) && !defined(LIGHT_TYPE_OMNI) && !defined (LIGHT_TYPE_SPOT)
//none
	diffuse.rgb=vec3(0.0,0.0,0.0);
# endif

	diffuse.rgb+=const_light_mult*emission;

#endif


#ifdef USE_VERTEX_LIGHTING

	vec3 ambient = light_ambient*diffuse.rgb;
# if defined(LIGHT_TYPE_OMNI) || defined (LIGHT_TYPE_SPOT)
	ambient*=diffuse_interp.a; //attenuation affects ambient too
# endif

//	diffuse.rgb=(diffuse.rgb * diffuse_interp.rgb + specular * specular_interp)*shadow_attenuation + ambient;
//	diffuse.rgb+=emission * const_light_mult;
	diffuse.rgb=(diffuse.rgb * diffuse_interp.rgb + specular * specular_interp)*shadow_attenuation + ambient;
	diffuse.rgb+=emission * const_light_mult;


#endif





#ifdef USE_SHADOW_PASS

#ifdef USE_DEPTH_SHADOWS

        //do nothing, depth is just written
#else
        // pack depth to rgba
        //highp float bias = 0.0005;
	highp float depth = ((position_interp.z / position_interp.w) + 1.0) * 0.5 + 0.0;//bias;
        highp vec4 comp = fract(depth * vec4(256.0 * 256.0 * 256.0, 256.0 * 256.0, 256.0, 1.0));
        comp -= comp.xxyz * vec4(0, 1.0 / 256.0, 1.0 / 256.0, 1.0 / 256.0);
        gl_FragColor = comp;

#endif

#else

#ifdef USE_FOG

	diffuse.rgb = mix(diffuse.rgb,fog_interp.rgb,fog_interp.a);
#endif

#ifdef USE_GLOW

	diffuse.a=glow;
#endif

#ifdef USE_HDR
	diffuse.rgb*=0.25;
#endif
	gl_FragColor = diffuse;
#endif
}


