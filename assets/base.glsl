#version 330 core

out vec4 FragColor;

uniform vec3 iResolution;
uniform vec4 iMouse;
uniform float iTime;

void main() {
    vec2 pos = gl_FragCoord.xy / iResolution.xy;
    vec2 mouse = iMouse.xy/iResolution.xy;
    FragColor = vec4(mouse, 0.0f, 1.0f);
}