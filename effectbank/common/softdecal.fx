//
// The Game Creators (www.thegamecreators.com)
// Soft Decal
//

#include "basepool.fx"

// shader

struct VSIn
{
    float3 pos          : POSITION;
    float3 norm         : NORMAL;
    float2 tex0         : TEXTURE0;
};

struct VSOut
{
    float4 pos : SV_Position;
    float2 tex0 : TEXTURE0;
    float4 spos : TEXTURE1;
    float4 colorD : COLOR0;
    float4 colorS : COLOR1;
    float fogDist : TEXTURE2;
    float3 planeDist : SV_ClipDistance0;
};

struct PSIn
{
    float4 pos : SV_Position;
    float2 tex0 : TEXTURE0;
    float4 spos : TEXTURE1;
    float4 colorD : COLOR0;
    float4 colorS : COLOR1;
    float fogDist : TEXTURE2;
};

cbuffer cbPerTechnique
{
    bool     g_bEnableLighting = true;
    bool     g_bEnableClipping = false;
    bool     g_bPointScaleEnable = false;
    float    g_pointScaleA;
    float    g_pointScaleB;
    float    g_pointScaleC;
    float    g_pointSize;
    float    g_fAlphaFactor;
    float    g_fAlphaTest;
    float4   g_fAmbientLight;
};
    
cbuffer cbPerViewChange
{
    //viewport params
    float    g_viewportHeight;
    float    g_viewportWidth;
    float    g_nearPlane;
};

cbuffer cbUser
{
    float g_fFadeDistance = 20.0f;
}

Texture2D g_tx2D0;
Texture2D g_txDepth;

SamplerState g_samPoint
{
    Filter = MIN_MAG_MIP_POINT;
    AddressU = Clamp;
    AddressV = Clamp;
};

SamplerState g_samLinear
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

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

DepthStencilState DisableDepthWrite
{
    DepthEnable = TRUE;
    DepthWriteMask = ZERO;
};

struct ColorsOutput
{
    float4 Diffuse;
    float4 Specular;
};

ColorsOutput CalcLighting( float3 worldNormal, float3 worldPos, float3 cameraPos )
{
    ColorsOutput output = (ColorsOutput)0.0;
    
    for(int i=0; i<g_LightsUsed; i++)
    {
        float3 toLight = g_lights[i].Position.xyz - worldPos;
        float lightDist = max(length( toLight ),200);
        float fAtten = 1.0/dot( g_lights[i].Atten, float4(1,lightDist,lightDist*lightDist,0) );
        float3 lightDir = normalize( toLight );
        float3 halfAngle = normalize( normalize(-cameraPos) + lightDir );
        
        output.Diffuse += max(0,dot( lightDir, worldNormal ) * g_lights[i].Diffuse * fAtten) + g_lights[i].Ambient;
        output.Specular += max(0,pow( dot( halfAngle, worldNormal ), 64 ) * g_lights[i].Specular * fAtten );
    }

    output.Diffuse += g_fAmbientLight;
    output.Diffuse.w = 1.0;
    output.Specular.w = 0.0f;
 
    return output;
}

VSOut VSScenemain(VSIn input)
{
    VSOut output = (VSOut)0.0;

    //output our final position in clipspace
    float4 worldPos = mul( float4( input.pos, 1 ), g_mWorld );
    float4 cameraPos = mul( worldPos, g_mView );
    output.pos = mul( cameraPos, g_mProj );
    output.spos = output.pos;
           
    //save the fog distance for later
    output.fogDist = cameraPos.z;
        
    //find our clipping planes (fixed function clipping is done in world space)
    if( g_bEnableClipping )
    {
        //calc the distance from the 3 clipping planes
        worldPos.w = 1;
        output.planeDist.x = dot( worldPos, g_clipplanes[0] );
        output.planeDist.y = dot( worldPos, g_clipplanes[1] );
        output.planeDist.z = dot( worldPos, g_clipplanes[2] );
    }
    else
    {
        output.planeDist.x = 1;
        output.planeDist.y = 1;
        output.planeDist.z = 1;
    }
    
    //do gouraud lighting
    if( g_bEnableLighting )
    {
        float3 worldNormal = normalize( mul( input.norm, (float3x3)g_mWorld ) );
        ColorsOutput cOut = CalcLighting( worldNormal, worldPos, cameraPos );
        output.colorD = cOut.Diffuse;
        output.colorS = cOut.Specular;
    }
    else
    {
        output.colorD = float4(1,1,1,1);
    }
    
    //propogate texture coordinate
    output.tex0 = input.tex0;
    
    return output;
}

float CalcFogFactor( float d )
{
    float fogCoeff = 1.0;
    if( FOGMODE_LINEAR == g_fogMode )
    {
        fogCoeff = (g_fogEnd - d)/(g_fogEnd - g_fogStart);
    }
    return clamp( fogCoeff, 0, 1 );
}

float4 PSScenemain(PSIn input) : SV_Target
{   
    float4 texColor = g_tx2D0.Sample( g_samLinear, input.tex0 );
    if ( texColor.a < g_fAlphaTest )
        discard;

    //calculate the color based off of the normal, textures, etc
    float4 normalColor = texColor * input.colorD + input.colorS;
    float4 color = normalColor;
    color.w = color.w * g_fAlphaFactor;

    // screenspace coordinates for the lookup into the depth buffer and output depth
    float2 inputScreenTex = input.spos.xy/input.spos.w;
    float2 inputDepth = input.spos.zw;
    float2 screenTex = 0.5*( (inputScreenTex) + float2(1,1));
    screenTex.y = 1 - screenTex.y;
    float particleDepth = inputDepth.x;
    particleDepth /= inputDepth.y;

    // work out depth difference        
    float depthFade = 1.0;
    float depthSample = g_txDepth.Sample( g_samPoint, screenTex );
    float4 depthViewSample = mul( float4( inputScreenTex, depthSample, 1 ), g_mInvProj );
    float4 depthViewParticle = mul( float4( inputScreenTex, particleDepth, 1 ), g_mInvProj );
    float depthDiff = depthViewSample.z/depthViewSample.w - depthViewParticle.z/depthViewParticle.w;
    if ( depthDiff < 0 )
	discard;
            
    depthFade = saturate( depthDiff / g_fFadeDistance );
    color.w *= depthFade;

    float fog = CalcFogFactor( input.fogDist );
    float4 fogcol = fog * color + (1.0 - fog)*g_fogColor;
    return float4(fogcol.xyz,color.w);
}

technique10 DefaultCOL
{
    pass p0
    {
        SetVertexShader( CompileShader( vs_4_0, VSScenemain() ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, PSScenemain() ) );
        SetBlendState( EnableTransparency, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
        SetDepthStencilState( DisableDepthWrite, 0 );
    }  
}
