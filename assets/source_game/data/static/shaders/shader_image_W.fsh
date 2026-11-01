// Shader taken from: http://webglsamples.googlecode.com/hg/electricflower/electricflower.html

#ifdef GL_ES
precision mediump float;
#endif

varying vec4 v_fragmentColor;
varying vec2 v_texCoord;

uniform sampler2D CC_Texture0;

uniform float imgW;
void main() {
	vec4 sum = vec4(0.0);
	sum += texture2D(CC_Texture0,v_texCoord);
	if(sum.a <0.5)
	{
		gl_FragColor = vec4(0.0) * v_fragmentColor;
	}
	else
	{
		gl_FragColor = vec4(imgW) * v_fragmentColor;
	}
	
}

