string Description = "DOF [Depth of Field] shader by Joshua Bawden Brett";
string Thumbnail = "DepthOfField.png";

//Shader edited for Nomad Mod

float2 ViewSize : ViewSize;

//box filter, declare in pixel offsets convert to texel offsets in PS
float2 PixelOffsets[9] =
{
    { -1,  -1 },
    { -1,  0  },
    { -1,  1  },
    { 0,   1  },
    { 1,   1  },
    { 1,   0  },
    { 1,   -1 },
    { 0,   -1 },
    { 0,   0  },
};

float blurSize
<
	string UIWidget = "slider";
	float UIMax = 5.0;
	float UIMin = 0.1;
	float UIStep = 0.001;
> = 2.500000;

float focalDistance
<
	string UIWidget = "slider";
	float UIMax = 1.0;
	float UIMin = 0.0;
	float UIStep = 0.001;
> = 0.850000;

//scene image
texture frame : RENDERCOLORTARGET
< 
	string ResourceName = "";
	float2 ViewportRatio = { 1.0, 1.0 };
>;

sampler2D frameSamp = sampler_state {
    Texture = < frame >;
    MinFilter = Linear; MagFilter = Linear; MipFilter = Linear;
    AddressU = Clamp; AddressV = Clamp;
};

//downsample image
texture Downsample1Img : RENDERCOLORTARGET 
< 
	string ResourceName = ""; 
	float2 ViewportRatio = { 1.0, 1.0 };
>;

sampler2D Downsample1Samp = sampler_state {
    Texture = < Downsample1Img >;
    MinFilter = Linear; MagFilter = Linear; MipFilter = Linear;
    AddressU = Clamp; AddressV = Clamp;
};

//downsample image
texture Downsample2Img : RENDERCOLORTARGET 
< 
	string ResourceName = ""; 
	float2 ViewportRatio = { 1.0, 1.0 };
>;

sampler2D Downsample2Samp = sampler_state {
    Texture = < Downsample2Img >;
    MinFilter = Linear; MagFilter = Linear; MipFilter = Linear;
    AddressU = Clamp; AddressV = Clamp;
};

struct input 
{
	float4 pos : POSITION;
	float2 uv : TEXCOORD0;
};
 
struct output {

	float4 pos: POSITION;
	float2 uv: TEXCOORD0;

};

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

//downsample used to blur the image
float4 PSDownsample( output IN, uniform sampler2D srcTex, uniform float reduceRatio ) : COLOR
{
    float4 color = 0;
    float2 scale = (reduceRatio*blurSize)/ViewSize;
    
    float4 center = tex2D( srcTex, IN.uv );
    float alpha1 = abs(center.a - focalDistance) * 2;
    
    for (int i = 0; i < 9; i++)
    {
        //convert pixel offsets into texel offsets via the inverse view values.
        float4 newColor = tex2D( srcTex, IN.uv + PixelOffsets[i].xy*scale );    
        float alpha2 = abs(newColor.a - 0.5) * 2;
        color += lerp(center, newColor, alpha1*alpha2);
    }

    return color / 9;    
}

//copy the low res downsample into a high res screen quad using bilinear filtering
float4 PSPresent( output IN, uniform sampler2D srcTex ) : COLOR
{
    return tex2D(srcTex,IN.uv);
}
  
technique Blur
<
	string RenderColorTarget = "frame";
>
{
	pass Downsample
	<
		string RenderColorTarget = "Downsample1Img";
	>
	{
		ZEnable = False;
		VertexShader = compile vs_1_1 VS();
		PixelShader = compile ps_2_a PSDownsample( frameSamp, 1.0 );
	}
	
	pass Downsample2
	<
		string RenderColorTarget = "Downsample2Img";
	>
	{
		ZEnable = False;
		VertexShader = compile vs_1_1 VS();
		PixelShader = compile ps_2_a PSDownsample( Downsample1Samp, 1.0 );
	}

	pass Present
	<
		string RenderColorTarget = "";
	>
	{
		VertexShader = compile vs_1_1 VS();
		PixelShader = compile ps_2_0 PSPresent( Downsample2Samp );
	}
}
