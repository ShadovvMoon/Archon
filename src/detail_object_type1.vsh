!!ARBvp1.0
TEMP r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11;

PARAM c[95] = { program.env[0..94] };
PARAM c95 = {0.0, 0.0, 0.0, 1.0};

ALIAS oPos = result.position;
ALIAS oD0 = result.color.primary;
ALIAS oT0 = result.texcoord[0];
ALIAS oFog = result.fogcoord;
ADDRESS a0;

#	struct detail_object_vertex
#	{
#		real_point3d	position;
#		pixel32			color;
#		pixel32			data;
#	};
ATTRIB v0 = vertex.attrib[0];
ATTRIB v8 = vertex.attrib[2];
ATTRIB v9 = vertex.attrib[1];

#DAJ defaults
MOV oT0, c95;
MOV oD0, c95.w;
MOV oFog, c95; 

# (7) lookup tables --------------------------------------------------------------------
MUL r10, v8, c[13].x;
ARL a0.x, r10.x;
MOV r7, c[a0.x + 29];
ARL a0.x, r10.y;
MOV r8, c[a0.x + 19];
ARL a0.x, r10.z;
MOV r9, c[a0.x + 15];

# (1) position within cell --------------------------------------------------------------
MOV r0, v0;

# (3) fade ------------------------------------------------------------------------------
ADD r5.xyz, r0, -c[4];
DP3 r10.w, r5, c[5];

# (6) viewer-facing transform -----------------------------------------------------------
MOV r2, c[13].yyzy;
MUL r3.xyz, r2.yzxw,  c[5].zxyw;
MAD r3.xyz, r2.zxyw, -c[5].yzxw, r3;
DP3 r3.w, r3, r3;
RSQ r3.w, r3.w;
MUL r3.xyz, r3, -r3.w; # X= Y^eye_forward

# (4) vertex position -------------------------------------------------------------------
# corner data .zw is {-1/2,0}, {1/2,0}, {1/2,1}, {-1/2,1}
# PERF: we could reMOVe a MULtiply if we premultiplied sprite bounds by type->size
MUL r10.xy, r8.zwww, r9.zwww; # adjust for corner, size
MUL r10.xy, r10, r7.zwww;                       # adjust for sprite bounds
MAD r0.xyz, r3,  r10.x, r0;                        # horizontal
MAD r0.xyz, r2, r10.y, r0;                        # vertical

# (4) output homogeneous point ----------------------------------------------------------
DP4 oPos.x, r0, c[0];
DP4 oPos.y, r0, c[1];
DP4 oPos.z, r0, c[2];
DP4 oPos.w, r0, c[3];
# DP4 oPos.x, v0, c[0];
# DP4 oPos.y, v0, c[1];
# DP4 oPos.z, v0, c[2];
# DP4 oPos.w, v0, c[3];

# (1) output texcoords ------------------------------------------------------------------
# corner data .xy is {0,0}, {1,0}, {1,1}, {0,1}
MAD oT0.xy, r9.xyyy, r7.zwww, r7.xyyy;

# (1) output color ----------------------------------------------------------------------
MOV oD0.xyz, v9;
MAD oD0.w, r10.w, r8.y, r8.x;

#DAJ CO fog
# (2) atmospheric fog ----------------------------------------------------------------
DP4 r8.z, r0, c[6];
MUL r8.z, r8.z, c[9].x;
SUB oFog.x, c[13].z, r8.z;

END
