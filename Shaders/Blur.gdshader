shader_type canvas_item;

uniform sampler2D screen_texture:hint_screen_texture, filter_linear_mipmap;

uniform float lod: hint_range(0.0, 5) = 0.0;
uniform float fade = 0.1;

float lerp(float a, float b, float t)
{
	return a + t*(b-a);
}

void fragment(){
	
	float bias = lerp(lod, 0.0, max(abs(UV.x - 0.5), abs(UV.y - 0.5)) * fade);
	vec4 color = texture(screen_texture, SCREEN_UV, bias);

	COLOR = color;
	//COLOR.r = bias;
}