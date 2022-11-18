// #iUniform vec4x4 ViewProj;
#iChannel0 "file:///home/manu/nfs/glmark2/data/textures/effect-2d.bmp"
#iChannel1 "file:///media/manu/samsung/pics/green_screen.bmp"

#iUniform float stat = 1.0

#iUniform float statinv = 1.0

#iUniform float opa = 1.0
#iUniform float ctst = 1.0
#iUniform float brt = 0.0
#iUniform float gma = 1.0

#iUniform vec2 ckey = vec2(0.163388997, 0.103018999)
#iUniform vec2 psize = vec2(0.00052083336, 0.00092592591)
#iUniform float sim = 0.4
#iUniform float smth = 0.079
#iUniform float spl = 0.1

vec4 CColor(vec4 rgba)
{
	return vec4(pow(rgba.rgb, vec3(gma, gma, gma)) * ctst + brt, rgba.a);
}

float GCDist(vec3 rgb)
{
	float cb = rgb.r * -0.100644 + rgb.g * -0.338572 + rgb.b * 0.439216 + 0.501961;
	float cr = rgb.r * 0.439216 + rgb.g * -0.398942 + rgb.b * -0.040274 + 0.501961;
	return distance(ckey, vec2(cb, cr));
}

float GNChannel(float u)
{
	return (u <= 0.0031308) ? (12.92 * u) : ((1.055 * pow(u, 1.0 / 2.4)) - 0.055);
}

vec3 GNColor(vec3 rgb)
{
	return vec3(GNChannel(rgb.r), GNChannel(rgb.g), GNChannel(rgb.b));
}

vec3 STexture(vec2 uv)
{
	// vec3 rgb = image.Sample(textureSampler, uv).rgb;
	vec3 rgb = texture(iChannel0, uv).rgb;
	return GNColor(rgb);
}

float GDist(vec3 rgb, vec2 texCoord)
{
	vec2 h_psize = psize / 2.0;
	vec2 point_0 = vec2(psize.x, h_psize.y);
	vec2 point_1 = vec2(h_psize.x, -psize.y);
	float distVal = GCDist(STexture(texCoord-point_0));
	distVal += GCDist(STexture(texCoord+point_0));
	distVal += GCDist(STexture(texCoord-point_1));
	distVal += GCDist(STexture(texCoord+point_1));
	distVal *= 2.0;
	distVal += GCDist(GNColor(rgb));
	return distVal / 9.0;
}

vec3 mlerp(vec3 colorone, vec3 colortwo, float value)
{
	return (colorone + value * (colortwo-colorone));
}

vec4 Filter(vec4 rgba, vec2 uv)
{
	float chromaDist = GDist(rgba.rgb, uv);
	float baseMask = chromaDist - sim;
	float fullMask = pow(saturate(baseMask / smth), 1.5);
	float splVal = pow(saturate(baseMask / spl), 1.5);

	rgba.a *= opa;
	rgba.a *= fullMask;

	float desat = dot(rgba.rgb, vec3(0.2126, 0.7152, 0.0722));
	rgba.rgb = mlerp(vec3(desat, desat, desat), rgba.rgb, splVal);

	return CColor(rgba);
}

vec4 ColorFilter(vec4 rgba, vec2 uv)
{
	rgba.rgb = max(vec3(0.0, 0.0, 0.0), rgba.rgb / rgba.a);
	rgba = Filter(rgba, uv);
	rgba.rgb *= rgba.a;
	return rgba;
}

vec4 SFilter(vec4 rgba, float stat)
{
	const float red_weight = 0.299f;
	const float green_weight = 0.587f;
	const float blue_weight = 0.114f;

	float one_minus_sat_red = (1.0f - stat) * red_weight;
	float one_minus_sat_green = (1.0f - stat) * green_weight;
	float one_minus_sat_blue = (1.0f - stat) * blue_weight;
	float sat_val_red = one_minus_sat_red + stat;
	float sat_val_green = one_minus_sat_green + stat;
	float sat_val_blue = one_minus_sat_blue + stat;

	mat4 color_matrix = mat4( sat_val_red, one_minus_sat_red, one_minus_sat_red, 0.0,  // a b c 0.0
															one_minus_sat_green, sat_val_green, one_minus_sat_green, 0.0,  // d e f 0.0
															one_minus_sat_blue, one_minus_sat_blue, sat_val_blue, 0.0,  // g h i 0.0
															0.0, 0.0, 0.0, 1.0);

	// mat4 color_matrix = mat4( sat_val_red, one_minus_sat_green, one_minus_sat_blue, 0.0,  // a d g 0.0
	// 														one_minus_sat_red, sat_val_green, one_minus_sat_blue, 0.0,  // b e h 0.0
	// 														one_minus_sat_red, one_minus_sat_green, sat_val_blue, 0.0,  // c f i 0.0
	// 														0.0, 0.0, 0.0, 1.0);

	rgba.rgb = max(vec3(0.0, 0.0, 0.0), rgba.rgb / rgba.a);
	rgba = color_matrix * rgba;
	rgba.rgb *= rgba.a;


	return rgba;
}

void main() {
    vec2 uv_in = (gl_FragCoord.xy / iResolution.xy);
    vec4 rgba_in = texture(iChannel0, uv_in);

	rgba_in = SFilter(rgba_in, stat);

	vec4 rgba_out  = ColorFilter(rgba_in, uv_in);

	rgba_out = SFilter(rgba_out, statinv);

	vec4 rgba_bg = texture(iChannel1, uv_in);

    gl_FragColor = rgba_out + (1.0 - rgba_out.a) * rgba_bg;
}
