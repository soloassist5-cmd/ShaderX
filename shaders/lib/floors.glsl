// Внешний вид каждого этажа и выбор этажа по высоте камеры.
// Требует: settings.glsl

struct FloorLook {
    vec3  tint;        // цветовой фильтр
    float saturation;
    float contrast;
    float exposure;
    vec3  lift;        // подъём теней (дешёвая плёнка/камера)
    vec3  fogColor;
    float fogStart;    // в блоках
    float fogEnd;
    float fogMax;      // максимальная плотность
    float flicker;     // мерцание ламп
    float bloom;
    float aberration;
    float grain;
    float vignette;
    float pulse;       // красная тревожная пульсация
};

// Вне этажей: нейтральная картинка, только камера
FloorLook lookOutside() {
#ifdef CAMERA_EVERYWHERE
    const float cam = 1.0;
#else
    const float cam = 0.0;
#endif
    return FloorLook(vec3(1.0), 1.0, 1.0, 1.0, vec3(0.0),
                     vec3(0.0), 16.0, 64.0, 0.0,
                     0.0, 0.25 * cam, 0.4 * cam, 0.5 * cam, 0.35 * cam, 0.0);
}

// Level 0: бесконечные моно-жёлтые комнаты, гудящие лампы, сырой ковёр
FloorLook lookLevel0() {
    return FloorLook(vec3(1.06, 1.0, 0.76), 0.80, 1.06, 1.08, vec3(0.035, 0.030, 0.0),
                     vec3(0.52, 0.47, 0.26), 6.0, 56.0, 0.55,
                     0.6, 0.9, 1.0, 1.0, 0.6, 0.0);
}

// Level 1: холодный бетон, склады, полутьма
FloorLook lookLevel1() {
    return FloorLook(vec3(0.90, 0.96, 1.02), 0.55, 1.15, 0.85, vec3(0.010, 0.012, 0.016),
                     vec3(0.050, 0.055, 0.060), 4.0, 40.0, 0.85,
                     0.8, 0.6, 1.0, 1.3, 0.85, 0.0);
}

// Level 2: трубы, ржавчина, тьма сразу за светом
FloorLook lookLevel2() {
    return FloorLook(vec3(1.06, 0.88, 0.70), 0.70, 1.20, 0.75, vec3(0.010, 0.005, 0.0),
                     vec3(0.020, 0.012, 0.006), 2.0, 24.0, 0.95,
                     1.0, 0.7, 1.2, 1.5, 1.0, 0.0);
}

// Level 37 (Poolrooms): белая плитка, вода, пересвеченный сон
FloorLook lookPoolrooms() {
    return FloorLook(vec3(0.92, 1.02, 1.06), 0.80, 0.90, 1.10, vec3(0.04, 0.05, 0.055),
                     vec3(0.80, 0.90, 0.93), 10.0, 80.0, 0.5,
                     0.0, 1.0, 0.6, 0.6, 0.35, 0.0);
}

// Level ! (Run For Your Life): красный свет, паника
FloorLook lookRun() {
    return FloorLook(vec3(1.35, 0.32, 0.28), 0.55, 1.30, 0.95, vec3(0.03, 0.0, 0.0),
                     vec3(0.18, 0.0, 0.0), 2.0, 30.0, 0.9,
                     0.5, 1.2, 2.0, 1.4, 1.2, 1.0);
}

// acc + l * w
FloorLook madLook(FloorLook acc, FloorLook l, float w) {
    acc.tint       += l.tint * w;
    acc.saturation += l.saturation * w;
    acc.contrast   += l.contrast * w;
    acc.exposure   += l.exposure * w;
    acc.lift       += l.lift * w;
    acc.fogColor   += l.fogColor * w;
    acc.fogStart   += l.fogStart * w;
    acc.fogEnd     += l.fogEnd * w;
    acc.fogMax     += l.fogMax * w;
    acc.flicker    += l.flicker * w;
    acc.bloom      += l.bloom * w;
    acc.aberration += l.aberration * w;
    acc.grain      += l.grain * w;
    acc.vignette   += l.vignette * w;
    acc.pulse      += l.pulse * w;
    return acc;
}

// 1 внутри [lo, hi + 1), плавный спад на FLOOR_TRANSITION блоков наружу
float zoneWeight(float y, float lo, float hi) {
    float t = max(float(FLOOR_TRANSITION), 0.001);
    hi += 1.0;
    return smoothstep(lo - t, lo, y) * (1.0 - smoothstep(hi, hi + t, y));
}

FloorLook getLook(float cameraY) {
#if FLOOR_MODE == 1
    return lookLevel0();
#elif FLOOR_MODE == 2
    return lookLevel1();
#elif FLOOR_MODE == 3
    return lookLevel2();
#elif FLOOR_MODE == 4
    return lookPoolrooms();
#elif FLOOR_MODE == 5
    return lookRun();
#elif FLOOR_MODE == 6
    return lookOutside();
#else
    float w0 = zoneWeight(cameraY, float(L0_MIN_Y),   float(L0_MAX_Y));
    float w1 = zoneWeight(cameraY, float(L1_MIN_Y),   float(L1_MAX_Y));
    float w2 = zoneWeight(cameraY, float(L2_MIN_Y),   float(L2_MAX_Y));
    float w3 = zoneWeight(cameraY, float(POOL_MIN_Y), float(POOL_MAX_Y));
    float w4 = zoneWeight(cameraY, float(RUN_MIN_Y),  float(RUN_MAX_Y));

    float total = w0 + w1 + w2 + w3 + w4;
    float norm  = 1.0 / max(total, 1.0);

    FloorLook acc = FloorLook(vec3(0.0), 0.0, 0.0, 0.0, vec3(0.0),
                              vec3(0.0), 0.0, 0.0, 0.0,
                              0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    acc = madLook(acc, lookOutside(),   max(1.0 - total, 0.0));
    acc = madLook(acc, lookLevel0(),    w0 * norm);
    acc = madLook(acc, lookLevel1(),    w1 * norm);
    acc = madLook(acc, lookLevel2(),    w2 * norm);
    acc = madLook(acc, lookPoolrooms(), w3 * norm);
    acc = madLook(acc, lookRun(),       w4 * norm);
    return acc;
#endif
}
