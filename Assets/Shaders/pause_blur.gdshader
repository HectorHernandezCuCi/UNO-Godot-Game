shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 5.0) = 2.5;

void fragment() {
    vec2 size = SCREEN_PIXEL_SIZE * blur_amount;
    vec4 color = vec4(0.0);

    color += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(-size.x, 0.0));
    color += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(size.x, 0.0));
    color += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(0.0, -size.y));
    color += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(0.0, size.y));

    color /= 4.0;
    COLOR = color;
}
