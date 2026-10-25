#version 120
// Финал: свечение + плёнка видеокамеры (found footage)

#include "/lib/settings.glsl"
#include "/lib/noise.glsl"
#include "/lib/floors.glsl"
#include "/lib/overlay.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex2;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;
uniform float viewWidth;
uniform float viewHeight;

varying vec2 texcoord;

void main() {
    FloorLook look = getLook(cameraPosition.y);
    float t = frameTimeCounter;
    vec2 uv = texcoord;

#ifdef VHS_ENABLED
    float vhs = VHS_STRENGTH;
#else
    float vhs = 0.0;
#endif

    // Лёгкая бочка объектива
    vec2 c = uv - 0.5;
    uv = 0.5 + c * (1.0 + 0.06 * vhs * dot(c, c));

    // Дрожание строк и ползущая полоса трекинга
    float line = floor(uv.y * viewHeight * 0.5);
    float jitter = (hash11(line + floor(t * 30.0) * 7.31) - 0.5) * 0.0012 * vhs * look.grain;
    float bandY = 1.0 - fract(t * 0.045);
    float band = exp(-pow((uv.y - bandY) * 35.0, 2.0)) * vhs;
    uv.x += jitter + band * 0.006 * (hash11(floor(t * 20.0)) - 0.3);

    // Паника на Level !: камера трясётся в руках
    uv += (vec2(noise11(t * 13.0), noise11(t * 11.0 + 5.0)) - 0.5) * 0.004 * look.pulse;

    // Хроматическая аберрация, сильнее к краям
    vec2 ab = (uv - 0.5) * 0.006 * ABERRATION_STRENGTH * look.aberration * vhs;
    vec3 col = vec3(texture2D(colortex0, uv + ab).r,
                    texture2D(colortex0, uv).g,
                    texture2D(colortex0, uv - ab).b);

    // Растекание цвета по горизонтали, как на кассете
    vec3 smear = texture2D(colortex0, uv - vec2(3.0 / viewWidth, 0.0)).rgb;
    float y = luma(col);
    col = y + mix(col - y, smear - luma(smear), 0.35 * clamp(vhs, 0.0, 1.0));

#ifdef BLOOM_ENABLED
    col += texture2D(colortex2, uv).rgb * look.bloom * BLOOM_STRENGTH;
#endif

    // Шум полосы трекинга
    col += band * 0.12 * hash12(vec2(gl_FragCoord.x, floor(t * 60.0)));

    // Строки развёртки
    col *= 1.0 - 0.07 * vhs * (0.5 + 0.5 * sin(gl_FragCoord.y * 3.14159));

    // Зерно
    float grain = hash12(gl_FragCoord.xy + fract(t * 7.13) * 917.0) - 0.5;
    col += grain * 0.07 * GRAIN_STRENGTH * look.grain * vhs;

    // Виньетка
    float vig = 1.0 - dot(c, c) * 1.6 * look.vignette;
    col *= clamp(vig, 0.0, 1.0);

    // Чёрные края после искажения
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) col = vec3(0.0);

#ifdef CAMCORDER_OVERLAY
    vec2 frag = vec2(gl_FragCoord.x, viewHeight - gl_FragCoord.y);
    col = drawCamcorderOverlay(col, frag, vec2(viewWidth, viewHeight), t);
#endif

    gl_FragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
