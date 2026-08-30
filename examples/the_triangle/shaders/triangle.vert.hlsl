struct VSOutput
{
    float4 position : SV_Position;
    float4 color    : TEXCOORD0;
};

VSOutput main(uint vertexID : SV_VertexID)
{
    VSOutput output;

    float2 positions[3] =
    {
        float2( 0.0,  0.6),
        float2( 0.6, -0.6),
        float2(-0.6, -0.6)
    };

    float4 colors[3] =
    {
        float4(1.0, 0.0, 0.0, 1.0),
        float4(0.0, 1.0, 0.0, 1.0),
        float4(0.0, 0.0, 1.0, 1.0)
    };

    output.position = float4(positions[vertexID], 0.0, 1.0);
    output.color = colors[vertexID];

    return output;
}
