#version 330 core

out vec4 FragColor;

uniform vec3 iResolution;
uniform vec4 iMouse;
uniform float iTime;

const int MAX_MARCHING_STEPS = 255;
const float MIN_DIST = 0.0;
const float MAX_DIST = 100.0;
const float EPSILON = 0.0001;

float sphereSDF(vec3 p, float r) {
    return length(p) - r;
}

float sceneSDF(vec3 samplePoint) {
    return sphereSDF(samplePoint, 1.0);
}

// float sphereSDF(vec3 samplePoint) {
//     return length(samplePoint) - 1.0f;
// }

float shortestDistanceToSurface(vec3 eye, vec3 marchingDirection, float start, float end) {
    float depth = start;
    for (int i = 0; i < 255; i++) {
        float dist = sceneSDF(eye + depth * marchingDirection);
        if (dist < 0.0001) {
			return depth;
        }
        depth += dist;
        if (depth >= end) {
            return end;
        }
    }
    return end;
}

vec3 rayDirection(float fieldOfView, vec2 size, vec2 fragCoord) {
    vec2 xy = fragCoord - size / 2.0;
    float z = size.y / tan(radians(fieldOfView) / 2.0);
    return normalize(vec3(xy, -z));
}

// vec3 estimateNormal(vec3 p) {
//     return normalize(vec3(
//         sceneSDF(vec3(p.x + EPSILON, p.y, p.z)) - sceneSDF(vec3(p.x - EPSILON, p.y, p.z)),
//         sceneSDF(vec3(p.x, p.y + EPSILON, p.z)) - sceneSDF(vec3(p.x, p.y - EPSILON, p.z)),
//         sceneSDF(vec3(p.x, p.y, p.z  + EPSILON)) - sceneSDF(vec3(p.x, p.y, p.z - EPSILON))
//     ));
// }

void main() {
    vec3 eye = vec3(0.0, 0.0, 5.0);
	vec3 dir = rayDirection(45.0, iResolution.xy, gl_FragCoord.xy);
    float dist = shortestDistanceToSurface(eye, dir, MIN_DIST, MAX_DIST);
    if (dist > MAX_DIST - 0.0001) {
        FragColor = vec4(0.0, 0.0, 0.0, 0.0);
		return;
    }
    vec3 pos = eye + dist * dir;
    FragColor = vec4(pos, 1.0);
}