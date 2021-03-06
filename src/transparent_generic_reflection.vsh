!!ARBvp1.0
TEMP r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11;
PARAM c[96] = { program.env[0..95] };
ALIAS oPos = result.position;
ALIAS oD0 = result.color.primary;
ALIAS oT0 = result.texcoord[0];
ALIAS oT1 = result.texcoord[1];
ALIAS oT2 = result.texcoord[2];
ALIAS oT3 = result.texcoord[3];

ATTRIB v0 = vertex.attrib[0];
ATTRIB v1 = vertex.attrib[1];
ATTRIB v2 = vertex.attrib[2];
ATTRIB v3 = vertex.attrib[3];
ATTRIB v4 = vertex.attrib[4];

#DAJ defaults
MOV oD0, c[95].w;
MOV oT0, c[95];
MOV oT1, c[95];
MOV oT2, c[95];
MOV oT3, c[95];

# (1) compute eye vector ----------------------------------------------------------------
ADD r5.xyz, -v0, c[4];

# (3) compute reflection vector ---------------------------------------------------------
DP3 r6.x, r5, v1;
MUL r6.xyz, r6.x, v1;
MAD r6.xyz, r6.xyzz, c[4].w, -r5; 

# (4) output homogeneous point ----------------------------------------------------------
DP4 oPos.x, v0, c[0];
DP4 oPos.y, v0, c[1];
DP4 oPos.z, v0, c[2];
DP4 oPos.w, v0, c[3];

# (12) output texcoords -----------------------------------------------------------------
# we have to compute the z- axis by the cross product of the x- and y- axes
MOV r11, c[14];
MUL r10, c[13].yzxw, r11.zxyw;
MAD r10,-r11.yzxw, c[13].zxyw, r10;
DP3 oT0.x, r6, c[13];
DP3 oT0.y, r6, c[14];
DP3 oT0.z, r6, r10;
DP4 oT1.x, v4, c[15];
DP4 oT1.y, v4, c[16];
DP4 oT2.x, v4, c[17];
DP4 oT2.y, v4, c[18];
DP4 oT3.x, v4, c[19];
DP4 oT3.y, v4, c[20];

#KLC - commenting out fog

# (17) fog ------------------------------------------------------------------------------
DP4 r8.x, v0, c[7];					# x
DP4 r8.y,   v0, c[8];					# y
DP4 r8.z,   v0, c[6];					# z
ADD r8.xy,  v4.w, -r8;                # {1 - x, 1 - y}
MAX r8.xyz, r8, v4.z;                 # clamp to zero
MUL r8.xy,  r8, r8;                   # {(1 - x)^2, (1 - y)^2}
MIN r8.xyz, r8, v4.w;                 # clamp to one
ADD r8.x,   r8.x, r8.y;               # (1 - x)^2 + (1 - y)^2
MIN r8.x,   r8, v4.w;                 # clamp to one
ADD r8.xy,  v4.w, -r8;                # {1 - (1 - x)^2 - (1 - y)^2, 1 - (1 - y)^2}
MUL r8.xy,  r8, r8;                   # {(1 - (1 - x)^2 - (1 - y)^2)^2, (1 - (1 - y)^2)^2}
ADD r8.y,   r8.y, -r8.x;
MAD r8.w, c[9].y, r8.y, r8.x;
MUL r8.w, r8.w, c[9].z;               # Pf
MUL r8.z, r8.z, c[9].x;				# Af
ADD r8.xyzw, -r8, v4.w;               # (1 - Af),(1 - Pf)
MUL r8.w, r8.z, r8.w; 				# (1 - Af)*(1 - Pf)

# (6) fade ------------------------------------------------------------------------------

DP3 r10.x, v1, -c[5];
MAX r10.x, r10.x, -r10.x;
ADD r10.y, v4.w, -r10.x;
MUL r10.xy, r10, r8.w;
MUL oD0.w, r8.w, c[12].z; 		#no fade
#MUL oD1.xyzw, r10.xxxy, c[12].z; # fade-when-perpendicular(w), parallel(xyz)

END
