//1
attribute vec4 a_position;
attribute vec2 a_texCoord;

//2
uniform mat4 u_MVPMatrix;
#ifdef GL_ES
varying mediump vec2 v_texCoord;
varying mediump vec4 v_position;
#else
varying vec2 v_texCoord;
varying vec4 v_position;
#endif


void main()
{
	gl_Position = CC_MVPMatrix * a_position;
	v_texCoord = a_texCoord;
	v_position = a_position;
}