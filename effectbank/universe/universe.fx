//
// The Game Creators (www.thegamecreators.com)
// Universe Shader - Generic Lightmapper
//

#include "basepool.fx"

// shader

struct VSIn
{
    float3 pos          : POSITION;
    float3 norm         : NORMAL;
    float2 tex0         : TEXTURE0;
    float2 tex1         : TEXTURE1;
    float3 Tangent 	: TANGENT;
};

struct VSOut
{
    float4 pos : SV_Position;
    float3 vPos : POSWORLD;		//world space Pos
    float3 Norm : NORMAL;		//Normal
    float2 tex0 : TEXTURE0;
    float2 tex1 : TEXTURE1;
    float3 Tangent : TANGENT;		//Normalized Tangent vector
    float4 colorD : COLOR0;
    float4 colorS : COLOR1;
    float fogDist : TEXTURE2;
    float3 planeDist : SV_ClipDistance0;
};

struct PSIn
{
    float4 pos : SV_Position;
    float3 vPos : POSWORLD;		//world space Pos
    float3 Norm : NORMAL;		//Normal
    float2 tex0 : TEXTURE0;
    float2 tex1 : TEXTURE1;
    float3 Tangent : TANGENT;		//Normalized Tangent vector
    float4 colorD : COLOR0;
    float4 colorS : COLOR1;
    float fogDist : TEXTURE2;
};

Texture2D g_tx2D0;
Texture2D g_tx2D1;
Texture2D g_tx2D2;
Texture2D g_tx2D3;

cbuffer cbPerCubeRender
{
    float4x4 g_mViewCM[6];
};

cbuffer cbPerTechnique
{
    bool     g_bEnableLighting = true;
    float4   g_fAmbientLight;
};

cbuffer cbUserChange
{
    float3 g_vLightPos;
    float3 g_vEyePt;
};

SamplerState g_samAniso
{
    Filter = ANISOTROPIC;
    AddressU = Wrap;
    AddressV = Wrap;
    AddressW = Wrap;
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

	//110110 - make dynamic light as strong as equal static light!        
        //output.Diffuse += max(0,dot( lightDir, worldNormal ) * g_lights[i].Diffuse * fAtten);
        output.Diffuse += max(0,dot( lightDir, worldNormal ) * g_lights[i].Diffuse * fAtten) * 5;
        output.Specular += max(0,pow( dot( halfAngle, worldNormal ), 64 ) * g_lights[i].Specular * fAtten );
    }
 
    output.Diffuse += g_fAmbientLight;
    output.Diffuse.w = 1.0;
    output.Specular.w = 0.0f;

    return output;
}

VSOut VS(VSIn input)
{
    VSOut output = (VSOut)0.0;

    //output our final position in clipspace
    float4 worldPos = mul( float4( input.pos, 1 ), g_mWorld );
    float4 cameraPos = mul( worldPos, g_mView );
    output.pos = mul( cameraPos, g_mProj );
           
    //save the fog distance for later
    output.fogDist = cameraPos.z;
 
    //calc the distance from the clipping plane
    worldPos.w = 1;
    output.planeDist.x = dot( worldPos, g_clipplanes[0] );
    output.planeDist.y = 1;
    output.planeDist.z = 1;

    //save world pos for later
    output.vPos = worldPos;
        
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
        output.colorD = float4(1,0,1,1);
    }
    
    //propogate texture coordinates
    output.tex0 = input.tex0;
    output.tex1 = input.tex1;

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

float4 PS(PSIn input) : SV_Target
{   
    float4 texColor = g_tx2D1.Sample( g_samAniso, input.tex0 );
    if ( texColor.a < 0.81 ) discard; // 207.0/255.0 x9 setting
    float4 baseColor = input.colorD + g_tx2D0.Sample( g_samAniso, input.tex1 );
    float4 normalColor = texColor * baseColor;
    float fog = CalcFogFactor( input.fogDist );
    return fog * normalColor + (1.0 - fog)*g_fogColor;
}

float4 PSILLUM(PSIn input) : SV_Target
{   
    float4 texColor = g_tx2D1.Sample( g_samAniso, input.tex0 );
    if ( texColor.a < 0.81 ) discard;
    float4 illuminationColor = g_tx2D2.Sample( g_samAniso, input.tex0 );
    float4 diffuse = input.colorD + illuminationColor;
    float4 baseColor = diffuse + g_tx2D0.Sample( g_samAniso, input.tex1 );
    float4 normalColor = texColor * baseColor;
    float fog = CalcFogFactor( input.fogDist );
    return fog * normalColor + (1.0 - fog)*g_fogColor;
}

float4 PSILLUMBUMP(PSIn input) : SV_Target
{   
    float4 staticlightmap = g_tx2D0.Sample( g_samAniso, input.tex1 );
    float4 origdiffuse = g_tx2D1.Sample( g_samAniso, input.tex0 );
    float4 diffuse = origdiffuse;
    if ( diffuse.a < 0.81 ) discard; // 207.0/255.0 x9 setting

    float3 Norm = g_tx2D3.Sample( g_samAniso, input.tex0 );
    float4 ShineWithIllum = g_tx2D2.Sample( g_samAniso, input.tex0 );
    float3 Shine = ShineWithIllum.xyz * 2;

    float Bumpy = 2.0;
    float SpecExpon = 64.0;
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
    float4 combineLight = max(0,(input.colorD+staticlightmap)-float4(fSutractLight,fSutractLight,fSutractLight,0));
    combineLight = max(0,combineLight-ShineWithIllum.w);

    // texture, bump light and diffuse + illumination component
    float4 finaldiffuse = (diffuse*combineLight)+(diffuse*ShineWithIllum.w);

    // Return combined lighting
    float4 normalColor = finaldiffuse + (spec*float4(Shine,1))*lightAmt*staticlightmap + diffuse*g_fAmbientLight;
    float fog = CalcFogFactor( input.fogDist );
    return fog * normalColor + (1.0 - fog)*g_fogColor;
}

technique10 Default2TEX
{
    pass p0
    {
        SetVertexShader( CompileShader( vs_4_0, VS() ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, PS() ) );        
        SetBlendState( EnableAlphaBlend, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
    }  
}

technique10 Default3TEX
{
    pass p0
    {
        SetVertexShader( CompileShader( vs_4_0, VS() ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, PSILLUM() ) );        
        SetBlendState( EnableAlphaBlend, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
    }  
}

technique10 Default4TEX
{
    pass p0
    {
        SetVertexShader( CompileShader( vs_4_0, VS() ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, PSILLUMBUMP() ) );        
        SetBlendState( EnableAlphaBlend, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
    }  
}
