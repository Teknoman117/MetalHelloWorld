//
//  Shaders.metal
//  MetalHelloWorld
//
//  Created by Nathaniel R. Lewis on 8/4/15.
//  Copyright (c) 2015 HoodooNet. All rights reserved.
//

#include <metal_stdlib>

using namespace metal;

struct Vertex
{
    packed_float3 position;
    packed_float4 color;
};

struct VertexOut
{
    float4 position [[ position ]];
    float4 color;
};



vertex VertexOut basic_vertex(const device Vertex* vertex_array [[ buffer(0) ]],
                              unsigned int vid [[ vertex_id ]]
                              )
{
    VertexOut output =
    {
        .position = float4(vertex_array[vid].position, 1.0),
        .color = vertex_array[vid].color
    };
    return output;
}

fragment half4 basic_fragment(VertexOut interpolated [[ stage_in ]])
{
    return half4(interpolated.color[0], interpolated.color[1], interpolated.color[2], interpolated.color[3]);
}

