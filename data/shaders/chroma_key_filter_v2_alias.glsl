// #iUniform vec4x4 ViewProj;
#iChannel0 "file:///home/manu/nfs/glmark2/data/textures/effect-2d.png"

#iUniform float opa = 1.0
#iUniform float ctst = 1.0
#iUniform float brtns = 0.0
#iUniform float gma = 1.0

#iUniform vec2 ckey = vec2(0.163388997, 0.103018999)
#iUniform vec2 ps = vec2(0.00052083336, 0.00092592591)
#iUniform float sim = 0.4
#iUniform float smth = 0.079
#iUniform float spl = 0.1

vec4 CColor(vec4 rgba)
{
	return vec4(pow(rgba.rgb, vec3(gma, gma, gma)) * ctst + brtns, rgba.a);
}

float GCDist(vec3 rgb)
{
	float cb = rgb.r * -0.100644 + rgb.g * -0.338572 + rgb.b * 0.439216 + 0.501961;
	float cr = rgb.r * 0.439216 + rgb.g * -0.398942 + rgb.b * -0.040274 + 0.501961;
	return distance(ckey, vec2(cb, cr));
}

float GNLChannel(float u)
{
	return (u <= 0.0031308) ? (12.92 * u) : ((1.055 * pow(u, 1.0 / 2.4)) - 0.055);
}

vec3 GNLColor(vec3 rgb)
{
	return vec3(GNLChannel(rgb.r), GNLChannel(rgb.g), GNLChannel(rgb.b));
}

vec3 STexture(vec2 uv)
{
	// vec3 rgb = image.Sample(textureSampler, uv).rgb;
	vec3 rgb = texture(iChannel0, uv).rgb;
	return GNLColor(rgb);
}

float GetDist(vec3 rgb, vec2 texCoord)
{
	vec2 h_ps = ps / 2.0;
	vec2 point_0 = vec2(ps.x, h_ps.y);
	vec2 point_1 = vec2(h_ps.x, -ps.y);
	float distVal = GCDist(STexture(texCoord-point_0));
	distVal += GCDist(STexture(texCoord+point_0));
	distVal += GCDist(STexture(texCoord-point_1));
	distVal += GCDist(STexture(texCoord+point_1));
	distVal *= 2.0;
	distVal += GCDist(GNLColor(rgb));
	return distVal / 9.0;
}

vec3 mlerp(vec3 colorone, vec3 colortwo, float value)
{
	return (colorone + value * (colortwo-colorone));
}

vec4 Filter(vec4 rgba, vec2 uv)
{
	float dist = GetDist(rgba.rgb, uv);
	float bMask = dist - sim;
	float fMask = pow(saturate(bMask / smth), 1.5);
	float sVal = pow(saturate(bMask / spl), 1.5);

	rgba.a *= opa;
	rgba.a *= fMask;

	float dst = dot(rgba.rgb, vec3(0.2126, 0.7152, 0.0722));
	rgba.rgb = mlerp(vec3(dst, dst, dst), rgba.rgb, sVal);

	return CColor(rgba);
}

vec4 ColorFilter(vec4 rgba, vec2 uv)
{
	rgba.rgb = max(vec3(0.0, 0.0, 0.0), rgba.rgb / rgba.a);
	rgba = Filter(rgba, uv);
	rgba.rgb *= rgba.a;
	return rgba;
}

void main() {
    vec2 uv_in = (gl_FragCoord.xy / iResolution.xy);
    vec4 rgba_in = texture(iChannel0, uv_in);

	vec4 rgba_out  = ColorFilter(rgba_in, uv_in);

    gl_FragColor = rgba_out;
}
