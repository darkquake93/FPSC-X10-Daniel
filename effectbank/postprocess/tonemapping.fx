//released under creative commons license by attribution: http://creativecommons.org/licenses/by-sa/3.0/
string Description = "Exposure with Tonemapping and Colour Correction";
string Thumbnail = "Blur.png";

float2 ViewSize : ViewSize;
float time : Time;

//9 sample gauss filter, declare in pixel offsets convert to texel offsets in PS
float4 GaussFilter[9] =
{
    { -1,  -1, 0,  0.0625 },
    { -1,   1, 0,  0.0625 },
    {  1,  -1, 0,  0.0625 },
    {  1,   1, 0,  0.0625 },
    { -1,   0, 0,  0.125  },
    {  1,   0, 0,  0.125  },
    {  0,  -1, 0,  0.125 },
    {  0,   1, 0,  0.125 },
    {  0,   0, 0,  0.25 },
};

float2 PixelOffsets[9] =
{
    { -1,  -1 },
    {  0,  -1  },
    {  1,  -1  },
    { -1,   0  },
    {  0,   0  },
    {  1,   0  },
    { -1,   1 },
    {  0,   1 },
    {  1,   1  },
};

float PixelWeights[9] =
{
   -1, -1, -1,
   -1, 16, -1,
   -1, -1, -1
};
//-----TWEAKABLES--------------------------------------------------------------------------------------//

//0 = Linear. Lots of clipping and colour Shifting.
//1 = Reinhard Simple. No clipping, but looks washed out.
//2 = Reinhard Luminance. No clipping, very saturated, no whites.
//3 = Reinhard Luminance Whitepoint. No clipping and very saturated.
//4 = Uncharted2 Filmic. Brighter without clipping, Customisable.
//5 = Filmic. Higher contrast filmic tonemap by Jim Hejl and Richard Burgess-Dawson.
//6 = ACES Filmic. High constrast but not as strong as Heji-Dawson.
float TonemapMode <
    string UIWidget = "slider";
    string UIName = "Exposure";
    float UIMin = 0.0;
    float UIMax = 6.0;
    float UIStep = 1;
> = 1.0000000;

float Exposure <
    string UIWidget = "slider";
    string UIName = "Exposure";
    float UIMin = -10.0;
    float UIMax = 10.0;
    float UIStep = 0.1;
> = 0.0000000;

float Whitepoint <
    string UIWidget = "slider";
    float UIMin = 0.0;
    float UIMax = 5.0;
    float UIStep = 0.1;
> = 9.0000000;

float Adaption
<
	string UIWidget = "slider";
	float UIMax = 5.0;
	float UIMin = 0.0;
	float UIStep = 0.1;
> = 1.0;

float AdaptionCurve
<
	string UIWidget = "slider";
	float UIMax = 5.0;
	float UIMin = 0.0;
	float UIStep = 0.1;
> = 0.5;

float AdaptionMin <
    string UIWidget = "slider";
    string UIName = "Exposure";
    float UIMin = 0.0;
    float UIMax = 1.0;
    float UIStep = 0.1;
> = 0.125;

float AdaptionMax < 
    string UIWidget = "slider";
    string UIName = "Exposure";
    float UIMin = 0.0;
    float UIMax = 1.0;
    float UIStep = 0.1;
> = 2.5;

float2 width 
<
	string UIWidget = "slider";
	float UIMax = 2.5;
	float UIMin = 0.5;
	float UIStep = 0.1;
> = { 2.5, 2.5};

float widthpow 
<
	string UIWidget = "slider";
	float UIMax = 5.0;
	float UIMin = 0.0;
	float UIStep = 0.1;
> = 1.000000;

float BloomThreshold 
<
	string UIWidget = "slider";
	float UIMax = 1.0;
	float UIMin = 0.0;
	float UIStep = 0.05;
> = 0.000000;

float BloomCurve 
<
	string UIWidget = "slider";
	float UIMax = 10.0;
	float UIMin = 0.0;
	float UIStep = 0.05;
> = 1.000000;


float PostBloomBoost 
<
	string UIWidget = "slider";
	float UIMax = 1.0;
	float UIMin = 0.0;
	float UIStep = 0.1;
> = 0.250000;


