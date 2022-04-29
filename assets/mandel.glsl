#version 330 core

out vec4 FragColor;

uniform vec3 iResolution;
uniform vec4 iMouse;
uniform float iTime;

float opRevolution(vec3 p, float o)
{
    vec2 q = vec2( length(p.xz) - o, p.y );
    return primitive(q)
}

vec3 sdMandelbrot(vec2 p) {
    vec2 c = p;
    vec2 z = vec2(0.0,0.0);
    vec2 dz = vec2(0.0,0.0);
    bool exterior = false;
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
    return (exterior) ? vec3(d, z) : vec3(0.0, z);
}

vec3 estimateNormal(vec3 p) {
    return normalize(vec3(
        sceneSDF(vec3(p.x + EPSILON, p.y, p.z)) - sceneSDF(vec3(p.x - EPSILON, p.y, p.z)),
        sceneSDF(vec3(p.x, p.y + EPSILON, p.z)) - sceneSDF(vec3(p.x, p.y - EPSILON, p.z)),
        sceneSDF(vec3(p.x, p.y, p.z  + EPSILON)) - sceneSDF(vec3(p.x, p.y, p.z - EPSILON))
    ));
}

void main() {
    vec2 pos = (2.0 * gl_FragCoord.xy - iResolution.xy) / iResolution.y;
    vec3 dist = sdMandelbrot(pos);
    FragColor = vec4(dist, 1.0);
}