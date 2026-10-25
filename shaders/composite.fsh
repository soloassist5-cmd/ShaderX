#version 120
// Проход 1: мерцание ламп, туман/тьма по дистанции, цветокоррекция этажа

#include "/lib/settings.glsl"
#include "/lib/noise.glsl"
#include "/lib/floors.glsl"

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform mat4 gbufferProjectionInverse;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;

varying vec2 texcoord;

// Гул люминесцентных ламп: лёгкая дрожь + редкие провалы и "моргания"
float lampFlicker(float t, float amount) {
    float hum = noise11(t * 9.0) * 0.06 + noise11(t * 47.0) * 0.03;
    float burstWindow = step(0.93, hash11(floor(t * 1.7)));
    float burst = burstWindow * step(0.45, hash11(floor(t * 24.0))) * 0.65;
    float blackout = step(0.995, hash11(floor(t * 0.6) + 17.0)) * 0.85;
    return clamp(1.0 - amount * (hum + burst + blackout), 0.0, 1.0);
}

void main() {
    vec3 color = texture2D(colortex0, texcoord).rgb;
    float depth = texture2D(depthtex0, texcoord).r;
    FloorLook look = getLook(cameraPosition.y);

    float light = 1.0;
#ifdef FLICKER_ENABLED
    light = lampFlicker(frameTimeCounter, look.flicker * FLICKER_STRENGTH);
#endif
    color *= light;

#ifdef FOG_ENABLED
    vec4 viewPos = gbufferProjectionInverse * vec4(vec3(texcoord, depth) * 2.0 - 1.0, 1.0);
    float dist = length(viewPos.xyz / viewPos.w);
    float fog = smoothstep(look.fogStart, look.fogEnd, dist);
    if (depth >= 1.0) fog = 1.0;
    fog = clamp(fog * look.fogMax * FOG_STRENGTH, 0.0, 1.0);
    color = mix(color, look.fogColor * light, fog);
#endif

    vec3 graded = color * look.exposure * look.tint;
    graded = mix(vec3(luma(graded)), graded, look.saturation);
    graded = (graded - 0.45) * look.contrast + 0.45;
    graded = graded + look.lift * (1.0 - graded);
    graded *= 1.0 - look.pulse * 0.3 * (0.5 + 0.5 * sin(frameTimeCounter * 4.5));
    color = mix(color, graded, COLOR_GRADING_STRENGTH);

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(clamp(color, 0.0, 1.0), 1.0);
}
