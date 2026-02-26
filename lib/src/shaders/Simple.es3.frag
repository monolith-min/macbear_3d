#version 300 es
// Simple frag-shader ES3 //////////
precision mediump float;
in lowp vec4 DestinationColor;
out vec4 fragColor;

void main(void)
{
    fragColor = DestinationColor;
}
