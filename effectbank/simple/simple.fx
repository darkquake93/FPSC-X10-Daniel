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
Texture2DArray g_tx2DA0;
Texture2DArray g_tx2DA1;
Texture2DArray g_tx2DA2;
uint g_iNonInstTexID;

// Texture samplers
SamplerState g_samLinear
{
    Filter = ANISOTROPIC;
    AddressU = Wrap;
    AddressV = Wrap;
    AddressW = Wrap;
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
        
	//130110 - make dynamic light as strong as equal static light!        
        //output.Diffuse += max(0,dot( lightDir, worldNormal ) * g_lights[i].Diffuse * fAtten);
        output.Diffuse += max(0,dot( lightDir, worldNormal ) * g_lights[i].Diffuse * fAtten) * 5;
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
    output.TexIndex = g_iNonInstTexID;
    
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
    float4 normalColor = g_tx2D0.Sample( g_samLinear, input.Tex ) * input.colorD;
    float fog = CalcFogFactor( input.fogDist );
    return fog * normalColor + (1.0 - fog)*g_fogColor;
}

float4 PSScenemainTEXARRAYATZERO(VSOut input) : SV_Target
{   
    float4 normalColor = g_tx2DA0.SampleLevel( g_samLinear, float3(input.Tex,input.TexIndex), 0 ) * input.colorD;
    float fog = CalcFogFactor( input.fogDist );
    return fog * normalColor + (1.0 - fog)*g_fogColor;
}

float4 PSScenemainDNS(VSOut input) : SV_Target
{   
    float4 origdiffuse = g_tx2D0.Sample( g_samLinear, input.Tex );
    float4 diffuse = origdiffuse;
    if ( diffuse.a < 0.01 ) discard;

    float3 Norm = g_tx2D1.Sample( g_samLinear, input.Tex );
    float4 ShineWithIllum = g_tx2D2.Sample( g_samLinear, input.Tex );
    float3 Shine = ShineWithIllum.xyz;

    float Bumpy = 2.0;
    float SpecExpon = 4.0;
    float3 bumps = Bumpy * (Norm-(0.5).xxx);
    float3 Nn = normalize(input.Norm);
    float3 Tn = normalize(input.Tangent);
    float3 Bn = normalize( cross( input.Norm, input.Tangent ) );
    float3 Nb = Nn + (bumps.x * Tn + bumps.y * Bn);
    Norm = normalize(Nb);
    float3 lightDir = normalize( g_vLightPos - input.vPos );
    float3 viewDir = normalize( g_vEyePt - input.vPos );

    //diffuse lighting
    float lightAmt = saturate( dot( lightDir, Norm ) ) / 1.5;

    // Calculate specular power
    float3 halfAngle = normalize( lightDir + viewDir );
    float4 spec = saturate( pow( dot( halfAngle, Norm ), SpecExpon ) );

    // 130907 - subtractive bump mapping (does not add moving light to render)
    float fSutractLight = max(0,1-lightAmt.x);
    float4 combineLight = max(0,input.colorD-float4(fSutractLight,fSutractLight,fSutractLight,0));
    combineLight = max(0,combineLight-ShineWithIllum.w);
    float4 finaldiffuse = (diffuse*combineLight)+(diffuse*ShineWithIllum.w);

    // Return combined lighting
    float4 normalColor = finaldiffuse + (spec*float4(Shine,1))*finaldiffuse + diffuse*g_fAmbientLight;
    float fog = CalcFogFactor( input.fogDist );
    return fog * normalColor + (1.0 - fog)*g_fogColor;
}

float4 PSScenemainDNSTEXARRAYATZERO(VSOut input) : SV_Target
{   
    float4 origdiffuse = g_tx2DA0.SampleLevel( g_samLinear, float3(input.Tex,input.TexIndex), 0 );
    float4 diffuse = origdiffuse;
    if ( diffuse.a < 0.01 ) discard;

    float3 Norm = g_tx2D1.Sample( g_samLinear, input.Tex );
    float4 ShineWithIllum = g_tx2D2.Sample( g_samLinear, input.Tex );
    float3 Shine = ShineWithIllum.xyz;

    float Bumpy = 2.0;
    float SpecExpon = 4.0;
    float3 bumps = Bumpy * (Norm-(0.5).xxx);
    float3 Nn = normalize(input.Norm);
    float3 Tn = normalize(input.Tangent);
    float3 Bn = normalize( cross( input.Norm, input.Tangent ) );
    float3 Nb = Nn + (bumps.x * Tn + bumps.y * Bn);
    Norm = normalize(Nb);
    float3 lightDir = normalize( g_vLightPos - input.vPos );
    float3 viewDir = normalize( g_vEyePt - input.vPos );

    //diffuse lighting
    float lightAmt = saturate( dot( lightDir, Norm ) ) / 1.5;
    //float4 lightColor = float4(lightAmt.xxx,1);

    // Calculate specular power
    float3 halfAngle = normalize( lightDir + viewDir );
    float4 spec = saturate( pow( dot( halfAngle, Norm ), SpecExpon ) );

    // 200807 - previous bump map had moving lights over them
    // texture, bump light and diffuse + illumination component
    // float4 combineLight = max(0,((lightColor+input.colorD)/2)-ShineWithIllum.w);
    // float4 finaldiffuse = (diffuse*combineLight)+(diffuse*ShineWithIllum.w);

    // 130907 - subtractive bump mapping (does not add moving light to render)
    float fSutractLight = max(0,1-lightAmt.x);
    float4 combineLight = max(0,input.colorD-float4(fSutractLight,fSutractLight,fSutractLight,0));
    combineLight = max(0,combineLight-ShineWithIllum.w);
    float4 finaldiffuse = (diffuse*combineLight)+(diffuse*ShineWithIllum.w);

    // Return combined lighting
    float4 normalColor = finaldiffuse + (spec*float4(Shine,1))*finaldiffuse + diffuse*g_fAmbientLight;
    float fog = CalcFogFactor( input.fogDist );
    return fog * normalColor + (1.0 - fog)*g_fogColor;
}

