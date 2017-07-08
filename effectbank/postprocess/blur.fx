//====================================================
// dof Blur
//====================================================
// By EVOLVED
// www.evolved-software.com
//====================================================

//--------------
// tweaks
//--------------
   float2 ViewVec;
   float BlurOffset=0.0018f;
   float2 samplesoffset[12]=
    {
     float2(-0.5,-1.5),
     float2(0.5,-1.5),
     float2(-1.5,-0.5),
     float2(-0.5,-0.5),
     float2(0.5,-0.5),
     float2(1.5,-0.5),
     float2(-1.5,0.5),
     float2(-0.5,0.5),
     float2(0.5,0.5),
     float2(1.5,0.5),
     float2(-0.5,1.5),
     float2(0.5,1.5)
    };

//--------------
// Textures
//--------------
   texture ColorsampleTX <string Name = " ";>;
   sampler Colorsample=sampler_state 
      {
	Texture=<ColorsampleTX>;
   	ADDRESSU=CLAMP;
   	ADDRESSV=CLAMP;
   	ADDRESSW=CLAMP;
      };

//--------------
// structs 
//--------------
   struct InPut
     {
 	float4 Pos:POSITION;
     };
   struct OutPut
     {
	float4 OPos:POSITION; 
 	float2 Tex:TEXCOORD0;
     };

//--------------
// vertex shader
//--------------
   OutPut VS(InPut IN) 
     {
 	OutPut OUT;
	OUT.OPos=IN.Pos; 
 	OUT.Tex=((float2(IN.Pos.x,-IN.Pos.y)+1.0)*0.5)+ViewVec;
	return OUT;
    }

//--------------
// pixel shader
//--------------
  float4 PS(OutPut IN) : COLOR
     {
 	float3 Scene=0;
   	for (int i = 0; i < 12; i++) Scene +=tex2D(Colorsample,IN.Tex+samplesoffset[i]*BlurOffset);
	return float4(Scene/12,1);	
     } 

//--------------
// techniques   
//--------------
    technique PostFilter
      {
 	pass p1
      {		
 	VertexShader = compile vs_2_0 VS(); 
 	PixelShader  = compile ps_2_0 PS();
	zwriteenable=false;
	zenable=false;
      }
      }
