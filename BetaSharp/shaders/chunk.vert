#version 410

attribute vec3 inPosition;
attribute vec2 inUV;
attribute vec4 inColor;
attribute float inLight;

varying vec4 vertexColor;
varying vec2 texCoord;
varying float fogDistance;

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform vec2 chunkPos;
uniform float time;
uniform bool envAnim;

const float POSITION_SCALE_INV = 64.0 / 32767.0;

vec3 unpackPosition(vec3 packedPos)
{
    return packedPos * POSITION_SCALE_INV;
}

float unpackSkyLight(float light)
{
    return floor(light * 255.0 / 16.0) / 15.0;
}

float unpackBlockLight(float light)
{
    return mod(light * 255.0, 16.0) / 15.0;
}

int atlasIndexFromUV(vec2 uv)
{
    uv = clamp(uv, 0.0, 0.999999);

    ivec2 tile = ivec2(floor(uv * 16.0));

    return tile.x + tile.y * 16;
}

void applyWind(inout vec3 position) {
    const float windStrength = 0.05;
    const vec2 windDirection = vec2(1.0, 0.35);
    
    float phase = position.x + position.z;
    
    float slowWave = sin(time * 0.5 + phase);
    float fastWave = sin(time * 2.0 + phase * 0.5);
    
    float wind = (slowWave + fastWave * 0.3) * windStrength;
    
    position.x += windDirection.x * wind;
    position.z += windDirection.y * wind;
    
    float heightFactor = max(0.0, position.y);
    position.y += sin(time * 1.5 + phase) * 0.1 * heightFactor * windStrength;
}

void applyWaterWaves(inout vec3 position) {
    float wave1 = sin(position.x * 0.5 + time * 1.0) * 0.1;
    float wave2 = sin(position.z * 0.8 + time * 1.3) * 0.08;
    float wave3 = sin((position.x + position.z) * 0.3 + time * 0.7) * 0.12;
    
    position.y += (wave1 + wave2 + wave3) * 0.25;
}

void main() 
{
    vec3 position = unpackPosition(inPosition);
    vec2 uv = inUV;

    if (envAnim)
    {
        int textureIndex = atlasIndexFromUV(uv);
    
        if (textureIndex == 12 || textureIndex == 13 || textureIndex == 39 || textureIndex == 52 || textureIndex == 55 || textureIndex == 56 || textureIndex == 132)
        {
            applyWind(position);
        }
        else if (textureIndex == 205)
        {
            vec3 worldPos = position + vec3(chunkPos.x, 0.0, chunkPos.y);
            applyWaterWaves(worldPos);
            position = worldPos - vec3(chunkPos.x, 0.0, chunkPos.y);
        }
    }

    vec4 color = inColor;

    vec4 viewPos = modelViewMatrix * vec4(position, 1.0);
    gl_Position = projectionMatrix * viewPos;
    
    vertexColor = color;
    texCoord = uv;

    fogDistance = length(viewPos.xyz);
}
