#version 450 core

layout(location = 0) out vec3 frag_color;

     in vec2 frag_texcoord;
flat in int frag_texid;

uniform sampler2D tex;

void main() {
   frag_color = texture(tex, frag_texcoord).rgb;
}
