// This Shader combines the 2 Bond1 shaders "Adaptive Bloom" and "Filmgrain + Recoloring" and gives also an Sharpening effect.
// Shader code combined by Dominik G. aka DarkGoblin
// Sharpen shader added by Dominik G. aka DarkGoblin

//Shader edited for Nomad Mod

//Original Copyright info:
//This shader provides an automatic adaptive bloom effect based on screen brightness to scale the bloom effect
//Shader code by Mark Blosser
//email: mjblosser@gmail.com
//website: www.mjblosser.com
//released under creative commons license by attribution: http://creativecommons.org/licenses/by-sa/3.0/

string Description = "Adaptive Bloom by bond1";
string Thumbnail = "Blur.png";
float time : Time;
float2 ViewSize : ViewSize;
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

float SharpenStrenght
<
string UIWidget = "slider";
    float UIMin = 0.0;
    float UIMax = 5.0;
    float UIStep = 0.1;
    string UIName =  "SharpenStrenght";
> = 1.000000;

float PreBloomBoost 
<
	string UIWidget = "slider";
	float UIMax = 4.0;
	float UIMin = 0.0;
	float UIStep = 0.1;
> = 1.500000;

float BloomThreshold 
<
	string UIWidget = "slider";
	float UIMax = 1.0;
	float UIMin = 0.0;
	float UIStep = 0.05;
> = 0.500000;

float PostBloomBoost 
<
	string UIWidget = "slider";
	float UIMax = 4.0;
	float UIMin = 0.0;
	float UIStep = 0.1;
> = 1.500000;



/*float width 
<
	string UIWidget = "slider";
	float UIMax = 10.0;
	float UIMin = 1;
	float UIStep = 0.01;
> = 2.5;*/

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


float Fog
<
string UIWidget = "slider";
    float UIMin = 0;
    float UIMax = 1.0;
    float UIStep = 0.1;
    string UIName =  "filmgrain amount";
> = 0.500000;


float Color
<
string UIWidget = "slider";
    float UIMin = 0;
    float UIMax = 1.0;
    float UIStep = 0.1;
    string UIName =  "filmgrain amount";
> = 1.000000;

float Monochrome
<
string UIWidget = "slider";
    float UIMin = 0;
    float UIMax = 1.0;
    float UIStep = 0.1;
    string UIName =  "filmgrain amount";
> = 0.000000;

float BrownSepia
<
string UIWidget = "slider";
    float UIMin = 0;
    float UIMax = 1.0;
    float UIStep = 0.1;
    string UIName =  "filmgrain amount";
> = 0.000000;

float GreenSepia
<
string UIWidget = "slider";
    float UIMin = 0;
    float UIMax = 1.0;
    float UIStep = 0.1;
    string UIName =  "filmgrain amount";
> = 0.000000;

float BlueSepia
<
string UIWidget = "slider";
    float UIMin = 0;
    float UIMax = 1.0;
    float UIStep = 0.1;
    string UIName =  "filmgrain amount";
> = 0.000000;

float Contrast
<
string UIWidget = "slider";
    float UIMin = 0;
    float UIMax = 5.0;
    float UIStep = 0.1;
    string UIName =  "filmgrain amount";
> = 1.000000;

float Brightness
<
string UIWidget = "slider";
    float UIMin = -1;
    float UIMax = 2.0;
    float UIStep = 0.1;
    string UIName =  "filmgrain amount";
> = 0.000000;

//noise effect intensity value (0 = no effect, 1 = full effect)
float FilmgrainAmount
<
string UIWidget = "slider";
    float UIMin = 0.1;
    float UIMax = 1.0;
    float UIStep = 0.1;
    string UIName =  "filmgrain amount";
> = 0.000000;


//scanlines effect intensity value (0 = no effect, 1 = full effect)
float ScanlineAmount 
<
string UIWidget = "slider";
    float UIMin = 0.1;
    float UIMax = 10.0;
    float UIStep = 0.1;
    string UIName =  "scanline amount";
> = 0.000000;




//scanlines effect count value (0 = no effect, 4096 = full effect)
float ScanlineCount = 1024.000000;




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
	int width = 2;
	int height = 2;
>;

sampler2D AvgLum2x2ImgSamp = sampler_state {
    Texture = < AvgLum2x2Img >;
    MinFilter = Point; MagFilter = Point; MipFilter = Point;
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
    MinFilter = Point; MagFilter = Point; MipFilter = Point;
    AddressU = Clamp; AddressV = Clamp;
};

