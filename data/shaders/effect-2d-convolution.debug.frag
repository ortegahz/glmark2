#ifdef GL_ES
precision mediump float;
#endif
#ifdef GL_ES
precision mediump float;
#endif
const float Kernel0 = 0.000000;
const float Kernel1 = 0.000000;
const float Kernel2 = 0.000000;
const float Kernel3 = 0.000000;
const float Kernel4 = 1.000000;
const float Kernel5 = 0.000000;
const float Kernel6 = 0.000000;
const float Kernel7 = 0.000000;
const float Kernel8 = 0.000000;
const float TextureStepY = 0.000926;
const float TextureStepX = 0.000521;
uniform sampler2D Texture0;
varying vec2 TextureCoord;

void main(void)
{
    vec4 result;

    result = texture2D(Texture0, TextureCoord + vec2(-1.0 * TextureStepX, 1.0 * TextureStepY)) * Kernel0 +
                    texture2D(Texture0, TextureCoord + vec2(0.0 * TextureStepX, 1.0 * TextureStepY)) * Kernel1 +
                    texture2D(Texture0, TextureCoord + vec2(1.0 * TextureStepX, 1.0 * TextureStepY)) * Kernel2 +
                    texture2D(Texture0, TextureCoord + vec2(-1.0 * TextureStepX, 0.0 * TextureStepY)) * Kernel3 +
                    texture2D(Texture0, TextureCoord + vec2(0.0 * TextureStepX, 0.0 * TextureStepY)) * Kernel4 +
                    texture2D(Texture0, TextureCoord + vec2(1.0 * TextureStepX, 0.0 * TextureStepY)) * Kernel5 +
                    texture2D(Texture0, TextureCoord + vec2(-1.0 * TextureStepX, -1.0 * TextureStepY)) * Kernel6 +
                    texture2D(Texture0, TextureCoord + vec2(0.0 * TextureStepX, -1.0 * TextureStepY)) * Kernel7 +
                    texture2D(Texture0, TextureCoord + vec2(1.0 * TextureStepX, -1.0 * TextureStepY)) * Kernel8;


    gl_FragColor = vec4(result.xyz, 1.0);
}

