// Общий фрагментный шейдер: обычное ванильное освещение по lightmap,
// вспышка урона у сущностей и ванильный туман (вода, лава, слепота, тьма).

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform vec4 entityColor;

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 glcolor;
varying float fogDist;

void main() {
    vec4 color = glcolor;
#ifdef USE_TEXTURE
    color *= texture2D(gtexture, texcoord);
#endif
#ifdef USE_ENTITY_COLOR
    color.rgb = mix(color.rgb, entityColor.rgb, entityColor.a);
#endif
#ifdef USE_LIGHTMAP
    color.rgb *= texture2D(lightmap, lmcoord).rgb;
#endif
    if (color.a < 0.004) discard;

#ifndef NO_FOG
    if (gl_Fog.end > gl_Fog.start + 0.5) {
        float fog = clamp((fogDist - gl_Fog.start) / (gl_Fog.end - gl_Fog.start), 0.0, 1.0);
        color.rgb = mix(color.rgb, gl_Fog.color.rgb, fog);
    }
#endif

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = color;
}
