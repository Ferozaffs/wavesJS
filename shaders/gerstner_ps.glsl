uniform samplerCube envMap;

varying vec3 vPosition;
varying vec3 vNormal;

vec3 fresnelFactor(vec3 v1, vec3 v2) {
    const vec3 F0 = vec3(0.04);
    return F0 + (1.0 - F0) * pow(1.01 - dot(v1, v2), 5.0);
}

void main() {
    vec3 lighting = vec3(0.0);
    vec3 normal = normalize(vNormal);
    vec3 viewDir = normalize(cameraPosition - vPosition);

    vec3 reflection = normalize(reflect(-viewDir, normal));
    vec3 ibl = textureCubeLodEXT(envMap, reflection,8.0).xyz;

    //Adjust gamma and tonemap since there is no tonemapper at the end
    ibl = pow(ibl, vec3(2.2));
    ibl = ibl / (ibl + vec3(1.0));

    vec3 lightDir = normalize(vec3(1.0, 0.5, 0.0));
    vec3 H = normalize(lightDir + viewDir);
    float NdH = max(0.001, dot(normal, H));
    float phongValue = pow(NdH, 256.0);

    vec3 specular = vec3(phongValue) * fresnelFactor(H,viewDir) * 10.0;

    //Scatter taken from Atlas, https://www.youtube.com/watch?v=Dqld965-Vv0&ab_channel=GDC
    vec3 waterColor = vec3(0.0, 0.2, 0.4);
    vec3 sunColor = vec3(1.0, 1.0, 0.5);
    
    float sctWaveTop = 0.5*max(0.0, vPosition.y) * pow(max(0.0, dot(lightDir, -viewDir)), 4.0);
    float sctLightAngle = pow(0.5 - 0.5 * dot(lightDir, H), 3.0);
    float sctNormal = 0.25*pow(max(0.0, dot(viewDir, normal)), 2.0);
    float lambert = max(0.0, dot(lightDir, normal));

    float scatter = sctWaveTop*sctLightAngle+sctNormal;
    vec3 sctColor = scatter * waterColor * sunColor;
    sctColor += lambert * sctColor * sunColor;

    vec3 color = 0.25*ibl + sctColor + specular + fresnelFactor(viewDir, normal) * ibl;

    color = pow(color, vec3(1.0 / 2.2));

    gl_FragColor = vec4(color, 1.0);
}