float Color
<
string UIWidget = "slider";
    float UIMin = 0;
    float UIMax = 1.0;
    float UIStep = 0.1;
    string UIName =  "filmgrain amount";
> = 1.0;

float Monochrome
<
string UIWidget = "slider";
    float UIMin = 0;
    float UIMax = 1.0;
    float UIStep = 0.1;
    string UIName =  "filmgrain amount";
> = 0.0;

float BrownSepia
<
string UIWidget = "slider";
    float UIMin = 0;
    float UIMax = 1.0;
    float UIStep = 0.1;
    string UIName =  "filmgrain amount";
> = 0.0;

float GreenSepia
<
string UIWidget = "slider";
    float UIMin = 0;
    float UIMax = 1.0;
    float UIStep = 0.1;
    string UIName =  "filmgrain amount";
> = 0.0;

float BlueSepia
<
string UIWidget = "slider";
    float UIMin = 0;
    float UIMax = 1.0;
    float UIStep = 0.1;
    string UIName =  "filmgrain amount";
> = 0.0;

float Contrast
<
string UIWidget = "slider";
    float UIMin = 0;
    float UIMax = 5.0;
    float UIStep = 0.1;
    string UIName =  "filmgrain amount";
> = 1.0;

float Brightness
<
string UIWidget = "slider";
    float UIMin = -1;
    float UIMax = 2.0;
    float UIStep = 0.1;
    string UIName =  "filmgrain amount";
> = 0.0;

float3 Curves 
<
    string UIWidget = "color";
    string UIName = "Fog";
> = { 1.0, 1.0, 1.0};

float WhiteBalance
<
	string UIWidget = "slider";
	float UIMax = 1.0;
	float UIMin = 0.0;
	float UIStep = 0.1;
> = 0.0;

float Vignette
<
	string UIWidget = "slider";
	float UIMax = 50.0;
	float UIMin = 0.0;
	float UIStep = 0.1;
> = 1.0;

float Sharpen
<
	string UIWidget = "slider";
	float UIMax = 5.0;
	float UIMin = 0.0;
	float UIStep = 0.1;
> = 0.0;

//noise effect intensity value (0 = no effect, 1 = full effect)
float FilmgrainAmount
<
string UIWidget = "slider";
    float UIMin = 0.1;
    float UIMax = 1.0;
    float UIStep = 0.1;
    string UIName =  "filmgrain amount";
> = 0.0;


//scanlines effect intensity value (0 = no effect, 1 = full effect)
float ScanlineAmount 
<
string UIWidget = "slider";
    float UIMin = 0.1;
    float UIMax = 10.0;
    float UIStep = 0.1;
    string UIName =  "scanline amount";
> = 0.0;






//-------Color Matrices for Color Correction--------------

float4x4 gray = {0.299,0.587,0.184,0,
                  0.299,0.587,0.184,0,
                  0.299,0.587,0.184,0,
                  0,0,0,1};
                  
                  
float4x4 sepia = {0.299,0.587,0.184,0.1,
                  0.299,0.587,0.184,0.018,
                  0.299,0.587,0.184,-0.090,
                  0,0,0,1};
                  
float4x4 sepia2 = {0.299,0.587,0.184,-0.090,
                  0.299,0.587,0.184,0.018,
                  0.299,0.587,0.184,0.1,
                  0,0,0,1};
                  
float4x4 sepia3 = {0.299,0.587,0.184,-0.090,
                  0.299,0.587,0.184,0.1,
                  0.299,0.587,0.184,0.1,
                  0,0,0,1};
//float4x4 sepia4 = {0.299,0.587,0.184,-0.090,
                 // 0.299,0.587,0.184,0.018,
                 // 0.1299,0.587,0.184,0.1,
                 // 0,0,0,1};
float4x4 sepia4 = {0.299,0.587,0.184,-0.090,
                  0.299,0.587,0.184,0.018,
                  0.1299,0.587,0.184,0.1,
                  0,0,0,1};
                  
//---------------------------------------------------------------


//scanlines effect count value (0 = no effect, 4096 = full effect)
float ScanlineCount = 1024;

                  
//---------------Filmic Curve------------------------------------------------

/*
float A = 0.15;
float B = 0.50;
float C = 0.10;
float D = 0.20;
float E = 0.02;
float F = 0.30;
*/
//float W = 11.2;
float W = 1;


