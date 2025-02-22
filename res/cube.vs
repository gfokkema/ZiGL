#version 450 core

layout(location = 0) in vec3 vert_pos;
layout(location = 1) in vec2 vert_texcoord;
layout(location = 2) in  int vert_texid;

out vec2 frag_texcoord;
out  int frag_texid;

uniform mat4 mvp;
uniform sampler2D tex[8];

void main() {
    frag_texcoord = vert_texcoord;
    frag_texid = vert_texid;

    gl_Position = mvp * vec4(vert_pos, 1.0);
}
