// #iUniform vec4x4 ViewProj;
#iChannel0 "file:///mnt_manu/glmark2/glmark2-out/usr/local/share/glmark2/textures/effect-2d.png"

#iUniform vec4 cb_v4 = vec4(-0.100644, -0.338572,  0.439216, 0.501961)
#iUniform vec4 cr_v4 = vec4(0.439216, -0.398942, -0.040274, 0.501961)

#iUniform float opacity = 1.0
#iUniform float contrast = 1.0
#iUniform float brightness = 0.0
#iUniform float gamma = 1.0

#iUniform vec2 chroma_key = vec2(0.163388997, 0.103018999)
#iUniform vec2 pixel_size = vec2(0.00052083336, 0.00092592591)
#iUniform float similarity = 0.4
#iUniform float smoothness = 0.079
#iUniform float spill = 0.1

vec4 CalcColor(vec4 rgba)
{
	return vec4(pow(rgba.rgb, vec3(gamma, gamma, gamma)) * contrast + brightness, rgba.a);
}

float GetChromaDist(vec3 rgb)
{
	float cb = dot(rgb.rgb, cb_v4.xyz) + cb_v4.w;
	float cr = dot(rgb.rgb, cr_v4.xyz) + cr_v4.w;
	return distance(chroma_key, vec2(cb, cr));
}

float GetNonlinearChannel(float u)
{
	return (u <= 0.0031308) ? (12.92 * u) : ((1.055 * pow(u, 1.0 / 2.4)) - 0.055);
}

vec3 GetNonlinearColor(vec3 rgb)
{
	return vec3(GetNonlinearChannel(rgb.r), GetNonlinearChannel(rgb.g), GetNonlinearChannel(rgb.b));
}

vec3 SampleTexture(vec2 uv)
{
	// vec3 rgb = image.Sample(textureSampler, uv).rgb;
	vec3 rgb = texture(iChannel0, uv).rgb;
	return GetNonlinearColor(rgb);
}

float GetBoxFilteredChromaDist(vec3 rgb, vec2 texCoord)
{
	vec2 h_pixel_size = pixel_size / 2.0;
	vec2 point_0 = vec2(pixel_size.x, h_pixel_size.y);
	vec2 point_1 = vec2(h_pixel_size.x, -pixel_size.y);
	float distVal = GetChromaDist(SampleTexture(texCoord-point_0));
	distVal += GetChromaDist(SampleTexture(texCoord+point_0));
	distVal += GetChromaDist(SampleTexture(texCoord-point_1));
	distVal += GetChromaDist(SampleTexture(texCoord+point_1));
	distVal *= 2.0;
	distVal += GetChromaDist(GetNonlinearColor(rgb));
	return distVal / 9.0;
}

vec3 lerp(vec3 colorone, vec3 colortwo, float value)
{
	return (colorone + value * (colortwo-colorone));
}

vec4 ProcessChromaKey(vec4 rgba, vec2 uv)
{
	float chromaDist = GetBoxFilteredChromaDist(rgba.rgb, uv);
	float baseMask = chromaDist - similarity;
	float fullMask = pow(saturate(baseMask / smoothness), 1.5);
	float spillVal = pow(saturate(baseMask / spill), 1.5);

	rgba.a *= opacity;
	rgba.a *= fullMask;

	float desat = dot(rgba.rgb, vec3(0.2126, 0.7152, 0.0722));
	rgba.rgb = lerp(vec3(desat, desat, desat), rgba.rgb, spillVal);

	return CalcColor(rgba);
}

vec4 PSChromaKeyRGBA(vec4 rgba, vec2 uv)
{
	rgba.rgb = max(vec3(0.0, 0.0, 0.0), rgba.rgb / rgba.a);
	rgba = ProcessChromaKey(rgba, uv);
	rgba.rgb *= rgba.a;
	return rgba;
}

void main() {
    vec2 uv_in = (gl_FragCoord.xy / iResolution.xy);
    vec4 rgba_in = texture(iChannel0, uv_in);

	vec4 rgba_out  = PSChromaKeyRGBA(rgba_in, uv_in);

    gl_FragColor = rgba_out;
}