float Gamma <
    string UIWidget = "slider";
    string UIName = "Gamma";
> = 2.2;

//---------------RENDER TARGET TEXTURES-------------------------------------------------------------------//

//starting scene image
texture frame : RENDERCOLORTARGET
< 
	string ResourceName = "";
	float2 ViewportRatio = {1.0,1.0 };
	
>;

sampler2D frameSamp = sampler_state {
    Texture = < frame >;
    MinFilter = Linear; MagFilter = Linear; MipFilter = Linear;
    AddressU = Clamp; AddressV = Clamp;
};

//2x2 average luminosity texture using point sampling
texture AvgLum2x2Img : RENDERCOLORTARGET 
< 
	string ResourceName = ""; 
	//float2 ViewportRatio = { 0.5, 0.5 };
	int width = 3;
	int height = 3;
>;

sampler2D AvgLum2x2ImgSamp = sampler_state {
    Texture = < AvgLum2x2Img >;
    MinFilter = Linear; MagFilter = Linear; MipFilter = Linear;
    AddressU = Clamp; AddressV = Clamp;
};

//Average scene luminosity stored in 1x1 texture 
texture AvgLumFinal : RENDERCOLORTARGET 
< 
	string ResourceName = ""; 
	//float2 ViewportRatio = { 0.5, 0.5 };
	int width = 1;
	int height = 1;
>;

sampler2D AvgLumFinalSamp = sampler_state {
    Texture = < AvgLumFinal >;
    MinFilter = Linear; MagFilter = Linear; MipFilter = Linear;
    AddressU = Clamp; AddressV = Clamp;
};

//reduce image to 1/8 size for brightpass
texture BrightpassImg : RENDERCOLORTARGET
< 
	string ResourceName = "";
	//float2 ViewportRatio = {1.0,1.0 };
	int width = 512;
	int height = 384;
>;

sampler2D BrightpassImgSamp = sampler_state {
    Texture = < BrightpassImg >;
    MinFilter = Linear; MagFilter = Linear; MipFilter = Linear;
    AddressU = Clamp; AddressV = Clamp;
};

//blur texture 1
texture Blur1Img : RENDERCOLORTARGET
< 
	string ResourceName = "";
	//float2 ViewportRatio = {0.25,0.25 };
	int width = 256;
	int height = 192;
	
>;

sampler2D Blur1ImgSamp = sampler_state {
    Texture = < Blur1Img >;
    MinFilter = Linear; MagFilter = Linear; MipFilter = Linear;
    AddressU = Clamp; AddressV = Clamp;
};

//blur texture 2
texture Blur2Img : RENDERCOLORTARGET
< 
	string ResourceName = "";
	//float2 ViewportRatio = {0.125,0.125 };
	int width = 128;
	int height = 96;
	
>;

sampler2D Blur2ImgSamp = sampler_state {
    Texture = < Blur2Img >;
    MinFilter = Linear; MagFilter = Linear; MipFilter = Linear;
    AddressU = Clamp; AddressV = Clamp;
};

//blur texture 3
texture Blur3Img : RENDERCOLORTARGET
< 
	string ResourceName = "";
	//float2 ViewportRatio = {0.0625,0.0625 };
	int width = 64;
	int height = 48;
	
>;

sampler2D Blur3ImgSamp = sampler_state {
    Texture = < Blur3Img >;
    MinFilter = Linear; MagFilter = Linear; MipFilter = Linear;
    AddressU = Clamp; AddressV = Clamp;
};

//blur texture 4
texture Blur4Img : RENDERCOLORTARGET
< 
	string ResourceName = "";
	//float2 ViewportRatio = {0.03125,0.03125 };
	int width = 32;
	int height = 24;
	
>;

sampler2D Blur4ImgSamp = sampler_state {
    Texture = < Blur4Img >;
    MinFilter = Linear; MagFilter = Linear; MipFilter = Linear;
    AddressU = Clamp; AddressV = Clamp;
};



//-------------STRUCTS-------------------------------------------------------------

struct input 
{
	float4 pos : POSITION;
	float2 uv : TEXCOORD0;
};
 
struct output {

	float4 pos: POSITION;
	float2 uv: TEXCOORD0;

};

