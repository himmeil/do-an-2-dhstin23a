#ifdef GL_ES
precision lowp float;
#endif

uniform vec2 resolution;
void main()
{

	vec2 uv = gl_FragCoord.xy /resolution.xy;
	gl_FragColor=vec4(1.0,1.0,sin(uv.x),0.0);
}