uniform sampler2D Texture0;
varying vec2 TextureCoord;

const float opa = 1.0;  // 透明度 [0 1]
const float ctst = 1.0;  // 对比度 [-4 4] 	ctst = (ctst < 0.0) ? (1.0 / (-ctst + 1.0)) : (ctst + 1.0);
const float brt = 0.0;  // 亮度 [-1 1]
const float gma = 1.0;  // 伽马矫正 [-1 1] gma = (gma < 0.0) ? (-gma + 1.0) : (1.0 / (gma + 1.0))

/* 选择的参考颜色
	换算公式：
	rgb = rgb / 255 （归一化）
	cb = rgb.r * -0.100644 + rgb.g * -0.338572 + rgb.b * 0.439216 + 0.501961;
	cr = rgb.r * 0.439216 + rgb.g * -0.398942 + rgb.b * -0.040274 + 0.501961;
	ckey = vec2(cb, cr);
*/
const vec2 ckey = vec2(0.163388997, 0.103018999);

const vec2 psize = vec2(0.00052083336, 0.00092592591);  // 平滑范围 [暂时写死]
const float sim = 0.4;  // 相似度阀值 [0.001 1]
const float smth = 0.079;  // 平滑滤波参数 [0.001 1]
const float spl = 0.1;  // 色彩融合 [0.001 1]

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
	vec3 rgb = texture2D(Texture0, TextureCoord).rgb;
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
	float cDist;
	float bMask;
	float fMask;
	float sVal;

	cDist = GDist(rgba.rgb, uv);
	bMask = cDist - sim;
	fMask = pow(clamp(bMask / smth, 0.0, 1.0), 1.5);
	sVal = pow(clamp(bMask / spl, 0.0, 1.0), 1.5);

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
	vec4 rgba_in;
	vec4 rgba_out;

	rgba_in = texture2D(Texture0, TextureCoord);
	rgba_out  = ColorFilter(rgba_in, TextureCoord);
	// rgba_out = rgba_in;

	gl_FragColor = rgba_out;
}