//-----------VERTEX SHADER------------------------------------------------------------//
output VS( input IN ) 
{
	output OUT;

	//quad needs to be shifted by half a pixel.
    //Go here for more info: http://www.sjbrown.co.uk/?article=directx_texels
    
	float4 oPos = float4( IN.pos.xy + float2( -1.0f/ViewSize.x, 1.0f/ViewSize.y ),0.0,1.0 );
	OUT.pos = oPos;

	float2 uv = (IN.pos.xy + 1.0) / 2.0;
	uv.y = 1 - uv.y; 
	OUT.uv = uv;
	
	return OUT;	
}

//---------PIXEL SHADERS--------------------------------------------------------------//

//takes original frame image and outputs to 2x2
float4 PSReduce( output IN, uniform sampler2D srcTex ) : COLOR
{
    float4 color = 0;    
    color= tex2D(srcTex,IN.uv); 
    
    return color;    
}

//-----------------computes average luminosity for scene-----------------------------
float4 PSGlareAmount( output IN, uniform sampler2D srcTex , uniform sampler2D srcTex2 ) : COLOR
{
    float4 GlareAmount = 0.5;
    
    //sample texture 4 times with offset texture coordinates
    float4 color1= tex2D( srcTex, IN.uv + float2(-0.0, -0.0) );
    float4 color2= tex2D( srcTex, IN.uv + float2(-0.0, 0.66) );
    float4 color3= tex2D( srcTex, IN.uv + float2(0.0, -0.66) );
    float4 color4= tex2D( srcTex, IN.uv + float2(-0.66, -0.0) );
    float4 color5= tex2D( srcTex, IN.uv + float2(-0.66, 0.66) );
    float4 color6= tex2D( srcTex, IN.uv + float2(-0.66, -0.66) );
    float4 color7= tex2D( srcTex, IN.uv + float2(0.66, -0.0) );
    float4 color8= tex2D( srcTex, IN.uv + float2(0.66, 0.66) );
    float4 color9= tex2D( srcTex, IN.uv + float2(0.66, -0.66) );
    
    //average these samples
    float3 AvgColor = (color1.xyz+color2.xyz+color3.xyz+color4.xyz+color5.xyz+color6.xyz+color7.xyz+color8.xyz+color9.xyz)/9;
    
    //AvgColor = (color1+color3+color4)/3;
    
    //convert to luminance
    //AvgColor = lerp(dot(float3(0.3,0.59,0.11), AvgColor),AvgColor,WhiteBalance);
    
    //AvgColor = dot(float3(0.3,0.59,0.11), AvgColor);
    
    GlareAmount.xyz = AvgColor;
    
    //interpolation value to blend with previous frames
    GlareAmount.w = 0.015*Adaption;
       
    return GlareAmount;    
}


//-------------brightpass pixel shader, removes low luminance pixels--------------------------
float4 PSBrightpass( output IN, uniform sampler2D srcTex, uniform sampler2D srcTex2  ) : COLOR
{
    float4 screen = tex2D(srcTex, IN.uv);  //original screen texture;//convert to luminance
    
    float4 glaretex = tex2D(srcTex2, IN.uv);  //glareamount from 1x1 in previous pass;
    
    //remove low luminance pixels, keeping only brightest
    float3 Brightest = saturate(screen.xyz - BloomThreshold) / (1- BloomThreshold);


    //use a curve instead of threshold to look more natural
    //Brightest.xyz = pow(Brightest.xyz,2);
    Brightest.xyz *= pow(dot(float3(0.3,0.59,0.11), Brightest.xyz),BloomCurve-1);

    float4 color = float4(Brightest.xyz, 1);
    
    return color;    
}

float4 PSBlur( output IN, uniform sampler2D srcTex, uniform float blurwidth  ) : COLOR
{
    float4 color = float4(0,0,0,0);
    
    //inverse view for correct pixel to texel mapping
    float2 ViewInv = float2( 1/ViewSize.x,1/ViewSize.y);  
    
    width*= pow(blurwidth,widthpow);
    
    //sample and output average colors using gauss filter samples
    for(int i=0;i<9;i++)
    
    {
    float4 col = GaussFilter[i].w * tex2D(srcTex,IN.uv + float2(GaussFilter[i].x * ViewInv.x*width.x, GaussFilter[i].y *ViewInv.y*width.y));  
    //float4 col = GaussFilter[i].w * tex2D(srcTex,IN.uv + float2(GaussFilter[i].x * ViewInv.x*2.5, GaussFilter[i].y *ViewInv.y*2.5));  
    color+=col;
    }
    return color;
}

