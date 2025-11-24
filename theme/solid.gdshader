shader_type canvas_item;
uniform float threshold : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    float alpha = texture(TEXTURE, UV).a;
	if (alpha > threshold) {
		COLOR.a = 1.0;
	} else {
		COLOR.a = 0.0;
	}
}