//
// The Game Creators (www.thegamecreators.com)
// Bloom (blur)
//

float blurWidth <> = 10;

float2 ViewSize =
{
    { 1280, 768 }
};

static const int FilterSize = 13;
float2 PixelOffsets [ FilterSize ] =
{
    { -6, 0 },
    { -5, 0 },
    { -4, 0 },
    { -3, 0 },
    { -2, 0 },
    { -1, 0 },
    {  0, 0 },
    {  1, 0 },
    {  2, 0 },
    {  3, 0 },
    {  4, 0 },
    {  5, 0 },
    {  6, 0 },
};
static const float BlurWeights [ FilterSize ] = 
{
    0.002216,
    0.008764,
    0.026995,
    0.064759,
    0.120985,
    0.176033,
    0.200496,
    0.176033,
    0.120985,
    0.064759,
    0.026995,
    0.008764,
    0.002216,
};

Texture2D g_tx2D0;

struct VSIn
{
	float3 pos	: POSITION;
	float2 tex	: TEXTURE0;
};

struct VSOut
{
	float4 pos 	: SV_Position;
  	float2 uv 	: TEXCOORD0;
};

SamplerState g_samLinear
{
    AddressU = Clamp; AddressV = Clamp;
    Filter = MIN_MAG_MIP_LINEAR;
};

DepthStencilState DisableDepth
{
	DepthEnable = FALSE;
	DepthWriteMask = ZERO;
};

BlendState NoAlphaBlend
{
        BlendEnable[0] = FALSE;
	RenderTargetWriteMask[0] = 0x0F;
};

BlendState AlphaBlend
{
        BlendEnable[0] = TRUE;
        SrcBlend = ONE;
        DestBlend = ONE;
        BlendOp = ADD;
        SrcBlendAlpha = ONE;
        DestBlendAlpha = ONE;
        BlendOpAlpha = ADD;
	RenderTargetWriteMask[0] = 0x0F;
};

VSOut VS_blur(VSIn input)
{
    VSOut OUT;
    OUT.uv = input.tex;
    OUT.pos=float4(input.pos,1);
    return OUT;
}

float4 PS_blurV(VSOut input) : SV_Target
{
    float4 color = 0;
    float2 scale = blurWidth/ViewSize;
    for (int i = 0; i < FilterSize; i++)
    {
	color += g_tx2D0.Sample( g_samLinear, input.uv + PixelOffsets[i].yx*scale ) * BlurWeights[i];
    }
    return color;
}


technique10 Bloom
{
    pass p0
    {
        SetVertexShader( CompileShader( vs_4_0, VS_blur() ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, PS_blurV() ) );        
        SetDepthStencilState( DisableDepth, 0 );
        SetBlendState( AlphaBlend, float4( 1.0f, 1.0f, 1.0f, 1.0f ), 0xFFFFFFFF );
    }
}
