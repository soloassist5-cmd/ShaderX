// Интерфейс видеокамеры: "● REC", "SP" и счётчик плёнки.
// Шрифт 3x5, каждый символ закодирован 15 битами (строки сверху вниз).
// GLSL 1.20 без побитовых операций, поэтому биты достаются арифметикой.

const float GLYPH_R     = 27565.0;
const float GLYPH_E     = 31143.0;
const float GLYPH_C     = 31015.0;
const float GLYPH_S     = 31183.0;
const float GLYPH_P     = 27556.0;
const float GLYPH_COLON = 1040.0;

float digitGlyph(float d) {
    if (d < 0.5) return 31599.0;
    if (d < 1.5) return 11415.0;
    if (d < 2.5) return 29671.0;
    if (d < 3.5) return 29647.0;
    if (d < 4.5) return 23497.0;
    if (d < 5.5) return 31183.0;
    if (d < 6.5) return 31215.0;
    if (d < 7.5) return 29257.0;
    if (d < 8.5) return 31727.0;
    return 31695.0;
}

// Покрытие символа в точке frag; origin - левый верхний угол, s - размер "пикселя" шрифта
float glyph(float code, vec2 origin, vec2 frag, float s) {
    vec2 p = floor((frag - origin) / s);
    if (p.x < 0.0 || p.x > 2.0 || p.y < 0.0 || p.y > 4.0) return 0.0;
    float bit = (4.0 - p.y) * 3.0 + (2.0 - p.x);
    return mod(floor(code / exp2(bit)), 2.0);
}

// frag в пикселях, начало координат слева сверху
vec3 drawCamcorderOverlay(vec3 color, vec2 frag, vec2 screen, float time) {
    float s = max(floor(screen.y / 180.0), 2.0);
    float adv = 4.0 * s;
    float margin = 8.0 * s;
    float text = 0.0;
    float shadow = 0.0;
    vec2 sh = vec2(s * 0.5);

    // REC
    vec2 o = vec2(margin + 7.0 * s, margin);
    text   += glyph(GLYPH_R, o, frag, s) + glyph(GLYPH_E, o + vec2(adv, 0.0), frag, s) + glyph(GLYPH_C, o + vec2(2.0 * adv, 0.0), frag, s);
    shadow += glyph(GLYPH_R, o + sh, frag, s) + glyph(GLYPH_E, o + vec2(adv, 0.0) + sh, frag, s) + glyph(GLYPH_C, o + vec2(2.0 * adv, 0.0) + sh, frag, s);

    // SP
    o = vec2(screen.x - margin - 2.0 * adv + s, margin);
    text   += glyph(GLYPH_S, o, frag, s) + glyph(GLYPH_P, o + vec2(adv, 0.0), frag, s);
    shadow += glyph(GLYPH_S, o + sh, frag, s) + glyph(GLYPH_P, o + vec2(adv, 0.0) + sh, frag, s);

    // Счётчик MM:SS (frameTimeCounter сбрасывается каждый час, как и минуты)
    float secs = floor(time);
    float mm = floor(secs / 60.0);
    float ss = mod(secs, 60.0);
    o = vec2(screen.x - margin - 5.0 * adv + s, screen.y - margin - 5.0 * s);
    float codes[5];
    codes[0] = digitGlyph(floor(mm / 10.0));
    codes[1] = digitGlyph(mod(mm, 10.0));
    codes[2] = GLYPH_COLON;
    codes[3] = digitGlyph(floor(ss / 10.0));
    codes[4] = digitGlyph(mod(ss, 10.0));
    for (int i = 0; i < 5; i++) {
        vec2 oi = o + vec2(float(i) * adv, 0.0);
        text   += glyph(codes[i], oi, frag, s);
        shadow += glyph(codes[i], oi + sh, frag, s);
    }

    color = mix(color, vec3(0.0), clamp(shadow, 0.0, 1.0) * 0.85);
    color = mix(color, vec3(0.95), clamp(text, 0.0, 1.0));

    // Мигающая красная точка
    vec2 dotCenter = vec2(margin + 2.5 * s, margin + 2.5 * s);
    float blink = step(0.5, fract(time * 0.5));
    float dotMask = 1.0 - smoothstep(2.0 * s, 2.5 * s, length(frag - dotCenter));
    color = mix(color, vec3(0.9, 0.05, 0.05), dotMask * blink);

    return color;
}