float4 PSAccumulateBloom( output IN, uniform sampler2D srcTex, uniform sampler2D srcTex1, uniform sampler2D srcTex2, uniform sampler2D srcTex3, uniform sampler2D srcTex4 ) : COLOR
{
    float4 color = float4(0,0,0,0);
    float4 Bloom1=tex2D(srcTex, IN.uv);
    float4 Bloom2=tex2D(srcTex1, IN.uv);
    float4 Bloom3=tex2D(srcTex2, IN.uv);
    float4 Bloom4=tex2D(srcTex3, IN.uv);
    float4 Bloom5=tex2D(srcTex4, IN.uv);
    

    //add bloom together
    color += (Bloom1 + Bloom2 + Bloom3 + Bloom4 + Bloom5 )/5;
    //color = Bloom5;
    
    return color;
}

float3 Reinhard(float3 x)
{
   return x/(1+x);
}

float3 ReinhardLuminance(float3 x)
{
    float Luminance = dot(x, float3(0.2126, 0.7152, 0.0722));;
	float3 Tone = Reinhard(Luminance);
	return ((Tone / Luminance)*x.rgb);
}

float3 ReinhardLumWhite(float3 x)
{
	float luma = dot(x, float3(0.2126, 0.7152, 0.0722));
	float toneMappedLuma = luma * (1. + luma / ((Whitepoint)*(Whitepoint))) / (1. + luma);
	x *= toneMappedLuma / luma;
	//x = pow(x, vec3(1. / gamma));
	return x;
}


float3 Uncharted2Tonemap(float3 x)
{
   float A = 0.15;
   float B = 0.50;
   float C = 0.10;
   float D = 0.20;
   float E = 0.02;
   float F = 0.30;
   return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
}

float3 FilmicTonemap(float3 x)
{
   x = max(0,x-0.004);
   float3 retColor = (x*(6.2*x+.5))/(x*(6.2*x+1.7)+0.06);
   return pow(retColor,2.2);
}

float3 ACESFilm( float3 x )
{
    float a = 2.51f;
    float b = 0.03f;
    float c = 2.43f;
    float d = 0.59f;
    float e = 0.14f;
    return saturate((x*(a*x+b))/(x*(c*x+d)+e));
}

