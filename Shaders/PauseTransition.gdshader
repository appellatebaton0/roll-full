shader_type canvas_item;

uniform float multipli = 100;
uniform float threshold = 0.3;

void fragment() {
	
	float original_alpha = COLOR.a;
	
	if (mod((SCREEN_UV.x + SCREEN_UV.y) * multipli, 1.) < threshold)
	{
		 COLOR.a = 0.;
	}
	
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
