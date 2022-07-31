#version 330
uniform mat4 vp;
layout(location = 0) in vec2 verts;
layout(location = 1) in vec2 uvs;
layout(location = 2) in vec4 color;

out vec2 texUVs;
out vec4 exColor;

void main() {
    gl_Position = vp * vec4(verts.x, verts.y, 0, 1);
    texUVs = uvs;
    exColor = color;
}