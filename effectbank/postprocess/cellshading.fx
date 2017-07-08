string Description = "Cartoon shader by Joshua Bawden Brett";
string Thumbnail = "EdgeDetect.png";

//Shader edited for Nomad Mod

float2 ViewSize : ViewSize;

float EdgeHardness
<
	string UIWidget = "slider";
	float UIMax = 3.0;
	float UIMin = 0.0;
	float UIStep = 0.01;
> = 1.000000;

//box filter, declare in pixel offsets convert to texel offsets in PS
float2 DownFilterSamples[9] =
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

float2 EdgeOffsets[9] =
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

float EdgeWeightsH[9] =
{
    1,  2,  1,
    0,  0,  0,
   -1, -2, -1
};

float EdgeWeightsV[9] =
{
   -1,  0,  1,
   -2,  0,  2,
   -1,  0,  1
};

texture frameImg : RENDERCOLORTARGET
< 
	string ResourceName = "";
	float2 ViewportRatio = { 1.0, 1.0 };
>;

sampler2D frameImgSamp = sampler_state {
    Texture = < frameImg >;
    MinFilter = Linear; MagFilter = Linear; MipFilter = Linear;
    AddressU = Clamp; AddressV = Clamp;
};

texture EdgeImg : RENDERCOLORTARGET 
< 
	string ResourceName = ""; 
	float2 ViewportRatio = { 1.0, 1.0 };
>;

sampler2D EdgeSamp = sampler_state {
    Texture = < EdgeImg >;
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

	//needs to be shifted by half a pixel.
    //Go here for more info: http://www.sjbrown.co.uk/?article=directx_texels
    
	float4 oPos = float4( IN.pos.xy + float2( -1.0f/ViewSize.x, 1.0f/ViewSize.y ),0.0,1.0 );
	OUT.pos = oPos;

	float2 uv = (IN.pos.xy + 1.0) / 2.0;
	uv.y = 1 - uv.y; 
	OUT.uv = uv;
	
	return OUT;	
}

float4 PSEdgeDetect( output IN, uniform sampler2D srcTex ) : COLOR
{
	float4 color=0;
	float4 edgeH = 0;
	float4 edgeV = 0;
	float2 scale = EdgeHardness/ViewSize;

        color = tex2D( srcTex, IN.uv );
	
	//Filter to detect the edges
	for (int i = 0; i < 9; i++)
    {
    	float4 pixel = tex2D( srcTex, IN.uv + EdgeOffsets[i].xy*scale );
        edgeH += pixel*EdgeWeightsH[i];
        edgeV += pixel*EdgeWeightsV[i];
    }
    

    
    //merge horizontal and vertical edges into a single value
    float edge = 1- saturate(abs(edgeH.r) + abs(edgeV.r));
    //return edge;
      return edge*color;
}

technique Blur
<
	//specify where the original scene should be drawn
	string RenderColorTarget = "frameImg";
>
{
	//single pass to detect edges and output modified result to screen
	pass EdgeDetect
	<
		string RenderColorTarget = "";
	>
	{
		VertexShader = compile vs_1_1 VS();
		PixelShader = compile ps_2_0 PSEdgeDetect( frameImgSamp );
	}
}
