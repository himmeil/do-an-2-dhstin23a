#ifdef GL_ES
precision mediump float;
#endif

// 1
varying vec2 v_texCoord;
varying vec2 v_position;

uniform sampler2D u_texture;
uniform sampler2D u_maskTexture;

void main(void)
{
	
	vec4 chanCol = texture2D(u_texture, vec2(1.0,1.0) - v_texCoord);
	vec4 maskCol = texture2D(u_maskTexture, vec2(0.0, v_texCoord.y));
	gl_FragColor = vec4(chanCol.r + maskCol.r*maskCol.a*chanCol.a, 
						chanCol.g + maskCol.g*maskCol.a*chanCol.a, 
						chanCol.b + maskCol.b*maskCol.a*chanCol.a, 
						chanCol.a);
}