shader_type spatial;

void fragment() {
	// Basic black color
	ALBEDO = vec3(0.0, 0.0, 0.0);

	// Faster oscillation and lower intensity for a subtler effect
	float glow = 0.005 * sin(TIME * 2.0);
	EMISSION = vec3(glow, glow, glow);
}