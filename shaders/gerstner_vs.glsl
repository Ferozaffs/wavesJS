//Based on implementation from https://catlikecoding.com/unity/tutorials/flow/waves/

uniform float time;

varying vec3 vPosition;
varying vec3 vNormal;

float rand(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

//wave: dir.x, dir.y, steepness, length
vec3 GerstnerWave(vec2 waveDir, float steepness, float waveLength, vec3 worldPos, inout vec3 tangent, inout vec3 binormal)
{
    const float PI = 3.14159265359;
    float waveNumber = 2.0 * PI / waveLength;

    float phaseSpeed = sqrt(9.81 / waveNumber);
    float frequency = waveNumber * (dot(waveDir, worldPos.xz) - phaseSpeed * time);
    float amplitude = steepness / waveNumber;

    tangent += vec3(
        -waveDir.x * waveDir.x * (steepness * sin(frequency)),
        waveDir.x * (steepness * cos(frequency)),
        -waveDir.x * waveDir.y * (steepness * sin(frequency))
    );
    binormal += vec3(
        -waveDir.x * waveDir.y * (steepness * sin(frequency)),
        waveDir.y * (steepness * cos(frequency)),
        -waveDir.y * waveDir.y * (steepness * sin(frequency))
    );

    vec3 offset;
    offset.xz = waveDir * (amplitude * cos(frequency));
    offset.y = amplitude * sin(frequency);

    return offset;
}

void main() {	
    vec4 worldPos = modelMatrix * vec4(position, 1.0);
    vec3 tangent = vec3(1,0,0);
	vec3 binormal = vec3(0,0,1);

    vec4 wavePos = worldPos;

    const float DefaultWaveLength = 500.0;
    const int NumWaves = 20;

    float waveLength = DefaultWaveLength;
    float steepness = 1.0;
    for(int i=0; i<NumWaves; ++i)
    {
        float s1 = rand(vec2(i));
        float s2 = rand(vec2(i+2));
        float s3 = min(0.2, max(0.001, s2));

        vec2 dir = normalize(vec2(s1,s2) * 2.0 - 1.0);
                
        wavePos.xyz += GerstnerWave(dir, s3 * steepness, waveLength, worldPos.xyz, tangent, binormal);

        steepness -= s3 * steepness;
        waveLength *= 0.8; 
    }
    
    vPosition = wavePos.xyz;
    vNormal = cross(binormal, tangent);
    gl_Position = projectionMatrix * viewMatrix * wavePos;
}