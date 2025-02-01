#version 430 core

layout (location = 0) in vec3 pos;
layout (location = 1) in vec2 coord;

out vec2 tex_coord;

void main()
{
    gl_Position = vec4(pos, 1.0);
    tex_coord = coord;
}
