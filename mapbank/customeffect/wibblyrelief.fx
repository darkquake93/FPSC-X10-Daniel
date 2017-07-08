//
// The Game Creators (www.thegamecreators.com)
// Crazy Wibbly Relief Shader (parallax relief mapping gone nuts)
//

#include "basepool.fx"

struct a2v
{
    float3 pos	   : POSITION;		//Position
    float3 normal  : NORMAL;		//Normal
    float2 txcoord : TEXTURE;		//Texture coordinate
    float3 tangent : TANGENT;		//Normalized Tangent vector
};

struct v2f
{
    float4 hpos		: SV_Position;
    float4 colorD	: COLOR0;
    float2 txcoord	: TEXCOORD0;
    float3 vpos		: TEXCOORD1;
    float3 tangent	: TEXCOORD2;
    float3 binormal	: TEXCOORD3;
    float3 normal	: TEXCOORD4;
    float4 lightpos	: TEXCOORD5;
};

float depth = 0.08;

cbuffer cb0
{
    float g_fTime;
};

cbuffer cbUserChange
{
    float3 g_vLightPos;
    float3 g_vEyePt;
};

cbuffer cbImmutable
{
    float4 g_fAmbientLight;
    float g_fAlphaFactor;
};

// Textures
Texture2D g_tx2D0;
Texture2D g_tx2D1;
Texture2D g_tx2D2;
Texture2D g_tx2D3;

// Texture sampler
SamplerState g_samLinear
{
    Filter = ANISOTROPIC;
    AddressU = Clamp;
    AddressV = Clamp;
};

// State
BlendState EnableTransparency
{
    AlphaToCoverageEnable = FALSE;
    BlendEnable[0] = TRUE;
    SrcBlend = SRC_ALPHA;
    DestBlend = INV_SRC_ALPHA;
    BlendOp = ADD;
    SrcBlendAlpha = ZERO;
    DestBlendAlpha = ZERO;
    BlendOpAlpha = ADD;
    RenderTargetWriteMask[0] = 0x0F;
};
DepthStencilState EnableDepth
{
    DepthEnable = TRUE;
    DepthWriteMask = ALL;
};

struct ColorsOutput
{
    float4 Diffuse;
};

ColorsOutput CalcLighting( float3 worldNormal, float3 worldPos )
{
    ColorsOutput output = (ColorsOutput)0.0;

    for(int i=0; i<g_LightsUsed; i++)
    {
        float3 toLight = g_lights[i].Position.xyz - worldPos;
        float lightDist = max(length( toLight ),200);
        float fAtten = 1.0/dot( g_lights[i].Atten, float4(1,lightDist,lightDist*lightDist,0) );
        float3 lightDir = normalize( toLight );
        output.Diffuse += max(0,dot( lightDir, worldNormal ) * g_lights[i].Diffuse * fAtten);
    }
    output.Diffuse.w = 1.0;

    return output;
}

v2f VS(a2v IN)
{
	v2f OUT;

	// vertex position in object space
	float4 pos=float4(IN.pos.x,IN.pos.y,IN.pos.z,1.0);

	// compute modelview rotation only part
	float3x3 modelviewrot;
	modelviewrot[0]=g_mWorldView[0].xyz;
	modelviewrot[1]=g_mWorldView[1].xyz;
	modelviewrot[2]=g_mWorldView[2].xyz;

	// vertex position in clip space
	OUT.hpos=mul(pos,g_mWorldViewProj);

	// vertex position in view space (with model transformations)
	OUT.vpos=mul(pos,g_mWorldView).xyz;

	// light position in view space
	float4 lp=float4(g_vLightPos.x,g_vLightPos.y,g_vLightPos.z,1);
	OUT.lightpos=mul(lp,g_mView);

	// tangent space vectors in view space (with model transformations)
	OUT.tangent=normalize(mul(IN.tangent,modelviewrot));
	OUT.normal=normalize(mul(IN.normal,modelviewrot));

        // Calculate binormal here
	float3 binormal = normalize( cross( IN.normal, IN.tangent ) );
	OUT.binormal=normalize(mul(binormal,modelviewrot));
	
	// copy texture coordinates
	OUT.txcoord=IN.txcoord.xy;

        // Diffuse color of gun
        float4 worldPos = mul( float4(IN.pos,1), g_mWorld );
        ColorsOutput cOut = CalcLighting( OUT.normal, worldPos.xyz );
        OUT.colorD = cOut.Diffuse;

	return OUT;
}

