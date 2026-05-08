shader_type canvas_item;

uniform sampler2D alpha_texture;

void fragment() {
	
	COLOR.a *= texture(alpha_texture, SCREEN_UV).a;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
