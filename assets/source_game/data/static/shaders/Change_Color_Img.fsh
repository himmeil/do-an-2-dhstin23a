// Shader taken from: http://webglsamples.googlecode.com/hg/electricflower/electricflower.html

#ifdef GL_ES
precision mediump float;
#endif

varying vec4 v_fragmentColor;
varying vec2 v_texCoord;
varying vec4 v_vColour;

uniform sampler2D CC_Texture0;

uniform float imgW;
uniform vec4 v_changeC;


uniform vec4  colorOut;

uniform vec4  HSLOut;
uniform vec4  setHSLOut;

uniform float ratio;
uniform float DL;
uniform float action;
float TrituyetDoi(float a)
{
if(a>0.0)
	return a;
return -a;	
}
float soDu(float sc,float sbc)
{
	int nguyen  =  int(sc/sbc);
	return (sc-sbc* float(nguyen));
}

float Max(float a,float b,float c)
{
	if(a>b)
	{
		if(a>c)
			return a;
		return c;
	}
	else
	{
		if(b>c)
			return b;
		return c;
	}	
}
float Min(float a,float b,float c)
{
	if(a<b)
	{
		if(a<c)
			return a;
		return c;
	}
	else
	{
		if(b<c)
			return b;
		return c;
	}
}
vec3 rgb( float r, float g ,float b, float m )
{
	vec3 a;
	a.b = b+m;
	a.g = g+m;
	a.r = r+m;
	return a;
}

vec3 hslToRgb( vec3 hsl )
{	
	float C,X,m;
	C = (1.0 - TrituyetDoi(2.0*hsl.b-1.0)) * hsl.g;
	
	float Xh= soDu(hsl.r,120.0);
	X = C * (1.0 - TrituyetDoi( Xh/60.0 - 1.0));
	m = hsl.b - C/2.0;

	
	if (hsl.r<60.0) return rgb(C,X,0.0,m);
	else if (hsl.r<120.0) return rgb(X,C,0.0,m);
	else if (hsl.r<180.0) return rgb(0.0,C,X,m);
	else if (hsl.r<240.0) return rgb(0.0,X,C,m);
	else if (hsl.r<300.0) return rgb(X,0.0,C,m);
	else if (hsl.r<360.0) return rgb(C,0.0,X,m);
	else return rgb(0.0,0.0,0.0,m);
}



vec3 RgbToHsl( vec3 rgb3 )
{

	vec3 hsl3;
	float Cmax = Max(rgb3.r,rgb3.g,rgb3.b);
	float Cmin = Min(rgb3.r,rgb3.g,rgb3.b);
	float deta =  Cmax - Cmin;

	//L
	hsl3.b = (Cmax + Cmin)/2.0;
	
	//S
	if(deta==0.0)
	{
		hsl3.g=0.0;
	}
	else
	{
		hsl3.g = deta/  ( 1.0 - TrituyetDoi(2.0*hsl3.b -1.0) );
	}

	if(deta==0.0)
		deta=1.0;
	
	if(Cmax == rgb3.r)
	{
		hsl3.r= 60.0 * soDu( (rgb3.g- rgb3.b)/deta ,6.0);
	}

	else if(Cmax == rgb3.g)
	{
		hsl3.r= 60.0 * ( ((rgb3.b- rgb3.r)/deta) +2.0 );
	}

	else if(Cmax == rgb3.b)
	{
		hsl3.r= 60.0 * ( ((rgb3.r- rgb3.g)/deta) +4.0 );
	}

	if(hsl3.r<0.0)
		hsl3.r+=360.0;
	return hsl3;
}

void main() {	
	vec4 colorPixel = texture2D( CC_Texture0, v_texCoord ); 
	
	vec3 d = RgbToHsl(colorPixel.rgb);
	
	if(action >0.0)
	{
		if(setHSLOut.a>0.5)
		{
			d.r=setHSLOut.r;
			d.g*=setHSLOut.g;
			d.b*=setHSLOut.b;
		}
		d.r += HSLOut.r;
		d.g += HSLOut.g;
		d.b += HSLOut.b;
		
		
		vec3 s = hslToRgb(d);	
		
		float gray= 0.299*s.r+0.587*s.g+0.114*s.b;
		//gl_FragColor = vec4(s.rgb,colorPixel.a);
		gl_FragColor = vec4(gray * ratio + s.r * (1.0 - ratio),
			gray * ratio + s.g * (1.0 - ratio),
			gray * ratio + s.b * (1.0 - ratio), 
			colorPixel.a)*vec4(DL,DL,DL,1);
	}
	else
	{
		float gray= 0.299*colorPixel.r+0.587*colorPixel.g+0.114*colorPixel.b;
		gl_FragColor = vec4(gray * ratio + colorPixel.r * (1.0 - ratio),
			gray * ratio + colorPixel.g * (1.0 - ratio),
			gray * ratio + colorPixel.b * (1.0 - ratio), 
			colorPixel.a)*vec4(DL,DL,DL,1);
	}
}

