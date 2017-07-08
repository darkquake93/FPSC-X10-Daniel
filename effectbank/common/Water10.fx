//
// The Game Creators (www.thegamecreators.com)
// Water Shader
//

#include "basepool.fx"

// Input/Output structures
struct VSIn
{
    float3 Pos	: POSITION;
    float3 Norm : NORMAL;
    float2 Tex	: TEXTURE;
    float3 Tan  : TANGENT;
};

struct VSOut
{
    float4 Pos	: SV_Position;
    float2 Tex1 : TEXCOORD0; 
    float2 Tex2 : TEXCOORD1; 
    float2 Tex3 : TEXCOORD2; 
    float3 ViewVec : TEXCOORD3; 
    float3 ViewFre : TEXCOORD4; 
    float4 Proj : TEXCOORD5; 
};

// Constant buffers
cbuffer cb0
{
    float g_fTime;
    float g_fWaterSpeed = 1.0f;
    float g_fWaterBump = 0.03f;
    float g_fWaterRefl = 1.0f;
    float g_fWaterRefr = 1.0f;
    float4 g_vWaterColor;
    float g_fFresnelPower = 30;
};
cbuffer cbUserChange
{
    float3 g_vLightPos;
    float3 g_vEyePt;
};

// Textures
Texture2D g_tx2D0;
Texture2D g_tx2D1;
Texture2D g_tx2D2;
Texture2D g_tx2D3;

