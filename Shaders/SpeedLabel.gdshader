shader_type canvas_item;

uniform float speed = 0.0;
uniform vec2 range = vec2(0.0, 1.0);
uniform vec3 colorA:source_color; 
uniform vec3 colorB:source_color; 

uniform float wave_affect = 6.;
uniform float wave_density = 150.;
uniform float wave_drift = 7.;

void fragment() {
	
	float y = (SCREEN_UV.y - range.x) / (range.y - range.x);
	if (int(speed * 200.) % 100 != 0){
		y += wave_affect / 100. * cos((wave_density * SCREEN_UV.x) + (wave_drift * TIME));
	}
	
	if (y > 1. - (2. * speed))
	{
		COLOR.rgb = colorA;
	}
	
	if (y > 1. - (speed - 0.5) * 2.)
	{
		COLOR.rgb = colorB;
	}
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
