#version 120
// Проход 3: вертикальное размытие свечения

#include "/lib/settings.glsl"

uniform sampler2D colortex1;
uniform float viewHeight;

varying vec2 texcoord;

void main() {
    vec3 sum = vec3(0.0);
#ifdef BLOOM_ENABLED
    float stepPx = max(viewHeight / 360.0, 1.0);
    vec2 dir = vec2(0.0, stepPx / viewHeight);
    float wsum = 0.0;
    for (int i = -8; i <= 8; i++) {
        float y = float(i);
        float w = exp(-y * y / 18.0);
        sum += texture2D(colortex1, texcoord + dir * y).rgb * w;
        wsum += w;
    }
    sum /= wsum;
#endif

    /* DRAWBUFFERS:2 */
    gl_FragData[0] = vec4(sum, 1.0);
}
