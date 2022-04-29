#version 330 core

out vec4 FragColor;

uniform vec3 iResolution;
uniform vec4 iMouse;
uniform float iTime;

const int MAX_MARCHING_STEPS = 255;
const float MIN_DIST = 0.0;
const float MAX_DIST = 100.0;
const float EPSILON = 0.0001;

mat3 rotateX(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(1, 0, 0),
        vec3(0, c, -s),
        vec3(0, s, c)
    );
}

mat3 rotateY(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(c, 0, s),
        vec3(0, 1, 0),
        vec3(-s, 0, c)
    );
}

mat3 rotateZ(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(c, -s, 0),
        vec3(s, c, 0),
        vec3(0, 0, 1)
    );
}

float sdMandelbrot(vec2 p) {
    vec2 c = p;
    vec2 z = vec2(0.0,0.0);
    vec2 dz = vec2(0.0,0.0);
    bool exterior = true;
    float r2;
    float n = 0.0;
    for( int i = 0; i<1024; i++ ) {
        // dz -> 2·z·dz + 1
        dz = 2.0*vec2(z.x*dz.x - z.y*dz.y, z.x*dz.y + z.y*dz.x) + vec2(1.0,0.0);
        // z -> z² + c
        z = vec2(z.x*z.x - z.y*z.y, 2.0*z.x*z.y) + c;
        
        n += 1.0;
        r2 = dot(z,z);
        if( r2>65536.0 ) {
            exterior = true;
            break;
        }
    }
    float en = exp2(n);
    float d = 0.5*sqrt(r2/dot(dz,dz))*en*(1.0-pow(r2,-1.0/en));
    return (exterior) ? d : 0.0;
}

float opExtrussion(vec3 p, float sdf, float h)
{
    vec2 w = vec2(sdf, abs(p.z) - h);
  	return min(max(w.x,w.y),0.0) + length(max(w,0.0));
}


vec2 opRevolution(vec3 p, float w)
{
    return vec2( length(p.yz) - w, p.x );
}

float sceneSDF(vec3 samplePoint) {
    // return sdMandelbrot(opRevolution(samplePoint, 0.5));
    samplePoint = rotateY(iTime / 2.0) * samplePoint;
    return opExtrussion(samplePoint, sdMandelbrot(samplePoint.xy)-1, abs(sdMandelbrot(samplePoint.xy)-1.0));
}

float shortestDistanceToSurface(vec3 eye, vec3 marchingDirection, float start, float end) {
    float depth = start;
    for (int i = 0; i < MAX_MARCHING_STEPS; i++) {
        float dist = sceneSDF(eye + depth * marchingDirection);
        if (dist < EPSILON) {
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

vec3 estimateNormal(vec3 p) {
    return normalize(vec3(
        sceneSDF(vec3(p.x + EPSILON, p.y, p.z)) - sceneSDF(vec3(p.x - EPSILON, p.y, p.z)),
        sceneSDF(vec3(p.x, p.y + EPSILON, p.z)) - sceneSDF(vec3(p.x, p.y - EPSILON, p.z)),
        sceneSDF(vec3(p.x, p.y, p.z  + EPSILON)) - sceneSDF(vec3(p.x, p.y, p.z - EPSILON))
    ));
}

mat3 viewMatrix(vec3 eye, vec3 center, vec3 up) {
    vec3 f = normalize(center - eye);
    vec3 s = normalize(cross(f, up));
    vec3 u = cross(s, f);
    return mat3(s, u, -f);
}

float calcAO(vec3 pos, vec3 nor)
{
	float occ = 0.0;
    float sca = 1.0;
    for(int i = 0; i < 5; i++)
    {
        float h = 0.01 + 0.12 * float(i) / 4.0;
        float d = sceneSDF(pos + h * nor);
        occ += (h - d) * sca;
        sca *= 0.95;
        if(occ > 0.35) break;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 ) * (0.5+0.5*nor.y);
}

void main() {
	vec3 dir = rayDirection(45.0, iResolution.xy, gl_FragCoord.xy);
    vec3 eye = vec3(8.0, 5.0, 7.0);
    mat3 viewToWorld = viewMatrix(eye, vec3(0.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0));
    vec3 worldDir = viewToWorld * dir;
    float dist = shortestDistanceToSurface(eye, worldDir, MIN_DIST, MAX_DIST);
    if (dist > MAX_DIST - 0.0001) {
        FragColor = vec4(0.0, 0.0, 0.0, 0.0);
		return;
    }
    vec3 pos = eye + dist * worldDir;
    vec3 normals = estimateNormal(pos);
    FragColor = vec4(normals, 1.0);
}