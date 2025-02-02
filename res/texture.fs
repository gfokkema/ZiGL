#version 430 core

in vec2 tex_coord;
out vec4 FragColor;

uniform sampler2D tex_id;

void main()
{
    FragColor = texture(tex_id, tex_coord);
}
