#version 330
in vec2 texUVs;
in vec4 exColor;
out vec4 outColor;

uniform sampler2D tex;

void main() {
    vec2 texSize = vec2(textureSize(tex, 0));
    outColor = texture(tex, texUVs/texSize) * exColor;
}