shader_type canvas_item;

// This creates a slider in the Inspector (0.0 = normal, 1.0 = solid white)
uniform float flash_modifier : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    // Look up the current pixel color from the sprite sheet texture
    vec4 color = texture(TEXTURE, UV);
    
    // Mix the original color with our flash color based on the modifier
    // We keep the original alpha (color.a) so transparent parts stay transparent!
    color.rgb = mix(color.rgb, flash_color.rgb, flash_modifier);
    
    COLOR = color;
}
