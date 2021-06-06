Shader "Custom/ExplosionShader"
{

    Properties
    {
        _Color("Color", color) = (1, 1, 1, 0)
        _MainTex("Base (RGB)", 2D) = "white" {}
        _MinDist("Min Distance", Range(0.1, 50)) = 10
        _MaxDist("Max Distance", Range(0.1, 50)) = 25
        _TessFactor("Tessellation", Range(1, 50)) = 3 
        _Displacement("Displacement", Range(0, 1.0)) = 0.3 //•ÏˆÊ
        _Center("Center", Vector) = (0,0, 0, 0)
        _ScaleFactor("Scale Factor", float) = 0.5
        _StartTime("Time", float) = 0.0
        _Speed("Speed", float) = 0.0
    }

        SubShader
        {

            Tags
            {
                "RenderType" = "Transparent"
                "Queue" = "Transparent"
            }
            ZTest Always
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Pass
            {
                CGPROGRAM
                #pragma vertex vert 
                #pragma fragment frag 
                #pragma hull hull 
                #pragma domain domain 
                #pragma require geometry
                #pragma require tessellation tessHW
                #pragma geometry geom

                #include "Tessellation.cginc"
                #include "UnityCG.cginc"

                #define INPUT_PATCH_SIZE 3
                #define OUTPUT_PATCH_SIZE 3

                float _TessFactor;
                float _Displacement;
                float _MinDist;
                float _MaxDist;
                sampler2D _MainTex;
                fixed4 _Color;
                float _ScaleFactor;
                float4 _Center;
                float _StartTime;

                float _Speed;


                // GPU -> VERTEX
                struct appdata
                {
                    float3 vertex : POSITION;
                    float3 normal : NORMAL;
                    float2 uv : TEXCOORD0;
                };

                //VERTEX -> HULL
                struct v2h
                {
                    float4 position : POS;
                    float3 normal : NORMAL;
                    float2 uv : TEXCOORD;
                };

                //HULL -> (TESS) -> DOM
                struct h2d
                {
                    float3 position : POS;
                    float3 normal : NORMAL;
                    float2 uv : TEXCOORD;
                };

                //Patch Constant Function -> (TESS) -> DOM
                struct p2d
                {
                    float tessFactor[3] : SV_TessFactor;
                    float insideTessFactor : SV_InsideTessFactor;
                };

                

                //DOM -> GEOM
                struct d2g
                {
                    float4 position : POS;
                    float2 uv : TEXCOORD0;
                };

                //GEOM -> FRAG
                struct g2f
                {
                    float4 position : SV_POSITION;
                    float2 uv : TEXCOORD0;
                };

                float random(float2 uv)
                {
                    return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453123);
                }

                float3 rotate(float3 p, float angle, float3 axis) {
                    float3 a = normalize(axis);
                    float s = sin(angle);
                    float c = cos(angle);
                    float r = 1.0 - c;
                    float3x3 m = float3x3(
                        a.x * a.x * r + c,
                        a.y * a.x * r + a.z * s,
                        a.z * a.x * r - a.y * s,
                        a.x * a.y * r - a.z * s,
                        a.y * a.y * r + c,
                        a.z * a.y * r + a.x * s,
                        a.x * a.z * r + a.y * s,
                        a.y * a.z * r - a.x * s,
                        a.z * a.z * r + c
                        );
                    return mul(m, p).xyz;
                }

                //VERTEX SHADER
                v2h vert(appdata i)
                {
                    v2h o;
                    o.position = float4(i.vertex, 1.0);
                    o.normal = i.normal;
                    o.uv = i.uv;

                    return o;
                }

                
                //HULL SHADER
                [domain("tri")] 
                [partitioning("pow2")] 
                [outputtopology("triangle_cw")] 
                [patchconstantfunc("genTri")] 
                [outputcontrolpoints(OUTPUT_PATCH_SIZE)] 
                h2d hull(InputPatch<v2h, INPUT_PATCH_SIZE> i, uint id : SV_OutputControlPointID)
                {
                    h2d o = (h2d)0;
                    
                    o.position = i[id].position.xyz;
                    o.normal = i[id].normal;
                    o.uv = i[id].uv;
                    return o;
                }

                //PATCH CONSTANT FUNC
                p2d genTri(InputPatch<v2h, INPUT_PATCH_SIZE> i)
                {
                    p2d o = (p2d)0;
                    o.tessFactor[0] = _TessFactor;
                    o.tessFactor[1] = _TessFactor;
                    o.tessFactor[2] = _TessFactor;
                    o.insideTessFactor = _TessFactor;
                    return o;
                }

                
                //DOMAIN SHADER
                [domain("tri")] 
                d2g domain(
                    p2d input,
                    const OutputPatch<h2d, INPUT_PATCH_SIZE> i,
                    float3 domLoc : SV_DomainLocation)
                {
                    d2g o = (d2g)0;

                    
                    o.position.xyz =
                        domLoc.x * i[0].position +
                        domLoc.y * i[1].position +
                        domLoc.z * i[2].position ;
                    o.position.w = 1.0;
                    
                    o.uv =
                        domLoc.x * i[0].uv +
                        domLoc.y * i[1].uv +
                        domLoc.z * i[2].uv;

                    return o;
                }

                // GEOMETORY SHADER
                [maxvertexcount(3)]
                void geom(triangle d2g input[3], inout TriangleStream<g2f> stream)
                {
                    float3 vec1 = input[1].position - input[0].position;
                    float3 vec2 = input[2].position - input[0].position;
                    float3 normal = normalize(cross(vec1, vec2));
                    float3 center = (input[0].position + input[1].position + input[2].position) / 3;
                    float2 centerUV = (input[0].uv + input[1].uv + input[2].uv) / 3;
                    [unroll]
                    for (int i = 0; i < 3; i++)
                    {
                        d2g v = input[i];
                        g2f o;
                        v.position.xy -= center.xy;
                        v.position.xyz = rotate(v.position.xyz, (_Time.y - _StartTime) * random(center) * 2.0, float3(0.6, 0.5, 1.0));
                        v.position.xy += center.xy;
                        v.position.z = 0;
                        float2 dir = normalize(_Center - center);
                        v.position.xy -= dir * (_Time.y - _StartTime) * _Speed;
                        
                        
                        o.position = UnityObjectToClipPos(v.position);
                        o.uv = v.uv;
                        stream.Append(o);

                    }


                    stream.RestartStrip();
                }

                // FRAGMENT SHADER
                fixed4 frag(g2f i) : SV_Target
                {
                    float time = (_Time.y - _StartTime);
                    fixed4 base = tex2D(_MainTex, i.uv) * _Color;
                    base.rgb += time * 0.2;
                    base.a -= lerp(0, time / 2.0, step(0, time / 2.0));
                    return base;
                }
                ENDCG
            }
        }

}
