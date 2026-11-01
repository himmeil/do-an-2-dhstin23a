// Shader taken from: http://webglsamples.googlecode.com/hg/electricflower/electricflower.html

#ifdef GL_ES
precision mediump float;
#endif

varying vec4 v_fragmentColor;
varying vec2 v_texCoord;


uniform sampler2D CC_Texture0;

uniform vec2 blurSize;
uniform vec4 substract;
uniform float ratio;
uniform float DL;
uniform vec4 curColor;
void main() {
	vec4 color=texture2D(CC_Texture0,v_texCoord);
	float gray= 0.299*color.r+0.587*color.g+0.114*color.b;
	 gl_FragColor = vec4(gray * ratio + color.r * (1.0 - ratio),
		gray * ratio + color.g * (1.0 - ratio),
		gray * ratio + color.b * (1.0 - ratio), 
		color.a)*curColor *vec4(DL,DL,DL,1);	
}

