#ifdef GL_ES
precision mediump float;
#endif

// 1
varying vec2 v_texCoord;
varying vec2 v_position;

varying vec2 textSize;
varying vec2 lightPos;
varying float lightAngle;
varying float bonusWeight;
varying float lightWidth;
uniform sampler2D u_texture;
uniform float unitest;
void main(void)
{
	float angle;
	if(lightAngle == 90.0)
	{
		angle = radians(89.9);
	}
	else
	{
		angle = radians(lightAngle);
	}
	vec4 chanCol = texture2D(u_texture, v_texCoord);
	
	vec2 pxPos = textSize*v_texCoord;
	
	float alpha = tan(angle);
	float height = lightWidth/cos(angle);
	
	vec4 resCol = vec4(0,0,0,chanCol.a);
	float xxa = (pxPos.x - lightPos.x)*alpha;
	float yxp = pxPos.y - lightPos.y;
	if(yxp > xxa - height/2.0  &&  yxp < xxa + height/2.0  )
	{
		float length = abs(xxa - yxp)/sqrt(alpha*alpha + 1.0);
		float hLW = lightWidth/2.0;
		float bonus =   (abs(hLW - length)/hLW)*bonusWeight + 1.0;
		resCol.r = chanCol.r*bonus*bonusWeight;
		resCol.g = chanCol.g*bonus*bonusWeight;
		resCol.b = chanCol.b*bonus*bonusWeight;
	}else
	{
		resCol.r = chanCol.r;
		resCol.g = chanCol.g;
		resCol.b = chanCol.b;
	}

	gl_FragColor = resCol;
}