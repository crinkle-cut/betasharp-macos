#version 410

varying vec4 vertexColor;
varying vec2 texCoord;
varying float fogDistance;

uniform sampler2D textureSampler;
uniform vec4 fogColor;
uniform float fogDensity;
uniform float fogStart;
uniform float fogEnd;
uniform int fogMode;

void main() 
{
    vec4 texColor = texture2D(textureSampler, texCoord);
    vec4 finalColor = texColor * vertexColor;

    if (finalColor.a < 0.001)
    {
        discard;
    }
    
    float fogFactor;
    
    if (fogMode == 0) 
    {
        fogFactor = (fogEnd - fogDistance) / (fogEnd - fogStart);
    } 
    else 
    {
        fogFactor = exp(-fogDensity * fogDistance);
    }
    
    fogFactor = clamp(fogFactor, 0.0, 1.0);
    
    FragColor = mix(fogColor, finalColor, fogFactor);
}
