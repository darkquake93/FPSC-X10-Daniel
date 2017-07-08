//
// The Game Creators (www.thegamecreators.com)
// Blur
//

float blurWidth <> = 0.008f;
float Brightness <> = 1.0f;

Texture2D g_tx2D0;

struct VSIn
{
	float3 pos	: POSITION;
	float2 tex	: TEXTURE0;
};

struct VSOut
{
	float4 pos 	: SV_Position;
  	float2 uva 	: TEXCOORD0;
  	float2 uvb 	: TEXCOORD1;
  	float2 uvc 	: TEXCOORD2;
  	float2 uvd 	: TEXCOORD3;
  	float2 uv	: TEXCOORD4;
};

SamplerState g_samLinear
{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};

BlendState EnableAlphaBlend
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

BlendState DisableAlphaBlend
{
	BlendEnable[0] = FALSE;
	RenderTargetWriteMask[0] = 0x0F;
};

DepthStencilState DisableDepth
{
	DepthEnable = FALSE;
	DepthWriteMask = ZERO;
};

VSOut VS_blurA(VSIn input)
{
   	VSOut OUT;
    	OUT.uva = input.tex+blurWidth*(1*float2(1.5,0.5));
    	OUT.uvb = input.tex+blurWidth*(1*float2(0.5,0.5)); 
    	OUT.uvc = input.tex+blurWidth*(1*float2(-0.5,0.5));
    	OUT.uvd = input.tex+blurWidth*(1*float2(-1.5,0.5));
    	OUT.uv = input.tex;
    	OUT.pos=float4(input.pos,1);
   	return OUT;
}

VSOut VS_blurB(VSIn input)
{
   	VSOut OUT;
    	OUT.uva = input.tex+blurWidth*(1*float2(1.5,-0.5));
    	OUT.uvb = input.tex+blurWidth*(1*float2(0.5,-0.5)); 
    	OUT.uvc = input.tex+blurWidth*(1*float2(-0.5,-0.5));
    	OUT.uvd = input.tex+blurWidth*(1*float2(-1.5,-0.5));
    	OUT.uv = input.tex;
    	OUT.pos=float4(input.pos,1);
   	return OUT;
}

VSOut VS_blurC(VSIn input)
{
   	VSOut OUT;
    	OUT.uva = input.tex+blurWidth*(1*float2(1.5,1.5));
    	OUT.uvb = input.tex+blurWidth*(1*float2(0.5,1.5)); 
    	OUT.uvc = input.tex+blurWidth*(1*float2(-0.5,1.5));
    	OUT.uvd = input.tex+blurWidth*(1*float2(-1.5,1.5));
    	OUT.uv = input.tex;
    	OUT.pos=float4(input.pos,1);
   	return OUT;
}

VSOut VS_blurD(VSIn input)
{
   	VSOut OUT;
    	OUT.uva = input.tex+blurWidth*(1*float2(1.5,-1.5));
    	OUT.uvb = input.tex+blurWidth*(1*float2(0.5,-1.5)); 
    	OUT.uvc = input.tex+blurWidth*(1*float2(-0.5,-1.5));
    	OUT.uvd = input.tex+blurWidth*(1*float2(-1.5,-1.5));
    	OUT.uv = input.tex;
    	OUT.pos=float4(input.pos,1);
   	return OUT;
}

float4 PS_blurA(VSOut input) : SV_Target
{
	// calculate blurred shadow as normal (using hard component)
	// Y component stores blurrable shadow based on distance from caster
   	float4 tex=(g_tx2D0.Sample( g_samLinear, input.uva).yyyy)/4;
   	tex=tex+(g_tx2D0.Sample( g_samLinear, input.uvb).yyyy)/4;
   	tex=tex+(g_tx2D0.Sample( g_samLinear, input.uvc).yyyy)/4;
   	tex=tex+(g_tx2D0.Sample( g_samLinear, input.uvd).yyyy)/4;	
	float4 fullblur = tex;

	// get raw shadow info ( red=distance from viewer / green=distance from light / blue=1 )
   	float4 rawcolor = g_tx2D0.Sample( g_samLinear, input.uv);

	// X component stores sharp shadow from caster
	fullblur += rawcolor.x;

	// global strength of shadow
	fullblur *= Brightness;

	// final pixel
	fullblur.w = 1;
  	return fullblur;
} 

technique10 Blur
{
    pass p0
    {
        SetVertexShader( CompileShader( vs_4_0, VS_blurA() ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, PS_blurA() ) );        
        SetBlendState( DisableAlphaBlend, float4( 1.0f, 1.0f, 1.0f, 1.0f ), 0xFFFFFFFF );
        SetDepthStencilState( DisableDepth, 0 );
    }  
    pass p1
    {
        SetVertexShader( CompileShader( vs_4_0, VS_blurB() ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, PS_blurA() ) );        
        SetBlendState( EnableAlphaBlend, float4( 1.0f, 1.0f, 1.0f, 1.0f ), 0xFFFFFFFF );
        SetDepthStencilState( DisableDepth, 0 );
    }  
    pass p2
    {
        SetVertexShader( CompileShader( vs_4_0, VS_blurC() ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, PS_blurA() ) );        
        SetBlendState( EnableAlphaBlend, float4( 1.0f, 1.0f, 1.0f, 1.0f ), 0xFFFFFFFF );
        SetDepthStencilState( DisableDepth, 0 );
    }  
    pass p3
    {
        SetVertexShader( CompileShader( vs_4_0, VS_blurD() ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, PS_blurA() ) );        
        SetBlendState( EnableAlphaBlend, float4( 1.0f, 1.0f, 1.0f, 1.0f ), 0xFFFFFFFF );
        SetDepthStencilState( DisableDepth, 0 );
    }  
}
