#version 330 core

out vec4 FragColor;

uniform vec3 iResolution;
uniform vec4 iMouse;
uniform float iTime;

vec2 complexMult(vec2 a, vec2 b) {
	return vec2(a.x*b.x - a.y*b.y, a.x*b.y + a.y*b.x);
}

float testMandelbrot(vec2 coord) {
    const int iterations = 912;
	vec2 testPoint = vec2(0,0);
	for (int i = 0; i < iterations; i++){
		testPoint = complexMult(testPoint,testPoint) + coord;
        float ndot = dot(testPoint,testPoint);
		if (ndot > 45678.0) {
            float sl = float(i) - log2(log2(ndot))+4.0;
			return sl/float(iterations);
		}
	}
	return 0.0;
}

vec4 mapColor(float mcol) {
    return vec4(0.5 + 0.5*cos(2.7+mcol*30.0 + vec3(0.0,.6,1.0)),1.0);
}
const float offsetsD = .35;

const vec2 offsets[4] = vec2[](
    vec2(-offsetsD,-offsetsD),
    vec2(offsetsD,offsetsD),
    vec2(-offsetsD,offsetsD),
    vec2(offsetsD,-offsetsD)
);

void main() {
    const vec2 zoomP = vec2(-.7457117,.186142);
    const float zoomTime = 100.0;
    float tTime = 9.0 + abs(mod(iTime+zoomTime,zoomTime*2.0)-zoomTime);
    tTime = (145.5/(.0005*pow(tTime,5.0)));
    vec2 aspect = vec2(1,iResolution.y/iResolution.x);
    vec2 mouse = iMouse.xy/iResolution.xy;
    
    vec4 outs = vec4(0.0);
    
    for(int i = 0; i < 4; i++) {        
        vec2 fragment = (fragCoord+offsets[i])/iResolution.xy;    
        vec2 uv = aspect * (zoomP + tTime * (fragment - mouse));
        outs += mapColor(testMandelbrot(uv));
    }
	FragColor = outs/4;
}