//
// The Game Creators (www.thegamecreators.com)
// Bloom (tone and downsize)
//

float2 ViewSize =
{
    { 1280, 768 }
};

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

Texture2D g_tx2D0;
float4 g_fBloomColor;

struct VSIn
{
	float3 pos	: POSITION;
	float2 tex	: TEXTURE0;
};

struct VSOut
{
	float4 pos 	: SV_Position;
  	float2 tex 	: TEXCOORD0;
};

SamplerState g_samLinear
{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};

DepthStencilState DisableDepth
{
	DepthEnable = FALSE;
	DepthWriteMask = ZERO;
};

VSOut VS(VSIn input)
{
	VSOut OUT;
	OUT.pos=float4(input.pos,1);
 	OUT.tex=input.tex; 
	return OUT;
}

float4 PS(VSOut input) : SV_Target
{   
    float4 color = 0;
    float2 scale = 1.0/ViewSize;
    for (int i = 0; i < 9; i++)
    {
	color += g_tx2D0.Sample( g_samLinear, input.tex + DownFilterSamples[i].xy*scale );
    }
    color /= 9;
    color += g_fBloomColor;
    return color;
}

technique10 Bloomtone
{
    pass p0
    {
        SetVertexShader( CompileShader( vs_4_0, VS() ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, PS() ) );        
        SetDepthStencilState( DisableDepth, 0 );
    }
}
