//
// The Game Creators (www.thegamecreators.com)
// Simple Render
//

#include "basepool.fx"

struct VSIn
{
    float3 pos          : POSITION;
    float3 norm         : NORMAL;
    float2 tex0         : TEXTURE0;
    float3 Tangent 	: TANGENT;
};

struct VSInInst
{
    float3 pos          : POSITION;
    float3 norm         : NORMAL;
    float2 tex0         : TEXTURE0;
    float3 Tangent 	: TANGENT;
    row_major float4x4 mTransform : mTransform;		// instance struct
    uint4 uExtraData : uExtraData;
};

struct VSOut
{
    float4 pos : SV_Position;
    float3 vPos : POSWORLD;		//world space Pos
    float3 Norm : NORMAL;		//Normal
    float2 Tex	: TEXTURE;	        //Texture coordinate
    float3 Tangent : TANGENT;		//Normalized Tangent vector
    float3 planeDist : SV_ClipDistance0;
    float4 colorD : COLOR0;
    float4 colorS : COLOR1;
    float fogDist : TEXTURE1;
    float3 view : TEXTURE2;
    uint TexIndex : TexIndex;
};

cbuffer cbPerCubeRender
{
    float4x4 g_mViewCM[6];
};

cbuffer cbPerTechnique
{
    bool     g_bEnableLighting = true;
    bool     g_bEnableClipping = true;
    bool     g_bPointScaleEnable = false;
    float    g_pointScaleA;
    float    g_pointScaleB;
    float    g_pointScaleC;
    float    g_pointSize;
    float4   g_fAmbientLight;
};
    
cbuffer cbPerViewChange
{
    //viewport params
    float    g_viewportHeight;
    float    g_viewportWidth;
    float    g_nearPlane;
};

cbuffer cbUserChange
{
    float3 g_vLightPos;
    float3 g_vEyePt;
    float g_fRefractionStrength;
};

cbuffer cbImmutable
{
    float3 g_positions[4] =
    {
        float3( -0.5, 0.5, 0 ),
        float3( 0.5, 0.5, 0 ),
        float3( -0.5, -0.5, 0 ),
        float3( 0.5, -0.5, 0 ),
    };
};

Texture2D g_tx2D0;
Texture2D g_tx2D1;
Texture2D g_tx2D2;
Texture2D g_tx2D3;
Texture2DArray g_tx2DA0;
Texture2DArray g_tx2DA1;
Texture2DArray g_tx2DA2;

// Texture samplers
SamplerState g_samLinear
{
    Filter = ANISOTROPIC;
};
SamplerState g_samClamp
{
    AddressU = CLAMP;
    AddressV = CLAMP;
};

DepthStencilState DisableDepth
{
    DepthEnable = FALSE;
    DepthWriteMask = ZERO;
};

DepthStencilState EnableDepth
{
    DepthEnable = TRUE;
    DepthWriteMask = ALL;
};

DepthStencilState EnableDepthNoWrite
{
    DepthEnable = TRUE;
    DepthWriteMask = ZERO;
};

BlendState EnableFrameBuffer
{
    BlendEnable[0] = FALSE;
    RenderTargetWriteMask[0] = 0x0F;
};

BlendState EnableAlphaBlend
{
        BlendEnable[0] = TRUE;
        SrcBlend = SRC_ALPHA;
        DestBlend = INV_SRC_ALPHA;
        BlendOp = ADD;
        SrcBlendAlpha = ONE;
        DestBlendAlpha = ONE;
        BlendOpAlpha = ADD;
	RenderTargetWriteMask[0] = 0x0F;
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
        
        output.Diffuse += max(0,dot( lightDir, worldNormal ) * g_lights[i].Diffuse * fAtten);
        output.Specular += max(0,pow( dot( halfAngle, worldNormal ), 64 ) * g_lights[i].Specular * fAtten );
    }

    output.Diffuse += g_fAmbientLight;
    output.Diffuse.w = 1.0;
    output.Specular.w = 0.0;
 
    return output;
}

//
// VS for emulating fixed function pipeline
//
VSOut VS(VSIn input)
{
    VSOut output = (VSOut)0.0;

    //output our final position in clipspace
    float4 worldPos = mul( float4( input.pos, 1 ), g_mWorld );
    float4 cameraPos = mul( worldPos, g_mView ); //Save cameraPos for fog calculations
    output.pos = mul( cameraPos, g_mProj );

    //save the fog distance for later
    output.fogDist = cameraPos.z;

    //save world pos for later
    output.vPos = worldPos;
        
    //find our clipping planes (fixed function clipping is done in world space)
    if( g_bEnableClipping )
    {
        //calc the distance from the clipping plane
        worldPos.w = 1;
        output.planeDist.x = dot( worldPos, g_clipplanes[0] );
        output.planeDist.y = 1;
        output.planeDist.z = 1;
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
        output.Norm = worldNormal;
        output.Tangent = normalize( mul( input.Tangent, (float3x3)g_mWorld ) );

        ColorsOutput cOut = CalcLighting( worldNormal, worldPos, cameraPos );
        output.colorD = cOut.Diffuse;
        output.colorS = cOut.Specular;
    }
    else
    {
        output.colorD = float4(1,1,1,1);
    }
    
    //propogate texture coordinate
    output.Tex = input.tex0;
    
    return output;
}