// Texture samplers
SamplerState g_samLinear
{
    Filter = ANISOTROPIC;
};
SamplerState g_samClamp
{
    Filter = ANISOTROPIC;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

// State
DepthStencilState EnableDepth
{
    DepthEnable = TRUE;
    DepthWriteMask = ALL;
};
DepthStencilState EnableDepthNoWrite
{
    DepthEnable = TRUE;
    DepthWriteMask = 0;
};

// Vertex shader
VSOut VS(VSIn input)
{
    VSOut output = (VSOut)0;
  
    output.Pos = mul( float4(input.Pos,1), g_mWorldViewProj );

    float WaterScale = 0.5f;
    float2 Speed1 = { -0.02, 0.0 };
    float2 Speed2 = { 0.0 , 0.02 };
    float2 Speed3 = { 0.02 , 0.02 };
    float FresnelScale = 1;

    Speed1 *= g_fWaterSpeed;
    Speed2 *= g_fWaterSpeed;
    Speed3 *= g_fWaterSpeed;
 
    output.Tex1 = input.Tex*WaterScale*0.5+(g_fTime*Speed1);
    output.Tex2 = input.Tex*WaterScale    +(g_fTime*Speed2);
    output.Tex3 = input.Tex*WaterScale*1.5+(g_fTime*Speed3);

    float3 WP = mul(input.Pos,g_mWorld); 
    float3 WN = mul(input.Norm,g_mWorld); WN = normalize(WN);
    float3 WT = mul(input.Tan,g_mWorld); WT = normalize(WT);
    float3 BiNorm = cross( input.Norm, input.Tan );
    float3 WB = mul(BiNorm,g_mWorld); WB = normalize(WB);
    float3x3 TBN = {WT,WB,WN}; TBN = transpose(TBN);

    float3 VP = g_mInvView[3].xyz-WP; 
    output.ViewVec = VP;
    output.ViewFre = -VP/(-VP.y*FresnelScale); 
  
    float4x4 scalemat = float4x4(0.5,    0,   0, 0.5,
                                   0, -0.5,   0, 0.5,
                                   0,    0,   1,   0,
                                   0,    0,   0,   1 );
    output.Proj = mul(scalemat,output.Pos);
  
    return output;
}

float4 PS_RefractReflect(VSOut input) : SV_Target
{	
    float FresnelBump = 0.3f;

    float4 Distort = (g_tx2D0.Sample( g_samLinear, input.Tex1 )*2-1)*0.33333;
    Distort = Distort+(Distort,g_tx2D0.Sample( g_samLinear, input.Tex2 )*2-1)*0.33333;
    Distort = Distort+(Distort,g_tx2D0.Sample( g_samLinear, input.Tex3 )*2-1)*0.33333;

    float depth = length(input.ViewVec.xyz);

    float3 ViewT = normalize(input.ViewVec);
    float3 ViewB = normalize(ViewT + Distort*0.03);

    // use y value to choose between reflection/refraction fade
    float Fresnel = pow( abs(ViewB.y), g_fFresnelPower );

    // check distort vector against view vector (in proj space) and shift to match direction
    float4 ProjPos = input.Proj/input.Proj.w;
    float height = ViewT.y > 0 ? 0.0 : 1.0;
    Distort=Distort*(g_fWaterBump+0.001f);
    float2 Distort2 = Distort.xy;
    float2 ViewVec2 = ProjPos.xy - float2(0.5,height);
    Distort2 = normalize(Distort2);
    ViewVec2 = normalize(ViewVec2);
    Distort2 = (ViewVec2 + Distort2) / 2.0;
    Distort2 = Distort2 * length(Distort.xy);

    // Distort2 vector now always points towards the camera, prevents sampling away from the camera
    float4 cookieCoord = ProjPos+float4(Distort2,0,0);  //don't distort z or w componenets

    float4 Refraction = float4(0,0,0,0);
    float4 Reflection = float4(0,0,0,0);
    //if( cookieCoord.z > 0 )
    {
       // darken refraction texture to give water a murky look
       // for perfect results use a depth value here instead (deeper=darker)
       Refraction = g_tx2D1.Sample( g_samClamp, cookieCoord.xy )*0.6*g_fWaterRefr;
       Reflection = g_tx2D2.Sample( g_samClamp, cookieCoord.xy )*g_fWaterRefl;
    }
    float4 FresnelWater = lerp(Reflection,Refraction,Fresnel);
    FresnelWater.xyz += g_vWaterColor.xyz;
    FresnelWater.w = 1.0f;

    if ( g_fogMode==FOGMODE_LINEAR )
    {
       float fog = smoothstep( g_fogStart, g_fogEnd, depth*0.5 );
       FresnelWater.xyz = lerp( FresnelWater.xyz, g_fogColor.xyz, fog );
    }

    return FresnelWater;
}

float4 PS_Color(VSOut input) : SV_Target
{	
    float FresnelBump = 0.3f;

    float4 Distort = (g_tx2D0.Sample( g_samLinear, input.Tex1 )*2-1)*0.33333;
    Distort = Distort+(Distort,g_tx2D0.Sample( g_samLinear, input.Tex2 )*2-1)*0.33333;
    Distort = Distort+(Distort,g_tx2D0.Sample( g_samLinear, input.Tex3 )*2-1)*0.33333;

    float depth = length(input.ViewVec.xyz);

    float3 ViewT = normalize(input.ViewVec);
    float3 ViewB = normalize(ViewT + Distort*0.03);

    // use y value to choose between reflection/refraction fade
    float Fresnel = pow( abs(ViewB.y), g_fFresnelPower );

    // check distort vector against view vector (in proj space) and shift to match direction
    float4 ProjPos = input.Proj/input.Proj.w;
    float height = ViewT.y > 0 ? 0.0 : 1.0;
    Distort=Distort*(g_fWaterBump+0.001f);
    float2 Distort2 = Distort.xy;
    float2 ViewVec2 = ProjPos.xy - float2(0.5,height);
    Distort2 = normalize(Distort2);
    ViewVec2 = normalize(ViewVec2);
    Distort2 = (ViewVec2 + Distort2) / 2.0;
    Distort2 = Distort2 * length(Distort.xy);

    float4 Refraction = float4(0,0,0,0);
    float4 Reflection = float4(1,1,1,1);
    float4 FresnelWater = lerp(Reflection,Refraction,Fresnel);
    FresnelWater.xyz += g_vWaterColor.xyz;
    FresnelWater.w = 0.5 + ((Distort2.x+Distort2.y)*10);

    if ( g_fogMode==FOGMODE_LINEAR )
    {
       float fog = smoothstep( g_fogStart, g_fogEnd, depth );
       FresnelWater.xyz = lerp( FresnelWater.xyz, g_fogColor.xyz, fog );
    }

    return FresnelWater;
}

technique10 DrawRefractReflect
{
    pass P0
    {       
        SetVertexShader( CompileShader( vs_4_0, VS() ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, PS_RefractReflect() ) );
        SetDepthStencilState( EnableDepth, 0 );
    }
}

technique10 DrawColor
{
    pass P0
    {       
        SetVertexShader( CompileShader( vs_4_0, VS() ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, PS_Color() ) );
        SetDepthStencilState( EnableDepth, 0 );
    }
}
