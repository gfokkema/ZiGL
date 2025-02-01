#version 430 core

in vec2 tex_coord;

uniform sampler2D tex_id;

out vec4 FragColor;

void main()
{
    FragColor = texture(tex_id, tex_coord);
}
