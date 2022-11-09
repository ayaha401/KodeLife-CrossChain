#version 150

uniform float time;
uniform vec2 resolution;
uniform vec2 mouse;
uniform vec3 spectrum;

uniform sampler2D texture0;
uniform sampler2D texture1;
uniform sampler2D texture2;
uniform sampler2D texture3;
uniform sampler2D prevFrame;
uniform sampler2D prevPass;

in VertexData
{
    vec4 v_position;
    vec3 v_normal;
    vec2 v_texcoord;
} inData;

out vec4 fragColor;
//define=============================================================================
#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))

//const==============================================================================
const float PI=3.1415926536;
const float TAU=PI*2;
const float eps=0.0001;
const float DEG2RAD = PI/180;

//Math===============================================================================
vec3 rep(vec3 p,float n)
{
    return abs(mod(p,n))-n*.5;
}

//SDF================================================================================
float chain(vec3 p, vec3 s)
{
    p.x-=clamp(p.x, -s.x, s.x);
    return length(vec2(length(p.xy)-s.y,p.z))-s.z;
}

//Map================================================================================

float map(vec3 p)
{
    p.y-=1.;
    if(mod(p.y,4.)<2.){
        if(mod(p.x,4.)<2.) p.z+=time*3.1;
        else p.z-=time*2.1;
        p.xz*=rot(PI/2);
    }
    else{
        if(mod(p.z,4.)<2.) p.x+=time*1.5;
        else p.x-=time*.5;
    }
    
    //vec3 pp=rep(p,2);
    vec3 pp=abs(mod(p-.1,2))-1.;

    vec3 a=pp;   a.x=mod(a.x,1.)-.5;
    vec3 b=pp;   b.x=mod(b.x+.5,1.)-.5;
    
    a.yz*=rot(time);
    b.yz*=rot(time);
    vec3 chainS=vec3(.2,.2,.1);
    float sdfChain=min(chain(a.xyz,chainS), chain(b.xzy,chainS));
    return sdfChain;
}

//Normal=============================================================================

vec3 makeN(vec3 p)
{
    vec2 eps = vec2(.0001, 0.);
    return normalize(vec3(map(p+eps.xyy)-map(p-eps.xyy),
                          map(p+eps.yxy)-map(p-eps.yxy),
                          map(p+eps.yyx)-map(p-eps.yyx)));
}

//Main==============================================================================

void main(void)
{
    vec2 uv=(2.*gl_FragCoord.xy-resolution)/resolution.y;
    float zfac=(1.-.5*length(uv))*1.3;
    float dist,hit,i=0;
    vec3 cPos=vec3(0,sin(time)*2.3,-time);
    vec3 cDir=normalize(vec3(0,0,-1));
    vec3 cUp=vec3(0,1,0);
    vec3 cSide=cross(cDir,cUp);
    vec3 ray=normalize(cSide*uv.x+cUp*uv.y+cDir*zfac);
    vec3 L=normalize(vec3(1));
    vec3 col=vec3(0);
    for(;i<64;i++)
    {
        vec3 rp=cPos+ray*hit;
        dist=map(rp);
        hit+=dist;
        if(dist<eps)
        {
            vec3 N=makeN(rp);
            float diff=dot(N,L);
            col=vec3(1)*diff;
        }
    }
    fragColor = vec4(col,1.);
}