//reduce image to 1/8 size for brightpass
texture BrightpassImg : RENDERCOLORTARGET
< 
	string ResourceName = "";
	//float2 ViewportRatio = {0.125,0.125 };
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
	//float2 ViewportRatio = {0.125,0.125 };
	int width = 512;
	int height = 384;
	
>;

sampler2D Blur1ImgSamp = sampler_state {
    Texture = < Blur1Img >;
    MinFilter = Anisotropic; MagFilter = Anisotropic; MipFilter = Anisotropic;
    AddressU = Clamp; AddressV = Clamp;
};

//blur texture 2
texture Blur2Img : RENDERCOLORTARGET
< 
	string ResourceName = "";
	//float2 ViewportRatio = {0.125,0.125 };
	int width = 512;
	int height = 384;
	
>;

sampler2D Blur2ImgSamp = sampler_state {
    Texture = < Blur2Img >;
    MinFilter = Linear; MagFilter = Linear; MipFilter = Linear;
    AddressU = Clamp; AddressV = Clamp;
};



//composite
texture CompImg : RENDERCOLORTARGET
< 
	string ResourceName = "";
	//float2 ViewportRatio = {0.125,0.125 };
	
	
>;

sampler2D CompImgSamp = sampler_state {
    Texture = < CompImg >;
    MinFilter = Linear; MagFilter = Linear; MipFilter = Linear;
    AddressU = Clamp; AddressV = Clamp;
};

//composite
texture BlendImg : RENDERCOLORTARGET
< 
	string ResourceName = "";
	//float2 ViewportRatio = {0.125,0.125 };
	
	
>;

sampler2D BlendImgSamp = sampler_state {
    Texture = < BlendImg >;
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
    color= tex2D( srcTex, IN.uv );    
    return color;    
}

//-----------------computes average luminosity for scene-----------------------------
float4 PSGlareAmount( output IN, uniform sampler2D srcTex ) : COLOR
{
    float4 GlareAmount = 0;
    
    //sample texture 4 times with offset texture coordinates
    float4 color1= tex2D( srcTex, IN.uv + float2(-0.5, -0.5) );
    float4 color2= tex2D( srcTex, IN.uv + float2(-0.5, 0.5) );
    float4 color3= tex2D( srcTex, IN.uv + float2(0.5, -0.5) );
    float4 color4= tex2D( srcTex, IN.uv + float2(0.5, 0.5) );
    
    //average these samples
    float3 AvgColor = saturate(color1.xyz * 0.25 + color2.xyz * 0.25 + color3.xyz * 0.25 + color4.xyz * 0.25);
    
    //exxagerate values to make effect more evident
    AvgColor = 8*AvgColor*AvgColor;
    
    //convert to luminance
    AvgColor = dot(float3(0.3,0.59,0.11), AvgColor);
    
    GlareAmount.xyz = AvgColor;
    
    //interpolation value to blend with previous frames
    GlareAmount.w = 0.03;
       
    return GlareAmount;    
}


//-------------brightpass pixel shader, removes low luminance pixels--------------------------
float4 PSBrightpass( output IN, uniform sampler2D srcTex, uniform sampler2D srcTex2  ) : COLOR
{
    float4 screen = tex2D(srcTex, IN.uv);  //original screen texture;  
    float4 glaretex = tex2D(srcTex2, IN.uv);  //glareamount from 1x1 in previous pass;
    
    //remove low luminance pixels, keeping only brightest
    float3 Brightest = saturate(screen.xyz - BloomThreshold) * PreBloomBoost;
    //Brightest.xyz = pow(Brightest.xyz,2) * 2;
    
    //apply glare adaption
    //float3 adapt = Brightest.xyz * (1-glaretex.xyz);
    
    float4 color = float4(Brightest.xyz, 1);
    
    return color;    
}

float4 PSBlur( output IN, uniform sampler2D srcTex ) : COLOR
{
    float4 color = float4(0,0,0,0);
    
    //inverse view for correct pixel to texel mapping
    float2 ViewInv = float2( 1/ViewSize.x,1/ViewSize.y);   
    
    //sample and output average colors using gauss filter samples
    for(int i=0;i<9;i++)
    
    {
    //float4 col = GaussFilter[i].w * tex2D(srcTex,IN.uv + float2(GaussFilter[i].x * ViewInv.x*width, GaussFilter[i].y *ViewInv.y*width));  
    float4 col = GaussFilter[i].w * tex2D(srcTex,IN.uv + float2(GaussFilter[i].x * ViewInv.x*2.5, GaussFilter[i].y *ViewInv.y*2.5));  
    color+=col;
    }
    return color;
}

