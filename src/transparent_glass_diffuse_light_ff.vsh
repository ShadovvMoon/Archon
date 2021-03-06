!!ARBvp1.0
TEMP r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11;
PARAM c[96] = { program.env[0..95] };
ALIAS oPos = result.position;
ALIAS oD0 = result.color.primary;
ALIAS oT0 = result.texcoord[0];
ALIAS oT1 = result.texcoord[1];

ATTRIB v0 = vertex.attrib[0];
ATTRIB v1 = vertex.attrib[1];
ATTRIB v4 = vertex.attrib[2];

#DAJ defaults
MOV oD0, c[95].w;
MOV oT0, c[95];
MOV oT1, c[95];

# (1) eye vector ------------------------------------------------------------------------
ADD r5.xyz, -v0, c[4];

# (9) compute point light 0 attenuation -------------------------------------------------
ADD r4.xyz, c[15], -v0;
DP3 r4.w, r4, r4;
RSQ r10.w, r4.w;
MUL r4.xyz, r4, r10.w;
MAD r8.x, r4.w, -c[15].w, v4.w;
DP3 r9.x, r4, v1;
DP3 r10.w, r4, c[16];
MUL r10.w, r10.w, c[16].w;
ADD r8.z, r10.w, c[17].w;

# (9) compute point light 1 attenuation -------------------------------------------------
ADD r4.xyz, c[18], -v0;
DP3 r4.w, r4, r4;
RSQ r10.w, r4.w;
MUL r4.xyz, r4, r10.w;
MAD r8.y, r4.w, -c[18].w, v4.w;
DP3 r9.y, r4, v1;
DP3 r10.w, r4, c[16];
MUL r10.w, r10.w, c[19].w;
ADD r9.z, r10.w, c[20].w;

# (1) compute distant light 2 attenuation -----------------------------------------------
DP3 r8.w, v1, -c[21];

# (1) compute distant light 3 attenuation -----------------------------------------------
DP3 r9.w, v1, -c[23];

# (4) clamp all light attenuations ------------------------------------------------------
MAX r8, r8, v4.z;
MAX r9, r9, v4.z;
MIN r8, r8, v4.w;
MIN r9, r9, v4.w;

# (8) output light contributions --------------------------------------------------------
MOV r7.xyz, c[25];
MUL r10.xy, r8, r9;
MUL r10.x, r10.x, r8.z;
MUL r10.y, r10.y, r9.z;
MAD r7.xyz, r10.x, c[17], r7;
MAD r7.xyz, r10.y, c[20], r7;
MAD r7.xyz, r8.w, c[22], r7;
MAD oD0.xyz, r9.w, c[24], r7;

# (4) output homogeneous point ----------------------------------------------------------
DP4 oPos.x, v0, c[0];
DP4 oPos.y, v0, c[1];
DP4 oPos.z, v0, c[2];
DP4 oPos.w, v0, c[3];

# (3) output texcoords ------------------------------------------------------------------
MUL oT0.xy, v4, c[10].xyyy;  
MUL oT1.xy, v4, c[10].zwww; # diffuse detail map

# (17) fog ------------------------------------------------------------------------------
DP4 r8.x, v0, c[7];     # x
DP4 r8.y,   v0, c[8];     # y
DP4 r8.z,   v0, c[6]; # z
ADD r8.xy,  v4.w, -r8;                            # {1 - x, 1 - y}
MAX r8.xyz, r8, v4.z;                            # clamp to zero
MUL r8.xy,  r8, r8;                     # {(1 - x)^2, (1 - y)^2}
MIN r8.xyz, r8, v4.w;                             # clamp to one
ADD r8.x,   r8.x, r8.y;                 # (1 - x)^2 + (1 - y)^2
MIN r8.x,   r8, v4.w;                             # clamp to one
ADD r8.xy,  v4.w, -r8;                            # {1 - (1 - x)^2 - (1 - y)^2, 1 - (1 - y)^2}
MUL r8.xy,  r8, r8;                     # {(1 - (1 - x)^2 - (1 - y)^2)^2, (1 - (1 - y)^2)^2}
ADD r8.y,   r8.y, -r8.x;
MAD r8.w, c[9].y, r8.y, r8.x;
MUL r8.w, r8.w, c[9].z;                # Pf
MUL r8.z, r8.z, c[9].x; # Af
ADD r8.xyzw, -r8, v4.w;                           # (1 - Af),(1 - Pf)
MUL oD0.w, r8.z, r8.w;           # (1 - Af)*(1 - Pf)
END
