#ifdef GL_ES
precision mediump float;
#endif


varying vec2 v_texCoord;
varying vec2 v_position;
uniform sampler2D u_texture;
uniform float bonusWeight;

void main()
{
	vec4 color=texture2D(u_texture,v_texCoord);
	gl_FragColor=vec4(bonusWeight*color.r,bonusWeight*color.g,bonusWeight*color.b,color.a);
}