VSOut VSInst(VSInInst input)
{
    VSOut output = (VSOut)0.0;

    float4 InstancePosition = mul(float4(input.pos,1), input.mTransform);
    uint iTexID = input.uExtraData.x;
    uint iMask = input.uExtraData.y;
    uint iRes1 = input.uExtraData.z;
    uint iRes2 = input.uExtraData.w;

    // this should be in a GS (maybe) - do not draw instance X
    if ( iMask==1 )
    {
     //output our final position in clipspace
     float4 worldPos = InstancePosition;
     float4 cameraPos = mul( worldPos, g_mView ); //Save cameraPos for fog calculations
     output.pos = mul( cameraPos, g_mProj );

     float4 pPos = mul(worldPos, g_mViewProj);
     output.view.x = 0.5 * (pPos.w + pPos.x);	//CHANGE - modify by w value for projected co-ords
     output.view.y = 0.5 * (pPos.w - pPos.y);
     output.view.z = pPos.w * 1;	//CHANGE since "view" is only float3, put w into z so we can proj divide later

     //save the fog distance for later
     output.fogDist = cameraPos.z;
    
     //save world pos for later
     output.vPos = worldPos;
    
     //find our clipping planes (fixed function clipping is done in world space)
     if( g_bEnableClipping )
     {         
         //calc the distance from the 3 clipping planes
         worldPos.w = 1;
         output.planeDist.x = dot( worldPos, g_clipplanes[0] );
         output.planeDist.y = 1;
         output.planeDist.z = 1;
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
         //float3 worldNormal = normalize( mul( input.norm, (float3x3)g_mWorld ) );
         float3 worldNormal = normalize( mul( input.norm, (float3x3)input.mTransform ) );
         output.Norm = worldNormal;
         output.Tangent = normalize( mul( input.Tangent, (float3x3)input.mTransform ) );

         ColorsOutput cOut = CalcLighting( worldNormal, worldPos, cameraPos );
         output.colorD = cOut.Diffuse;
         output.colorS = cOut.Specular;
     }
     else
     {
         output.colorD = float4(1,1,1,1);
     }
    }

    //propogate texture coordinate
    output.Tex = input.tex0;
    output.TexIndex = iTexID;
    
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

float4 PSScenemain(VSOut input) : SV_Target
{   
    float4 NB = g_tx2DA1.SampleLevel( g_samLinear, float3(input.Tex,input.TexIndex), 0 )*2-1;
    NB = normalize(NB);
    NB=NB*g_fRefractionStrength;
    float2 nuv=float2(input.view.x,input.view.y)/input.view.z+NB ;
    float4 refraction = g_tx2D2.Sample( g_samClamp, nuv );
    float4 glasscolor = g_tx2D0.Sample( g_samLinear, input.Tex );
    float3 glasstex = glasscolor.xyz * glasscolor.w;
    float4 normalColor = float4(refraction.xyz+glasstex,1);
    float fog = CalcFogFactor( input.fogDist );
    return fog * normalColor + (1.0 - fog)*g_fogColor;
}

float4 PSScenemainNoRefraction(VSOut input) : SV_Target
{   
    float4 glasscolor = g_tx2D0.Sample( g_samLinear, input.Tex );
    glasscolor.w=0.2f;
    float fog = CalcFogFactor( input.fogDist );
    return fog * glasscolor + (1.0 - fog)*g_fogColor;
}

technique10 DefaultTEX
{
    pass p0
    {
        SetVertexShader( CompileShader( vs_4_0, VS() ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, PSScenemain() ) );        
        SetBlendState( EnableAlphaBlend, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
    }  
}

technique10 DrawInst
{
    pass p0
    {
        SetVertexShader( CompileShader( vs_4_0, VSInst() ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, PSScenemain() ) );        
        SetBlendState( EnableAlphaBlend, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
    }  
}

technique10 DrawInstNoRefraction
{
    pass p0
    {
        SetVertexShader( CompileShader( vs_4_0, VSInst() ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, PSScenemainNoRefraction() ) );        
        SetBlendState( EnableAlphaBlend, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
    }  
}
