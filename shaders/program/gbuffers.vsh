// Общий вершинный шейдер для всей геометрии мира.
// Флаги задаются в gbuffers_*.vsh: USE_TEXTURE, USE_LIGHTMAP, USE_ENTITY_COLOR

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 glcolor;
varying float fogDist;

void main() {
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor  = gl_Color;
    fogDist  = length((gl_ModelViewMatrix * gl_Vertex).xyz);
}
