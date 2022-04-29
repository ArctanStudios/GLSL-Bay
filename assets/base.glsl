#version 330 core

out vec4 FragColor;

uniform vec3 iResolution;
uniform vec4 iMouse;
uniform float iTime;

float sdSphere(vec3 p, float s)
{
    return length(p) - s;
}

void main() {
    vec2 pos = (2.0 * gl_FragCoord.xy - iResolution.xy) / iResolution.y;
    float dist = sdSphere(vec3(pos, 0.0f), 1.0f);
    FragColor = vec4(pos, dist, 1.0f);
}