//combine adaptive bloom texture with original scene image
float4 PSPresent( output IN, uniform sampler2D srcTex, uniform sampler2D srcTex2, uniform sampler2D srcTex3,float2 Tex : TEXCOORD0 ) : COLOR
{
    float4 color = float4(0,0,0,0);
    
    //sample screen texture and bloom texture 
    
   float strength = 10;
   float4 ScreenMap;

   ScreenMap = tex2D( srcTex, IN.uv);
   ScreenMap -= tex2D( srcTex, IN.uv+0.0001)*SharpenStrenght;
   ScreenMap += tex2D( srcTex, IN.uv-0.0001)*SharpenStrenght;
   
  // Color.a = 1.0;
        
  //  float4 ScreenMap=texd2;//tex2D(srcTex, IN.uv);
    float4 BloomMap=tex2D(srcTex2, IN.uv);
    float4 AmtMap=tex2D(srcTex3, IN.uv);
    //float4 BlendMap=tex2D(srcTex3, IN.uv);
    
    //technique 1: just add results
    
    float Luminance = dot(ScreenMap.xyz, float3(0.3, 0.59, 0.11));
    float3 mod = lerp(PostBloomBoost,0,AmtMap.x);
    float3 final = ScreenMap + 0.25*ScreenMap*mod + mod*BloomMap;
    float4 MaxAmount= ((1-Fog)*ScreenMap) + BloomMap+ Fog;
    final  = lerp(MaxAmount, ScreenMap+final*.1, Luminance);
    //float3 final = BloomMap;
    
    //technique 2: add results based scene pixel brightness
    //float Luminance = dot(ScreenMap.xyz, float3(0.3, 0.59, 0.11));
    //float4 MaxAmount= ScreenMap + BloomMap;
    //float3 final=lerp(MaxAmount, ScreenMap, Luminance);
    
    //technique 3: inverse multiplication
    //float3 final=(ScreenMap.xyz + BloomMap.xyz * (1-ScreenMap.xyz));
    
    color = float4(final,1);

    return color;
    

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
	
	// sample the source
	float4 cTextureScreen = color;

	
	float x = Tex.x * Tex.y *(time*100);
	x = fmod(x, 13) * fmod(x, 123);	
	float dx = fmod(x, 0.01);

	float3 cResult = cTextureScreen.rgb + cTextureScreen.rgb * saturate(0.1f + dx.xxx * 100);

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
	return (combine  * Contrast)  + Brightness;
    
    
  //  return color;
    
    
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
		PixelShader = compile ps_2_0 PSGlareAmount( AvgLum2x2ImgSamp );
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
		PixelShader = compile ps_2_0 PSBlur( BrightpassImgSamp );
		
	}
	
	//5. repeat blur texture and save in Blur2Img
	pass Blur2
	<
		string RenderColorTarget = "Blur2Img";
	>
	{
		ZEnable = False;
		VertexShader = compile vs_1_1 VS();
		PixelShader = compile ps_2_0 PSBlur( Blur1ImgSamp );
		
	}
	
	//6. repeat blur again
	pass Blur3
	<
		string RenderColorTarget = "Blur1Img";
	>
	{
		ZEnable = False;
		VertexShader = compile vs_1_1 VS();
		PixelShader = compile ps_2_0 PSBlur( Blur2ImgSamp );
		
	}
	
	pass Blur4
	<
		string RenderColorTarget = "Blur2Img";
	>
	{
		ZEnable = False;
		VertexShader = compile vs_1_1 VS();
		PixelShader = compile ps_2_0 PSBlur( Blur1ImgSamp );
		
	}
	
	pass Blur5
	<
		string RenderColorTarget = "Blur1Img";
	>
	{
		ZEnable = False;
		VertexShader = compile vs_1_1 VS();
		PixelShader = compile ps_2_0 PSBlur( Blur2ImgSamp );
		
	}
	
	
	
	
	
	
	
	
	//send the combined image to the screen
	pass Present
	<
		string RenderColorTarget = "";
	>
	{
		VertexShader = compile vs_1_1 VS();
		PixelShader = compile ps_2_b PSPresent( frameSamp, Blur1ImgSamp, AvgLumFinalSamp );
	}
}

