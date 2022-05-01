#version 330 core

out vec4 FragColor;

uniform vec3 iResolution;
uniform vec4 iMouse;
uniform float iTime;

const int MAX_MARCHING_STEPS = 512;
const float MIN_DIST = 0.0;
const float MAX_DIST = 200.0;
const float EPSILON = 0.00001;

const int aoIter = 8;
const float aoDist = 0.07;
const float aoPower = 2.0;

const vec3 aoDir[12] = vec3[12](
	vec3(0.357407, 0.357407, 0.862856),
	vec3(0.357407, 0.862856, 0.357407),
	vec3(0.862856, 0.357407, 0.357407),
	vec3(-0.357407, 0.357407, 0.862856),
	vec3(-0.357407, 0.862856, 0.357407),
	vec3(-0.862856, 0.357407, 0.357407),
	vec3(0.357407, -0.357407, 0.862856),
	vec3(0.357407, -0.862856, 0.357407),
	vec3(0.862856, -0.357407, 0.357407),
	vec3(-0.357407, -0.357407, 0.862856),
	vec3(-0.357407, -0.862856, 0.357407),
	vec3(-0.862856, -0.357407, 0.357407)
);

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
    p.x /= 2.0;
    vec2 c = p;
    vec2 z = vec2(0.0,0.0);
    vec2 dz = vec2(0.0,0.0);
    bool exterior = true;
    float r2;
    float n = 0.0;
    for(int i = 0; i<64; i++) {
        // dz -> 2·z·dz + 1
        dz = 2.0*vec2(z.x*dz.x - z.y*dz.y, z.x*dz.y + z.y*dz.x) + vec2(1.0,0.0);
        // z -> z² + c
        z = vec2(z.x*z.x - z.y*z.y, 2.0*z.x*z.y) + c;
        
        n += 1.0;
        r2 = dot(z,z);
        if(r2>65536.0) {
            exterior = true;
            break;
        }
    }
    float en = exp2(n);
    float d = 0.5*sqrt(r2/dot(dz,dz))*en*(1.0-pow(r2,-1.0/en));
    return (exterior) ? d : 0.0;
}

vec3 mb(vec3 p, float power) {
	p.xyz = p.xzy;
	vec3 z = p;
	vec3 dz=vec3(0.0);
	float r, theta, phi;
	float dr = 1.0;
	
	float t0 = 1.0;
	for(int i = 0; i < 7; ++i) {
		r = length(z);
		if(r > 2.0) continue;
		theta = atan(z.y / z.x);
        #ifdef phase_shift_on
		phi = asin(z.z / r) + iTime*0.1;
        #else
        phi = asin(z.z / r);
        #endif
		
		dr = pow(r, power - 1.0) * dr * power + 1.0;
	
		r = pow(r, power);
		theta = theta * power;
		phi = phi * power;
		
		z = r * vec3(cos(theta)*cos(phi), sin(theta)*cos(phi), sin(phi)) + p;
		
		t0 = min(t0, r);
	}
	return vec3(0.5 * log(r) * r / dr, t0, 0.0);
}

void ry(inout vec3 p, float a) {  
 	float c,s;
    vec3 q = p;  
  	c = cos(a); s = sin(a);  
  	p.x = c * q.x + s * q.z;  
  	p.z = -s * q.x + c * q.z; 
}

vec3 f(vec3 p, float power){ 
	ry(p, iTime / 4.0);
    return mb(p, power); 
}

float opExtrussion(vec3 p, float sdf, float h) {
    vec2 w = vec2(sdf, abs(p.z) - h);
  	return min(max(w.x,w.y),0.0) + length(max(w,0.0));
}


vec2 opRevolution(vec3 p, float w) {
    return vec2(length(p.yz) - w, p.x );
}

float sceneSDF(vec3 samplePoint) {
    // return sdMandelbrot(opRevolution(samplePoint, 0.5));
    samplePoint *= rotateY(iTime / 2.0);
    samplePoint *= rotateX(sin(iTime / 5.0));
    // return sdMandelbrot(opRevolution(samplePoint, 1.0)) - 0.01;
    return f(samplePoint/1.5, 4.0).x - 0.01;
}

vec3 opRep(vec3 p, vec3 c) {
    return mod(p + 0.5 * c, c) - 0.5 * c;
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

float ao(vec3 p, vec3 n) {
    float dist = aoDist;
    float occ = 1.0;
    for (int i = 0; i < aoIter; ++i) {
        occ = min(occ, sceneSDF(p + dist * n) / dist);
        dist *= aoPower;
    }
    occ = max(occ, 0.0);
    return occ;
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
    float ao = ao(pos, normals);
    FragColor = vec4(normals * ao * normals * 5.0, 1.0);
}