float4 PSScenemainDNSTEXARRAYATALL(VSOut input) : SV_Target
{   
    float4 origdiffuse = g_tx2DA0.SampleLevel( g_samLinear, float3(input.Tex,input.TexIndex), 0 );
    float4 diffuse = origdiffuse;
    if ( diffuse.a < 0.01 ) discard;

    float3 Norm = g_tx2DA1.SampleLevel( g_samLinear, float3(input.Tex,input.TexIndex), 0 );
    float4 ShineWithIllum = g_tx2DA2.SampleLevel( g_samLinear, float3(input.Tex,input.TexIndex), 0 );
    float3 Shine = ShineWithIllum.xyz;

    float Bumpy = 2.0;
    float SpecExpon = 4.0;
    float3 bumps = Bumpy * (Norm-(0.5).xxx);
    float3 Nn = normalize(input.Norm);
    float3 Tn = normalize(input.Tangent);
    float3 Bn = normalize( cross( input.Norm, input.Tangent ) );
    float3 Nb = Nn + (bumps.x * Tn + bumps.y * Bn);
    Norm = normalize(Nb);
    float3 lightDir = normalize( g_vLightPos - input.vPos );
    float3 viewDir = normalize( g_vEyePt - input.vPos );

    //diffuse lighting
    float lightAmt = saturate( dot( lightDir, Norm ) ) / 1.5;
    //float4 lightColor = float4(lightAmt.xxx,1);

    // Calculate specular power
    float3 halfAngle = normalize( lightDir + viewDir );
    float4 spec = saturate( pow( dot( halfAngle, Norm ), SpecExpon ) );

    // 200807 - previous bump map had moving lights over them
    // texture, bump light and diffuse + illumination component
    // float4 combineLight = max(0,((lightColor+input.colorD)/2)-ShineWithIllum.w);
    // float4 finaldiffuse = (diffuse*combineLight)+(diffuse*ShineWithIllum.w);

    // 130907 - subtractive bump mapping (does not add moving light to render)
    float fSutractLight = max(0,1-lightAmt.x);
    float4 combineLight = max(0,input.colorD-float4(fSutractLight,fSutractLight,fSutractLight,0));
    combineLight = max(0,combineLight-ShineWithIllum.w);
    float4 finaldiffuse = (diffuse*combineLight)+(diffuse*ShineWithIllum.w);

    // Return combined lighting
    float4 normalColor = finaldiffuse + (spec*float4(Shine,1))*finaldiffuse + diffuse*g_fAmbientLight;
    float fog = CalcFogFactor( input.fogDist );
    return fog * normalColor + (1.0 - fog)*g_fogColor;
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

technique10 Default1TEX
{
    pass p0
    {
        SetVertexShader( CompileShader( vs_4_0, VS() ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, PSScenemain() ) );        
        SetBlendState( EnableAlphaBlend, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
    }  
}

technique10 Default2TEX
{
    pass p0
    {
        SetVertexShader( CompileShader( vs_4_0, VS() ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, PSScenemain() ) );        
        SetBlendState( EnableAlphaBlend, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
    }  
}

technique10 Default3TEX
{
    pass p0
    {
        SetVertexShader( CompileShader( vs_4_0, VS() ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, PSScenemainDNS() ) );        
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

technique10 DrawInstTEXARRAYATZERO
{
    pass p0
    {
        SetVertexShader( CompileShader( vs_4_0, VSInst() ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, PSScenemainTEXARRAYATZERO() ) );        
        SetBlendState( EnableAlphaBlend, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
    }  
}

technique10 DrawDNSInst
{
    pass p0
    {
        SetVertexShader( CompileShader( vs_4_0, VSInst() ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, PSScenemainDNS() ) );        
        SetBlendState( EnableAlphaBlend, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
    }  
}

technique10 DrawDNSInstTEXARRAYATZERO
{
    pass p0
    {
        SetVertexShader( CompileShader( vs_4_0, VSInst() ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, PSScenemainDNSTEXARRAYATZERO() ) );        
        SetBlendState( EnableAlphaBlend, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
    }  
}

technique10 DrawDNSInstTEXARRAYATALL
{
    pass p0
    {
        SetVertexShader( CompileShader( vs_4_0, VSInst() ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, PSScenemainDNSTEXARRAYATALL() ) );        
        SetBlendState( EnableAlphaBlend, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
    }  
}
