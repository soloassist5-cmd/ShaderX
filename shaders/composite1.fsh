#version 120
// Проход 2: яркие места (лампы, плитка) + горизонтальное размытие для свечения

#include "/lib/settings.glsl"
#include "/lib/noise.glsl"

/*
const int colortex1Format = RGBA16F;
const int colortex2Format = RGBA16F;
*/

uniform sampler2D colortex0;
uniform float viewWidth;
uniform float viewHeight;

varying vec2 texcoord;

vec3 brightPass(vec2 uv) {
    vec3 c = texture2D(colortex0, uv).rgb;
    return c * smoothstep(0.62, 0.95, luma(c));
}

void main() {
    vec3 sum = vec3(0.0);
#ifdef BLOOM_ENABLED
    float stepPx = max(viewHeight / 360.0, 1.0);
    vec2 dir = vec2(stepPx / viewWidth, 0.0);
    float wsum = 0.0;
    for (int i = -8; i <= 8; i++) {
        float x = float(i);
        float w = exp(-x * x / 18.0);
        sum += brightPass(texcoord + dir * x) * w;
        wsum += w;
    }
    sum /= wsum;
#endif

    /* DRAWBUFFERS:1 */
    gl_FragData[0] = vec4(sum, 1.0);
}
