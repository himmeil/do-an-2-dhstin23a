//1
attribute vec4 a_position;
attribute vec2 a_texCoord;
attribute vec2 a_textSize;
attribute vec2 a_lightPos;
attribute float a_lightAngle;
attribute float a_bonusWeight;
attribute float a_lightWidth;
//2
uniform mat4 u_MVPMatrix;

//3
#ifdef GL_ES
	varying mediump vec2 v_texCoord;
	varying mediump vec4 v_position;
	varying mediump vec2 textSize;
	varying mediump vec2 lightPos;
	varying mediump float lightAngle;
	varying mediump float bonusWeight;
	varying mediump float lightWidth;
#else
	varying vec2 v_texCoord;
	varying vec4 v_position;
	varying vec2 textSize;
	varying vec2 lightPos;
	varying float lightAngle;
	varying float bonusWeight;
	varying float lightWidth;
#endif

//4
void main()
{
    //5
    gl_Position = CC_MVPMatrix * a_position;
    //6
    v_texCoord = a_texCoord;
	v_position = a_position;
	
	textSize = a_textSize;
	lightPos = a_lightPos;
	lightAngle = a_lightAngle;
	bonusWeight = a_bonusWeight;
	lightWidth = a_lightWidth;
	
}