float ray_intersect_rm( float2 dp, float2 ds)
{
	const int linear_search_steps=15;
	const int binary_search_steps=5;
	float depth_step=1.0/linear_search_steps;

	// current size of search window
	float size=depth_step;
	// current depth position
	float depth=0.0;
	// best match found (starts with last position 1.0)
	float best_depth=1.0;

	// search front to back for first point inside object
	for( int i=0;i<linear_search_steps-1;i++ )
	{
		depth+=size;
		float4 t=(1.0-g_tx2D1.Sample( g_samLinear, dp+ds*depth ))-0.5;

		if (best_depth>0.996)	// if no depth found yet
			if (depth>=t.w)
				best_depth=depth;	// store best depth
	}
	depth=best_depth;
	
	// recurse around first point (depth) for closest match
	for( int i=0;i<binary_search_steps;i++ )
	{
		size*=0.5;
		float4 t=(1.0-g_tx2D1.Sample( g_samLinear, dp+ds*depth ))-0.5;
		if (depth>=t.w)
		{
			best_depth=depth;
			depth-=2*size;
		}
		depth+=size;
	}

	return best_depth;
}

float4 PS(v2f IN) : SV_Target
{
	float4 t;
	float3 p,v,l,s;
	float2 dp,ds,uv;
	float d,a;
	dp = IN.txcoord;
	float4 DiffuseOriginal = g_tx2D0.Sample( g_samLinear, dp );
	if ( DiffuseOriginal.w==0 ) discard;

	// ray intersect in view direction
	p  = IN.vpos;
	v  = normalize(p);
	a  = dot(IN.normal,-v);
	s  = normalize(float3(dot(v,IN.tangent),dot(v,IN.binormal),a));
	float wibbledepth = depth * (1+cos(IN.txcoord.x*5+IN.txcoord.y*5+g_fTime*2));
	s *= wibbledepth/a;
	ds = s.xy;
	d  = ray_intersect_rm(dp,ds);
	
	// get rm and color texture points
	uv=dp+ds*d;
	t=g_tx2D1.Sample( g_samLinear, uv );
	float4 Diffuse = g_tx2D0.Sample( g_samLinear, uv );

	// expand normal from normal map in local polygon space
	t.xy=t.xy*2.0-1.0;
	t.z=sqrt(1.0-dot(t.xy,t.xy));
	t.xyz=normalize(t.x*IN.tangent-t.y*IN.binormal+t.z*IN.normal);

	// compute light direction
	p += v*d*a;
	l=normalize(p-IN.lightpos.xyz);
	
	// compute diffuse and specular terms
	float att=saturate(dot(-l,IN.normal.xyz));
	float diff=saturate(dot(-l,t.xyz));
	float spec=saturate(pow(saturate(dot(normalize(-l-v),t.xyz)),16));
        float3 Shine = g_tx2D2.Sample( g_samLinear, uv );

	float4 combineLight = IN.colorD*att;
	float4 finaldiffuse = (Diffuse*combineLight);
	float4 normalColor = finaldiffuse + (spec*float4(Shine,1))*att + Diffuse*g_fAmbientLight*2;

        // determine level of alpha used
	normalColor.w = (1.0-g_fAlphaFactor)+(DiffuseOriginal.w*g_fAlphaFactor);

	return normalColor;
}

technique10 Default3TEX
{
    pass P0
    {       
        SetVertexShader( CompileShader( vs_4_0, VS() ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, PS() ) );
        SetBlendState( EnableTransparency, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
        SetDepthStencilState( EnableDepth, 0 );
    }
}