//combine adaptive bloom texture with original scene image
float4 PSPresent( output IN, uniform sampler2D srcTex, uniform sampler2D srcTex2, uniform sampler2D srcTex3 ) : COLOR
{
    float4 color = float4(0,0,0,0);
    
    //sample screen texture and bloom texture
    float4 ScreenMap=tex2D(srcTex, IN.uv);
    float4 BloomMap=tex2D(srcTex2, IN.uv);
    float4 AmtMap=tex2D(srcTex3, IN.uv);


    //gamma in
    ScreenMap=pow(ScreenMap,Gamma);
    BloomMap=pow(BloomMap,Gamma);
    //AmtMap=pow(AmtMap,Gamma); //mathimatical, don't gamma correct
    	

    float Luminance = dot(ScreenMap.xyz, float3(0.3, 0.57, 0.11));
    float3 mod = dot(AmtMap.xyz, float3(0.3, 0.57, 0.11));
    
    float3 final = ScreenMap + (BloomMap*PostBloomBoost);
    //final = lerp(final, ScreenMap, Luminance);
    
    final = lerp(final,(final/AmtMap)*mod,WhiteBalance); //experimental white balance

      //vignette
    float2 vpos = (IN.uv - float2(.5,.5)) * 2 ;
    //vpos.x = vpos.x * -1.5 - 0; //can also scale and shift horizontally
    float dist = (dot(vpos, vpos)) ;
    dist =  pow(1-0.4 * dist,Vignette);
    final*=dist;


    //exposure
    mod   = pow(mod,AdaptionCurve); 
    mod   = clamp(mod,AdaptionMin,AdaptionMax); //clamping eye adaption
    
    //final = final*pow(2,Exposure)*pow(2,1/mod); 
    final = final*pow(2,Exposure+(1/mod)); 
    
    Luminance = dot(final.xyz, float3(0.3, 0.57, 0.11));

    //tonemapping - DONT USE MORE THAN ONE AT A TIME
    
     if (TonemapMode==0)
    {
    //final = ((2*final)/(Whitepoint/2)); //no tonemap, lots of clipping
    }
    
    else if (TonemapMode==1)
    {
    final = Reinhard(final); //reinhard tonemap, no clipping but washed out
    }
    
    else if (TonemapMode==2)
    {
    final = ReinhardLuminance(final); //reinhard tonemap on luminance only, very saturated
    }
    
    else if (TonemapMode==3)
    {
    final = ReinhardLumWhite(final); //reinhard tonemap on luminance, but with whitepoint
    }
    
    else if (TonemapMode==4)
    {
    float ExposureBias = 2.0f;
    float3 curr = Uncharted2Tonemap(ExposureBias*final);
    float3 whiteScale = 1.0f/Uncharted2Tonemap(Whitepoint*2);
    final = curr*whiteScale; //Uncharted 2 filmic tonemap, less washed out
    }
	else if (TonemapMode==5)
    {
    final =FilmicTonemap(final/2)/FilmicTonemap(Whitepoint/2); //Filmic tonemap by Jim Hejl and Richard Burgess-Dawson, higher contrast
    }
    
	else if (TonemapMode==6)
    {
    final = ACESFilm(final/2)/ACESFilm(Whitepoint/2);///ACESFilm(Whitepoint*2); //ACES filmic tonemap, high contrast
    }


    //gamma out
    final = pow(final,1/Gamma);
    final = saturate(final);

    color = float4(final,1);
    
    return color;
    
    
}

///Pixel shader
float4 ps_main( float2 Tex : TEXCOORD0  ) : COLOR0 
{
	//-------------prevent time value from becoming too large--------------
	//float framespersec = 25;
	float looptime = 1000; //looptime in seconds			
	float loopcounter  = floor(time/looptime); //increments by one every 50 seconds (or whatever "looptime" is)
	float offset ;  //initialize offset value used below	
	offset = looptime*loopcounter; //offset time value -increments every looptime
	//float speed =(time*framespersec) - (offset*framespersec) ;	 
	float speed =(time) - (offset) ;
	//------------------------------------------------------------------------
	
	
	// sample the source
	float4 cTextureScreen = tex2D( frameSamp, Tex.xy);
	//cTextureScreen = pow(cTextureScreen,Gamma);

	
	float x = Tex.x * Tex.y *(speed*500);
	x = fmod(x, 13) * fmod(x, 123);	
	float dx = fmod(x, 0.01);

	//float3 cResult = cTextureScreen.rgb + cTextureScreen.rgb * saturate(0.1f + dx.xxx * 100);
    //float3 cResult = cTextureScreen.rgb * saturate(pow(cTextureScreen,.2) * 1.0f + dx.xxx * 100);
    float3 cResult = cTextureScreen.rgb;

	float2 sc; sincos(Tex.y * ScanlineCount, sc.x, sc.y);

	cResult += cTextureScreen.rgb * float3(sc.x, sc.y, sc.x) * ScanlineAmount;
	
	// interpolate between source and result by intensity
	cResult = lerp(cTextureScreen, cResult, saturate(FilmgrainAmount));
	
	//cResult.rgb = (cResult.r * 0.3f + cResult.g * 0.59f + cResult.b * 0.11f);
	float3 monochrome = (cResult.r * 0.3f + cResult.g * 0.59f + cResult.b * 0.11f);
	float4 monochrome4 = float4(monochrome,1);
	//cResult.rgb =  (Color * cResult.rgb) + (monochrome* Monochrome);
	
	float4 result2 = float4(cResult,1);

	float4 brownsepia = mul(sepia,result2) ;
    float4 greensepia = mul(sepia3,result2) ;
    float4 bluesepia = mul(sepia2,result2) ;
     
	// return with source alpha


	float4 combine =  (brownsepia *BrownSepia ) + (greensepia *GreenSepia )+ (bluesepia *BlueSepia )+ (monochrome4 *Monochrome)+(Color * result2);
	combine = saturate((combine * Contrast)  + Brightness);

    //curves
    combine.r = pow(combine.r,Curves.r);
    combine.g = pow(combine.g,Curves.g);
    combine.b = pow(combine.b,Curves.b);
    //combine = pow(combine,1/Gamma);
    //combine = saturate(combine);
    
    //combine = .5;
    
	//cResult = combine.rgb * saturate(combine + dx.xxx * 100);
	cResult.rgb = combine.rgb * saturate(pow(combine,.2) + dx.xxx * 100);
	
	// interpolate between source and result by intensity
	combine = float4(lerp(combine, cResult, saturate(FilmgrainAmount)),1);
	
    
    return combine;
	
} 

