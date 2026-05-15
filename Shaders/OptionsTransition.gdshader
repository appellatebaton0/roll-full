shader_type canvas_item;

uniform float threshold = 0.0;
uniform vec2 warp = vec2(1, 1);

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	
	if (sqrt(pow((SCREEN_UV.x - 0.5) * warp.x,2) + pow((SCREEN_UV.y - 0.5) * warp.y, 2)) > threshold)
	{
		COLOR.a = 0.0;
	}
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
