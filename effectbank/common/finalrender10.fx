//
// The Game Creators (www.thegamecreators.com)
// Base Effect Foundation
//

float BloomBrightness <> = 5.0f;

Texture2D g_tx2D0;
Texture2D g_tx2D1;
Texture2D g_tx2D2;

struct VSIn
{
	float3 pos	: POSITION;
	float3 norm 	: NORMAL;
	float2 tex	: TEXTURE0;
};

struct VSOut
{
	float4 pos 	: SV_Position;
	float2 tex 	: TEXTURE0;
};

struct PSIn
{
	float4 pos 	: SV_Position;
	float2 tex 	: TEXTURE0;
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

float4 PS_Hard(PSIn input) : SV_Target
{   
	float4 color = g_tx2D0.Sample( g_samLinear, input.tex );
	return color;	
}

float4 PS_Soft(PSIn input) : SV_Target
{   
	float4 color = g_tx2D0.Sample( g_samLinear, input.tex );

	float BloomPower = 3.0f;
	float BloomScale = BloomBrightness;
        float3 bloomsrc = pow(g_tx2D1.Sample( g_samLinear, input.tex ),BloomPower) * BloomScale;
	float4 bloom = float4(bloomsrc,1);

        float4 shade = g_tx2D2.Sample( g_samLinear, input.tex );
	float4 result = (color+bloom) * (0.5+((1-shade)*0.5));	
	return result;	
}

technique10 soft
{
    pass p0
    {
        SetVertexShader( CompileShader( vs_4_0, VS() ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, PS_Soft() ) );        
        SetDepthStencilState( DisableDepth, 0 );
    }  
}

technique10 hard
{
    pass p0
    {
        SetVertexShader( CompileShader( vs_4_0, VS() ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, PS_Hard() ) );        
        SetDepthStencilState( DisableDepth, 0 );
    }  
}
