//
// Shared Effect Pool
//

#define FOGMODE_NONE    0
#define FOGMODE_LINEAR  1

shared cbuffer cbPerLevel
{
    int      g_fogMode = FOGMODE_NONE;
    float    g_fogStart;
    float    g_fogEnd;
    float4   g_fogColor;
};

shared cbuffer cbPerFrame
{
    float4x4 g_mView;
    float4x4 g_mProj;
    float4x4 g_mInvView;
    float4x4 g_mInvProj;
    float4x4 g_mViewProj;
};

shared cbuffer cbPerDraw
{
    float4x4 g_mWorld;
    float4x4 g_mInvWorld;
    float4x4 g_mWorldView;
    float4x4 g_mWorldViewProj;
};

struct Light
{
    float4 Position;
    float4 Diffuse;
    float4 Specular;
    float4 Ambient;
    float4 Atten;
};

shared cbuffer cbLights
{
    float4   g_clipplanes[3];
    Light    g_lights[8];
    int      g_LightsUsed;
};

