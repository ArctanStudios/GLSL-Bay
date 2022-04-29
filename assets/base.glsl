#version 330 core

out vec4 FragColor;

uniform vec3 iResolution;

void main() {
    vec2 pos = gl_FragCoord.xy / iResolution;
    FragColor = vec4(pos, 0.0f, 1.0f);
}