float4 PSSharpen( output IN, uniform sampler2D srcTex ) : COLOR
{
    float4 color = 0;
    float2 scale = Sharpen/ViewSize;
    
    for (int i = 0; i < 9; i++)
    {
        //convert pixel offsets into texel offsets via the inverse view values.
        color += tex2D( srcTex, IN.uv + PixelOffsets[i].xy*scale )*PixelWeights[i];
    }

    return color / 8.0f;    //the pixel weights have been multiplied by 8, divide to get back to 1
}

//-------TECHNIQUE------------------------------------------------------------------
  
technique AdaptiveBloom
<
	//specify where we want the original image to be put
	string RenderColorTarget = "frame";
>
{
	
	//1. first reduce to 2x2 and save in AvgLum2x2Img
	pass Reduce2x2
	<
		string RenderColorTarget = "AvgLum2x2Img";
	>
	{
		ZEnable = False;
		VertexShader = compile vs_1_1 VS();
		PixelShader = compile ps_2_0 PSReduce( frameSamp );
		
	}
	
	//2. reduce to 1x1 and save in AvgLumFinalImg, using alpha blending to blend with previous frames
	pass Reduce1x1
	<
		string RenderColorTarget = "AvgLumFinal";
	>
	{
		ZEnable = False;
		VertexShader = compile vs_1_1 VS();
		PixelShader = compile ps_2_0 PSGlareAmount( AvgLum2x2ImgSamp,frameSamp );
		AlphaBlendEnable = true;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
	}
	
	//3. remove low luminance pixels keeping only brightest for blurring in next pass
	pass Brightpass
	<
		string RenderColorTarget = "BrightpassImg";
	>
	{
		ZEnable = False;
		VertexShader = compile vs_1_1 VS();
		PixelShader = compile ps_2_0 PSBrightpass( frameSamp, AvgLumFinalSamp );
		
	}

	
	//4. blur texture and save in Blur1Img
	pass Blur1
	<
		string RenderColorTarget = "Blur1Img";
	>
	{
		ZEnable = False;
		VertexShader = compile vs_1_1 VS();
		PixelShader = compile ps_2_0 PSBlur( BrightpassImgSamp, 1 );
		
	}
	
	//5. repeat blur texture and save in Blur2Img
	pass Blur2
	<
		string RenderColorTarget = "Blur2Img";
	>
	{
		ZEnable = False;
		VertexShader = compile vs_1_1 VS();
		PixelShader = compile ps_2_0 PSBlur( Blur1ImgSamp, 1 );
		
	}
	
	//6. repeat blur again
	pass Blur3
	<
		string RenderColorTarget = "Blur3Img";
	>
	{
		ZEnable = False;
		VertexShader = compile vs_1_1 VS();
		PixelShader = compile ps_2_0 PSBlur( Blur2ImgSamp, 1 );
		
	}
	
	pass Blur4
	<
		string RenderColorTarget = "Blur4Img";
	>
	{
		ZEnable = False;
		VertexShader = compile vs_1_1 VS();
		PixelShader = compile ps_2_0 PSBlur( Blur3ImgSamp, 1 );
		
	}

	pass Blur1
	<
		string RenderColorTarget = "BrightpassImg";
	>
	{
		ZEnable = False;
		VertexShader = compile vs_1_1 VS();
		PixelShader = compile ps_2_0 PSBlur( BrightpassImgSamp, 1 );
		
	}
	
	//5. repeat blur texture and save in Blur2Img
	pass Blur5
	<
		string RenderColorTarget = "Blur1Img";
	>
	{
		ZEnable = False;
		VertexShader = compile vs_1_1 VS();
		PixelShader = compile ps_2_0 PSBlur( Blur1ImgSamp, 1.25 );
		
	}
	
	//6. repeat blur again
	pass Blur6
	<
		string RenderColorTarget = "Blur2Img";
	>
	{
		ZEnable = False;
		VertexShader = compile vs_1_1 VS();
		PixelShader = compile ps_2_0 PSBlur( Blur2ImgSamp, 1.5 );
		
	}
	
	pass Blur7
	<
		string RenderColorTarget = "Blur3Img";
	>
	{
		ZEnable = False;
		VertexShader = compile vs_1_1 VS();
		PixelShader = compile ps_2_0 PSBlur( Blur3ImgSamp, 1.75 );
		
	}
	
	pass Blur5
	<
		string RenderColorTarget = "Blur4Img";
	>
	{
		ZEnable = False;
		VertexShader = compile vs_1_1 VS();
		PixelShader = compile ps_2_0 PSBlur( Blur4ImgSamp, 2 );
		
	}
	
	pass AccumulateBloom
	<
		string RenderColorTarget = "BrightpassImg";
	>
	{
		ZEnable = False;
		VertexShader = compile vs_1_1 VS();
		PixelShader = compile ps_2_0 PSAccumulateBloom( BrightpassImgSamp, Blur1ImgSamp, Blur2ImgSamp, Blur3ImgSamp, Blur4ImgSamp );
		
	}
/*
	pass Blur5
	<
		string RenderColorTarget = "Blur4Img";
	>
	{
		ZEnable = False;
		VertexShader = compile vs_1_1 VS();
		PixelShader = compile ps_2_0 PSBlur( Blur4ImgSamp );
		
	}
	
	pass AccumulateBloom
	<
		string RenderColorTarget = "Blur3Img";
	>
	{
		ZEnable = False;
		VertexShader = compile vs_1_1 VS();
		PixelShader = compile ps_2_0 PSAccumulateBloomBlur( Blur4ImgSamp, Blur3ImgSamp );
		
	}
	
	pass AccumulateBloom
	<
		string RenderColorTarget = "Blur2Img";
	>
	{
		ZEnable = False;
		VertexShader = compile vs_1_1 VS();
		PixelShader = compile ps_2_0 PSAccumulateBloomBlur( Blur3ImgSamp, Blur2ImgSamp );
		
	}
	
	pass AccumulateBloom
	<
		string RenderColorTarget = "Blur1Img";
	>
	{
		ZEnable = False;
		VertexShader = compile vs_1_1 VS();
		PixelShader = compile ps_2_0 PSAccumulateBloomBlur( Blur2ImgSamp, Blur1ImgSamp  );
		
	}

	
	pass AccumulateBloom
	<
		string RenderColorTarget = "BrightpassImg";
	>
	{
		ZEnable = False;
		VertexShader = compile vs_1_1 VS();
		PixelShader = compile ps_2_0 PSAccumulateBloomBlur( Blur1ImgSamp, BrightpassImgSamp  );
		
	}

*/

	pass Blur1
	<
		string RenderColorTarget = "BrightpassImg";
	>
	{
		ZEnable = False;
		VertexShader = compile vs_1_1 VS();
		PixelShader = compile ps_2_0 PSBlur( BrightpassImgSamp, 1 );
		
	}
	
	
	
	
	
	
	//send the combined image to the screen
	pass Present
	<
		string RenderColorTarget = "frame";
	>
	{
		VertexShader = compile vs_1_1 VS();
		PixelShader = compile ps_2_b PSPresent( frameSamp, BrightpassImgSamp, AvgLumFinalSamp );
	}
	
	pass Negative
	<
		//use a blank render target to draw to the screen
		string RenderColorTarget = "frame";
	>
	{
		ZEnable = False;
		VertexShader = compile vs_2_0 VS();
		PixelShader = compile ps_2_b ps_main(  );
	}
	
	pass Sharpen
	<
		string RenderColorTarget = "";
	>
	{
		ZEnable = False;
		VertexShader = compile vs_1_1 VS();
		PixelShader = compile ps_2_0 PSSharpen( frameSamp );
	}
}