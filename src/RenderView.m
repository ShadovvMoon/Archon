//
//  RenderView.m
//  swordedit
//
//  Created by sword on 5/6/08.renderO
//  Copyright 2008 sword Inc. All rights reserved.
//

#import "RenderView.h"
#import "defines.h"

#import "Camera.h"

#import "GeneralMath.h"

#import "BSP.h"
#import "ModelTag.h"

#import "TextureManager.h"

#import "SpawnEditorController.h"
#import "unistd.h"
//#import "math.h"


#include <assert.h>
#include <CoreServices/CoreServices.h>

#include <unistd.h>
#import "BitmapTag.h"


#ifndef MACVERSION
#import "glew.h"
#endif

#import <OpenGL/glext.h>
#import <OpenGL/glu.h>
#include "gssdkcr.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include "md5.h"

#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/ptrace.h>
#include <mach/mach.h>
#include <errno.h>
#include <stdlib.h>
#include <Security/Authorization.h>

mach_port_name_t halo = MACH_PORT_NULL;
@implementation NSBitmapImageRep (Resize)

- (NSBitmapImageRep *)resizeBitmapImageRepToSize:(NSSize)outputBitmapSize
{
    NSBitmapImageRep *newRep =
    [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                            pixelsWide:outputBitmapSize.width
                                            pixelsHigh:outputBitmapSize.height
										 bitsPerSample:8
									   samplesPerPixel:4
                                              hasAlpha:YES    // must have alpha!
                                              isPlanar:NO
										colorSpaceName:NSCalibratedRGBColorSpace
										   bytesPerRow:0
                                          bitsPerPixel:0 ];
	
    [NSGraphicsContext saveGraphicsState];
    
    NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:newRep];
    [context setImageInterpolation:NSImageInterpolationHigh];
    [context setShouldAntialias:YES];
    
    [NSGraphicsContext setCurrentContext:context];
	
    NSLog(@"Resizing bitmap to %f %f", outputBitmapSize.width, outputBitmapSize.height);
    
    // do not use drawAtPoint: !! it does not respect resolution due to a bug
    [self drawInRect:NSMakeRect(0, 0, outputBitmapSize.width, outputBitmapSize.height)];
	
    [NSGraphicsContext restoreGraphicsState];
    [newRep setSize:outputBitmapSize];  // this sets the resolution of the source
	
	return newRep;
}

@end

CVector3 AddTwoVectors(CVector3 v1, CVector3 v2);
CVector3 SubtractTwoVectors(CVector3 v1, CVector3 v2);
CVector3 MultiplyTwoVectors(CVector3 v1, CVector3 v2);
CVector3 DivideTwoVectors(CVector3 v1, CVector3 v2);
CVector3 Cross(CVector3 vVector1, CVector3 vVector2);
float Magnitude(CVector3 vNormal);
CVector3 Normalize(CVector3 vVector);
CVector3 Cross(CVector3 vVector1, CVector3 vVector2);
CVector3 NewCVector3(float x,float y,float z);

GLfloat lightPos[]={50.371590,-50.247974,100,0.0};

int selectedBSP = -1;

/* 
 create a matrix that will project the desired shadow */
void
shadowmatrix(GLfloat shadowMat[4][4],
             GLfloat groundplane[4],
             GLfloat lightpos[4])
{
    GLfloat dot;
    
    /* find dot product between light position vector and ground plane normal */
    dot = groundplane[0] * lightpos[0] +
    groundplane[1] * lightpos[1] +
    groundplane[2] * lightpos[2] +
    groundplane[3] * lightpos[3];
    
    shadowMat[0][0] = dot - lightpos[0] * groundplane[0];
    shadowMat[1][0] = 0.f - lightpos[0] * groundplane[1];
    shadowMat[2][0] = 0.f - lightpos[0] * groundplane[2];
    shadowMat[3][0] = 0.f - lightpos[0] * groundplane[3];
    
    shadowMat[0][1] = 0.f - lightpos[1] * groundplane[0];
    shadowMat[1][1] = dot - lightpos[1] * groundplane[1];
    shadowMat[2][1] = 0.f - lightpos[1] * groundplane[2];
    shadowMat[3][1] = 0.f - lightpos[1] * groundplane[3];
    
    shadowMat[0][2] = 0.f - lightpos[2] * groundplane[0];
    shadowMat[1][2] = 0.f - lightpos[2] * groundplane[1];
    shadowMat[2][2] = dot - lightpos[2] * groundplane[2];
    shadowMat[3][2] = 0.f - lightpos[2] * groundplane[3];
    
    shadowMat[0][3] = 0.f - lightpos[3] * groundplane[0];
    shadowMat[1][3] = 0.f - lightpos[3] * groundplane[1];
    shadowMat[2][3] = 0.f - lightpos[3] * groundplane[2];
    shadowMat[3][3] = dot - lightpos[3] * groundplane[3];
    
}

bool   gp;                      // G Pressed? ( New )
GLuint filter;                      // Which Filter To Use
GLuint fogMode[]= { GL_EXP, GL_EXP2, GL_LINEAR };   // Storage For Three Types Of Fog
GLuint fogfilter= 0;                    // Which Fog To Use


/*
	TODO:
		Fucking lookup selection lookup table is being fed very large values for some reason. Something to do with the names, have to check it out.
*/

int useNewRenderer()
{
    return newR;
}

bool drawObjects()
{
    return drawO;
}

#include <sys/socket.h>
#include <netinet/in.h>
@implementation RenderView




//Networking crap

int hex_to_int(char c){
    if(c >=97)
        c=c-32;
    int first = c / 16 - 3;
    int second = c % 16;
    int result = first*10 + second;
    if(result > 9) result--;
    return result;
}

int hex_to_ascii(char c, char d){
    int high = hex_to_int(c) * 16;
    int low = hex_to_int(d);
    return high+low;
}


static unsigned char gethex(const char *s, char **endptr) {
    assert(s);
    while (isspace(*s)) s++;
    assert(*s);
    return strtoul(s, endptr, 16);
}

unsigned char *convert(const char *s, int *length) {
    unsigned char *answer = malloc((strlen(s) + 1) / 3);
    unsigned char *p;
    for (p = answer; *s; p++)
        *p = gethex(s, (char **)&s);
    *length = p - answer;
    return answer;
}




//Halo encryption stuff
/*
 
 Halo packets decryption/encryption algorithm and keys builder 0.1.3
 by Luigi Auriemma
 e-mail: aluigi@autistici.org
 web:    aluigi.org
 
 
 INTRODUCTION
 ============
 The famous game called Halo (I talk about the PC version) uses
 encrypted packets and the set of functions available here is all you
 need to decrypt and encrypt the packets of this game.
 It's a bit complex to explain the details of the algorithm moreover for
 me since I have no knowledge of cryptography, however it uses the TEA
 algorithm to encrypt and decrypt the packets and exist 2 keys exchanged
 between the 2 hosts plus a private key (a random hash) for each one.
 It's not possible for a third person to decrypt the data between them
 due to the usage of this nice method to handle keys, so capturing the
 exchanged keys will not let you to decrypt the data.
 FYI, the data in the packets is stored in bitstream format and the
 latest 4 bytes are a classical 32 bits checksum of the packet, so keep
 that in mind when you want to analyze the data.
 
 
 HOW TO USE
 ==========
 First, you need to specify the following buffers in your program:
 
 u_char    enckey[16],  // used to encrypt
 deckey[16],  // used to decrypt
 hash[17];    // the private key, it's 17 bytes long (NULL)
 
 You need only 3 functions to do everything but there are many others
 available in this file so you have the maximum freedom of using your
 preferred way to handle the keys and the data:
 
 - halo_generate_keys()
 needs 3 arguments: the random hash, the source key and the
 destination key
 All these fields are automatically zeroed when needed so you must do
 nothing.
 This function must be called the first time to send the key to the
 other host and other 2 consecutive times to calculate the decryption
 and encryption key.
 The hash field is just your private key which is random.
 
 To create your key use NULL as source key, a buffer of 17 bytes for
 the private key and a destination buffer of 16 bytes that will contain
 the generated key.
 Example:    halo_generate_keys(hash, NULL, enckey);
 // you can use enckey or a temporary buffer too
 
 To create the decryption and encryption keys use the key received from
 the other host as source and a buffer of 16 bytes as destination.
 The hash is ever the same, you must not touch it.
 Example:    halo_generate_keys(hash, packet_buffer + 7, deckey);
 halo_generate_keys(hash, packet_buffer + 7, enckey);
 // "packet_buffer + 7" is where is located the received
 // key
 
 - void halo_tea_decrypt()
 needs 3 arguments, the buffer to decrypt, its size and the decryption
 key previously generated with the halo_generate_keys() function:
 halo_tea_decrypt(buffer, len, deckey);
 
 - void halo_tea_encrypt()
 needs 3 arguments, the buffer to encrypt, its size and the encryption
 key previously generated:
 halo_tea_encrypt(buffer, len, enckey);
 
 Useful is also the halo_crc32() function that calculates the CRC number
 that must be placed at the end of each packet. The data that must be
 passed to the function usually starts at offset 7 of each packet, the
 same resulted from the decryption/encryption. Remember that the size
 must not contain the last 4 bytes occupied by the checksum.
 Example:      halo_crc32(packet_buffer + 7, packet_len - 7 - 4);
 
 
 REAL EXAMPLES
 =============
 Check the stuff I have written for Halo on my website and my
 proof-of-concept for a vulnerability I found:
 
 http://aluigi.org/papers.htm#halo
 http://aluigi.org/poc/haloloop.zip
 
 
 LICENSE
 =======
 Copyright 2005,2006 Luigi Auriemma
 
 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
 
 http://www.gnu.org/licenses/gpl.txt
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <time.h>

#ifdef WIN32            // something better than a simple time(NULL)
#include <windows.h>
#define HALO_RAND   (uint32_t)GetTickCount()    // 1000/s resolution
#else
#include <sys/times.h>
#define HALO_RAND   (uint32_t)times(0)          // 100/s resolution
#endif


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include "show_dump.h"
#include "rwbits.h"

#ifdef WIN32
#include <winsock.h>
#include "winerr.h"

#define close   closesocket
#define sleep   Sleep
#else
#include <unistd.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <netdb.h>
#endif

typedef uint8_t     u8;
typedef uint16_t    u16;
typedef uint32_t    u32;


#define VER         "0.1.2"
#define BUFFSZ      0xffff
#define SEND(x,y)   sendto(x, buff, len, 0, (struct sockaddr *)&y, sizeof(struct sockaddr_in));
#define RECV(x,y)   len = recvfrom(x, buff, BUFFSZ, 0, (struct sockaddr *)&y, &psz); \
if(len < 0) std_err();



void genkeys(u8 *text, u8 *hash1, u8 *hash2, u8 *skey1, u8 *skey2, u8 *dkey1, u8 *dkey2);
BOOL decshow(u8 *buff, int len, u8 *deckey, u8 *enckey, BOOL output, BOOL client, int tickcount);
int read_bstr(u8 *data, u32 len, u8 *buff, u32 bitslen);
void halobits(u8 *buff, int buffsz, BOOL output);
u32 resolv(char *host);
void std_err(void);

void sendPacket(char *s, u8 enckey1[16], u8 deckey1[16], int sd2, struct sockaddr_in peer2,  int packet_no, int secondpktnum, int player_number);

#pragma pack(1)
typedef struct {
    u16     sign;
    u8      type;
    u16     gs1;
    u16     gs2;
} gh_t;
#pragma pack()


#ifndef WIN32
void std_err(void) {
    NSLog(@"ERROR!");
    
}
#endif


void halo_create_randhash(uint8_t *out) {
    uint32_t            randnum;
    int                 i;
    const static char   hex[16] = "0123456789ABCDEF";
    

    randnum = time(0);
    for(i = 0; i < 16; i++) {
        randnum = (randnum * 0x343FD) + 0x269EC3;
        *out++ = hex[(randnum >> 16) & 15];
    }
    *out = 0;
}



void halo_byte2hex(uint8_t *in, uint8_t *out) {
    int                 i;
    const static char   hex[16] = "0123456789ABCDEF";
    
    for(i = 16; i; i--) {
        if(*in) break;
        in++;
    }
    while(i--) {
        *out++ = hex[*in >> 4];
        *out++ = hex[*in & 15];
        in++;
    }
    *out = 0;
}



void halo_hex2byte(uint8_t *in, uint8_t *out) {
    int     i,
    j,
    t;
    
    memset(out, 0, 16);
    while(*in) {
        for(j = 0; j < 4; j++) {
            t = 0;
            for(i = 15; i >= 0; i--) {
                t += (out[i] << 1);
                out[i] = t;
                t >>= 8;
            }
        }
        t = *in |= 0x20;
        out[15] |= ((t - (0x27 * (t > 0x60))) - 0x30);
        in++;
    }
}



void halo_fix_check(uint8_t *key1, uint8_t *key2) {
    int     i,
    j;
    
    for(i = 0; i < 16; i++) {
        if(key1[i] != key2[i]) break;
    }
    if((i < 16) && (key1[i] > key2[i])) {
        for(j = 0, i = 16; i--; j >>= 8) {
            j += (key1[i] - key2[i]);
            key1[i] = j;
        }
    }
}



void halo_key_scramble(uint8_t *key1, uint8_t *key2, uint8_t *fixnumb) {
    int     i,
    j,
    cnt;
    uint8_t tk1[16],
    tk2[16];
    
    memcpy(tk1,  key1, 16);
    memcpy(tk2,  key2, 16);
    memset(key1, 0,    16);
    
    cnt = 16 << 3;
    while(cnt--) {
        if(tk1[15] & 1) {
            for(j = 0, i = 16; i--; j >>= 8) {
                j += key1[i] + tk2[i];
                key1[i] = j;
            }
            halo_fix_check(key1, fixnumb);
        }
        
        for(j = i = 0; i < 16; i++, j <<= 8) {
            j |= tk1[i];
            tk1[i] = j >> 1;
            j &= 1;
        }
        
        for(j = 0, i = 16; i--; j >>= 8) {
            j += (tk2[i] << 1);
            tk2[i] = j;
        }
        halo_fix_check(tk2, fixnumb);
    }
}



void halo_create_key(uint8_t *keystr, uint8_t *randhash, uint8_t *fixnum, uint8_t *dest) {
    int     i,
    j,
    cnt;
    uint8_t keystrb[16],
    randhashb[16],
    fixnumb[16];
    
    halo_hex2byte(keystr,   keystrb);
    halo_hex2byte(randhash, randhashb);
    halo_hex2byte(fixnum,   fixnumb);
    
    memset(dest, 0, 16);
    dest[15] = 0x01;
    
    cnt = 16 << 3;
    while(cnt--) {
        if(randhashb[15] & 1) {
            halo_key_scramble(dest, keystrb, fixnumb);
        }
        halo_key_scramble(keystrb, keystrb, fixnumb);
        
        for(j = i = 0; i < 16; i++, j <<= 8) {
            j |= randhashb[i];
            randhashb[i] = j >> 1;
            j &= 1;
        }
    }
}



void tea_decrypt(uint32_t *p, uint32_t *keyl) {
    uint32_t    y,
    z,
    sum,
    a = keyl[0],
    b = keyl[1],
    c = keyl[2],
    d = keyl[3];
    int         i;
    
    y = p[0];
    z = p[1];
    sum = 0xc6ef3720;
    for(i = 0; i < 32; i++) {
        z -= ((y << 4) + c) ^ (y + sum) ^ ((y >> 5) + d);
        y -= ((z << 4) + a) ^ (z + sum) ^ ((z >> 5) + b);
        sum -= 0x9e3779b9;
    }
    p[0] = y;
    p[1] = z;
}



void halo_tea_decrypt(uint8_t *data, int size, uint8_t *key) {
    uint32_t    *p    = (uint32_t *)data,
    *keyl = (uint32_t *)key;
    
    if(size & 7) {
        tea_decrypt((uint32_t *)(data + size - 8), keyl);
    }
    
    size >>= 3;
    while(size--) {
        tea_decrypt(p, keyl);
        p += 2;
    }
}



void tea_encrypt(uint32_t *p, uint32_t *keyl) {
    uint32_t    y,
    z,
    sum,
    a = keyl[0],
    b = keyl[1],
    c = keyl[2],
    d = keyl[3];
    int         i;
    
    y = p[0];
    z = p[1];
    sum = 0;
    for(i = 0; i < 32; i++) {
        sum += 0x9e3779b9;
        y += ((z << 4) + a) ^ (z + sum) ^ ((z >> 5) + b);
        z += ((y << 4) + c) ^ (y + sum) ^ ((y >> 5) + d);
    }
    p[0] = y;
    p[1] = z;
}


int nextrand(int *ret) {
    static int  num = 0;
    
    if(ret) num = *ret;
    if(!num) num = time(NULL);
    num = ((num * 0x343FD) + 0x269EC3);
    if(ret) *ret = num;
    return(num);
}


void create_randchall(u32 rnd, u8 *out, int len) {
    static const u8 table[] =
    "0123456789"
    "abcdefghijklmnopqrstuvwxyz"
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    
    while(len--) {
        rnd = (rnd * 0x343FD) + 0x269EC3;
        *out++ = table[(rnd >> 16) % (sizeof(table) - 1)];
    }
    *out = 0;
}

u8 *do_md5(u8 *data, int len, u8 *hexout) {
    static const u8 hex[] = "0123456789abcdef";
    int     i;
    u8      md5h[16];
    
    md5(data, len, md5h);
    
    if(!hexout) return(NULL);
    for(i = 0; i < 16; i++) {
        *hexout++ = hex[md5h[i] >> 4];
        *hexout++ = hex[md5h[i] & 0xf];
    }
    // no final NULL
    return(hexout);
}


void hash2byte(u8 *in, u8 *out) {
    int     i,
    n;
    
    for(i = 0; i < 16; i++) {
        sscanf(in + (i << 1), "%02x", &n);
        out[i] = n;
    }
}



void halo_tea_encrypt(uint8_t *data, int size, uint8_t *key) {
    uint32_t    *p    = (uint32_t *)data,
    *keyl = (uint32_t *)key;
    int         rest  = size & 7;
    
    size >>= 3;
    while(size--) {
        tea_encrypt(p, keyl);
        p += 2;
    }
    
    if(rest) {
        tea_encrypt((uint32_t *)((uint8_t *)p - (8 - rest)), keyl);
    }
}



void halo_generate_keys(uint8_t *hash, uint8_t *source_key, uint8_t *dest_key) {
    uint8_t tmp_key[33],
    fixed_key[33];
    
    strcpy(fixed_key, "10001"); // key 1
    
    if(!source_key)
    {           // encryption
        strcpy(tmp_key, "3");   // key 2
        halo_create_randhash(hash);
        
        printf("\nHASH: %s\n", hash);
    } else {
        halo_byte2hex(source_key, tmp_key);
    }
    
    source_key = tmp_key;
    halo_create_key(source_key, hash, fixed_key, dest_key);
}

u32 halo_info(u8 *buff, struct sockaddr_in *peer) {
    u32     ver         = 0;
    int     sd,
    len;
    u8      *gamever    = NULL,
    *p;
    
    sd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if(sd < 0) std_err();
    
    printf("\n- send query\n");

    len = send_recv(sd, "\\status\\", 8, buff, BUFFSZ, peer, 0);

   
    if(len >= 0)
    {
    
        printf("\n- handle reply:\n");
        
        gs_handle_info(buff, len, 1, '\\', 0, 0,
                       "gamever",  &gamever,
                       NULL,       NULL);
        
        if(gamever)
        {
            NSLog(@"We have the game version");
            p = strrchr(gamever, '.');
            if(p) {
                p++;
            } else {
                p = gamever;
            }
            ver = atoi(p) * 1000;
        }
        
    
    }
    
    //close(sd);
    return(ver);
}



int putcc(u8 *buff, int chr, int len) {
    memset(buff, chr, len);
    return(len);
}



int putmm(u8 *buff, u8 *data, int len) {
    memcpy(buff, data, len);
    return(len);
}



int putxx(u8 *data, u32 num, int bits) {
    int     i,
    bytes;
    
    bytes = bits >> 3;
    for(i = 0; i < bytes; i++) {
        data[i] = (num >> (i << 3)) & 0xff;
    }
    return(bytes);
}

u8 *lastHostPacket;
int lastHostLength;


int timeout(int sock, int secs) {
    struct  timeval tout;
    fd_set  fd_read;
    
    tout.tv_sec  = secs;
    tout.tv_usec = 0;
    FD_ZERO(&fd_read);
    FD_SET(sock, &fd_read);
    if(select(sock + 1, &fd_read, NULL, NULL, &tout)
       <= 0) return(-1);
    return(0);
}

int gs_handle_info(u8 *data, int datalen, int nt, int chr, int front, int rear, ...) {
    va_list ap;
    int     i,
    args,
    found;
    u8      **parz,
    ***valz,
    *p,
    *limit,
    *par,
    *val;
    
    va_start(ap, rear);
    for(i = 0; ; i++) {
        if(!va_arg(ap, u8 *))  break;
        if(!va_arg(ap, u8 **)) break;
    }
    va_end(ap);
    
    args = i;
    parz = malloc(args * sizeof(u8 *));
    valz = malloc(args * sizeof(u8 **));
    
    va_start(ap, rear);
    for(i = 0; i < args; i++) {
        parz[i]  = va_arg(ap, u8 *);
        valz[i]  = va_arg(ap, u8 **);
        *valz[i] = NULL;
    }
    va_end(ap);
    
    found  = 0;
    limit  = data + datalen - rear;
    *limit = 0;
    data   += front;
    par    = NULL;
    val    = NULL;
    
    for(p = data; (data < limit) && p; data = p + 1, nt++) {
        p = strchr(data, chr);
        if(p) *p = 0;
        
        if(nt & 1) {
            if(!par) continue;
            val = data;
            printf("  %35s %s\n", par, val);
            
            
            for(i = 0; i < args; i++) {
                if(!strcmp(par, parz[i])) *valz[i] = val;
            }
        } else {
            par = data;
        }
    }
    
    free(parz);
    free(valz);
    return(found);
}

unsigned int wartimes_crc(unsigned char *data, unsigned int len) {
    int             i;
    unsigned int   crc = 0x0000007f,
    table[4] = {
        0x0000162e,
        0x000004d0,
        0x00001994,
        0x00002694
    };
    
    data += 8;
    for(i = 8; i < len; i++) {
        crc += table[i & 3] + *data;
        data++;
    }
    return(crc);
}


uint32_t halo_crc32(uint8_t *data, int size) {
    const static uint32_t   crctable[] = {
        0x00000000, 0x77073096, 0xee0e612c, 0x990951ba,
        0x076dc419, 0x706af48f, 0xe963a535, 0x9e6495a3,
        0x0edb8832, 0x79dcb8a4, 0xe0d5e91e, 0x97d2d988,
        0x09b64c2b, 0x7eb17cbd, 0xe7b82d07, 0x90bf1d91,
        0x1db71064, 0x6ab020f2, 0xf3b97148, 0x84be41de,
        0x1adad47d, 0x6ddde4eb, 0xf4d4b551, 0x83d385c7,
        0x136c9856, 0x646ba8c0, 0xfd62f97a, 0x8a65c9ec,
        0x14015c4f, 0x63066cd9, 0xfa0f3d63, 0x8d080df5,
        0x3b6e20c8, 0x4c69105e, 0xd56041e4, 0xa2677172,
        0x3c03e4d1, 0x4b04d447, 0xd20d85fd, 0xa50ab56b,
        0x35b5a8fa, 0x42b2986c, 0xdbbbc9d6, 0xacbcf940,
        0x32d86ce3, 0x45df5c75, 0xdcd60dcf, 0xabd13d59,
        0x26d930ac, 0x51de003a, 0xc8d75180, 0xbfd06116,
        0x21b4f4b5, 0x56b3c423, 0xcfba9599, 0xb8bda50f,
        0x2802b89e, 0x5f058808, 0xc60cd9b2, 0xb10be924,
        0x2f6f7c87, 0x58684c11, 0xc1611dab, 0xb6662d3d,
        0x76dc4190, 0x01db7106, 0x98d220bc, 0xefd5102a,
        0x71b18589, 0x06b6b51f, 0x9fbfe4a5, 0xe8b8d433,
        0x7807c9a2, 0x0f00f934, 0x9609a88e, 0xe10e9818,
        0x7f6a0dbb, 0x086d3d2d, 0x91646c97, 0xe6635c01,
        0x6b6b51f4, 0x1c6c6162, 0x856530d8, 0xf262004e,
        0x6c0695ed, 0x1b01a57b, 0x8208f4c1, 0xf50fc457,
        0x65b0d9c6, 0x12b7e950, 0x8bbeb8ea, 0xfcb9887c,
        0x62dd1ddf, 0x15da2d49, 0x8cd37cf3, 0xfbd44c65,
        0x4db26158, 0x3ab551ce, 0xa3bc0074, 0xd4bb30e2,
        0x4adfa541, 0x3dd895d7, 0xa4d1c46d, 0xd3d6f4fb,
        0x4369e96a, 0x346ed9fc, 0xad678846, 0xda60b8d0,
        0x44042d73, 0x33031de5, 0xaa0a4c5f, 0xdd0d7cc9,
        0x5005713c, 0x270241aa, 0xbe0b1010, 0xc90c2086,
        0x5768b525, 0x206f85b3, 0xb966d409, 0xce61e49f,
        0x5edef90e, 0x29d9c998, 0xb0d09822, 0xc7d7a8b4,
        0x59b33d17, 0x2eb40d81, 0xb7bd5c3b, 0xc0ba6cad,
        0xedb88320, 0x9abfb3b6, 0x03b6e20c, 0x74b1d29a,
        0xead54739, 0x9dd277af, 0x04db2615, 0x73dc1683,
        0xe3630b12, 0x94643b84, 0x0d6d6a3e, 0x7a6a5aa8,
        0xe40ecf0b, 0x9309ff9d, 0x0a00ae27, 0x7d079eb1,
        0xf00f9344, 0x8708a3d2, 0x1e01f268, 0x6906c2fe,
        0xf762575d, 0x806567cb, 0x196c3671, 0x6e6b06e7,
        0xfed41b76, 0x89d32be0, 0x10da7a5a, 0x67dd4acc,
        0xf9b9df6f, 0x8ebeeff9, 0x17b7be43, 0x60b08ed5,
        0xd6d6a3e8, 0xa1d1937e, 0x38d8c2c4, 0x4fdff252,
        0xd1bb67f1, 0xa6bc5767, 0x3fb506dd, 0x48b2364b,
        0xd80d2bda, 0xaf0a1b4c, 0x36034af6, 0x41047a60,
        0xdf60efc3, 0xa867df55, 0x316e8eef, 0x4669be79,
        0xcb61b38c, 0xbc66831a, 0x256fd2a0, 0x5268e236,
        0xcc0c7795, 0xbb0b4703, 0x220216b9, 0x5505262f,
        0xc5ba3bbe, 0xb2bd0b28, 0x2bb45a92, 0x5cb36a04,
        0xc2d7ffa7, 0xb5d0cf31, 0x2cd99e8b, 0x5bdeae1d,
        0x9b64c2b0, 0xec63f226, 0x756aa39c, 0x026d930a,
        0x9c0906a9, 0xeb0e363f, 0x72076785, 0x05005713,
        0x95bf4a82, 0xe2b87a14, 0x7bb12bae, 0x0cb61b38,
        0x92d28e9b, 0xe5d5be0d, 0x7cdcefb7, 0x0bdbdf21,
        0x86d3d2d4, 0xf1d4e242, 0x68ddb3f8, 0x1fda836e,
        0x81be16cd, 0xf6b9265b, 0x6fb077e1, 0x18b74777,
        0x88085ae6, 0xff0f6a70, 0x66063bca, 0x11010b5c,
        0x8f659eff, 0xf862ae69, 0x616bffd3, 0x166ccf45,
        0xa00ae278, 0xd70dd2ee, 0x4e048354, 0x3903b3c2,
        0xa7672661, 0xd06016f7, 0x4969474d, 0x3e6e77db,
        0xaed16a4a, 0xd9d65adc, 0x40df0b66, 0x37d83bf0,
        0xa9bcae53, 0xdebb9ec5, 0x47b2cf7f, 0x30b5ffe9,
        0xbdbdf21c, 0xcabac28a, 0x53b39330, 0x24b4a3a6,
        0xbad03605, 0xcdd70693, 0x54de5729, 0x23d967bf,
        0xb3667a2e, 0xc4614ab8, 0x5d681b02, 0x2a6f2b94,
        0xb40bbe37, 0xc30c8ea1, 0x5a05df1b, 0x2d02ef8d
    };
    uint32_t    crc = 0xffffffff;
    
    while(size--) {
        crc = crctable[(*data ^ crc) & 0xff] ^ (crc >> 8);
        data++;
    }
    return(crc);
}



#undef HALO_RAND




void genkeys(u8 *text, u8 *hash1, u8 *hash2, u8 *skey1, u8 *skey2, u8 *dkey1, u8 *dkey2) {
    printf("- generate %s keys\n", text);
    halo_generate_keys(hash1, skey1, dkey1);
    halo_generate_keys(hash2, skey2, dkey2);
}


int decreypt(u8 *buff, int len, u8 *deckey, u8 *enckey, BOOL output) {
    gh_t    *gh;
    int     head;
    
    head = 0;
    gh   = (gh_t *)buff;
    
    if(ntohs(gh->sign) == 0xfefd) { /* info */
        if (output)
            show_dump(buff, len, stdout);
        return 0;
    }
    if(ntohs(gh->sign) == 0xfefe)
    {
        
        if(len <= 7)
        {
            if (output)
                show_dump(buff, len, stdout);
            
            return 0;
        }
        head = 7;
    }
    
    halo_tea_decrypt(buff + head, len - head, deckey);
    
    if(head) show_dump(buff, head, stdout);
    return haloreturnbits(buff + head, buff + head,len - head, output);
}

int impersoinateNumber = 0;
BOOL decshow(u8 *buff, int len, u8 *deckey, u8 *enckey, BOOL output, BOOL client, int tick)
{
    gh_t    *gh;
    int     head;
    
  
    
    head = 0;
    gh   = (gh_t *)buff;
    
    if (docopyme)
    {
        if (client && didReceive && tick > 1)
        {
            printf("\nSENDING DATA\n");
            
            //Modify the header information
            sendto(socketAddress,buff,len,0,(struct sockaddr *)&peeraddress,sizeof(peeraddress));
        }
    }

    if(ntohs(gh->sign) == 0xfefd) { /* info */
        
        if (output)
        {
            //show_dump(buff, len, stdout);
        }
        return YES;
    }
    if(ntohs(gh->sign) == 0xfefe)
    {
        
        if(len <= 7)
        {
            //printf("LENGTH!");
            if (output)
            {
                //show_dump(buff, len, stdout);
            }
            
            return NO;
        }
        head = 7;
    }
    
    halo_tea_decrypt(buff + head, len - head, deckey);
  


    
    if (filterTheNetwork)
    {
        u8 *data = malloc(10000);
        haloreturnbits(buff + head, data,len - head, output);
        
        
        
        if (client && data[0] == 0x1e)
        {
            //4e e8 01 18 20 09
            
            /*48 e8 01 20 08 09 02 08 02 08 02 08 02 08 02 08   H.. ............
             02 08 02 08 02 08 02 08 02 08 02 08 02 08 02 08   ................
             02 08 02 08 02 08 02 08 02 08 02 08 02 08 02 08   ................
             02 08 02 08 02 08 02 08 02 08 02 08 02 08 02 08   ................
             02 08 02 08 02 08 02 c8 5a 9f 9a 09               ........Z...
             
             --newbit--
             1e 00 82 90 20 80 20 80 20 80 20 80 20 80 20 80   .... . . . . . .
             20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80    . . . . . . . .
             20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80    . . . . . . . .
             20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80    . . . . . . . .
             20 80 20 80 20 80 ac f5                            . . ...*/
            
            
            
            /*--prebit--
             48 e8 01 20 08 09 02 08 02 08 02 08 02 08 02 08   H.. ............
             02 08 02 08 02 08 02 08 02 08 02 08 02 08 02 08   ................
             02 08 02 08 02 08 02 08 02 08 02 08 02 08 02 08   ................
             02 08 02 08 02 08 02 08 02 08 02 08 02 08 02 08   ................
             02 08 02 08 02 08 02 68 b2 3c 4c df               .......h.<L.
             
             --newbit--
             1e 00 82 90 20 80 20 80 20 80 20 80 20 80 20 80   .... . . . . . .
             20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80    . . . . . . . .
             20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80    . . . . . . . .
             20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80    . . . . . . . .
             20 80 20 80 20 80 26 cb                            . . .&.*/
            
            
            /*--prebit--
             68 e8 01 00 88 09 02 08 02 08 02 08 02 08 02 08   h...............
             02 08 02 08 02 08 02 08 02 08 02 08 02 08 02 08   ................
             02 08 02 08 02 08 02 08 02 08 02 08 02 08 02 08   ................
             02 08 02 08 02 08 02 08 02 08 02 08 02 08 02 08   ................
             02 08 02 08 02 08 02 08 02 08 02 08 02 08 02 08   ................
             02 08 02 08 02 08 02 08 02 08 02 08 02 08 02 08   ................
             02 08 02 08 02 08 02 78 bc f6 a0 da               .......x....*/
            
            /*--newbit--
             1e 00 80 98 20 80 20 80 20 80 20 80 20 80 20 80   .... . . . . . .
             20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80    . . . . . . . .
             20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80    . . . . . . . .
             20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80    . . . . . . . .
             20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80    . . . . . . . .
             20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80    . . . . . . . .
             20 80 20 80 20 80 c7 6b                            . . ..k*/
            
            
            //44 e8 01 08
            
            
            //Player 0 send chat
            /*4a e8 01 00 10 09 02 08 02 08 02 08 02 08 02 08   J...............
             02 08 02 08 02 08 02 08 02 08 02 08 02 08 02 08   ................
             02 08 02 08 02 08 02 08 02 08 02 08 02 08 02 08   ................
             02 08 02 08 02 08 02 08 02 08 02 08 02 08 02 08   ................
             02 08 02 08 02 08 02 08 02 88 0f f3 f8 03         ..............*/
            
            //Player 1 receive chat
            /*4c e8 01 08 18 09 02 08 02 08 02 08 02 08 02 08   L...............
             02 08 02 08 02 08 02 08 02 08 02 08 02 08 02 08   ................
             02 08 02 08 02 08 02 08 02 08 02 08 02 08 02 08   ................
             02 08 02 08 02 08 02 08 02 08 02 08 02 08 02 08   ................
             02 08 02 08 02 08 02 08 02 08 02 80 a6 9a 51 ad   ..............Q.*/
            
            
            //10
            
            
            //2a e8 01 00 90 48 03
            printf("\nSENDING DATA\n");
            show_dump(buff, len, stdout);
            (buff+head)[3] = (u8)impersoinateNumber;
            //(buff+head)[4] = 0xf0;
            
            
            uint32_t crc = halo_crc32(buff+head,len - head-4);
            void *datad = malloc(sizeof(uint32_t));
            memset(datad, crc, sizeof(uint32_t));
            
            //memset(buff+len*sizeof(u8)-sizeof(uint32_t), crc, sizeof(uint32_t));
            
            putxx(buff + sizeof(u8)*len - 4, crc, 32);
            
            //memcpy(buff+len-4, datad, 4);
            
            printf("\nNEW DATA\n");
            show_dump(buff, len, stdout);
        }

if (data[0] != 0xcd  && data[0] != 0x1b && data[0] != 0x2a && data[0] != 0x4d && data[0] != 0xe8  && data[0] != 0xb0  && (buff+head)[0] != 0x16 && (buff+head)[0] != 0x06&& (buff+head)[0] != 0x18 && (buff+head)[0] != 0x14&& (buff+head)[0] != 0x0a&& (buff+head)[0] != 0x0d)
{
if (client)
printf("\n    ### CLIENT ###\n");
else
printf("\n    ### SERVER ###\n");
    
    
    if(head) show_dump(buff, head, stdout);
    if (output)
    {
        printf("\n--prebit--\n");
        show_dump(buff+head, len - head, stdout);
        printf("\n--newbit--\n");
        halobits(buff + head, len - head, output);
        
    }
    
    
}

    }
    
    
    /*
    printf("\n--original--\n");
    show_dump(buff, head, stdout);
    
    printf("\n--streamed--\n");
    int newLen = haloreturnbits(buff + head, len - head, output);
    show_dump(buff, newLen, stdout);
    
    printf("\n--undone--\n");
    haloundobits(buff, newLen, output);
    
    */
    
    halo_tea_encrypt(buff + head, len - head, enckey);
}

int write_bstr(u8 *data, u32 len, u8 *buff, u32 bitslen) {
    int     i;
    
    for(i = 0; i < len; i++)
    {
        bitslen = write_bits(data[i], 8,  buff, bitslen);
    }
    /*for(     ; i < len; i++) {
        bitslen = write_bits(0,       8,  buff, bitslen);
    }*/
    return(bitslen);
}

int read_bstr(u8 *data, u32 len, u8 *buff, u32 bitslen) {
    int     i;
    
    for(i = 0; i < len; i++) {
        data[i] = read_bits(8, buff, bitslen);
        bitslen += 8;
    }
    return(bitslen);
}


int lettermapLength = 100;
char *lettermap00[] = {
    "A00","A01","A02","A03","A04","A05","A06","A07","A08","A09","A10","A11","A12","A13","A14","A15"," ","A17","A18","A19","A20","A21",",","A23","0","2","4","6","8","A29","A30","A31","A32","B", "D", "F", "H", "J", "L", "N", "P", "R", "T", "V", "X", "Z", "A46", "A47", "A48", "b", "d", "f","h","j","l","n","p","r","t","v","x","z","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0"
};
char *lettermap80[] = {
    "B00","B01","B02","B03","B04","B05","B06","B07","B08","B09","B10","B11","B12","B13","B14","B15","B16","B17","B18","B19","B20","B21","B22","B23","1","3","5","7","9","B29","B30","?","A","C", "E", "G", "I", "K", "M", "O", "Q", "S", "U", "W", "Y", "B45", "B46", "B47", "a", "c", "e", "g", "i", "k", "m", "o", "q", "s", "u", "w", "y", "B61", "B62","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0"
};

u8 indexforLetter(char l)
{
    u8 g;
    for (g=0; g < lettermapLength; g++)
    {
        
        int slen = strlen(lettermap00[g]);
        int mlen = strlen(lettermap80[g]);
        
        //if (slen == 1 || mlen == 1)
            //printf("\n %d %s %s %d %d", g, lettermap00[g], lettermap80[g], slen, mlen);
        
        if (slen == 1 && lettermap00[g][0] == l)
        {
            return g;
        } 
        else if (mlen == 1 && lettermap80[g][0] == l)
        {
            return g;
        }
    }
    return -1;
}

u8 typeforLetter(char l)
{
    u8 g;
    for (g=0; g < lettermapLength; g++)
    {
        int slen = strlen(lettermap00[g]);
        int mlen = strlen(lettermap80[g]);
        
        if (slen == 1 && lettermap00[g][0] == l)
        {
            return 0x00;
        }
        else if (mlen == 1 && lettermap80[g][0]
                 == l)
        {
            return 0x80;
        }
    }
    return -1;
}

int haloreturnbits(u8 *buff,u8 *retbuff, int buffsz, BOOL output) {
    int     b,
    n,
    o;
    u8      str[1 << 11];
    
    int offset = 0;
    
    buffsz -= 4;    // crc;
    if(buffsz <= 0) return -1;
    buffsz <<= 3;
    
    for(b = 0;;) {
        if((b + 11) > buffsz) break;
        n = read_bits(11, buff, b);     b += 11;
        
        if((b + 1) > buffsz) break;
        o = read_bits(1,  buff, b);     b += 1;
        
        if((b + n) > buffsz) break;
        b = read_bstr(str, n, buff, b);
        
        memcpy(retbuff+offset, str, n);
        offset+=n;
    }
    return offset;
}



void haloundobits(u8 *buff,int buffsz, BOOL output) {
    int     b,
    n,
    o;
    u8      str[1 << 11];
    
    buffsz -= 4;    // crc;
    
    if(buffsz <= 0) return;
    buffsz <<= 3;
    
    
    for(b = 0;;)
    {
        if((b + 11) > buffsz) break;
        n = read_bits(11, buff, b);     b += 11;
        
        if((b + 1) > buffsz) break;
        o = read_bits(1,  buff, b);     b += 1;
        
        if((b + n) > buffsz) break;
        b = read_bstr(str, n, buff, b);
        
        show_dump(str, n, stdout);
    }
    
    
}



void halobits(u8 *buff,int buffsz, BOOL output) {
    int     b,
    n,
    o;
    u8      str[1 << 11];
    
    buffsz -= 4;    // crc;

    if(buffsz <= 0) return;
    buffsz <<= 3;
    
    
    for(b = 0;;)
    {
        if((b + 11) > buffsz) break;
        n = read_bits(11, buff, b);     b += 11;
        
        if((b + 1) > buffsz) break;
        o = read_bits(1,  buff, b);     b += 1;
        
        if((b + n) > buffsz) break;
        b = read_bstr(str, n, buff, b);
        
        show_dump(str, n, stdout);
        
        
        if (n > 5 && str[0] == 0x1e)
        {
            //printf("%d\n", n);
            
            //return;
            
            
            //show_dump(str, n, stdout);
            
            
            
        }
    }
}

void halobieeets(u8 *buff, int buffsz, BOOL output) {
    int     b,
    n,
    o;
    u8      str[1 << 11];
    

    buffsz -= 4;    // crc;
    if(buffsz <= 0) return;
    buffsz <<= 3;
    
    for(b = 0;;) {
        if((b + 11) > buffsz) break;
        n = read_bits(11, buff, b);     b += 11;
        
        if((b + 1) > buffsz) break;
        o = read_bits(1,  buff, b);     b += 1;
        
        if((b + n) > buffsz) break;
        b = read_bstr(str, n, buff, b);
        
        show_dump(str, n, stdout);
        
        if (output)
        {
            
            //printf("%d\n", str[7]);
            
        }
        
        
    }
}



u32 resolv(char *host) {
    struct  hostent *hp;
    u32     host_ip;
    
    host_ip = inet_addr(host);
    if(host_ip == INADDR_NONE) {
        hp = gethostbyname(host);
        if(!hp) {
            printf("\nError: Unable to resolv hostname (%s)\n", host);
            exit(1);
        } else host_ip = *(u32 *)(hp->h_addr);
    }
    return(host_ip);
}

int send_recv(int sd, u8 *in, int insz, u8 *out, int outsz, struct sockaddr_in *peer, int err) {
    int     retry = 2,
    len;
    
    if(in) {
        while(retry--) {
            //fputc('.', stdout);
            if(sendto(sd, in, insz, 0, (struct sockaddr *)peer, sizeof(struct sockaddr_in))
               < 0) goto quit;
            if(!out) return(0);
            if(!timeout(sd, 2)) break;
        }
    } else {
        if(timeout(sd, 3) < 0) retry = -1;
    }
    
    if(retry < 0) {
        if(!err) return(-1);
        printf("\nError: socket timeout, no reply received\n\n");
        return -1;
    }
    
    //fputc('.', stdout);
    len = recvfrom(sd, out, outsz, 0, NULL, NULL);
    if(len < 0) goto quit;
    return(len);
quit:
    if(err) std_err();
    return(-1);
}

typedef struct {
    u8  cdkey[64];
    u8  hash[16];
} dbkey_t;

dbkey_t *dbkey  = NULL;
int     dbkey_idx;

#define WAITSEC     15
#define DBKEYMAX    64
u8 *message_data;

BOOL receivingMessage;
char *gskeychallprehash(char *cdkey, char *stoken, int ctoken) {
    static char     chall[73];
    char            *tmp;
    unsigned char   md5h[16],
    *ptr;
    const char      *hex = "0123456789abcdef";
    md5_context     md5t;
    int             i,
    tmplen;
    
#define DOMD5(x,y) \
md5_starts(&md5t); \
md5_update(&md5t, x, y); \
md5_finish(&md5t, md5h);
    
    
    if(!ctoken)
    {
        //srand(time(NULL));
        ctoken = (arc4random() << 16) ^ arc4random();
    }
    ctoken = abs(ctoken);   // needed, positive integer
    
    /* 1) CDKEY HASH */
    md5_starts(&md5t);
    memcpy(&md5t, cdkey, strlen(cdkey));
    md5_finish(&md5t, md5h);
    
    for(ptr = chall, i = 0; i < 16; i++) {
        *ptr++ = hex[md5h[i] >> 4];
        *ptr++ = hex[md5h[i] & 0xf];
    }
    
    /* 2) CLIENT TOKEN */
    sprintf(
            ptr,
            "%.8x",
            ctoken);
    
    printf("\nCLIENT TOKEN %s\n", ptr);
    
    /* 3) THIRD STRING */
    tmplen = strlen(cdkey) + 5 + strlen(stoken);
    tmp = alloca(tmplen + 1);   // auto-free
    if(!tmp) return("");
    
    i = sprintf(
                tmp,
                "%s%d%s",
                cdkey,
                ctoken % 0xffff,
                stoken);
    DOMD5(tmp, i);
    for(ptr += 8, i = 0; i < 16; i++) {
        *ptr++ = hex[md5h[i] >> 4];
        *ptr++ = hex[md5h[i] & 0xf];
    }
    
    *ptr = 0;
    return(chall);
}


char *gskeychall(char *cdkey, char *stoken, int ctoken) {
    static char     chall[73];
    char            *tmp;
    unsigned char   md5h[16],
    *ptr;
    const char      *hex = "0123456789abcdef";
    md5_context     md5t;
    int             i,
    tmplen;
    
#define DOMD5(x,y) \
md5_starts(&md5t); \
md5_update(&md5t, x, y); \
md5_finish(&md5t, md5h);
    
    
    if(!ctoken)
    {
        //srand(time(NULL));
        ctoken = (arc4random() << 16) ^ arc4random();
    }
    ctoken = abs(ctoken);   // needed, positive integer
    
    /* 1) CDKEY HASH */
    DOMD5(cdkey, strlen(cdkey));
    for(ptr = chall, i = 0; i < 16; i++) {
        *ptr++ = hex[md5h[i] >> 4];
        *ptr++ = hex[md5h[i] & 0xf];
    }
    
    /* 2) CLIENT TOKEN */
    sprintf(
            ptr,
            "%.8x",
            ctoken);
    
    printf("\nCLIENT TOKEN %s\n", ptr);
    
    /* 3) THIRD STRING */
    tmplen = strlen(cdkey) + 5 + strlen(stoken);
    tmp = alloca(tmplen + 1);   // auto-free
    if(!tmp) return("");
    
    i = sprintf(
                tmp,
                "%s%d%s",
                cdkey,
                ctoken % 0xffff,
                stoken);
    DOMD5(tmp, i);
    for(ptr += 8, i = 0; i < 16; i++) {
        *ptr++ = hex[md5h[i] >> 4];
        *ptr++ = hex[md5h[i] & 0xf];
    }
    
    *ptr = 0;
    return(chall);
}


int firstBot;

BOOL isTurn[20];
BOOL isWalking[20];
BOOL isShooting[20];
BOOL isCrouched[20];
BOOL isRotating[20];
BOOL isChangingPacket[20];
void receivedData(u8 *recvline, int n, u8 enckey1[16], u8 deckey1[16], int sd2, struct sockaddr_in peer2, int packet_nom, int secondpktnum, int player_number)
{
    
    //printf("\n- #### SERVER ##### \n");
    
    gh_t    *gh;
    int     head;
    
    head = 0;
    gh   = (gh_t *)recvline;
    
    BOOL isMessage = YES;
    if(ntohs(gh->sign) == 0xfefd)
    { /* info */
        isMessage = NO;
    }
    
    //printf("\nServer\n");
    //show_dump(recvline, n, stdout);
    
    if(ntohs(gh->sign) == 0xfefe)
    {
        if(n <= 7)
        {
            //UPDATE MESSAGE?
            if (gh->type == 0x64)
            {
                //Update packet number
                u8 secondPacketNo = recvline[3];
                u8 firstPacketNo = recvline[4];
                
                //printf("\nReceived server packet id %02x %02x \n", firstPacketNo, secondPacketNo);
                //show_dump(recvline, n, stdout);
                
                //if (firstPacketNo == 00 && secondPacketNo < 200)
                //    return;
                
                //Only if we JUST updated the packet
                
                if (isChangingPacket[player_number])
                {
                    if (firstPacketNo == 0)
                    {
                        firstPacketNo=0xff;
                        secondPacketNo--;
                    }
                    else
                    {
                        firstPacketNo--;
                    }
                }
                
                
                packet_no[player_number] = firstPacketNo;
                second_packet_no[player_number] = secondPacketNo;
                
                return;
            }
            else
            {
                ////0d a8 0e 00 00 00 00 80 00 01 00 00 00
                //06 88 0e 88 0e a0
                
                //0d a8 0e 00 00 00 00 80 80 01 00 00 00
                //06 88 0e 88 0e 48
                
                //0d a8 0e 00 00 00 00 80 80 00 00 00 00
                //06 88 0e 88 0e 60
                
                //0d a8 0e 00 00 00 00 80 80 00 00 00 00
                //06 88 0e 88 0e b0
                
                //0d a8 0e 00 00 00 00 80 80 00 00 00 00
                //06 88 0e 88 0e 08
                
                
                //sprintf(a,"08 88 0e 88 0e 88 0e 48", second_packet_no[my_player], packet_no[my_player]); //<<------- or this?
                //sendData(a, enckey1, deckey1, sd2, peer2, packet_no[my_player], second_packet_no[my_player], my_player);
                return;
            }
            
            isMessage = NO;
        }
        head = 7;
        
        
        
        halo_tea_decrypt(recvline+head,  n-head, deckey1);
        
        

        //printf("\n %02x", recvline[8]);
        //show_dump(recvline, head, stdout);
        //halobits(recvline+head, n-head, stdout);
        
    }
    else if(ntohs(gh->sign) == 0x0da8||ntohs(gh->sign) == 0x14d8)
    {
        //printf("\Sending ping\n");
        //show_dump(recvline, n, stdout);
        
        char *a = malloc(1000);
        
        if (ntohs(gh->sign) == 0x14d8)
            sprintf(a,"06 88 0e 88 0e 90", second_packet_no[player_number], packet_no[player_number]); //<<------- or this?
        else
            sprintf(a,"06 88 0e 88 0e 08", second_packet_no[player_number], packet_no[player_number]); //<<------- or this?
        
        
        sendData(a, enckey1, deckey1, sd2, peer2, packet_no[player_number], second_packet_no[player_number], player_number);
    }
    else
    {
        halo_tea_decrypt(recvline, n, deckey1);

        
        //printf("\nRECEIVECD\n");
        //show_dump(recvline, n, stdout);
    }

    
    /* sprintf(a,"0a c0 08 10 20 60 e8 1f 1a 70"); //<<------- or this?
     sendData(a, enckey1, deckey1, sd2, peer2, packet_no[my_player], second_packet_no[my_player], my_player);
     
     */
    
    if (isMessage)
    {
        
        halo_tea_decrypt(recvline + head, n - head, deckey1);
        
        if (player_number != 0)
            return;
        
       
        memset(message_data, 0, 10000);
        int lenn = haloreturnbits(recvline + head, message_data,n - head, YES);
        if (message_data[0] == 0x1e)
        {
            
            return;
            
            //fe fe 00 00 0f 01 62
            //08 d8 0c 40 38 01 20 e7
            
            //cd 00 04 14 00 76 5a 1d
            
            //08 d8 0c 40 40 01 60 a7
            //cd 00 84 13 00 72 3e 73
            
            
            //fe fe 00 01 63 00 10
            
            //05 b8 01 f0 7d
            //1b 00 df c7 7e
            
            //printf("\Received data\n");
            //show_dump(message_data, lenn, stdout);
            
            //show_dump(recvline+head, lenn - head, stdout);
            
            //printf("\nmessage\n");
            
            
            
            int start = 3;
            int i;
            char *finalString = malloc(200);
            int offset = 0;
            for (i=4; i < lenn-2; i+=2)
            {
                u8 letter = message_data[i];
                u8 shift = message_data[start];
                
                if (letter > lettermapLength)
                    continue;
                
                char *string = nil;
                BOOL hasString = NO;
                if (shift == 0x80||shift == 0x81 ||shift == 0x82 ||shift == 0x83 ||shift == 0x84 ||shift == 0x85 ||shift == 0x86 ||shift == 0x87 ||shift == 0x88 ||shift == 0x89||shift == 0x8a||shift == 0x8b||shift == 0x8c||shift == 0x8d||shift == 0x8e||shift == 0x8f)
                {
                    string=lettermap80[letter];
                    hasString = YES;
                }
                else if (shift == 0x00||shift == 0x01 ||shift == 0x02 ||shift == 0x03 ||shift == 0x04 ||shift == 0x05 ||shift == 0x06 ||shift == 0x07 ||shift == 0x08 ||shift == 0x09||shift == 0x0a||shift == 0x0b||shift == 0x0c||shift == 0x0d||shift == 0x0e||shift == 0x0f)
                {
                    string=lettermap00[letter];
                    hasString = YES;
                }
                
                start+=2;
                shift = message_data[start];
                
                //dmprintf("%d %d\n", letter, shift);
                //if (string)
                
                if (string)
                {
                    memcpy(finalString+offset, string, strlen(string));
                    offset+=strlen(string);
                }
            
                printf("%s", string);
            }
             /*
            //packet_no, secondpktnum
            char *a = malloc(1000);
            
            sprintf(a, "fe fe 00 01 %x 00 %x", packet_no, secondpktnum);
            sendNormalPacket(a, "1e 80 80 90 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 00", enckey1, deckey1, sd2, peer2, packet_no, secondpktnum);
            
            sprintf(a, "fe fe 00 01 %x 00 %x", packet_no+1, secondpktnum);
            sendNormalPacket(a, "1b 00 80", enckey1, deckey1, sd2, peer2, packet_no, secondpktnum);
            */
            
            
                if (strcmp(finalString, "wolf, shoot") == 0)
                {
                    printf("SHOOT\n");
                    int a;
                    for (a=0; a < 20; a++)
                    {
                        isShooting[a] = YES;
                    }
                }
                if (strcmp(finalString, "wolf, stop")  == 0)
                {
                    printf("STOP\n");
                    int a;
                    for (a=0; a < 20; a++)
                    {
                        isShooting[a] = NO;
                    }
                }
                if (strcmp(finalString, "wolf, move") == 0)
                {
                    printf("WALK\n");
                    int a;
                    for (a=0; a < 20; a++)
                    {
                        isWalking[a] = YES;
                    }
                }
                if (strcmp(finalString, "wolf, seek") == 0)
                {
                    printf("SEEK\n");
                    int a;
                    for (a=0; a < 20; a++)
                    {
                        isRotating[a] = YES;
                    }
                }
            
                if (strcmp(finalString, "wolf, idle")  == 0)
                {
                    printf("IDLE\n");
                    int a;
                    for (a=0; a < 20; a++)
                    {
                        isWalking[a] = NO;
                    }
                }
                if (strcmp(finalString, "wolf, crouch")  == 0)
                {
                    printf("CROUCH\n");
                    int a;
                    for (a=0; a < 20; a++)
                    {
                        isCrouched[a] = YES;
                    }
                }
                if (strcmp(finalString, "wolf, stand")  == 0)
                {
                    printf("STAND\n");
                    int a;
                    for (a=0; a < 20; a++)
                    {
                        isCrouched[a] = NO;
                    }
                }
            
            
            //sprintf(a, "fe fe 00 01 %x 00 %x", packet_no+1, secondpktnum);
            //sendNormalPacket(a, "1b 00 80", enckey1, deckey1, sd2, peer2, packet_no, secondpktnum);
            
          
        }
        
        //halo_tea_encrypt(rev + head, len - head, enckey);
        
       
    }

}


void sendData(char *s, u8 enckey1[16], u8 deckey1[16], int sd2, struct sockaddr_in peer2,  int packet_no, int secondpktnum, int player_number)
{
    unsigned char *bb;
    int length;
    u8      *buff,*p,    *psdk;
    uint32_t crc;
    u8 sendline[1000];
    u8 recvline[1000];
    buff    = malloc(1000);
    
    
    //Send the next packet
    bb = convert(s, &length);
    p = buff;
    memcpy(buff, bb, length);
    p+=length;
    
    if (!muteOutput)
        printf("\n- sending\n");
    
    
    
    crc = halo_crc32(buff, p - buff);
    p += putxx(p, crc, 32);
    
    //printf("\n- sending %d\n", p - psdk);
    //show_dump(buff, p - buff, stdout);
    
    //printf("\n- sending data %d\n", p - buff);
    //show_dump(buff, 7, stdout);
    
    
    
    //printf("\n- encrypting\n");
    halo_tea_encrypt(buff, p - buff, enckey1);
    sendto(sd2,buff,p - buff,0,(struct sockaddr *)&peer2,sizeof(peer2));
    
    if (!muteOutput)
    show_dump(buff, p - buff, stdout);
    
    sendto(sd2,buff,p - buff,0,(struct sockaddr *)&peer2,sizeof(peer2));
    
    int n;
    
    n=recvfrom(sd2,recvline,1000,0,NULL,NULL);
    
    if (!muteOutput)
        printf("\n- received \n");
    
    //printf("\n- sending data %d\n", p - buff);
    receivedData(recvline, n, deckey1, enckey1, sd2, peer2, packet_no, secondpktnum, player_number);
    
    
    
}

void sendPing(char *s, u8 enckey1[16], u8 deckey1[16], int sd2, struct sockaddr_in peer2,  int packet_no, int secondpktnum, int player_number)
{
    unsigned char *bb;
    int length;
    u8      *buff,*p,    *psdk;
    uint32_t crc;
    u8 sendline[1000];
    u8 recvline[1000];
    buff    = malloc(1000);
    

    //Send the next packet
    bb = convert(s, &length);
    p = buff;
    memcpy(buff, bb, length);
    p+=length;

    if (!muteOutput)
    printf("\n- sending\n");

    //printf("\n- sending ping %d\n", p - buff);
    //show_dump(buff, 7, stdout);

    
    //show_dump(buff, p - buff, stdout);
    
    sendto(sd2,buff,p - buff,0,(struct sockaddr *)&peer2,sizeof(peer2));
    
    int n;
    n=recvfrom(sd2,recvline,1000,0,NULL,NULL);
    
    if (!muteOutput)
    printf("\n- received \n");
    
    
    //printf("\n- sending ping %d\n", p - buff);
    receivedData(recvline, n, deckey1, enckey1, sd2, peer2, packet_no, secondpktnum, player_number);
    
    
    
}


void sendNormalPacket2(char *s1,char *s, u8 newleength, u8 enckey1[16], u8 deckey1[16], int sd2, struct sockaddr_in peer2, int packet_no, int secondpktnum, int player_number, u8 *buff)
{
    unsigned char *bb;
    int length;
    u8      *p,    *psdk;
    uint32_t crc;
    u8 sendline[1000];
    u8 recvline[1000];
    
    
    
    u8 b;
    
    //Send the next packet
    bb = convert(s1, &length);
    
    p = buff;
    psdk = buff+7;
    memcpy(buff, bb, length);
    
    
    bb = s;
    
    b = 0;
    b = write_bits(newleength, 11, psdk, b);
    b = write_bits(1, 1, psdk, b); // this part is not important, it's only needed to send a total of 4 bytes
    b = write_bstr(bb, newleength*4, psdk, b); // this part is not important, it's only needed to send a total of 4 bytes
    
    //memcpy(buff, bb, length);
    p+=(newleength)+7;
    
    
    crc = halo_crc32(psdk, p - psdk);
    p += putxx(p, crc, 32);
    
    //printf("\n- sending normal %d\n", p - psdk);
    //show_dump(buff, 7, stdout);
    //halobits(psdk, p - psdk, YES);
    
    //printf("\n- encrypting\n");
    halo_tea_encrypt(psdk, p - psdk, enckey1);
    
    //show_dump(buff, p - buff, stdout);
    sendto(sd2,buff,p - buff,0,(struct sockaddr *)&peer2,sizeof(peer2));
    
    int n;
    n=recvfrom(sd2,recvline,10000,0,NULL,NULL);
    
    //printf("\n- received \n");
    
    //decshow(recvline, n, deckey1, enckey1, YES);
    
    //printf("\n- sending normal %d\n", p - buff);
    receivedData(recvline, n, deckey1, enckey1, sd2, peer2, packet_no, secondpktnum, player_number);
}


void sendNormalPacket(char *s1,char *s, u8 enckey1[16], u8 deckey1[16], int sd2, struct sockaddr_in peer2, int packet_no, int secondpktnum, int player_number, u8 *buff)
{
    unsigned char *bb;
    int length;
    u8      *p,    *psdk;
    uint32_t crc;
    u8 sendline[1000];
    u8 recvline[1000];
    
    
    
    u8 b;
    
    //Send the next packet
    bb = convert(s1, &length);
    
    p = buff;
    psdk = buff+7;
    memcpy(buff, bb, length);
    
    
    bb = convert(s, &length);
    b = 0;
    b = write_bits(length, 11, psdk, b);
    b = write_bits(1, 1, psdk, b); // this part is not important, it's only needed to send a total of 4 bytes
    b = write_bstr(bb, length*4, psdk, b); // this part is not important, it's only needed to send a total of 4 bytes
    
    //memcpy(buff, bb, length);
    p+=(length)+7;
    
    
    crc = halo_crc32(psdk, p - psdk);
    p += putxx(p, crc, 32);

    //printf("\n- sending normal %d\n", p - psdk);
    //show_dump(buff, 7, stdout);
    //halobits(psdk, p - psdk, YES);
  
    //printf("\n- encrypting\n");
    halo_tea_encrypt(psdk, p - psdk, enckey1);
    
    //show_dump(buff, p - buff, stdout);
    sendto(sd2,buff,p - buff,0,(struct sockaddr *)&peer2,sizeof(peer2));
    
    int n;
    n=recvfrom(sd2,recvline,10000,0,NULL,NULL);
    
    //printf("\n- received \n");
    
    //decshow(recvline, n, deckey1, enckey1, YES);
    
    //printf("\n- sending normal %d\n", p - buff);
    receivedData(recvline, n, deckey1, enckey1, sd2, peer2, packet_no, secondpktnum, player_number);
}


void sendPacket(char *s, u8 enckey1[16], u8 deckey1[16], int sd2, struct sockaddr_in peer2, int packet_no, int secondpktnum, int player_number)
{
    unsigned char *bb;
    int length;
    u8      *buff,*p,    *psdk;
    uint32_t crc;
    u8 sendline[1000];
    u8 recvline[1000];
    buff    = malloc(BUFFSZ);
    
    psdk = buff+7;
    //Send the next packet
    bb = convert(s, &length);
    p = buff;
    memcpy(buff, bb, length);
    p+=length;
    
    crc = halo_crc32(psdk, p - psdk);
    p += putxx(p, crc, 32);
    
    
    //printf("\n- sending packet %d\n", p - psdk);
    //show_dump(buff, 7, stdout);
    //halobits(psdk, p - psdk, YES);
    
    
    if (!muteOutput)
    printf("\n- sending\n");

    if (!muteOutput)
    show_dump(buff, p - buff, stdout);
    
    halo_tea_encrypt(psdk, p - psdk, enckey1);
    sendto(sd2,buff,p - buff,0,(struct sockaddr *)&peer2,sizeof(peer2));
    
    int n;
    n=recvfrom(sd2,recvline,10000,0,NULL,NULL);
    
    if (!muteOutput)
        printf("\n- received \n");
    
    //printf("\n- sending packet %d\n", p - buff);
    receivedData(recvline, n, deckey1, enckey1, sd2, peer2, packet_no, secondpktnum, player_number);
}

int filterTheNetwork;
-(IBAction)connectToServer:(id)sender
{
    [self initialiseMemorycode];
    [self performSelectorInBackground:@selector(connectBackground:) withObject:nil];
}

- (char *)randomSerialKey
{
	uint8_t key[10];
	char ascii[20];
	generate_key(key);
	fix_key(key);
	print_key(ascii, key);
	
	return ascii;
}





OSStatus AcquireTaskportRight() {
    
    OSStatus stat = noErr;
    AuthorizationItem taskport_item[] = {
        {"system.privilege.taskport"},0,0,0
    };
    AuthorizationRights rights = {1, taskport_item}, *out_rights = NULL;
    AuthorizationRef authRef;
    AuthorizationFlags auth_flags =  kAuthorizationFlagExtendRights | kAuthorizationFlagPreAuthorize | kAuthorizationFlagInteractionAllowed | ( 1 << 5);
    
    stat = AuthorizationCreate (NULL, kAuthorizationEmptyEnvironment, auth_flags, &authRef);
    
    if (stat == errAuthorizationSuccess) {
        stat = AuthorizationCopyRights ( authRef,  &rights,  kAuthorizationEmptyEnvironment, auth_flags, &out_rights);
    }
    
    if (stat == errAuthorizationSuccess) {
        NSLog(@"system.privilege.taskport acquired");
    }
    else {
        NSLog(@"Failed to acquire system.privilege.taskport right. Error: %d", (int)stat);
    }
    
    return stat;
}



/*
int acquireTaskportRight()
{
    OSStatus stat;
    AuthorizationItem taskport_item[] = {{"system.privilege.taskport:"}};
    AuthorizationRights rights = {1, taskport_item}, *out_rights = NULL;
    AuthorizationRef author;
    int retval = 0;
    
    AuthorizationFlags auth_flags = kAuthorizationFlagExtendRights | kAuthorizationFlagPreAuthorize | kAuthorizationFlagInteractionAllowed | ( 1 << 5);
    
    stat = AuthorizationCreate (NULL, kAuthorizationEmptyEnvironment,auth_flags,&amp;amp;author);
    if (stat != errAuthorizationSuccess)
    {
        return 0;
    }
    
    stat = AuthorizationCopyRights ( author, &amp;amp;rights, kAuthorizationEmptyEnvironment, auth_flags,&amp;amp;out_rights);
    if (stat != errAuthorizationSuccess)
    {
        printf("fail");
        return 1;
    }
    return 0;
}
 */


//Memory code for synching with Halo MD. You need to codesign for this.
static __inline__ vm_map_t _VMTaskFromPID( pid_t process )
{
	vm_map_t task;
	
	if ( task_for_pid( current_task(), process, &task ) == KERN_SUCCESS ) {
		return task;
	}
	return 0;
}

#define NATIVE_ENDIAN_BYTE_ORDER 0
#define BIG_ENDIAN_BYTE_ORDER    1
#define LITTLE_ENDIAN_BYTE_ORDER 2

static void InitializeByteOrder(int *byteOrder)
{
	if (*byteOrder == NATIVE_ENDIAN_BYTE_ORDER)
	{
		*byteOrder = (CFByteOrderGetCurrent() == CFByteOrderBigEndian) ? (BIG_ENDIAN_BYTE_ORDER) : (LITTLE_ENDIAN_BYTE_ORDER);
	}
}

+ (NSNumber *)readUnsignedInt16AtProcess:(pid_t)process
                           memoryAddress:(mach_vm_address_t)address
							   byteOrder:(int)byteOrder
{
	UInt16 unsignedInt16;
	mach_vm_size_t size = sizeof(UInt16);
	
	if (VMReadBytes(process, address, &unsignedInt16, &size))
	{
		InitializeByteOrder(&byteOrder);
		
		if (byteOrder == BIG_ENDIAN_BYTE_ORDER)
		{
			unsignedInt16 = CFSwapInt16BigToHost(unsignedInt16);
		}
		else if (byteOrder == LITTLE_ENDIAN_BYTE_ORDER)
		{
			unsignedInt16 = CFSwapInt16LittleToHost(unsignedInt16);
		}
		return [NSNumber numberWithUnsignedShort:unsignedInt16];
	}
    
	return nil;
}

+ (NSNumber *)readFloatAtProcess:(pid_t)process
                   memoryAddress:(mach_vm_address_t)address
					   byteOrder:(int)byteOrder
{
	float floatValue;
	mach_vm_size_t size = sizeof(float);
	
	if (VMReadBytes(process, address, &floatValue, &size))
	{
		InitializeByteOrder(&byteOrder);
		
		if (byteOrder == BIG_ENDIAN_BYTE_ORDER)
		{
			int newValue = CFSwapInt32BigToHost(*((int *)&floatValue));
			floatValue = *((float *)&newValue);
		}
		else if (byteOrder == LITTLE_ENDIAN_BYTE_ORDER)
		{
			int newValue = CFSwapInt32LittleToHost(*((int *)&floatValue));
			floatValue = *((float *)&newValue);
		}
		return [NSNumber numberWithFloat:floatValue];
	}
	
	return nil;
}

NSData *VMReadData( pid_t process, mach_vm_address_t address, mach_vm_size_t size )
{
	vm_map_t task = _VMTaskFromPID( process );
	kern_return_t result;
	
	void *buffer;
	mach_vm_size_t actualSize;
	
	// create a local block to hold the incoming data
	buffer = (void *)malloc( (size_t)size );
	if ( !buffer ) {
		// no buffer, abort
		return nil;
	}
	
	// perform the read
	result = mach_vm_read_overwrite( task, address, size, (mach_vm_address_t)buffer, &actualSize );
	if ( result != KERN_SUCCESS ) {
		// read error, abort
		free( buffer );
		return nil;
	}
	
	// everything seems to be peachy, so return the data
	return [[[NSData alloc] initWithBytesNoCopy:buffer length:actualSize freeWhenDone:YES] autorelease];
}

BOOL VMReadBytes( pid_t process, mach_vm_address_t address, void *bytes, mach_vm_size_t *size )
{
	vm_map_t task = _VMTaskFromPID( process );
	kern_return_t result;
	mach_vm_size_t staticsize = *size;
	
	// perform the read
	result = mach_vm_read_overwrite( task, address, staticsize, (mach_vm_address_t)bytes, size );
	if ( result != KERN_SUCCESS ) {
		return NO;
	}
	
	return YES;
}



typedef mach_vm_address_t ZGMemoryAddress;
typedef mach_vm_size_t ZGMemorySize;
typedef vm_prot_t ZGMemoryProtection;
typedef vm_map_t ZGMemoryMap;


void ZGFreeBytes(ZGMemoryMap processTask, const void *bytes, ZGMemorySize size)
{
	mach_vm_deallocate(current_task(), (vm_offset_t)bytes, size);
}

bool CSReadBytes(ZGMemoryMap processTask, ZGMemoryAddress address, void **bytes, ZGMemorySize size)
{
	ZGMemorySize originalSize = size;
	vm_offset_t dataPointer = 0;
	mach_msg_type_number_t dataSize = 0;
	bool success = false;
	if (mach_vm_read(processTask, address, originalSize, &dataPointer, &dataSize) == KERN_SUCCESS)
	{
		success = true;
		*bytes = (void *)dataPointer;
		size = dataSize;
	}
	
	return success;
}

short readShort(ZGMemoryMap processTask, ZGMemoryAddress address)
{
    void *bytes = NULL;
    if (CSReadBytes(processTask, address, &bytes, 2))
    {
        ZGMemoryAddress returnAddress = 0;
        memcpy(&returnAddress, bytes, 2);
        ZGFreeBytes(processTask, bytes, 2);
        
        return (short)returnAddress;
    }
    return -2;
}

float readFloat(ZGMemoryMap processTask, ZGMemoryAddress address)
{
    void *bytes = NULL;
    if (CSReadBytes(processTask, address, &bytes, 4))
    {
        float returnAddress;
        memcpy(&returnAddress, bytes, 4);
        ZGFreeBytes(processTask, bytes, 4);
        
        return (float)returnAddress;
    }
    return -2;
}

int readInt(ZGMemoryMap processTask, ZGMemoryAddress address)
{
    void *bytes = NULL;
    if (CSReadBytes(processTask, address, &bytes, 4))
    {
        ZGMemoryAddress returnAddress = 0;
        memcpy(&returnAddress, bytes, 4);
        ZGFreeBytes(processTask, bytes, 4);
        
        return (int)returnAddress;
    }
    return -2;
}

-(void)initialiseMemorycode
{
    
    NSArray *applications = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.null.halominidemo"];
    
    if (AcquireTaskportRight() != 0)
    {
        printf("acquireTaskportRight() failed!\n");
        exit(0);
    }
    
    int pid = [[applications objectAtIndex:0] processIdentifier];
    NSLog(@"Halo PID: %d", pid);
    
    kern_return_t result = task_for_pid(current_task(), pid, &halo);
    if (result != KERN_SUCCESS || !MACH_PORT_VALID(halo))
    {
        NSLog(@"TASK FAILED");
    }
}

short object_id_for_player(short player_number)
{
    return readShort(halo, 0x402AAFFC+0x200*player_number);
}
int pointerToObject(short number)
{
    long address = 0x400506E8 + number * 12 + 0x8;
    return readInt(halo, address);
}
float distanceToObjectH(short from, short to)
{
    int frompt = pointerToObject(from);
    int topt = pointerToObject(to);
    
    float x1 = x_coordinate(frompt);
    float y1 = y_coordinate(frompt);
    float z1 = z_coordinate(frompt);
    
    float x2 = x_coordinate(topt);
    float y2 = y_coordinate(topt);
    float z2 = z_coordinate(topt);
    
    return sqrtf(powf(x1-x2, 2)+powf(y1-y2, 2)+powf(z1-z2, 2));
}
float x_coordinate(int pointerToObject)
{
    return readFloat(halo, pointerToObject+0x5c);
}
float y_coordinate(int pointerToObject)
{
    return readFloat(halo, pointerToObject+0x5c+4);
}
float z_coordinate(int pointerToObject)
{
    return readFloat(halo, pointerToObject+0x5c+8);
}


u8 packet_no[20];
u8 second_packet_no[20];

  bool muteOutput = YES;
int port_number = 2800;
int pNo = 0;
int wolfNo = 0;

static short Encode(double value)
{
    int cnt = 0;
    while (value != floor(value)) {
        value *= 10.0;
        cnt++;
    }
    return (short)((cnt << 12) + (int)value);
}


int playernumberinitial=0;;
-(void)connectBackground:(id)obj
{
    BOOL showServer=YES;
    BOOL useArchon = ![doHost state];
    
    int sd2, sd1;
    struct  sockaddr_in peer1,
    peer2;

    u8 enckey1[16];
    u8 deckey2[16];
    u8 deckey1[16];
    
    //NSRunAlertPanel(@"This button is just a placeholder at the moment.", @"Sorry about that.", @"Okay :(", nil, nil);
    //002C <block> 0000 4011 <block> 0A00 010F 1857 9B23 08FF 08FE 0018 <block> 0000 <counter>00 <block> <block> <block> <block> <block>
    
    enum glog_type
    {
        kGameEnd = 1 << 4,
        kGameStart,
        kPlayerJoin = (1 << 5) + 2,
        kPlayerLeave,
        kPlayerChange,
        kPlayerDeath,
        kPlayerChat,
        kServerCommand = (1 << 6) + 6,
        kServerClose,
        kScriptEvent = (1 << 7) + 8
    };
    
    //Death stuff
    //1 fall or server
    //2 guardians
    //3 vehicle
    //4 another
    //5 betray
    //6 suicide
    
    //Chat type (global,team,vehicle)
    //d_ptr pointer to message
    
    
    //building the packet
    // char *s = arg[1]
    // char c = src[i]
    //i++
    //while (c != 0)
    
    
    //Very complicated crap
    
    
    //Halo stuff

    char *message_packet_to_string_table[] = {
        "client-broadcast_game_search",
        "client-ping",
        "server-game_advertise",
        "server-pong",
        "server-new_client_challenge",
        "server-machine_accepted",
        "server-machine_rejected",
        "server-game_is_ending_holdup",
        "server-game_settings_update",
        "server-pregame_countdown",
        "server-begin_game",
        "server-graceful_game_exit_pregame",
        "server-pregame_keep_alive",
        "server-postgame_keep_alive",
        "client-join_game_request",
        "client-add_player_request_pregame",
        "client-remove_player_request_pregame",
        "client-settings_request",
        "client-player_settings_request",
        "client-game_start_request",
        "client-graceful_game_exit_pregame",
        "client-map_is_precached_pregame",
        "server-game_update",
        "server-add_player_ingame",
        "server-remove_player_ingame",
        "server-game_over",
        "client-loaded",
        "client-game_update",
        "client-add_player_request_ingame",
        "client-remove_player_request_ingame",
        "client-graceful_game_exit_ingame",
        "client-host_crashed_cry_for_help",
        "client-join_new_host",
        "server-reconnect",
        "server-graceful_game_exit",
        "client-remove_player_request_postgame",
        "client-switch_to_pregame",
        "client-graceful_game_exit_postgame",
    };
    
    
    
    
   
    
    //setbuf(stdout, NULL);
    
    
    char *keyChallenge = gskeychall("", "qabgpzq", 0x1b1c62e0);
    
    
    printf("\n- key\n");
    printf(
           "- the query that will be sent to the master server is:\n"
           "\n"
           "  %s\n"
           "\n", keyChallenge);
    
    fputs("\n"
          "Halo proxy data decrypter "VER"\n"
          "by Luigi Auriemma\n"
          "e-mail: aluigi@autistici.org\n"
          "web:    aluigi.org\n"
          "\n", stdout);
    
    //argv[] = {"", "10.0.1.19", "2302", "2306"};
    
    int argc = 4;
    
    pNo++;
    firstBot = 1;
    
    int my_player = playernumberinitial;
    playernumberinitial++;
    
    //int my_player = pNo;
    
    //Use a random port
    //port_number++;
    
    wolfNo++;
    char *pn = malloc(100);
    sprintf(pn,"%d", port_number);
    //port_number
    
    printf("PORT NUMBER %d %s\n", my_player, pn);
    
  
    char *argv[] = {"", [[serveraddress stringValue] cString], [[serverport stringValue] cString], pn};
    //argv[] = {"", "162.217.250.28", "2300", "2306"};
    
    if(argc < 4) {
        printf("\n"
               "Usage: %s <server> <server_port> <local_port>\n"
               "\n"
               "How to use:\n"
               "1) launch this tool specifying the server in which you wanna join and the\n"
               "   ports to use, the game usually uses the port 2302\n"
               "2) open your game client\n"
               "3) connect your client to localhost on the port specified in local_port\n"
               "   only one client at time is supported\n"
               "\n", argv[0]);
        exit(1);
    }
    
    
    fd_set  rset;
    gh_t    *gh;
    int
    selsock,
    len,
    plain,
    on = 1,
    psz;
    u16     port,
    lport;
    u8      *buff,
    basekey1[16],
    basekey2[16],
    // client
    
    enckey2[16],    // server
    hash1[17],
    hash2[17],
    *psdk;
    
#ifdef WIN32
    WSADATA    wsadata;
    WSAStartup(MAKEWORD(1,0), &wsadata);
#endif
    
    port  = atoi(argv[2]);
    
    if (!useArchon)
        lport = atoi(argv[3]);
    else
        lport = atoi("1005");
    
    peer1.sin_addr.s_addr = INADDR_ANY;
    peer1.sin_port        = htons(lport);
    peer1.sin_family      = AF_INET;
    
    peer2.sin_addr.s_addr = resolv(argv[1]);
    peer2.sin_port        = htons(port);
    peer2.sin_family      = AF_INET;
    
    printf(
           "- target   %s : %hu\n"
           "- set local proxy on port %hu\n"
           "- only one client at time is allowed\n",
           inet_ntoa(peer2.sin_addr), port,
           lport);
    
    sd1 = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if(sd1 < 0) std_err();
    sd2 = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if(sd2 < 0) std_err();
     NSLog(@"bind!");
    
    if(setsockopt(sd1, SOL_SOCKET, SO_REUSEADDR, (char *)&on, sizeof(on)) < 0)
    {
        NSLog(@"Socket output failed");
        std_err();
    }
    
    if(bind(sd1, (struct sockaddr *)&peer1, sizeof(peer1)) < 0)
    {
       NSLog(@"Binding failed");
        std_err();
    }
    printf("- wait packets...\n");
    FD_ZERO(&rset);
    FD_SET(sd1, &rset);
    
    
    //Handshake
     NSLog(@"begin!");
    struct  sockaddr_in peer;
    struct  linger  ling = {1,1};
    u32     ver;
    int     sd,
    b,
    tryver  = 0;
    u8     
    enckey[16],
    deckey[16],
    hash[17],
    *p;
    buff    = malloc(BUFFSZ);

#ifdef WIN32
    WSADATA    wsadata;
    WSAStartup(MAKEWORD(1,0), &wsadata);
#endif
     NSLog(@"sart!");
    //setbuf(stdout, NULL);
    
    if(argc > 2) port = atoi(argv[2]);
    peer.sin_addr.s_addr  = resolv(argv[1]);
    peer.sin_port         = htons(port);
    peer.sin_family       = AF_INET;
    
    printf("- target   %s : %hu\n",
           inet_ntoa(peer.sin_addr), port);


    ver = halo_info(buff, &peer);

    if(!ver) ver = 612000;
    
    //CUSTOM EDITION VERSION 609000
    
    printf("\n- version %d\n", ver);
    
    psdk = buff + 7;
    
    
    
    printf("\n- connect\n");

    
    int sockfd, clientfc,n;
    struct sockaddr_in servaddr,cliaddr;
    char sendline[1000];
    char recvline[1000];
    
    int length;
    sockfd=socket(AF_INET,SOCK_DGRAM,0);
    clientfc=socket(AF_INET,SOCK_DGRAM,0);
    int fd, ret;
    
    //int flags = fcntl(sockfd, F_GETFL, 0);
    //fcntl(sockfd, F_SETFL, flags | O_NONBLOCK);
    
    bzero(&servaddr,sizeof(servaddr));
    servaddr.sin_family = AF_INET;
    servaddr.sin_addr.s_addr=inet_addr(argv[1]);
    servaddr.sin_port=htons(argv[2]);
    

    
    if (useArchon)
    {
    
    
    //sd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    //if(sd < 0) std_err();
    //setsockopt(sd, SOL_SOCKET, SO_LINGER, (char *)&ling, sizeof(ling));
    
    p = buff;
    p += putxx(p, 0xfefe,   16);    // gssdk_header
    p += putxx(p, 1,        8);
    p += putxx(p, htons(0), 16);
    p += putxx(p, htons(0), 16);
    memset(psdk, '1',       32);
    gssdkcr(psdk, psdk,     0);
    p += 32;
    
    if (!muteOutput)
    printf("\n- preheader\n");
    
    if (!muteOutput)
    show_dump(buff, p - buff, stdout);

    //unsigned char *s = "fe fe 01 00 00 00 00 7b 73 52 2b 6a 7b 7b 74 36 7b 2f 3f 66 69 34 2b 50 45 58 7b 5d 2f 48 2f 40 43 68 35 3e 51 66 5f";
    //b = convert(s, &length);
    
    //sendto(sd1,buff,p - buff,0,(struct sockaddr *)&peer1,sizeof(peer1));
    //sendto(sd1,b,length,0,(struct sockaddr *)&peer1,sizeof(peer1));
    
   
    printf("\n- header\n");

    len = send_recv(sd2, buff, p - buff, buff, BUFFSZ, &peer, 1);
    
    while(buff[2] != 2)
    {
        len = send_recv(sd2, NULL, 0, buff, BUFFSZ, &peer, 1);
    }
     show_dump(buff, len, stdout);
    
    ver = 616000;
    
    //CE
    //ver = 609999; //or 648444
        
    char *chlng = malloc(33);
    memset(chlng, 0, 33);
    memcpy(chlng, buff + 39, 32);
    
        if (!muteOutput)
    printf("\n- challenge\n");
    show_dump(chlng, 32, stdout);
    
    p = buff;
    p += putxx(p, 0xfefe,   16);    // gssdk_header
    p += putxx(p, 3,        8);
    p += putxx(p, htons(1), 16);
    p += putxx(p, htons(1), 16);
    gssdkcr(psdk, buff + 39, 0);    p += 32;
    halo_generate_keys(hash, NULL, enckey1);
    p += putmm(p, enckey1,   16);    // Halo handshake
    p += putxx(p, ver,      32);
    
        printf("\n- version\n");
    NSLog(@"%d", ver);

    printf("\n- sending\n");
    show_dump(buff, p - buff, stdout);

    printf("\n- reply\n");
    
    
    
    len = send_recv(sd2, buff, p - buff, buff, BUFFSZ, &peer, 1);
    
    while((buff[2] != 4) && (buff[2] != 5) && (buff[2] != 0x68)) {
        len = send_recv(sd2, NULL, 0, buff, BUFFSZ, &peer, 1);
    }
     
    
     show_dump(buff, len, stdout);
    

    
    
    
    if((buff[2] == 5) && (buff[7] == 6))
    {
        close(sd);
        printf("  server full ");
    }
    else if((buff[2] == 5) && (buff[7] == 4))
    {
        close(sd);
        if(ver == 6013999) {
            printf("\nError: unknown server version\n");
            exit(1);
        } else if(ver == 609999) {
            ver = 6013999;
        } else {
            ver = 609999;
        }
        printf("  try version %d", ver);
    }
    else if((buff[2] == 5) && (buff[7] == 5))
    {
        if(tryver < 5) {
            ver -= 1000;            // servers 1.07 need a different version
        } else if(tryver == 5) {
            ver = 2;
        } else if(tryver == 6) {
            ver = 1;
        } else {
            printf("\nError: unknown server version\n");
            exit(1);
        }
        tryver++;
        printf("  try version %d", ver);
    }
    else if(buff[2] == 0x68)
    {
        close(sd);
        printf("  disconnected");
    }
    else if(buff[2] != 4)
    {
        close(sd);
        printf("\nError: you have been disconnected for unknown reasons (%02x %02x)\n", buff[2], buff[7]);
        return;
    }
    
    
    //show_dump(recvline, n, stdout);
    
    
    halo_generate_keys(hash, psdk, deckey1);
    halo_generate_keys(hash, psdk, enckey1);
    
        if (!muteOutput)
    printf("\n- keys\n");
    show_dump(deckey1, 16, stdout);
    show_dump(enckey1, 16, stdout);
    

    

    
    n=recvfrom(sd2,recvline,10000,0,NULL,NULL);
        
       
    n=decreypt(recvline, n, deckey1, enckey1, YES);
    
        
    printf("\n- key string\n");
    show_dump(recvline, n, stdout);
        
    char string[] = "                    ";
    string[0] = recvline[10];
    string[1] = recvline[11];
    string[2] = recvline[12];
    string[3] = recvline[13];
    string[4] = recvline[14];
    string[5] = recvline[15];
    string[6] = recvline[16];

    pNo = (int)(recvline[22]);
    u8 myPno = pNo;
    //my_player = pNo;
        
    chlng = string;
    
    
    u32     rnd             = 0,
    client_token    = 0,
    pid             = 0,
    ip              = 0;
    u8      buffer[2048 + 1]  = "",
    tmp[128]        = "",
    challenge[32]   = "";
    int     skey            = 0,
    valid           = 0,
    invalid         = 0;
    FILE    *fdkeys         = NULL,
    *fdres          = NULL;
    int  
    i               = 0,

    respoff         = 0;
    
        
    u8 cdkey[64]       = "K9TGM-K337P-JW24T-B9V73-C3TVW";
    memcpy(cdkey, [self randomSerialKey], 20);
        
    printf("\nCDKEY %s\n\n", cdkey);
        
    //Insert our key hash thing
    rnd = time(0);
    
    nextrand(&rnd);
    create_randchall(hash, challenge, 8);
    printf("- server challenge (SERVER_TOKEN) generated: %s\n", chlng);
    
    nextrand(&rnd);
    client_token = hash;
    printf("- client challenge (CLIENT_TOKEN) generated: 0x%.8x\n", client_token);
    
    nextrand(&rnd);
    ip   = ~rnd;
    
    nextrand(&rnd);
    skey = rnd & 0xfff;
    
    // only one comment: stupid Microsoft, Windows 7 and _set_printf_count_output
    // all compatibility broken due to these idiots
    
    // do not touch len because it's used later!
    len = sprintf(
                  buffer,
                  "",
                  pid,
                  chlng);
    respoff = len;
    len += sprintf(
                   buffer + len,
                   "%s%.8x%s",
                   "                                ", // space for cd-key MD5
                   client_token,
                   "                                " // space for third string MD5
                   );
    
    p = do_md5(cdkey, strlen(cdkey), buffer + respoff);
    printf("- MD5 hash of the cd-key: %.32s\n", p - 32);
    
    if(dbkey) {
        hash2byte(p - 32, tmp);
        memcpy(dbkey[dbkey_idx % DBKEYMAX].hash, tmp, 16);
        strncpy(dbkey[dbkey_idx % DBKEYMAX].cdkey, cdkey, 64);
        dbkey[dbkey_idx % DBKEYMAX].cdkey[64 - 1] = 0;
        dbkey_idx++;
    }
    
    i = sprintf(
                tmp,
                "%s%u",
                cdkey,
                client_token % 0xffff,
                chlng);
    if(i < 0) std_err();
    do_md5(tmp, i, p + 8);
    
    //chlng="rxtmhpq";
    //[self randomSerialKey]
    chlng = string;
        
        
    char *keyChallenge = gskeychall([self randomSerialKey], chlng, 0);
    
        
    //keyChallenge = gskeychall("K9TGM-K337P-JW24T-B9V73-C3TVW", "stjwqgd", 0x75a360f8);
        
    
    printf("\n- key\n");
    printf(
           "- the query that will be sent to the master server is:\n"
           "\n"
           "  %s\n"
           "\n", keyChallenge);
    
    int cdkeyLength = strlen(keyChallenge);
    
    
    const char *s = "fe fe 00 00 02 00 03 0c 09 01 6d 65 73 73 61 67 65 20 69 6e 20 61 20 62 6f 74 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00";
    
//CE
        //s = "fe fe 00 00 02 00 03 4c 09 01 6d 65 73 73 61 67 65 20 69 6e 20 61 20 62 6f 74 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00";
        
        
    const char *s2 = "00 04 00 4b 00 69 00 74 00 74 00 79 00 00 00 00 00 00 00 00 00 00 00 00 00 00 ff ff ff ff 01 00 ff ff 0e 98 20 02 c4 d8 de de c8 ce ea d8 c6 d0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00";
    
    
    unsigned char *bb = convert(s, &length);
    
    p = buff;
    
    memcpy(buff, bb, length);
    p+=length;
    
    int cdlen = length;
    
    memcpy(buff+length, keyChallenge, cdkeyLength);
    p+=cdkeyLength;
    
    bb = convert(s2, &length);
    
    memcpy(buff+cdlen+cdkeyLength, bb, length);
    p+=length;
    
    //putcc(p, putmm, length);

    
    
    
  
        s ="fe fe 00 00 02 00 03 96 c1 90 10 d0 56 36 37 17 76 56 06 92 e6 06 12 06 22 f6 46 07 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 23 03 93 73 03 63 13 46 26 23 96 83 33 06 73 83 43 66 16 96 43 43 66 36 33 36 83 53 56 13 43 76 73 63 66 66 66 43 73 23 26 96 23 63 43 76 53 33 76 93 33 96 13 33 96 23 16 33 43 06 33 26 13 26 16 66 46 76 33 26 56 06 10 00 e0 04 50 06 70 07 00 03 00 03 10 03 00 00 00 00 00 00 00 00 00 00 00 f0 ff ff ff 1f 00 f0 ff ef 80 09 22 40 8c ed ed 8d ec ac 8e 6d 0c 0d 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 a0 02";
        
        p=buff;
        bb = convert(s, &length);
        memcpy(buff, bb, length);
        p+=(length);
    
        
        //halobits(psdk, p - psdk, YES);
        
    int ab = 0;
    int n = read_bits(1, psdk+11, ab);
        
    
    s ="fe fe 00 00 02 00 03";
    bb = convert(s, &length);
    
    
    p = buff;
    memcpy(buff, bb, length);
    
         
    char *name = malloc(30);
    sprintf(name, "Wolf %d", wolfNo);
    
    s = malloc(2000);
        //start 0c to 4c for CE
    sprintf(s,"0c 09 01 6d 65 73 73 61 67 65 20 69 6e 20 61 20 62 6f 74 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 30 32 30 39 37 30 36 61 64 32 62 39 38 63 30 37 38 64 66 61 39 34 64 66 33 63 33 38 65 35 31 64 39 61 66 66 38 35 34 31 30 62 33 31 32 36 37 64 31 30 30 63 62 61 30 35 30 61 34 62 30 64 64 38 35 33 35 39 37 66 38 34 00 04 00 52 00 4f 00 46 00 4c 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 ff ff ff ff %02x 00 ff ff 0e 98 20 02 c4 d8 de de c8 ce ea d8 c6 d0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 2a 00 00", pNo);
    
    //HALO CE
        //sprintf(s,"4c 09 01 6d 65 73 73 61 67 65 20 69 6e 20 61 20 62 6f 74 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 30 32 30 39 37 30 36 61 64 32 62 39 38 63 30 37 38 64 66 61 39 34 64 66 33 63 33 38 65 35 31 64 39 61 66 66 38 35 34 31 30 62 33 31 32 36 37 64 31 30 30 63 62 61 30 35 30 61 34 62 30 64 64 38 35 33 35 39 37 66 38 34 00 04 00 52 00 4f 00 46 00 4c 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 ff ff ff ff %02x 00 ff ff 1c 23 8e 55 0e 98 20 02 c4 d8 de de c8 ce ea d8 c6 d0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 2a b0 00", pNo);
        
    bb = convert(s, &length);
    memcpy(bb+37, keyChallenge, cdkeyLength);
        
    int k = bb+37+72+3;
    int ms;
    for (ms=0; ms < strlen(name); ms++)
    {
        memcpy(k, name+ms, 1);
        k+=2;
    }
        
    
        
    printf("\n- prebits\n");
    show_dump(bb, length, stdout);
    
    printf("\n- bits2\n");
    //int ab=0;
        
    
   
        
    b = 0;
    b = write_bits(length, 11, psdk, b);
    b = write_bits(1, 1, psdk, b); // this part is not important, it's only needed to send a total of 4 bytes
    b = write_bstr(bb, (length)*4, psdk, b); // this part is not important, it's only needed to send a total of 4 bytes
        
    
    //memcpy(buff, bb, length);
    p+=(length)+7;
        

   // b=0;
   // b=write_bstr(p, b, keyChallenge, -1);
    //putmm(buff+2, b, 32);
        
        
        
        
        
    //Overwirte
    /*
    s ="fe fe 00 00 02 00 03 96 c1 90 10 d0 56 36 37 17 76 56 06 92 e6 06 12 06 22 f6 46 07 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 23 03 93 73 03 63 13 46 26 23 96 83 33 06 73 83 43 66 16 96 43 43 66 36 33 36 83 53 56 13 43 76 73 63 66 66 66 43 73 23 26 96 23 63 43 76 53 33 76 93 33 96 13 33 96 23 16 33 43 06 33 26 13 26 16 66 46 76 33 26 56 06 10 00 e0 04 50 06 70 07 00 03 00 03 10 03 00 00 00 00 00 00 00 00 00 00 00 f0 ff ff ff 1f 00 f0 ff ef 80 09 22 40 8c ed ed 8d ec ac 8e 6d 0c 0d 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 a0 02";
    
    p=buff;
    bb = convert(s, &length);
    memcpy(buff, bb, length);
    p+=(length);
    */
        
        
   
    printf("\n- bits %d %d %d\n", n, p - psdk, length);
    halobits(psdk, p - psdk, YES);
    
    
     //show_dump(psdk, p - psdk, stdout);
   
    
    //show_dump(crc, 32, stdout);
    
    //Fix up the header
    s ="fe fe 00 00 02 00 03 96 c1 90";
    bb = convert(s, &length);
    memcpy(buff, bb, length);
        
    printf("\n- presdetails\n");
    show_dump(buff, p - buff, stdout);
        
        printf("\n- crc32 %d\n", length);
        uint32_t crc = halo_crc32(psdk, p - psdk);
        printf("%d\n", crc);
        
    //return;
    /*
    b = 0;
    b = write_bits(3, 11, p, b);
    b = write_bits(1, 1, p, b); // this part is not important, it's only needed to send a total of 4 bytes
    b = write_bits(0, 6, p, b); // in version 1.04 this particular type of packet causes a silent unhandling of the server (process active but packets are not handled)
    b = write_bits('A', 8, p, b);*/
    
    //p += putxx(p, b, 16);
    
    //p += (((b+7)&(~7)) >> 3);
    //*(u_int *)(p - 4) = crc;
    
    
    p += putxx(p, crc, 32);
    
   
    printf("\n- details\n");
    show_dump(psdk, p - psdk, stdout);
    
    halo_tea_encrypt(psdk, p - psdk, enckey1);
    
   
    
    
    //sendto(sd1,buff,p - buff,0,(struct sockaddr *)&peer1,sizeof(peer1));
    sendto(sd2,buff,p - buff,0,(struct sockaddr *)&peer2,sizeof(peer2));
    
        //sleep(1);
        
        
    n=recvfrom(sd2,recvline,10000,0,NULL,NULL);
    printf("\n- received final\n");
    //decshow(recvline, n, deckey2, enckey1, YES);
    show_dump(recvline, n, stdout);
    
    /*
    sendPacket("fe fe 00 00 03 00 04 0a c0 08 10 00 00 00 00 a0 c1");
    sendPacket("fe fe 00 00 04 00 07 0f b8 69 08 04 60 ad 53 a0 d0 ec e4 9d ff ff");
    sendPacket("fe fe 00 00 05 00 07 05 b8 09 10 10");
    sendPacket("fe fe 00 00 06 00 07 05 b8 09 20 84");
    sendPacket("fe fe 00 00 07 00 07 05 b8 01 30 10");
    sendPacket("fe fe 00 00 08 00 08 05 b8 01 40 14");
    */
        
    packet_no[my_player] = 4;
    second_packet_no[my_player] = 0;
        
    sendPacket("fe fe 00 00 03 00 03 fe", enckey1, deckey1, sd2, peer2, packet_no[my_player], second_packet_no[my_player], my_player);
        
    char *a = malloc(100);
    char *b = malloc(100);
    char *d = malloc(100);
    int bn = 0;
    u8 currentHex = 0;
    int bcount = 0;
    int somecount = 0;
        
        
        
    sendPacket("fe fe 00 00 03 00 04 0a c0 08 10 00 00 00 00 a0 81", enckey1, deckey1, sd2, peer2, packet_no[my_player], second_packet_no[my_player], my_player); //Join the game <-- useful
    /*sprintf(a,"fe fe 00 00 03 00 04", secondpktnum, packet_no );
    sprintf(b,"8c 00 01 00 00 00 00", pNo);
    sendNormalPacket(a, b, enckey1, deckey1, sd2, peer2, packet_no, secondpktnum, my_player, buff);
    if (packet_no >= 0xff) { packet_no = 0; secondpktnum++; } else { packet_no++; }
     */   
        
        
    sendPacket("fe fe 00 00 05 00 07 05 b8 09 10 04", enckey1, deckey1, sd2, peer2, packet_no[my_player], second_packet_no[my_player], my_player);
        currentHex = 16*2;
  
   
        //fe fe 00 00 03 00 04
        //0a c0 08 10 00 00 00 00 a0 11 68 1f 1c c3 (8c 00 01 00 00 00 00 1a 81 f6) WITH HEADER
        
    
        int endNumber = 0;
    
        /*
    sendPing("fe fe 00 00 04 00 04", enckey1, deckey1, sd2, peer2, packet_no[my_player], second_packet_no[my_player], my_player);
    if (packet_no[my_player] >= 0xff) { packet_no[my_player] = 0; second_packet_no[my_player]++; }
    sendPing("fe fe 00 00 05 00 04", enckey1, deckey1, sd2, peer2, packet_no[my_player], second_packet_no[my_player], my_player);
    if (packet_no[my_player] >= 0xff) { packet_no[my_player] = 0; second_packet_no[my_player]++; }
    sendPing("fe fe 00 00 06 00 04", enckey1, deckey1, sd2, peer2, packet_no[my_player], second_packet_no[my_player], my_player);
    if (packet_no[my_player] >= 0xff) { packet_no[my_player] = 0; second_packet_no[my_player]++; }
        */
        
        

    //sendPacket("fe fe 00 00 03 00 04 0a c0 08 10 00 00 00 00 a0 11", enckey1, deckey1, sd2, peer2, packet_no[my_player], second_packet_no[my_player], my_player);
    packet_no[my_player]=4;
        
/*
        sprintf(a,"04 88 fe 07"); //<<------- or this?
        sendData(a, enckey1, deckey1, sd2, peer2, packet_no[my_player], second_packet_no[my_player], my_player);
        */
        

    //printf("%s", a);
        
        endNumber = 4;
    
        //Keep spamming this packet
        int g = 0;
        int h = 0;
        int someNum = 0;
        
    //secondpktnum++;
        
    isCrouched[my_player]= YES;
    isShooting[my_player] = NO;
    isWalking[my_player] = YES;
        
    isRotating[my_player] = NO;
       
         BOOL previousAction = NO;
         BOOL previousMelee = NO;
        
    BOOL previousGrenading = NO;
    BOOL previousShooting = NO;
    BOOL previousCrouching = NO;
    BOOL previousWalking = NO;
        BOOL previousTeam = NO;
        BOOL directionStrafe;
    u8 testNumber = 0;
        int c = 0;
    float someDirection = 0.0;
        u8 randomNumber = 0;
        int currentBe = 2;
        
        BOOL teamSwitchState = NO;;
    int packetDelay = 0;
        
        

 
        
        int strafeTimer = 0;
        
        isCrouched[my_player] = [ai_crouch state];
        
        isRotating[my_player] = [ai_seek state];
        isWalking[my_player] = [ai_move state];
        isShooting[my_player] = [ai_shoot state];
        
        
    while (1)
    {
       
        //printf("\n%02x %02x %d", second_packet_no[my_player], packet_no[my_player], g);
        
       
        
        if (docopyme)
        {
            peeraddress = (struct sockaddr *)&peer2;
            socketAddress = sd2;
            
            didReceive = 1;
            
            usleep(10000000);
            return;
            
            if (packetReady && lastHostLength > 0)
            {
                printf("\nSENDING DATA\n");
                show_dump(lastHostPacket, lastHostLength, stdout);
                sendto(sd2,lastHostPacket,lastHostLength,0,(struct sockaddr *)&peer2,sizeof(peer2));
                
                didReceive = 1;
                //int n;
                //n=recvfrom(sd2,recvline,1000,0,NULL,NULL);
                //printf("\n- received output \n");
            
                packetReady=0;
            }
            continue;
        }
        
        
        //printf("\nSECOND NUMBER: %02x", second_packet_no[my_player]);
        
        float sleeptime = 1;
        if (g >= 100)
        {
           
            
    
            
          
            sprintf(a,"fe fe 64 00 04", packet_no[my_player]); //<<--- maybe this?
            sendPing(a, enckey1, deckey1, sd2, peer2, packet_no[my_player], second_packet_no[my_player], my_player);
            
            u8 number = 6+1*8;
            sprintf(a,"0c 88 %02x 88 %02x 88 %02x 88 %02x 88 %02x 45", number,number,number,number,number); //<<------- or this?
            sendData(a, enckey1, deckey1, sd2, peer2, packet_no[my_player], second_packet_no[my_player], my_player);
            
        
            
            
            
      
            
            /*
            isChangingPacket[my_player] = YES;
            sprintf(a,"fe fe 00 %02x %02x 00 04 05 b8 01 %02x 00", second_packet_no[my_player], packet_no[my_player], currentHex);
            if (currentHex >= 0xf0){currentHex = 0;}else{currentHex+=16;}
            sendPacket(a,  enckey1, deckey1, sd2, peer2, packet_no[my_player], second_packet_no[my_player], my_player);
            isChangingPacket[my_player] = NO;
            */
            
            /*
            isChangingPacket[my_player] = YES;
            sprintf(a,"fe fe 00 %02x %02x 00 04", second_packet_no[my_player], packet_no[my_player] );
            
            if (someNum == 0)
                sprintf(b,"1b 00 10 6c 9f");
            else if (someNum == 1)
                sprintf(b,"1b 00 51 6e f7");
            else if (someNum == 2)
                sprintf(b,"1b 00 d2 72 30");
            else if (someNum == 3)
                sprintf(b,"1b 00 13 15 c4");
            else if (someNum == 4)
                sprintf(b,"1b 00 94 d7 d4");
            else if (someNum == 5)
                sprintf(b,"1b 00 15 ef 40");
            else if (someNum == 6)
                sprintf(b,"1b 00 d6 ac e7");
            else if (someNum == 7)
                sprintf(b,"1b 00 97 69 9c");
            else if (someNum == 8)
                sprintf(b,"1b 00 58 ca 4f");
            else if (someNum == 9)
                sprintf(b,"1b 00 99 a5 89");
            else if (someNum == 10)
                sprintf(b,"1b 00 9a 56 ec");
            else if (someNum == 11)
                sprintf(b,"1b 00 cb b6 81");
            else if (someNum == 12)
                sprintf(b,"1b 00 cc 11 0d");
            else if (someNum == 13)
                sprintf(b,"1b 00 8d 17 7c");
            else if (someNum == 14)
                sprintf(b,"1b 00 8e e4 19");
            else if (someNum == 15)
                sprintf(b,"1b 00 cf ea 5a");
            
            if (currentBe >= 0xf) { currentBe = 0; } else {currentBe++;}
            sendNormalPacket(a, b, enckey1, deckey1, sd2, peer2, packet_no[my_player], second_packet_no[my_player], my_player, buff);
            if (currentHex == 0xf0){currentHex = 00;}else{currentHex+=16;}
            if (packet_no[my_player] >= 0xff) { packet_no[my_player] = 0; second_packet_no[my_player]++; } else {packet_no[my_player]++;}
            usleep(packetDelay);
            isChangingPacket[my_player] = NO;
            if (someNum == 15) {someNum = 0;} else {someNum++;}
            */
            
        }
        g++;
        

           
        
        
        
        if (teamSwitchState != [ai_teamswitch state])
        {
            teamSwitchState = [ai_teamswitch state];
            
            char *a = malloc(1000);
            
            /*1e 80 83 04 31 80 32 00 3a 00 3a 00 3a 80 32 00   ....1.2.:.:.:.2.
             39 00 10 80 1f 80 80 2f 11 16 13 00 c2 5e 49 e0   9
            */
            
            /*
            1e 80 80 90 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 80 20 00
            */
            
            
            //Create a message using the lettermap
            char *message_wolf = "Samuco has unfortunately hacked me";
            printf("\n %c %d %d\n", message_wolf[0], typeforLetter(message_wolf[0]), indexforLetter(message_wolf[0]));
            
             isChangingPacket[my_player] = YES;
            int hm = 0;
            for (hm = 0; hm < 1; hm++)
            {
                u8 *b = malloc(3000);
                b[0]=0x1e;
                b[1]=(char)typeforLetter(message_wolf[0]); //First index
                b[2]=0x81;
                b[3]=0x90;
                b[4]=(char)indexforLetter(message_wolf[0]); //First index
                
                int inde = 5;
                int m=0;
                for (m=1; m < strlen(message_wolf); m++)
                {
                    char letter = message_wolf[m];
                    b[inde] = (u8)typeforLetter(message_wolf[m]);
                    b[inde+1] = (u8)indexforLetter(message_wolf[m]);
                    inde+=2;
                }
                b[inde]=0x00;
                
                show_dump(b, 4+strlen(message_wolf)*2, stdout);
                
                sprintf(a, "fe fe 00 %02x %02x 00 04", second_packet_no[my_player], packet_no[my_player]);
                sendNormalPacket2(a, b, 4+strlen(message_wolf)*2, enckey1, deckey1, sd2, peer2, packet_no[my_player], second_packet_no[my_player], my_player, buff);
                if (packet_no[my_player] >= 0xff) { packet_no[my_player] = 0; second_packet_no[my_player]++; } else {packet_no[my_player]++;}
                
            }
            isChangingPacket[my_player] = NO;
            
            /*
            int nn;
            for (nn=0; nn < 16; nn++)
            {
                u8 number = 3+nn*8;
                if ([ai_team state])
                {
                    isChangingPacket[my_player] = YES;
                    sprintf(a,"fe fe 00 %02x %02x 00 04 05 48 %02x 00 78", second_packet_no[my_player], packet_no[my_player], number );
                    sendPacket(a, enckey1, deckey1, sd2, peer2, packet_no[my_player], second_packet_no[my_player], my_player);
                    if (packet_no[my_player] >= 0xff) { packet_no[my_player] = 0; second_packet_no[my_player]++; } else {packet_no[my_player]++;}
                    isChangingPacket[my_player] = NO;
                }
                else
                {
                    isChangingPacket[my_player] = YES;
                    sprintf(a,"fe fe 00 %02x %02x 00 04 05 48 %02x 08 78", second_packet_no[my_player], packet_no[my_player], number );
                    sendPacket(a, enckey1, deckey1, sd2, peer2, packet_no[my_player], second_packet_no[my_player], my_player);
                    if (packet_no[my_player] >= 0xff) { packet_no[my_player] = 0; second_packet_no[my_player]++; } else {packet_no[my_player]++;}
                    isChangingPacket[my_player] = NO;
                }
            }
             */
        }
         
    
        if (previousTeam != [ai_team state])
        {
            previousTeam = [ai_team state];
        
            if ([ai_team state])
            {
                u8 number = 3+myPno*8;
                isChangingPacket[my_player] = YES;
                sprintf(a,"fe fe 00 %02x %02x 00 04 05 48 %02x 00 78", second_packet_no[my_player], packet_no[my_player], number );
                sendPacket(a, enckey1, deckey1, sd2, peer2, packet_no[my_player], second_packet_no[my_player], my_player);
                if (packet_no[my_player] >= 0xff) { packet_no[my_player] = 0; second_packet_no[my_player]++; } else {packet_no[my_player]++;}
                isChangingPacket[my_player] = NO;
            }
            else
            {
                u8 number = 3+myPno*8;
                isChangingPacket[my_player] = YES;
                sprintf(a,"fe fe 00 %02x %02x 00 04 05 48 %02x 08 78", second_packet_no[my_player], packet_no[my_player], number );
                sendPacket(a, enckey1, deckey1, sd2, peer2, packet_no[my_player], second_packet_no[my_player], my_player);
                if (packet_no[my_player] >= 0xff) { packet_no[my_player] = 0; second_packet_no[my_player]++; } else {packet_no[my_player]++;}
                isChangingPacket[my_player] = NO;
            }
        }
        
                
        
        
        if ([ai_grenade state] != previousGrenading)
        {
            previousGrenading = [ai_grenade state];
            sprintf(a,"fe fe 00 %02x %02x 00 04", second_packet_no[my_player], packet_no[my_player] );
            sprintf(b,"1b 01 10 60 00 00", somecount);
            sendNormalPacket(a, b, enckey1, deckey1, sd2, peer2, packet_no[my_player], second_packet_no[my_player], my_player, buff);
            if (packet_no[my_player] >= 0xff) { packet_no[my_player] = 0; second_packet_no[my_player]++; } else {packet_no[my_player]++;}
            
        }
        
        if ([ai_action state] != previousAction)
        {
            previousAction = [ai_action state];
            sprintf(a,"fe fe 00 %02x %02x 00 04", second_packet_no[my_player], packet_no[my_player] );
            sprintf(b,"1b 01 34 02 3f 6d", somecount);
            sendNormalPacket(a, b, enckey1, deckey1, sd2, peer2, packet_no[my_player], second_packet_no[my_player], my_player, buff);
            if (packet_no[my_player] >= 0xff) { packet_no[my_player] = 0; second_packet_no[my_player]++; } else {packet_no[my_player]++;}
            
        }
        
        if ([ai_melee state] != previousMelee)
        {
            previousMelee = [ai_melee state];
            sprintf(a,"fe fe 00 %02x %02x 00 04", second_packet_no[my_player], packet_no[my_player] );
            sprintf(b,"1b 01 25 04 90 d5", somecount);
            sendNormalPacket(a, b, enckey1, deckey1, sd2, peer2, packet_no[my_player], second_packet_no[my_player], my_player, buff);
            if (packet_no[my_player] >= 0xff) { packet_no[my_player] = 0; second_packet_no[my_player]++; } else {packet_no[my_player]++;}
            
        }
        
            //1b 01 10 60 00 00 <-- grenaide
            //1b 20 74 40 3f <-- change weps
            //1b 01 34 02 3f 6d <--- enter vehicle
            //1b 01 25 04 90 d5  <--- meleee

        if ([isStrafed state] && strafeTimer == 30)
        {
            NSLog(@"STRAFE");
            if (directionStrafe)
            {
                isChangingPacket[my_player] = YES;
                sprintf(a,"fe fe 00 %02x %02x 00 04", second_packet_no[my_player], packet_no[my_player] );
                sprintf(b,"1b 08 00 00 00", currentBe, randomNumber, randomNumber);
                sendNormalPacket(a, b, enckey1, deckey1, sd2, peer2, packet_no[my_player], second_packet_no[my_player], my_player, buff);
                if (packet_no[my_player] >= 0xff) { packet_no[my_player] = 0; second_packet_no[my_player]++; } else {packet_no[my_player]++;}
                usleep(packetDelay);
                isChangingPacket[my_player] = NO;
            }
            else
            {
                isChangingPacket[my_player] = YES;
                sprintf(a,"fe fe 00 %02x %02x 00 04", second_packet_no[my_player], packet_no[my_player] );
                sprintf(b,"1b 08 2b ca c2", currentBe, randomNumber, randomNumber);
                sendNormalPacket(a, b, enckey1, deckey1, sd2, peer2, packet_no[my_player], second_packet_no[my_player], my_player, buff);
                if (packet_no[my_player] >= 0xff) { packet_no[my_player] = 0; second_packet_no[my_player]++; } else {packet_no[my_player]++;}
                usleep(packetDelay);
                isChangingPacket[my_player] = NO;
            }
            
            
            isChangingPacket[my_player] = YES;
            sprintf(a,"fe fe 00 %02x %02x 00 04", second_packet_no[my_player], packet_no[my_player] );
            sprintf(b,"1b 11 %02x 10 00 00", somecount);
            sendNormalPacket(a, b, enckey1, deckey1, sd2, peer2, packet_no[my_player], second_packet_no[my_player], my_player, buff);
            if (packet_no[my_player] >= 0xff) { packet_no[my_player] = 0; second_packet_no[my_player]++; } else {packet_no[my_player]++;}
            usleep(packetDelay);
            isChangingPacket[my_player] = NO;
            
            
            directionStrafe = !directionStrafe;
            
            
            //isWalking[my_player] = !isWalking[my_player];
            
            //[isStrafed state]
            strafeTimer=0;
        }
        strafeTimer++;
        
        if (isWalking[my_player] != previousWalking)
        {
            previousWalking = isWalking[my_player];
            if (isWalking[my_player])
            {
                //printf("\n %02x", randomNumber);
                isChangingPacket[my_player] = YES;
                sprintf(a,"fe fe 00 %02x %02x 00 04", second_packet_no[my_player], packet_no[my_player] );
                sprintf(b,"1b 08 2b ca c2", currentBe, randomNumber, randomNumber);
                sendNormalPacket(a, b, enckey1, deckey1, sd2, peer2, packet_no[my_player], second_packet_no[my_player], my_player, buff);
                if (packet_no[my_player] >= 0xff) { packet_no[my_player] = 0; second_packet_no[my_player]++; } else {packet_no[my_player]++;}
                usleep(packetDelay);
                isChangingPacket[my_player] = NO;
            }
            else
            {
                isChangingPacket[my_player] = YES;
                sprintf(a,"fe fe 00 %02x %02x 00 04", second_packet_no[my_player], packet_no[my_player] );
                sprintf(b,"1b 08 00 00 00", currentBe, somecount);
                sendNormalPacket(a, b, enckey1, deckey1, sd2, peer2, packet_no[my_player], second_packet_no[my_player], my_player, buff);
                if (packet_no[my_player] >= 0xff) { packet_no[my_player] = 0; second_packet_no[my_player]++; } else {packet_no[my_player]++;}
                usleep(packetDelay);
                isChangingPacket[my_player] = NO;
            }
        }
        
        
        
        
        
        
        //Find the closest player
        float closestDistance = 3;
        int closestPlayerID = -1;
        int pidm = object_id_for_player(my_player);
        
        int ad;
        for (ad=0; ad < 16; ad++)
        {
            if (ad == my_player)
                continue;
            
            short pida = object_id_for_player(ad);
            if (pida == -1)
                continue;
            
            float distance = distanceToObjectH(pidm, pida);
            if (distance < closestDistance)
            {
                NSLog(@"PLAYER ID: %d", pida);
                closestDistance = distance;
                closestPlayerID = ad;
            }
        }
        
        if (closestPlayerID != -1)
        {
            //Looks like we found a player. Aim at them.
            isCrouched[my_player] = YES;
            isShooting[my_player] = YES;
            //isWalking[my_player] = YES;
            
            
            
            int frompt = pointerToObject(pidm);
            int topt = pointerToObject(object_id_for_player(closestPlayerID));
            
            float x1 = x_coordinate(frompt);
            float y1 = y_coordinate(frompt);
            float z1 = z_coordinate(frompt);
            
            float x2 = x_coordinate(topt);
            float y2 = y_coordinate(topt);
            float z2 = z_coordinate(topt);
            
            
            
            if (x2 > x1)
            {
                if (y2 > y1)
                {
                    //Bottom left
                    float radians = atan((x2-x1)/(y2-y1));
                    float degrees = (radians*180)/M_PI;
                    testNumber = 20+((90-degrees)/90.0)*20;
                    NSLog(@"BOTTOM LEFT %d %f %f", testNumber, radians, degrees);
                }
                else
                {
                    //Top left
                    float radians = atan((x2-x1)/(y1-y2));
                    float degrees = (radians*180)/M_PI;
                    testNumber = (degrees/90.0)*20;
                    NSLog(@"TOP LEFT %d %f %f", testNumber, radians, degrees);
                }
            }
            else
            {
                if (y2 > y1)
                {
                    //Bottom right //0 and 15
                    float radians = atan((x1-x2)/(y2-y1));
                    float degrees = (radians*180)/M_PI;
                    testNumber = 40+(degrees/90.0)*20;
                    NSLog(@"BOTTOM RIGHT %d %f %f", testNumber, radians, degrees);
                }
                else
                {
                    float radians = atan((x1-x2)/(y1-y2));
                    float degrees = (radians*180)/M_PI;
                    testNumber = 60+(degrees/90.0)*20;
                    NSLog(@"TOP RIGHT %d %f %f", testNumber, radians, degrees);
                }
            }
            
            //testNumber = 37.5;
            
            isChangingPacket[my_player] = YES;
            sprintf(a,"fe fe 00 %02x %02x 00 04", second_packet_no[my_player], packet_no[my_player] );
            sprintf(b,"1b 06 54 00 00 %02x 90 00 00 00 0f 00 00", testNumber);
            sendNormalPacket(a, b, enckey1, deckey1, sd2, peer2, packet_no[my_player], second_packet_no[my_player], my_player, buff);
            if (packet_no[my_player] >= 0xff) { packet_no[my_player] = 0; second_packet_no[my_player]++; } else {packet_no[my_player]++;}
            usleep(packetDelay);
            isChangingPacket[my_player] = NO;
             
        }
        else
        {
            //Stand
            isCrouched[my_player] = NO;
            //isShooting[my_player] = NO;
            //isWalking[my_player] = NO;
            
        }
        
        //previousCrouching  = !isCrouched[my_player];
        
        
        somecount=0;
        if (isCrouched[my_player])
        {
            somecount = 0x70; //Jump/shoot
        }
        
        
        if (previousShooting != isShooting[my_player] || previousCrouching != isCrouched[my_player])
        {
            previousShooting = isShooting[my_player];
            previousCrouching = isCrouched[my_player];
            if (isShooting[my_player])
            {
                
                
                //05 48 13 00 f8 <-red (p2
                //05 48 0b 08 78 <blue (p1
                
                
                
                isChangingPacket[my_player] = YES;
                sprintf(a,"fe fe 00 %02x %02x 00 04", second_packet_no[my_player], packet_no[my_player] );
                sprintf(b,"1b 11 %02x 10 00 00", somecount);
                sendNormalPacket(a, b, enckey1, deckey1, sd2, peer2, packet_no[my_player], second_packet_no[my_player], my_player, buff);
                if (packet_no[my_player] >= 0xff) { packet_no[my_player] = 0; second_packet_no[my_player]++; } else {packet_no[my_player]++;}
                usleep(packetDelay);
                isChangingPacket[my_player] = NO;
            }
            else
            {
                isChangingPacket[my_player] = YES;
                sprintf(a,"fe fe 00 %02x %02x 00 04", second_packet_no[my_player], packet_no[my_player] );
                sprintf(b,"1b 11 %02x 00 00 00", somecount);
                sendNormalPacket(a, b, enckey1, deckey1, sd2, peer2, packet_no[my_player], second_packet_no[my_player], my_player, buff);
                if (packet_no[my_player] >= 0xff) { packet_no[my_player] = 0; second_packet_no[my_player]++; } else {packet_no[my_player]++;}
                usleep(packetDelay);
                isChangingPacket[my_player] = NO;
            }
        }

        
        
        
        
        
            if (isRotating[my_player])
            {

            //Send head direction
                isChangingPacket[my_player] = YES;
            sprintf(a,"fe fe 00 %02x %02x 00 04", second_packet_no[my_player], packet_no[my_player] );
            sprintf(b,"1b 06 54 00 00 %02x 90 00 00 00 0f 00 00", testNumber);
            sendNormalPacket(a, b, enckey1, deckey1, sd2, peer2, packet_no[my_player], second_packet_no[my_player], my_player, buff);
            if (packet_no[my_player] >= 0xff) { packet_no[my_player] = 0; second_packet_no[my_player]++; } else {packet_no[my_player]++;}
            usleep(packetDelay);
                isChangingPacket[my_player] = NO;
            }
            
            //Send rotation
            /*
            sprintf(a,"fe fe 00 %02x %02x 00 04", second_packet_no[my_player], packet_no[my_player] );
            sprintf(b,"1b 02 9%01x %02x %02x %02x 10 00 00", c, testNumber, testNumber, testNumber);
            sendNormalPacket(a, b, enckey1, deckey1, sd2, peer2, packet_no[my_player], second_packet_no[my_player], my_player, buff);
            if (packet_no[my_player] >= 0xff) { packet_no[my_player] = 0; second_packet_no[my_player]++; } else {packet_no[my_player]++;}
            */
            
            
        
            h++;
            c++;
            
            if (c > 0xf)
                c =0;
            
            testNumber+=1;
            
            if (testNumber > 60)
                testNumber = 0;
            
            someDirection+=1.0;
            
            randomNumber++;
            if (randomNumber > 0xff)
                randomNumber = 0;
       
        //usleep(500000);
        //packet_no=0;
  
        if ([ai_headers state])
        {
        isChangingPacket[my_player] = YES;
        sprintf(a,"fe fe 00 %02x %02x 00 04", second_packet_no[my_player], packet_no[my_player] );
        
        
        if (someNum == 0)
            sprintf(b,"1b 00 10 6c 9f");
        else if (someNum == 1)
            sprintf(b,"1b 00 51 6e f7");
        else if (someNum == 2)
            sprintf(b,"1b 00 d2 72 30");
        else if (someNum == 3)
            sprintf(b,"1b 00 13 15 c4");
        else if (someNum == 4)
            sprintf(b,"1b 00 94 d7 d4");
        else if (someNum == 5)
            sprintf(b,"1b 00 15 ef 40");
        else if (someNum == 6)
            sprintf(b,"1b 00 d6 ac e7");
        else if (someNum == 7)
            sprintf(b,"1b 00 97 69 9c");
        else if (someNum == 8)
            sprintf(b,"1b 00 58 ca 4f");
        else if (someNum == 9)
            sprintf(b,"1b 00 99 a5 89");
        else if (someNum == 10)
            sprintf(b,"1b 00 9a 56 ec");
        else if (someNum == 11)
            sprintf(b,"1b 00 cb b6 81");
        else if (someNum == 12)
            sprintf(b,"1b 00 cc 11 0d");
        else if (someNum == 13)
            sprintf(b,"1b 00 8d 17 7c");
        else if (someNum == 14)
            sprintf(b,"1b 00 8e e4 19");
        else if (someNum == 15)
            sprintf(b,"1b 00 cf ea 5a");
            
        if (currentBe >= 0xf) { currentBe = 0; } else {currentBe++;}
        sendNormalPacket(a, b, enckey1, deckey1, sd2, peer2, packet_no[my_player], second_packet_no[my_player], my_player, buff);
        if (currentHex == 0xf0){currentHex = 00;}else{currentHex+=16;}
        if (packet_no[my_player] >= 0xff) { packet_no[my_player] = 0; second_packet_no[my_player]++; } else {packet_no[my_player]++;}
        usleep(packetDelay);
        isChangingPacket[my_player] = NO;
            if (someNum == 15) {someNum = 0;} else {someNum++;}
            
        }

        //usleep(100000);
    
        
        
        /*
        int n;
        n=recvfrom(sd2,recvline,10000,0,NULL,NULL);
        receivedData(recvline, n, enckey1, deckey1, sd2, peer2, packet_no[my_player], second_packet_no[my_player], my_player);
        
        */
        
        /*
*/
        
        
        
        
        
        //588
        //decshow(recvline, n, deckey1, enckey1, YES);
        
        
        //sprintf(a,"fe fe 00 00 0a 00 06"); //Last byte unknown
        //sendPing(a);
        

        //sprintf(a,"fe fe 00 00 0f 00 06 06 88 0e 88 0e 68", packet_no); //Last byte unknown
        //sendPacket(a);
        
        //currentHex+=16;
        
        //if (currentHex == 0xf0)
        //{
        //    currentHex = 00;
        //}
        
        //packet_no++;
        //show_dump(recvline, n, stdout);*/
        
        //sleep(1);
        
        
    }
   
}

    //printf("%d", recvline[4]);
    
    printf("\n\n");
    
    /*fe fe 00 00 02 00 03 0c 09 01 6d 65 73 73 61 67 65 20 69 6e 20 61 20 62 6f 74 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 30 32 30 39 37 30 36 61 64 32 62 39 38 63 30 37 38 64 66 61 39 34 64 66 33 63 33 38 65 35 31 64 64 37 66 66 31 32 62 34 37 32 38 64 30 62 36 65 38 35 36 33 64 64 63 61 39 38 37 34 64 30 35 31 31 32 63 33 63 30 31 31 00 04 00 4b 00 69 00 74 00 74 00 79 00 00 00 00 00 00 00 00 00 00 00 00 00 00 ff ff ff ff 01 00 ff ff 0e 98 20 02 c4 d8 de de c8 ce ea d8 c6 d0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 2a 80 f3*/
    
    //sendto(sd1,buff,p - buff,0,(struct sockaddr *)&peer1,sizeof(peer1));
    /*printf("\n- server reply\n");
    
    len = send_recv(sd2, buff, p - buff, buff, BUFFSZ, &peer, 1);
    
    while((buff[2] != 4) && (buff[2] != 5) && (buff[2] != 0x68)) {
        len = send_recv(sd2, NULL, 0, buff, BUFFSZ, &peer, 1);
    }
    
    
    show_dump(buff, len, stdout);
*/
    
    //NSLog(@"Done!");

    
    //Lets send THEM something!
        //NSLog(@"still waiting");
    //buff    = malloc(BUFFSZ);
   // len = 50;
    //SEND(requestClientKey, peer2);
    //NSLog(@"sent");
    
    
    
    
    
    // NSLog(@"Sending %s %d", b, length);
    
    //ret = bind(clientfc, (struct sockaddr *)&cliaddr, sizeof(struct sockaddr));
    //if ( ret == -1 )
    //NSLog(@"Bind failure");
    
    
    /*
    unsigned char *s = "fe fe 01 00 00 00 00 7b 73 52 2b 6a 7b 7b 74 36 7b 2f 3f 66 69 34 2b 50 45 58 7b 5d 2f 48 2f 40 43 68 35 3e 51 66 5f";
    b = convert(s, &length);
    
 */
    /*
    NSLog(@"Receiving");
    while(1)
    {
        
        
        NSLog(@"Sent to");
        n=recvfrom(sockfd,recvline,10000,0,NULL,NULL);
        NSLog(@"Received stuff");
        
        //42 bytes is initially crap.
        
        recvline[n]=0;
        //fputs(recvline,stdout);
        
        NSLog(@"%d", n);
        
    }
    
    

    return;
     */
    
    
    /*if(select(sd1 + 1, &rset, NULL, NULL, NULL) < 0)
    {
        std_err();
    }
    */
    
    
    if(!buff) std_err();
    psdk    = buff + 7;
    gh      = (gh_t *)buff;
    selsock = 1 + ((sd1 > sd2) ? sd1 : sd2);
    psz     = sizeof(struct sockaddr_in);
    
    printf("- ready:\n");
    plain = 1;
    
    int tickcountn = 0;
    for(;;)
    {
        docopyme = [copyMe state];
        filterTheNetwork = [filterNetwork state];
        impersoinateNumber = [playerNumberImpersonate intValue];
        
        FD_ZERO(&rset);
        FD_SET(sd1, &rset);
        FD_SET(sd2, &rset);
        if(select(selsock, &rset, NULL, NULL, NULL) < 0) std_err();
        
        if(FD_ISSET(sd1, &rset))
        {
           
            RECV(sd1, peer1);
            
  
            BOOL sendToServer = YES;
            
            if(ntohs(gh->sign) == 0xfefd) {
                plain = 1;
            }
            if((ntohs(gh->sign) == 0xfefe) && (gh->type == 1) && (ntohs(gh->gs1) == 0) && (ntohs(gh->gs2) == 0))
            {
                genkeys("my client", hash1, hash2, NULL, NULL, basekey1, basekey2);
                plain = 1;
                
                
                //printf("\n- keys\n");
                //show_dump(hash1, 16, stdout);
                //show_dump(hash2, 16, stdout);
                show_dump(buff, len, stdout);
            }
            
            if(plain)
            {
                if((ntohs(gh->sign) == 0xfefe) && (gh->type == 3) && (ntohs(gh->gs1) == 1) && (ntohs(gh->gs2) == 1)) {
                    genkeys("client", hash1, hash1, psdk + 32, psdk + 32, deckey1, enckey1);
                    memcpy(psdk + 32, basekey2, 16);
                }
                
                //printf("\n- keys\n");
                //show_dump((u32)hash1 % 0xffff, 8, stdout);
                //show_dump(hash2, 8, stdout);

                //printf("\n- other\n");
                //decshow(buff, len, deckey1, enckey1, YES);
                show_dump(buff, len, stdout);
            }
            else
            {
                sendToServer = decshow(buff, len, deckey1, enckey2, YES, YES, tickcountn);
                
                //if (filterTheNetwork)
                //sendToServer=NO;
            }
            
            //if (sendToServer)
            //{
                
                SEND(sd2, peer2);
            //}
            
            tickcountn++;
        }
        else if(FD_ISSET(sd2, &rset))
        {
            if (showServer)

            RECV(sd2, peer2);
            
            if((ntohs(gh->sign) == 0xfefe) && (gh->type == 2) && (ntohs(gh->gs1) == 0) && (ntohs(gh->gs2) == 1)) {
                genkeys("my server", hash1, hash2, NULL, NULL, basekey1, basekey2);
                plain = 1;

                printf("\n- keys\n");
                ///show_dump(hash1, 16, stdout);
                ///show_dump(hash2, 16, stdout);
                
                if (showServer)
                show_dump(buff, len, stdout);
            }
            
            if(plain)
            {
                if((ntohs(gh->sign) == 0xfefe) && (gh->type == 4) && (ntohs(gh->gs1) == 1) && (ntohs(gh->gs2) == 2))
                {
                    genkeys("server", hash2, hash2, psdk, psdk, deckey2, enckey2);
                    memcpy(psdk, basekey1, 16);
                    plain = 0;
                    
                    
                }
                //printf("\n- keys\n");
                ///show_dump(hash1, 16, stdout);
                ///show_dump(hash2, 16, stdout);
                if (showServer)
                show_dump(buff, len, stdout);
            }
            else
            {
                decshow(buff, len, deckey2, enckey1, showServer, NO, tickcountn);
            }
            
            if (!useArchon)
                SEND(sd1, peer1);
        }
    }
    
    close(sd1);
    close(sd2);
    free(buff);
    
    
    
    /*
    int sockfd, clientfc,n;
    struct sockaddr_in servaddr,cliaddr;
    char sendline[1000];
    char recvline[1000];
    
    int length;
    
    unsigned char* s = "FE FE 01 00 00 00 00 6C 25 7B 49 7D 59 63 3C 23 72 56 58 21 5E 7D 69 2D 7C 76 27 67 24 35 28 61 76 40 4E 3B 28 63 3E 38";
    unsigned char *b = convert(s, &length);
    
    sockfd=socket(AF_INET,SOCK_DGRAM,0);
    clientfc=socket(AF_INET,SOCK_DGRAM,0);
    int fd, ret;
    
    //int flags = fcntl(sockfd, F_GETFL, 0);
    //fcntl(sockfd, F_SETFL, flags | O_NONBLOCK);
    
    bzero(&servaddr,sizeof(servaddr));
    servaddr.sin_family = AF_INET;
    servaddr.sin_addr.s_addr=inet_addr("162.217.250.28");
    servaddr.sin_port=htons(2300);
    
    bzero(&cliaddr,sizeof(servaddr));
    cliaddr.sin_family = AF_INET;
    cliaddr.sin_addr.s_addr=INADDR_ANY;
    cliaddr.sin_port=htons(2303);
    
    NSLog(@"Sending %s %d", b, length);
    
    ret = bind(clientfc, (struct sockaddr *)&cliaddr, sizeof(struct sockaddr));
    if ( ret == -1 )
        NSLog(@"Bind failure");
    
    NSLog(@"Receiving");
    while(1)
    {
        
        sendto(sockfd,b,length,0,(struct sockaddr *)&servaddr,sizeof(servaddr));
        NSLog(@"Sent to");
        n=recvfrom(sockfd,recvline,10000,0,NULL,NULL);
        NSLog(@"Received stuff");
        
        //42 bytes is initially crap.
        
        recvline[n]=0;
        //fputs(recvline,stdout);
        
        NSLog(@"%d", n);
        
    }
     */
    
    
}















/* w
*
*		Begin RenderView Functions
*
*/

-(IBAction)changeRenderer:(id)sender
{
    newR = (int)[sender indexOfItem:[sender selectedItem]];
}

-(IBAction)changeDrawObjects:(id)sender
{
    drawO = [sender state];
}




-(void)setPID:(int)my_pid
{
	my_pid_v = my_pid;
}

- (id)initWithFrame: (NSRect) frame
{
    USEDEBUG NSLog(@"Init render view");
    
    [self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
    renderV = self;
    USEDEBUG NSLog(@"Creating");
	// First, we must create an NSOpenGLPixelFormatAttribute
	NSOpenGLPixelFormat *nsglFormat;
	NSOpenGLPixelFormatAttribute attr[] =
	{
		NSOpenGLPFADoubleBuffer,
        NSOpenGLPFASupersample,
        NSOpenGLPFASampleBuffers, 1,
        NSOpenGLPFASamples, 4,
		NSOpenGLPFAAccelerated,
		NSOpenGLPFAColorSize, 
		BITS_PER_PIXEL,
		NSOpenGLPFADepthSize, 
		DEPTH_SIZE,
		0 
	};

    lightScene = false;
    [self setPostsFrameChangedNotifications: YES];
	
    USEDEBUG NSLog(@"More inits");
    
	// Next, we initialize the NSOpenGLPixelFormat itself
    nsglFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attr];
	
	// Check for errors in the creation of the NSOpenGLPixelFormat
    // If we could not create one, return nil (the OpenGL is not initialized, and
    // we should send an error message to the user at this point)
    if(!nsglFormat) { NSLog(@"Invalid format... terminating."); return nil; }
	USEDEBUG  NSLog(@"Still initing");
    
	// Now we create the the CocoaGL instance, using our initial frame and the NSOpenGLPixelFormat
    self = [super initWithFrame:frame pixelFormat:nsglFormat];
    [nsglFormat release];
	
	// If there was an error, we again should probably send an error message to the user
    if(!self) { NSLog(@"Self not created... terminating."); return nil; }
	USEDEBUG NSLog(@"Making contenxt");
	// Now we set this context to the current context (means that its now drawable)
    [[self openGLContext] makeCurrentContext];
	[[self openGLContext] setView:self];
    
	// Finally, we call the initGL method (no need to make this method too long or complex)
    [self initGL];
    USEDEBUG NSLog(@"Finished");
    return self;
    
}
- (void)initGL
{
    NSLog(@"Initing GL");
#ifndef MACVERSION
    GLenum error = glewInit();
    if (error != GLEW_OK)
    {
        
        printf ("An error occurred with glew %d: %s \n", error, (char *) glewGetErrorString(error));
    }
#endif
    
	
	glClearDepth(1.0f);
	glDepthFunc(GL_LEQUAL);
	//glEnable(GL_DEPTH_TEST);
	
   
	/*glHint(GL_POLYGON_SMOOTH_HINT,GL_NICEST);
    
    
    if (lightScene)
    {
        GLfloat ambientLight[]={0.2,0.2,0.2,1.0};    	             // set ambient light parameters
        glLightfv(GL_LIGHT0,GL_AMBIENT,ambientLight);
        
        GLfloat diffuseLight[]={1.0,1.0,1.0,1.0};    	             // set diffuse light parameters
        glLightfv(GL_LIGHT0,GL_DIFFUSE,diffuseLight);

        
        glEnable(GL_LIGHT0);                         	              // activate light0
        glEnable(GL_LIGHTING);                       	              // enable lighting
        glLightModelfv(GL_LIGHT_MODEL_AMBIENT, ambientLight); 	     // set light model
        glEnable(GL_COLOR_MATERIAL);                 	              // activate material
        glColorMaterial(GL_FRONT,GL_AMBIENT_AND_DIFFUSE);
        glEnable(GL_NORMALIZE);                      	              // normalize normal vectors
    }*/
	
	first = YES;

   
}
- (void)prepareOpenGL
{
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
	glClearDepth(1.0f);
	glDepthFunc(GL_LEQUAL);
	//glEnable(GL_DEPTH_TEST);
	
	glHint(GL_POLYGON_SMOOTH_HINT,GL_NICEST);
	
	first = YES;
	//NSLog(@"end initGL");
}

-(void)updateQuickLink:(NSTimer *)abc
{
    //NSLog(@"Update quicklink");
    /*
	[player_1 setTitle:[new_characters objectAtIndex:0]];
	[player_2 setTitle:[new_characters objectAtIndex:1]];
	[player_3 setTitle:[new_characters objectAtIndex:2]];
	[player_4 setTitle:[new_characters objectAtIndex:3]];
	[player_5 setTitle:[new_characters objectAtIndex:4]];
	[player_6 setTitle:[new_characters objectAtIndex:5]];
	[player_7 setTitle:[new_characters objectAtIndex:6]];
	[player_8 setTitle:[new_characters objectAtIndex:7]];
	[player_9 setTitle:[new_characters objectAtIndex:8]];
	[player_10 setTitle:[new_characters objectAtIndex:9]];
	[player_11 setTitle:[new_characters objectAtIndex:10]];
	[player_12 setTitle:[new_characters objectAtIndex:11]];
	[player_13 setTitle:[new_characters objectAtIndex:12]];
	[player_14 setTitle:[new_characters objectAtIndex:13]];
	[player_15 setTitle:[new_characters objectAtIndex:14]];
*/
}

#include <assert.h>
#include <CoreServices/CoreServices.h>

#include <unistd.h>

-(void)renderTimer:(id)object
{
	//NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	//NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
    
    //Calculate fps

    int averageFPS = 100;
    int fpsCap = 30;
    
    uint64_t        start;
    uint64_t        end;
    
    
    uint64_t        start2;
    uint64_t        end2;
    uint64_t        elapsed2;
    
    uint64_t        elapsed;

    
    uint64_t        required = ((1000000000.0)/ fpsCap); 
    
    while(1)
    {


        
        
            
            
            
            start = mach_absolute_time();
        
        
            //Cap FPS at 30
        
            int i;
            for (i=0; i < averageFPS; i++)
            {
                [self performSelectorOnMainThread:@selector(timerTick:) withObject:nil waitUntilDone:YES];
            }
        
            end = mach_absolute_time();
            elapsed = end - start;
        
            double fps = ((1000000000.0 * averageFPS)/ elapsed);
            [fpsText performSelectorOnMainThread:@selector(setStringValue:) withObject:[NSString stringWithFormat:@"FPS: %f", fps] waitUntilDone:YES];
            
        if (!performanceMode)
            break;
        //NSLog(@"%f", fps);
         
    }
    
	//[runLoop run];
	//[pool release];
}


-(IBAction)openSettingsPopup:(id)sender
{
    if (popover)
    {
        [popover close];
        popover = nil;
    }
    if (c)
    {
        [c release];
        c=nil;
        return;
    }
 
    
    c = [[NSViewController alloc] init];
    c.view = settingsView;
    
    [popover setContentViewController:c];
    [popover setContentSize:c.view.frame.size];
    
    
    [popover showRelativeToRect:NSMakeRect([sender frame].size.width/2-0.5, 20, 1, 1) ofView:sender preferredEdge:NSMaxYEdge];
}
-(IBAction)reloadBitmapsForMap:(id)sender
{
    
    if (performanceMode)
    {
        [performanceThread cancel];
        performanceMode = FALSE;
        
        [self resetTimerWithClassVariable];
    }
    else
    {
        
        if (NSRunAlertPanel(@"Are you sure you want to enter performance mode?", @"Performance mode will render frames as fast as it can. Presents a smooth visual performance but may stutter on large maps.", @"Cancel", @"Enter Performance Mode", nil) == NSOKButton)
        {
            
        }
        else
        {
            [drawTimer invalidate];
            [drawTimer release];
            drawTimer = nil;
            
            performanceMode = TRUE;
            
            performanceThread = [[NSThread alloc] initWithTarget:self selector:@selector(renderTimer:) object:nil]; //Create a new thread
            [performanceThread start];
        }
        
    }
    
    
    
    
    //[_texManager deleteAllTextures];
    //[mapBSP setActiveBsp:0];
    
    return;
    // First, we must create an NSOpenGLPixelFormatAttribute
	NSOpenGLPixelFormat *nsglFormat;
	NSOpenGLPixelFormatAttribute attr[] =
	{
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFAAccelerated,
		NSOpenGLPFAColorSize,
		BITS_PER_PIXEL,
		NSOpenGLPFADepthSize,
		DEPTH_SIZE,
		0
	};
    
    [self setPostsFrameChangedNotifications: YES];
	
	// Next, we initialize the NSOpenGLPixelFormat itself
    nsglFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attr];
	
	// Check for errors in the creation of the NSOpenGLPixelFormat
    // If we could not create one, return nil (the OpenGL is not initialized, and
    // we should send an error message to the user at this point)
    //if(!nsglFormat) { NSLog(@"Invalid format... terminating."); return nil; }
	
	// Now we create the the CocoaGL instance, using our initial frame and the NSOpenGLPixelFormat
    //self = [super initWithFrame:frame pixelFormat:nsglFormat];
    //[nsglFormat release];
	
	// If there was an error, we again should probably send an error message to the user
    //if(!self) { NSLog(@"Self not created... terminating."); return nil; }
	
	// Now we set this context to the current context (means that its now drawable)
    [[self openGLContext] makeCurrentContext];
	
	// Finally, we call the initGL method (no need to make this method too long or complex)
    [self initGL];
    //glFlush();
}
- (void)awakeFromNib
{
    _mode = select;
    [self unpressButtons];
    [selectMode setState:NSOnState];
    
    
    
    didReceive=0;
    lastHostLength=0;
    lastHostPacket = malloc(10000);
    message_data=malloc(10000);
    NSLog(@"Checking mac render view");
#ifndef MACVERSION
    [render_SP setState:0];
    [pixelPaint setState:1];
#endif
    
     needsReshape = YES;
    
    /*
#ifndef MACVERSION
    return;
#endif
    */
	//[[self window] setLevel:100];
	
	int i;
	for (i = 0; i < 150; i++)
	{
		playercoords[i] = 0.0;
	}
	
	
	
	is_css = YES;
	//isfull = YES;
	selee = [[Selection alloc] initWithContentRect:NSMakeRect(0, 0, 0, 0) styleMask:NSBorderlessWindowMask backing:nil defer:YES];
	[selee setReleasedWhenClosed:NO];
	
	[spawne setFrame:NSMakeRect([[NSScreen mainScreen] frame].size.width - [spawne frame].size.width,[[NSScreen mainScreen] frame].size.height - [spawne frame].size.height - 44, [spawne frame].size.width, [spawne frame].size.height) display:YES];
	[spawnc setFrame:NSMakeRect([[NSScreen mainScreen] frame].size.width - [spawnc frame].size.width,[[NSScreen mainScreen] frame].size.height - [spawne frame].size.height - [spawnc frame].size.height - 44 - 8, [spawnc frame].size.width, [spawnc frame].size.height) display:YES];
	//[render setFrame:NSMakeRect([[NSScreen mainScreen] frame].size.width - [render frame].size.width,[[NSScreen mainScreen] frame].size.height - [spawne frame].size.height - [spawnc frame].size.height - [render frame].size.height - 44 - 16, [render frame].size.width, [render frame].size.height) display:YES];
	//[camera setFrame:NSMakeRect([[NSScreen mainScreen] frame].size.width - [camera frame].size.width,[[NSScreen mainScreen] frame].size.height - [spawne frame].size.height - [spawnc frame].size.height - [render frame].size.height - [camera frame].size.height - 44 - 24, [camera frame].size.width, [camera frame].size.height) display:YES];
	
	[select_panel setFrame:NSMakeRect([[NSScreen mainScreen] frame].size.width - [select_panel frame].size.width,[[NSScreen mainScreen] frame].size.height - [spawne frame].size.height - [spawnc frame].size.height - [select_panel frame].size.height - 24 - 32, [select_panel frame].size.width, [select_panel frame].size.height) display:YES];
	
	//[[self window] setFrame:NSMakeRect(0, 0, [[NSScreen mainScreen] frame].size.width, [[NSScreen mainScreen] frame].size.height) display:YES];
	
	_fps = 30;
	drawTimer = [[NSTimer scheduledTimerWithTimeInterval:(1.0/_fps) target:self selector:@selector(timerTick:) userInfo:nil repeats:YES] retain];
	
    //NSThread* timerThread = [[NSThread alloc] initWithTarget:self selector:@selector(renderTimer:) object:nil]; //Create a new thread
	//[timerThread start];

	prefs = [NSUserDefaults standardUserDefaults];
	[self loadPrefs];
	
	shouldDraw = NO;
	
	_camera = [[Camera alloc] init];
	acceleration = 0;
	cameraMoveSpeed = 0.5;
	maxRenderDistance = 3000000.0f;
	
	selectDistance = 300.0f;
	rendDistance = 3000000.0f;
	
	meshColor.blue = 1.0;
	meshColor.green = 0.1;
	meshColor.red = 0.1;
	meshColor.color_count = 0;
	
	color_index = alphaIndex;
    drawO = true;
    
#ifdef MACVERSION
    newR = 3;
#else
    newR = 3;
#endif
    
    [renderEngine selectItemAtIndex:newR];
	
	currentRenderStyle = textured_tris;
	
	_LOD = 4;
	
	_selectType = 0;
	s_acceleration = 1.0f;
	
	[fpsText setFloatValue:50.0];
	[bspNumbersButton removeAllItems];
	
	//_mode = rotate_camera;
	//[moveCameraMode setState:NSOnState];
	
	[_spawnEditor setUpdateDelegate:self];
	
	selections = [[NSMutableArray alloc] initWithCapacity:2000]; // Default it at 300, but possible to expand if needed lol.
	[selections retain];
	
	//selections = [[NSMutableArray alloc] initWithCapacity:1000];
	
	_lineWidth = 1.5f;
	

	

	//NSTimer *playertimer = [[NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(updatePlayerPosition:) userInfo:nil repeats:YES] retain];
	//[[NSRunLoop currentRunLoop] addTimer:playertimer forMode:(NSString *)kCFRunLoopCommonModes];
	

	//[NSApp setDelegate:self];
	
	
	[NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(updateQuickLink:) userInfo:nil repeats:YES];

}

-(void)setTermination:(NSTimer*)ti
{
	
	
}

-(IBAction)FocusOnPlayer:(id)sender
{
    NSLog(@"Focus on plaer");
	int i;
	for (i = 0; i < 16; i++)
	{
		if ([[new_characters objectAtIndex:i] isEqualToString:[sender title]])
		{
			
			float x = playercoords[(i * 8) + 0];
			float y = playercoords[(i * 8) + 1];
			float z = playercoords[(i * 8) + 2];
			
			if (x != 0)
			{
			
			//Focus ont he character
			[_camera PositionCamera:[_camera position][0] positionY:[_camera position][1] positionZ:[_camera position][2] 
							  viewX:x viewY:y viewZ:z
						  upVectorX:0.0f upVectorY:0.0f upVectorZ:1.0f];
			
			[self deselectAllObjects];
			
			//Select the player
			playercoords[(i * 8) + 4] = 1.0;
				
			}
			
			break;
		}
	}
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    
    NSLog(@"Application is terminating why");
    
		//Save main screen window
	if ([[[NSUserDefaults standardUserDefaults]objectForKey:@"automatic"] isEqualToString:@"NO"])
	{
	}
	else
	{
		
	

		NSRect main = [[self window] frame];
		
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		[userDefaults setObject:[NSString stringWithFormat:@"%f, %f, %f, %f", main.origin.x, main.origin.y, main.size.width, main.size.height] forKey:@"windowsize"];
		[userDefaults synchronize];
		
		
		float* pos = [self getCameraPos];
		float* view = [self getCameraView];
		
		[[NSString stringWithFormat:@"%@, %f, %f, %f, %f, %f, %f", [opened stringValue], pos[0],pos[1],pos[2], view[0],view[1],view[2]]  writeToFile:@"/tmp/starlight.auto" atomically:YES];
		
	}
}





- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard *paste = [sender draggingPasteboard];
    //gets the dragging-specific pasteboard from the sender
    NSArray *types = [NSArray arrayWithObjects:NSTIFFPboardType,
                      NSFilenamesPboardType, nil];
    //a list of types that we can accept
    NSString *desiredType = [paste availableTypeFromArray:types];
    NSData *carriedData = [paste dataForType:desiredType];
    
    if (nil == carriedData)
    {
        //the operation failed for some reason
        NSRunAlertPanel(@"Paste Error", @"Sorry, but the past operation failed",
                        nil, nil, nil);
        return NO;
    }
    else
    {
        //the pasteboard was able to give us some meaningful data
        if ([desiredType isEqualToString:NSTIFFPboardType])
        {
            NSImage *newImage = [[NSImage alloc] initWithData:carriedData];
			
            [newImage release];
        }
        else if ([desiredType isEqualToString:NSFilenamesPboardType])
        {
            NSArray *fileArray = [paste propertyListForType:@"NSFilenamesPboardType"];
            NSString *path = [fileArray objectAtIndex:0];
            
            NSPoint location = [sender draggingLocation];
			location = [[[self window] contentView] convertPoint:location toView:self];
			
            NSRange r = [path rangeOfString:@"/tmp/Archon/"];
            if (r.location != NSNotFound)
            {
                NSLog(@"Special drop");
                
                //What type of file is it?
                NSRange scen = [path rangeOfString:@"/tmp/Archon/scen"];
                NSRange vehi = [path rangeOfString:@"/tmp/Archon/vehi"];
                NSRange mach = [path rangeOfString:@"/tmp/Archon/mach"];
                

                //Are we interescting the bsp anywhere?
                int selection = [self tryBSPSelection:location shiftDown:NO width:1 height:1];
                if (selection != -1)
                {
                    SUBMESH_INFO *pMesha;
                    pMesha = [mapBSP GetActiveBspPCSubmesh:selection];
                    
                    if (!pMesha)
                        return NO;
                    if (pMesha->DefaultLightmapIndex == -1)
                        return NO;
                    if (pMesha->LightmapIndex == -1)
                        return NO;
                    if (pMesha->DefaultBitmapIndex == -1)
                        return NO;
                    
                    //insX,insY,insZ
                    float *coord = malloc(sizeof(float)*6);
                    coord[0] = insX;
                    coord[1] = insY;
                    coord[2] = insZ;
                    float *gg = (float*)[self coordtoGround:coord];
        
                    if (scen.location != NSNotFound)
                    {
                        //Create a new scenery at the location. What type?
                        NSLog(@"NEW SCENERY %@", [[path lastPathComponent] stringByDeletingPathExtension]);
                    }
                    else if (vehi.location != NSNotFound)
                    {
                        //Create a new scenery at the location. What type?
                        NSLog(@"NEW VEHICLE %@", [[path lastPathComponent] stringByDeletingPathExtension]);
                        int newSpawnCount = [_scenario createVehicle:gg];
                        
                        int m;
                        for (m=0; m < [_scenario vehi_ref_count]; m++)
                        {
                            NSString *name = [[_mapfile tagForId:[_scenario vehi_references][m].vehi_ref.TagId] tagName];
                            if ([name isEqualToString:[[path lastPathComponent] stringByDeletingPathExtension]])
                            {
                                [_scenario vehi_spawns][newSpawnCount].modelIdent = [_scenario baseModelIdent:[_scenario vehi_references][m].vehi_ref.TagId];
                                
                            }
                        }
                        
                    }
                    else if (mach.location != NSNotFound)
                    {
                        //Create a new scenery at the location. What type?
                        NSLog(@"NEW MACHINE %@", [[path lastPathComponent] stringByDeletingPathExtension]);
                    }
                    
                }
                
                
            }
        }
    }
    [self setNeedsDisplay:YES];    //redraw us with the new image
    return YES;
}



//Image dragging
//DRAG OPERATIONS. THIS ENABLES SOMEBODY TO SIMPLE DRAG AN IMAGE FROM THE FINDER ONTO OUR DOCUMENT. IT ALSO ALLOWS STAMPS TO WORK :)
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    NSLog(@"Drag enter");
    if ((NSDragOperationGeneric & [sender draggingSourceOperationMask]) == NSDragOperationGeneric)
    {
        //this means that the sender is offering the type of operation we want
        //return that we want the NSDragOperationGeneric operation that they
        //are offering
        return NSDragOperationGeneric;
    }
    else
    {
        //since they aren't offering the type of operation we want, we have
        //to tell them we aren't interested
        return NSDragOperationNone;
    }
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
    if ((NSDragOperationGeneric & [sender draggingSourceOperationMask]) == NSDragOperationGeneric)
    {
        //this means that the sender is offering the type of operation we want
        //return that we want the NSDragOperationGeneric operation that they
        //are offering
        return NSDragOperationGeneric;
    }
    else
    {
        //since they aren't offering the type of operation we want, we have
        //to tell them we aren't interested
        return NSDragOperationNone;
    }
}






- (void)reshape
{
    //Do we need a reshape?
    if ([[[self window] contentView] bounds].size.width != lastRectShape.size.width || [[[self window] contentView] bounds].size.height != lastRectShape.size.height)
    {
        needsReshape=YES;
    }
    lastRectShape = [[[self window] contentView] bounds];
    
    if (!needsReshape)
        return;
    needsReshape = NO;
    
    //NSLog(@"RESHAPING");
    
    //[[self window] setFrame:[[self window] frame] display:NO];
    [self setFrame:[[[self window] contentView] bounds]];
    [[self openGLContext] update];
    
    //[self setFrame:[[[self window] contentView] bounds]];
    
   // [self setFrame:[[[self window] contentView] bounds]];
	NSSize sceneBounds = [self frame].size;
	glViewport(0,0,sceneBounds.width,sceneBounds.height);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	gluPerspective(45.0f,
					(sceneBounds.width / sceneBounds.height),
					0.1f,
					4000000.0f);
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
}

- (BOOL)acceptsFirstResponder
{ 
	return YES; 
}

- (IBAction)openSEL:(id)sender
{
	//[select center];
	[select orderFront:nil];
}

- (IBAction)openCamera:(id)sender
{
	[self updateQuickLink:nil];
	
	//[camera center];
	[camera orderFront:nil];
}

- (IBAction)openRender:(id)sender
{
	//[render center];
	[render orderFront:nil];
	
}

- (IBAction)openSXpawn:(id)sender
{
	//[spawne center];
	[spawne orderFront:nil];
}

- (IBAction)openSpawn:(id)sender
{
	//[spawnc center];
	[spawnc orderFront:nil];
}

- (IBAction)openMach:(id)sender
{
	//[machine center];
	[machine orderFront:nil];
}

- (void)scrollWheel:(NSEvent*)theEvent
{
    
#ifdef MACVERSION
    if ([s_xRotation floatValue]+[theEvent scrollingDeltaY] < 0)
    {
        [s_xRotation setFloatValue:360+[s_xRotation floatValue]+[theEvent scrollingDeltaY]];
    }
    else if ([s_xRotation floatValue]+[theEvent scrollingDeltaY] > 360)
    {
        [s_xRotation setFloatValue:[s_xRotation floatValue]+[theEvent scrollingDeltaY]-360];
    }
    else
        [s_xRotation setFloatValue:[s_xRotation floatValue]+[theEvent scrollingDeltaY]];
#endif
    [self rotateFocusedItem:[s_xRotation floatValue] y:[s_yRotation floatValue] z:[s_zRotation floatValue]];
    
    //NSLog(@"test");
}

int wKey = 0;
int aKey = 0;
int sKey = 0;
int dKey = 0;
int cKey = 0;
int spaceKey = 0;

- (void)keyDown:(NSEvent *)theEvent
{
    NSString *characters = [theEvent characters];
    if ([characters length]<=0)
    {
        //NSLog(@"No characters!");
    }
    
    int k = [theEvent keyCode];

	unichar character = [characters characterAtIndex:0];
	//NSLog(@"%x", character);
    //NSLog(@"DOWN: %d %x", k, character);
	if (character == NSDeleteCharacter || character == NSBackspaceCharacter)
	{
		//Delete the current shape.
		[self buttonPressed:b_deleteSelected];
		
	}
	else
    {
		
	

	switch (character)
	{
		case 'w':
			move_keys_down[0].direction = forward;
			move_keys_down[0].isDown = YES;
            
            wKey = k;
			break;
		case '1':
			[self buttonPressed:translateMode];
			break;
		case '2':
			[self buttonPressed:selectMode];
			break;
		case '3':
			[self buttonPressed:dirtMode];
			break;
		case '4':
			[self buttonPressed:grassMode];
            break;
        case '5':
			[self buttonPressed:eyedropperMode];
            break;
        case '6':
			[self buttonPressed:lightmapMode];
            break;
		case 's':
			move_keys_down[1].direction = back;
			move_keys_down[1].isDown = YES;
            
            sKey = k;
			break;
		case 'a':
			move_keys_down[2].direction = left;
			move_keys_down[2].isDown = YES;
            
            aKey = k;
			break;
		case 'd':
			move_keys_down[3].direction = right;
			move_keys_down[3].isDown = YES;
            
            dKey = k;
			break;
        case 'm':
        {
            if (move_keys_down[3].isDown)
            {
                [debugWindow center];
                [debugWindow makeKeyAndOrderFront:self];
            }
            break;
        }
		case ' ':
			move_keys_down[4].direction = up;
			move_keys_down[4].isDown = YES;
            
            spaceKey = k;
			break;
		case 'c':
			move_keys_down[5].direction = down;
			move_keys_down[5].isDown = YES;
            
            cKey = k;
			break;
		case 0xF700: // Forward Key
			if (_mode == rotate_camera)
				[_camera MoveCamera:0.1];
			if (_mode == translate)
			{
				NSPoint fakeDownPoint = prevDown;
				fakeDownPoint.y += 1;
				[self performTranslation:fakeDownPoint zEdit:FALSE];
			}
			break;
		case 0xF701: // Back Key
			if (_mode == rotate_camera)
				[_camera MoveCamera:-0.1];
			if (_mode == translate)
			{
				NSPoint fakeDownPoint = prevDown;
				fakeDownPoint.y -= 1;
				[self performTranslation:fakeDownPoint zEdit:FALSE];
			}
			break;
		case 0xF702: // Left Key
			if (_mode == rotate_camera)
				[_camera StrafeCamera:-0.1];
			if (_mode == translate)
			{
				NSPoint fakeDownPoint = prevDown;
				fakeDownPoint.x -= 1;
				[self performTranslation:fakeDownPoint zEdit:FALSE];
			}
			break;
		case 0xF703: // Right Key
			if (_mode == rotate_camera)
				[_camera StrafeCamera:0.1f];
			if (_mode == translate)
			{
				NSPoint fakeDownPoint = prevDown;
				fakeDownPoint.x += 1;
				[self performTranslation:fakeDownPoint zEdit:FALSE];
			}
			break;
		case 0x2E: // ? key
			if (_mode == rotate_camera)
				[_camera LevitateCamera:0.1f];
			if (_mode == translate)
			{
				NSPoint fakeDownPoint = prevDown;
				fakeDownPoint.y += 1;
				[self performTranslation:fakeDownPoint zEdit:TRUE];
			}
			break;
		case 0x2C: // > key
			if (_mode == rotate_camera)
				[_camera LevitateCamera:-0.1f];
			if (_mode == translate)
			{
				NSPoint fakeDownPoint = prevDown;
				fakeDownPoint.y -= 1;
				[self performTranslation:fakeDownPoint zEdit:TRUE];
			}
			break;
		case 'l':
			NSLog(@"Camera z coord: %f", [_camera position][2]);
			break;
	}
		
	}
}

- (void)keyUp:(NSEvent *)event
{
#ifdef MACVERSION
	unichar character = [[event characters] characterAtIndex:0];
	switch (character)
	{
		case 'w':
			move_keys_down[0].isDown = NO;
			break;
		case 's':
			move_keys_down[1].isDown = NO;
			break;
		case 'a':
			move_keys_down[2].isDown = NO;
			break;
		case 'd':
			move_keys_down[3].isDown = NO;
			break;
		case ' ':
			move_keys_down[4].isDown = NO;
			break;
		case 'c':
			move_keys_down[5].isDown = NO;
			break;
	}
#else
    NSString *characters = [event characters];
    if ([characters length]<=0)
    {
        //NSLog(@"No characters!");
    }
    
    int k = [event keyCode];
    //NSLog(@"UP %d %@", k, characters);
    
    

        if (k == wKey) //W
            move_keys_down[0].isDown = NO;
        else if (k == sKey) //S
            move_keys_down[1].isDown = NO;
        else if (k == aKey) //A
            move_keys_down[2].isDown = NO;
        else if (k == dKey) //D
            move_keys_down[3].isDown = NO;
        else if (k == spaceKey) //Space
            move_keys_down[4].isDown = NO;
        else if (k == cKey) //C
            move_keys_down[5].isDown = NO;
    
/*
        move_keys_down[0].isDown = NO;
        move_keys_down[1].isDown = NO;
        move_keys_down[2].isDown = NO;
        move_keys_down[3].isDown = NO;
        move_keys_down[4].isDown = NO;
        move_keys_down[5].isDown = NO;
*/
#endif
}
- (void)mouseUp:(NSEvent *)theEvent
{
    
}
- (void)mouseDown:(NSEvent *)event
{

    
    //NSLog(@"Mouse down %d %d %d %d", (([event modifierFlags] & NSControlKeyMask)!=0), (([event modifierFlags] & NSCommandKeyMask)!=0), (([event modifierFlags] & NSShiftKeyMask)!=0), (([event modifierFlags] & NSAlternateKeyMask)!=0));
    
    duplicatedAlready = NO;
    
	
	
	NSPoint downPoint = [event locationInWindow];
	NSPoint local_point = [self convertPoint:downPoint fromView:[[self window] contentView]];
	prevDown = [NSEvent mouseLocation];
	
	if (_mode == select && _mapfile)
	{
		
	
			
            event = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
            NSPoint graphicOrigin = [NSEvent mouseLocation];
                
            NSPoint en = graphicOrigin;
            
            
            CGFloat w = 0.0;
            CGFloat h = 0.0;
        
            if ([msel state])
            {
            while ([event type]!=NSLeftMouseUp)
            {
                
                event = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
                NSPoint graphicOrigin = [NSEvent mouseLocation];

                
                if (en.x < graphicOrigin.x)
                {
                    w = graphicOrigin.x - en.x;
                    
                    if (en.y < graphicOrigin.y)
                    {
                        h = graphicOrigin.y - en.y;
                        
                        [selee setFrame:NSMakeRect(en.x, en.y, w, h) display:YES];
                    }
                    else
                    {
                        h =  en.y - graphicOrigin.y;
                        
                        [selee setFrame:NSMakeRect(en.x, graphicOrigin.y, w, h) display:YES];
                    }
                    
                }
                else
                {
                    
                    w = en.x - graphicOrigin.x;
                    
                    if (en.y < graphicOrigin.y)
                    {
                        h = graphicOrigin.y - en.y;
                        
                        [selee setFrame:NSMakeRect(graphicOrigin.x, en.y, w, h) display:YES];
                    }
                    else
                    {
                        
                        h =  en.y - graphicOrigin.y;
                        
                        [selee setFrame:NSMakeRect(graphicOrigin.x, graphicOrigin.y, w, h) display:YES];
                    }
                    
                }
                
                [selee orderFront:nil];
                
            }
            }
        
            int tx = [selee frame].origin.x;
            int ty = [selee frame].origin.y;
                
            int wx =   [[self window] frame].origin.x;
            int wy =  [[self window] frame].origin.y;

            tx -= wx;
            ty -= wy;
        
            if (w < 1.0f)
            {
                w = 1.0f;
                
                tx = local_point.x;
                ty = local_point.y;
            }
            
            if (h < 1.0f)
            {
                h = 1.0f;
                
                tx = local_point.x;
                ty = local_point.y;
            }
            
            
            NSPoint sp = NSMakePoint(tx, ty);
        
       /// NSLog(@"Trying selection %f %f %f %f", sp.x, sp.y, w, h);
            [self trySelection:sp shiftDown:(([event modifierFlags] & NSShiftKeyMask) != 0) width:[NSNumber numberWithFloat:w] height:[NSNumber numberWithFloat:h]];
       // NSLog(@"Finished trying");
        
            [selee close];
			
		

		//[sel release];
	}
    
    
		
}




-(IBAction)doubleLightmaps:(id)sender
{
    
#ifdef MACVERSION
    if (NSRunAlertPanel(@"This operation will double the size of lightmaps (and immediately write to the map). You will not see benefits unless you manually edit the lightmaps afterwards.", @"Please make sure you backup your map as this operation cannot be undone.", @"Cancel", @"OK", nil) == NSOKButton)
    {
        return;
    }
#else
    if (NSRunAlertPanel(@"Warning", @"This operation will double the size of lightmaps (and immediately write to the map). You will not see benefits unless you manually edit the lightmaps afterwards. Please make sure you backup your map as this operation cannot be undone.", @"Cancel", @"OK", nil) == NSOKButton)
    {
        return;
    }
#endif
    
    
    
        NSLog(@"Doubling lightmap");
        float scalingFactor = 2;
        
        //Ok, we need to encode the new lightmaps
        unsigned int mesh_count;
        int m, i;
        
        SUBMESH_INFO *pMeshaa;
        mesh_count = [mapBSP GetActiveBspSubmeshCount];
        
        for (m = 0; m < mesh_count; m++)
        {
            pMeshaa = [mapBSP GetActiveBspPCSubmesh:m];
            
            BitmapTag *tmpBitm = [_texManager bitmapForIdent:pMeshaa->DefaultLightmapIndex];
            [tmpBitm resetDouble:pMeshaa->LightmapIndex];
        }
        
        //Update the bitmaps
        for (m = 0; m < mesh_count; m++)
        {
            pMeshaa = [mapBSP GetActiveBspPCSubmesh:m];
            
            BitmapTag *tmpBitm = [_texManager bitmapForIdent:pMeshaa->DefaultLightmapIndex];
            if ([tmpBitm alreadyDouble:pMeshaa->LightmapIndex])
                continue;
            
            int index = pMeshaa->LightmapIndex;
            if (pMeshaa->LightmapIndex == -1)
                continue;
            
            if (!tmpBitm)
                continue;
            
            unsigned char *pixels = [tmpBitm imagePixelsForImageIndex:index];
            NSSize size = NSMakeSize([tmpBitm textureSizeForImageIndex:index].width, [tmpBitm textureSizeForImageIndex:index].height);
            NSSize newsize = NSMakeSize(([tmpBitm textureSizeForImageIndex:index].width*scalingFactor), ([tmpBitm textureSizeForImageIndex:index].height*scalingFactor));

            NSBitmapImageRep *imgRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&pixels
                                                                               pixelsWide:size.width
                                                                               pixelsHigh:size.height
                                                                            bitsPerSample:8
                                                                          samplesPerPixel:4
                                                                                 hasAlpha:true
                                                                                 isPlanar:false
                                                                           colorSpaceName:NSDeviceRGBColorSpace
                                                                              bytesPerRow:0
                                                                             bitsPerPixel:0];
            
            imgRep = [imgRep resizeBitmapImageRepToSize:newsize];
            [tmpBitm doubleImage:index withFactor:[NSNumber numberWithFloat:scalingFactor]];
            [_texManager updateBitmapDataWithIdent:pMeshaa->DefaultLightmapIndex data:[imgRep bitmapData] index:index];
            [tmpBitm forceImageWriteToMap:index];
            free(pixels);
            [imgRep release];
            
            
            if (pMeshaa->DefaultLightmapIndex != -1 && pMeshaa->LightmapIndex != -1)
                [_texManager refreshTextureOfIdent:pMeshaa->DefaultLightmapIndex index:index];
            
        }
    
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	NSPoint dragPoint = [NSEvent mouseLocation];
	//if (_mode == rotate_camera)
	//	[_camera HandleMouseMove:(dragPoint.x - prevDown.x) dy:(dragPoint.y - prevDown.y)];
	if (_mode == translate)
	{
        if ([theEvent modifierFlags] & NSShiftKeyMask)
        {
            if (!duplicatedAlready)
            {
                
                //if (dup >= [duplicate_amount doubleValue])
                //{
                    unsigned int type, index, nameLookup;
                    
                    if (!selections || [selections count] == 0)
                        return;
                    
                    nameLookup = [[selections objectAtIndex:0] unsignedIntValue];
                    type = (unsigned int)(nameLookup / MAX_SCENARIO_OBJECTS);
                    index = (unsigned int)(nameLookup % MAX_SCENARIO_OBJECTS);

                //[selections removeAllObjects];
                
                long selection = [_scenario duplicateScenarioObject:type index:index];
                
                NSLog(@"%ld", selection);
                //[selections addObject:[NSNumber numberWithLong:selection]];
                //_selectFocus = [[selections objectAtIndex:0] longValue];
                
                
                //[self processSelection:selection];
                 
                    //[selections removeAllObjects];
                
                    //[selections addObject:[NSNumber numberWithLong:[_scenario duplicateScenarioObject:type index:index]]];
                    //_selectFocus = [[selections objectAtIndex:0] longValue];
                
                    //dup=0;
                //}
                //else
                //{
                    //dup++;
                //}
                
                duplicatedAlready = YES;

            }
        }
        
        //[self performTranslation:dragPoint zEdit:(([theEvent modifierFlags] & NSControlKeyMask) != 0)];
        
#ifdef MACVERSION
		[self performTranslation:dragPoint zEdit:(([theEvent modifierFlags] & NSControlKeyMask) != 0)];
#else
        [self performTranslation:dragPoint zEdit:(([theEvent modifierFlags] & NSCommandKeyMask) != 0)];
#endif
        
        // Now lets apply the transformations.
        unsigned int	i,
        nameLookup,
        type,
        index;
        for (i = 0; i < [selections count]; i++)
        {
            nameLookup = [[selections objectAtIndex:i] unsignedIntValue];
            type = (unsigned int)(nameLookup / MAX_SCENARIO_OBJECTS);
            index = (unsigned int)(nameLookup % MAX_SCENARIO_OBJECTS);
            
            switch (type)
            {
                case s_scenery:
                    [self setPositionSliders:[NSNumber numberWithFloat:[_scenario scen_spawns][index].coord[0]] y:[NSNumber numberWithFloat:[_scenario scen_spawns][index].coord[1]] z:[NSNumber numberWithFloat:[_scenario scen_spawns][index].coord[2]]];
                    break;
                case s_vehicle:
                    [self setPositionSliders:[NSNumber numberWithFloat:[_scenario vehi_spawns][index].coord[0]] y:[NSNumber numberWithFloat:[_scenario vehi_spawns][index].coord[1]] z:[NSNumber numberWithFloat:[_scenario vehi_spawns][index].coord[2]]];
                    break;
                case s_playerspawn:
                {
                    /*float *gg = (float*)[self coordtoGround:(float*)[_scenario spawns][index].coord];
                    if (gg[0] != 0.0)
                    {
                        [_scenario spawns][index].coord[0] = gg[0];
                        [_scenario spawns][index].coord[1] = gg[1];
                        [_scenario spawns][index].coord[2] = gg[2];
                    }*/
                    
                    [self setPositionSliders:[NSNumber numberWithFloat:[_scenario spawns][index].coord[0]] y:[NSNumber numberWithFloat:[_scenario spawns][index].coord[1]] z:[NSNumber numberWithFloat:[_scenario spawns][index].coord[2]]];
                    break;
                }
                case s_netgame:
                    [self setPositionSliders:[NSNumber numberWithFloat:[_scenario netgame_flags][index].coord[0]] y:[NSNumber numberWithFloat:[_scenario netgame_flags][index].coord[1]] z:[NSNumber numberWithFloat:[_scenario netgame_flags][index].coord[2]]];
                    break;
                case s_item:
                    [self setPositionSliders:[NSNumber numberWithFloat:[_scenario item_spawns][index].coord[0]] y:[NSNumber numberWithFloat:[_scenario item_spawns][index].coord[1]] z:[NSNumber numberWithFloat:[_scenario item_spawns][index].coord[2]]];
                    break;
                case s_machine:
                    [self setPositionSliders:[NSNumber numberWithFloat:[_scenario mach_spawns][index].coord[0]] y:[NSNumber numberWithFloat:[_scenario mach_spawns][index].coord[1]] z:[NSNumber numberWithFloat:[_scenario mach_spawns][index].coord[2]]];
                    break;
            }
        }
        
        
	}
	else if (_mode == rotate)
	{
        #ifdef MACVERSION
		[self performRotation:dragPoint zEdit:(([theEvent modifierFlags] & NSControlKeyMask) != 0)];
#else
        [self performRotation:dragPoint zEdit:(([theEvent modifierFlags] & NSCommandKeyMask) != 0)];

#endif
	}
    else
    {
        bool PAINT = TRUE;
        
        if ([dirtMode state]||[grassMode state]||[lightmapMode state]||[eyedropperMode state])
        {
            
            NSPoint downPoint = [theEvent locationInWindow];
            NSPoint local_point = [self convertPoint:downPoint fromView:[[self window] contentView]];
            
            NSPoint sp = NSMakePoint(local_point.x, local_point.y);
            
            
            //Are we interescting the bsp anywhere?
            int selection = [self tryBSPSelection:sp shiftDown:NO width:1 height:1];
            

          
            if (selection != -1)
            {
                //Find the image files associated with this
                SUBMESH_INFO *pMesha;
                pMesha = [mapBSP GetActiveBspPCSubmesh:selection];
                
                if (!pMesha)
                    return;
                if (pMesha->DefaultLightmapIndex == -1)
                    return;
                if (pMesha->LightmapIndex == -1)
                    return;
                if (pMesha->DefaultBitmapIndex == -1)
                    return;
                
                
                
               // NSLog(@"%d %d %d %d", selection, pMesha->DefaultLightmapIndex, pMesha->LightmapIndex, pMesha->DefaultBitmapIndex );

                
                //Texture ident
                //NSString *name = [_texManager nameForImage:pMesha->baseMap];
                //NSString *file = [NSString stringWithFormat:@"%@/Desktop/Images/%@_original.tiff", NSHomeDirectory(), name];
                //NSString *alphaim = [NSString stringWithFormat:@"%@/Desktop/Images/%@_alpha.tiff", NSHomeDirectory(), name];
    
                //Where is this texture MAPPED to this image? Like, where does the triangle map to? We need to find the UV coordinates for each vertex.
                //pindex = selectedPIndex;
              
                float *vertex1 =  pMesha->pVert[pMesha->pIndex[selectedPIndex].tri_ind[0]].uv;
                float *vertex2 =  pMesha->pVert[pMesha->pIndex[selectedPIndex].tri_ind[1]].uv;
                float *vertex3 =  pMesha->pVert[pMesha->pIndex[selectedPIndex].tri_ind[2]].uv;
                
                float *lmvertex1 =  pMesha->pLightmapVert[pMesha->pIndex[selectedPIndex].tri_ind[0]].uv;
                float *lmvertex2 =  pMesha->pLightmapVert[pMesha->pIndex[selectedPIndex].tri_ind[1]].uv;
                float *lmvertex3 =  pMesha->pLightmapVert[pMesha->pIndex[selectedPIndex].tri_ind[2]].uv;
                
                float x = uva1*vertex1[0] + uva2*vertex2[0] + uva3*vertex3[0];
                float y = uva1*vertex1[1] + uva2*vertex2[1] + uva3*vertex3[1];
                
                //NSLog(@"%f %f | %f %f %f | %f %f %f %f %f %f", x, y, uva1, uva2, uva3, vertex1[0], vertex1[1], vertex2[0], vertex2[1], vertex3[0], vertex3[1]);
                
                int index = 0;
                BitmapTag *tmpBitm;
                
                if ([lightmapMode state])
                {
                    index = pMesha->LightmapIndex;
                    
                    tmpBitm = [_texManager bitmapWithIdent:pMesha->DefaultLightmapIndex];
                    
                     x = uva1*lmvertex1[0] + uva2*lmvertex2[0] + uva3*lmvertex3[0];
                     y = uva1*lmvertex1[1] + uva2*lmvertex2[1] + uva3*lmvertex3[1];
                    
                }
                else
                    tmpBitm = [_texManager bitmapWithIdent:pMesha->baseMap];
                
                //Create an image from the bitmap
                
                if (!tmpBitm)
                    return;
                
                
                unsigned char *pixels = [tmpBitm imagePixelsForImageIndex:index];
                
                
                NSSize size = NSMakeSize([tmpBitm textureSizeForImageIndex:index].width, [tmpBitm textureSizeForImageIndex:index].height);
                
                unsigned char *pixels_alpha = malloc(size.width * size.height * 4);
                
                
                
                NSBitmapImageRep *imgRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&pixels
                                                                                   pixelsWide:size.width
                                                                                   pixelsHigh:size.height
                                                                                bitsPerSample:8
                                                                              samplesPerPixel:4
                                                                                     hasAlpha:true
                                                                                     isPlanar:false
                                                                               colorSpaceName:NSDeviceRGBColorSpace
                                            
                                                                                  bytesPerRow:0
                                                                                 bitsPerPixel:0];
                NSBitmapImageRep *imgRepalpha;
                unsigned char *data;
                int as, j = 0;
                
                if ([pixelPaint state])
                    data = [imgRep bitmapData];
                
                if (![lightmapMode state])
                {
                    data = [imgRep bitmapData];
                    
                    for (as = 0; as < size.width * size.height * 4; as += 4)
                    {
                        unsigned char r, g, b, a;
                        r = *(pixels + as+0);
                        g = *(pixels + as+1);
                        b = *(pixels + as+2);
                        a = *(pixels + as+3);
                        
                        *(pixels_alpha + as + 0) = a;
                        *(pixels_alpha + as + 1) = a;
                        *(pixels_alpha + as + 2) = a;
                        *(pixels_alpha + as + 3) = a;
                    }
                   
                    //Need to convert this data
                    imgRepalpha = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&pixels_alpha
                                                                                       pixelsWide:size.width
                                                                                       pixelsHigh:size.height
                                                                                    bitsPerSample:8
                                                                                  samplesPerPixel:4
                                                                                         hasAlpha:true
                                                                                         isPlanar:false
                                                                                   colorSpaceName:NSDeviceRGBColorSpace
                                                
                                                                                      bytesPerRow:0
                                                                                     bitsPerPixel:0];
                    
                    
                }
          
                
                float xa = size.width*x;
                float ya =  size.height- size.height*y;
                
                if ([eyedropperMode state])
                {
                    int xap = size.width*x;
                    int yap =  size.height- size.height*y;
                    
                    int as = (size.height-yap-1)*(size.width)*4 + xap*4;
                    
                    if (as < size.width * size.height * 4 && as >=0)
                    {
                        unsigned char r, g, b, a;
                        r = *(pixels + as+0);
                        g = *(pixels + as+1);
                        b = *(pixels + as+2);
                        a = *(pixels + as+3);
                        
                        //NSLog(@"%d %d %d %d", r, g, b, a);
                        //NSLog(@"Setting paint colour %f %f %f", r/255.0, g/255.0, b/255.0);
                        [paintColor setColor:[NSColor colorWithCalibratedRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1]];
                    }
                    //NSLog(@"Done!");
                    //uv's are a percent that map into the texture.
                    /*
                    *(data + as + 0) = 0;
                    *(data + as + 1) = 0;
                    *(data + as + 2) = 0;
                    *(data + as + 3) = 255;
                    [_texManager updateBitmapDataWithIdent:pMesha->baseMap data:[imgRep bitmapData] index:index];
                    */
                }
                else
                {
                    float brush_size = [paintSize floatValue];
                    
                    NSRect rect = NSMakeRect(xa-brush_size/2.0, ya-brush_size/2.0, brush_size, brush_size);
                    NSBezierPath* circlePath = [NSBezierPath bezierPath];
                    [circlePath appendBezierPathWithOvalInRect: rect];
                    
                    NSBezierPath *path;
                    if ([clipPaint state])
                    {
                        path = [NSBezierPath bezierPath];
                        
                        float xap1 = size.width*vertex1[0];
                        float yap1 =  size.height-size.height*vertex1[1];
                        
                        float xap2 = size.width*vertex2[0];
                        float yap2 =  size.height-size.height*vertex2[1];
                        
                        float xap3 = size.width*vertex3[0];
                        float yap3 =  size.height-size.height*vertex3[1];
                        
                        if ([lightmapMode state])
                        {
                            xap1 = size.width*lmvertex1[0];
                            yap1 =  size.height-size.height*lmvertex1[1];
                            
                            xap2 = size.width*lmvertex2[0];
                            yap2 =  size.height-size.height*lmvertex2[1];
                            
                            xap3 = size.width*lmvertex3[0];
                            yap3 =  size.height-size.height*lmvertex3[1];
                        }
                        
                        
                        
                        [path moveToPoint:NSMakePoint(xap1, yap1)];
                        [path lineToPoint:NSMakePoint(xap2, yap2)];
                        [path lineToPoint:NSMakePoint(xap3, yap3)];
                        [path closePath];
                        
                        
                        //[[paintColor color] set];
                        // [path fill];
                    }
                    
                    if (![pixelPaint state])
                    {
                        
                        [[NSColorPanel sharedColorPanel] setShowsAlpha:YES];
                        //Need to do this twice unfortunately.
                        [NSGraphicsContext saveGraphicsState];
                        [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:imgRep]];
                        
                       
                        if ([clipPaint state])
                        [path addClip];
                        [colorRGBA setStringValue:[NSString stringWithFormat:@"Color: %d %d %d", (int)([[paintColor color] redComponent]*255), (int)([[paintColor color] greenComponent]*255), (int)([[paintColor color] blueComponent]*255)]];
                        
                        //Flip windows colours ;)
    #ifdef MACVERSION
                        [[paintColor color] set];
                        //[[NSColor colorWithCalibratedRed:[[paintColor color] redComponent] green:1.0-[[paintColor color] greenComponent] blue:1.0-[[paintColor color] blueComponent] alpha:[[paintColor color] alphaComponent]] set];
    #else
                        [[paintColor color] set];
    #endif
                        
                        [circlePath fill];
                        [NSGraphicsContext restoreGraphicsState];
                    }
                    else
                    {
                        //Paint only a single pixel.
                        if (TRUE)
                        {
                            float ac = [[paintColor color] alphaComponent];
                            float e = 1.0-[[paintColor color] alphaComponent];
                            
                            float radius = brush_size;

                            for (as = 0; as < size.width * size.height * 4; as += 4)
                            {
                                int xlocpix = ((as/4) % (int)size.width);
                                int ylocpix = size.height-(floor((as/4) / size.width));
                                
                                //Check the four points of the pixel
                                
                                char a;
                                
                                float distance = sqrt(powf(xlocpix-xa, 2) + powf(ylocpix-ya, 2));
                                /*float distance1 = sqrt(powf(xlocpix+1-xa, 2) + powf(ylocpix-ya, 2));
                                float distance2 = sqrt(powf(xlocpix+1-xa, 2) + powf(ylocpix+1-ya, 2));
                                float distance3 = sqrt(powf(xlocpix-xa, 2) + powf(ylocpix+1-ya, 2));
                                
                                float percent = 0.0;
                                
                                if (distance < radius && distance2 > radius)
                                    percent = sqrtf(2)/(distance2-distance);
                                else if (distance2 < radius && distance > radius)
                                    percent = sqrtf(2)/(distance-distance2);
                                else if (distance1 < radius && distance3 > radius)
                                    percent = sqrtf(2)/(distance3-distance1);
                                else if (distance3 < radius && distance1 > radius)
                                    percent = sqrtf(2)/(distance1-distance3);
                                else if (distance < radius && distance1 < radius && distance2 < radius && distance3 < radius)
                                    percent = 1.0;
                                
                                //What percentage of this pixel is outside the radius
                     
                                ac = [[paintColor color] alphaComponent]*percent;
                                e = 1.0-ac;
                                
                                *(data + as + 0) = (char)(int)((*(data + as + 0))*e   + [[paintColor color] redComponent]*255*ac);
                                *(data + as + 1) = (char)(int)((*(data + as + 1))*e   + [[paintColor color] greenComponent]*255*ac);
                                *(data + as + 2) = (char)(int)((*(data + as + 2))*e   + [[paintColor color] blueComponent]*255*ac);
                                
                                if ([grassMode state])
                                    a=*(data + as + 3)*e + 0*ac;
                                else
                                    a=*(data + as + 3)*e + 255*ac;
                                
                                *(data + as + 3) = a;*/
                                
                                if (distance < radius)
                                {
                                    *(data + as + 0) = (char)(int)((*(data + as + 0))*e   + [[paintColor color] redComponent]*255*ac);
                                    *(data + as + 1) = (char)(int)((*(data + as + 1))*e   + [[paintColor color] greenComponent]*255*ac);
                                    *(data + as + 2) = (char)(int)((*(data + as + 2))*e   + [[paintColor color] blueComponent]*255*ac);
                                    
                                    if ([grassMode state])
                                        a=*(data + as + 3)*e + 0*ac;
                                    else
                                        a=*(data + as + 3)*e + 255*ac;
                                    
                                    *(data + as + 3) = a;
                                }
                                
                                
                            }
                            
                        }
                        else
                        {
                            int xap = size.width*x;
                            int yap =  size.height- size.height*y;
                            
                            int as = (size.height-yap-1)*(size.width)*4 + xap*4;
                            
                            if (as < size.width * size.height * 4 && as >=0)
                            {
                                //Alpha
                                float a = [[paintColor color] alphaComponent];
                                float e = 1.0-[[paintColor color] alphaComponent];
                                
                                *(data + as + 0) = (char)(int)((*(data + as + 0))*e +    [[paintColor color] redComponent]*255*a);
                                *(data + as + 1) = (char)(int)((*(data + as + 1))*e   + [[paintColor color] greenComponent]*255*a);
                                *(data + as + 2) = (char)(int)((*(data + as + 2))*e   + [[paintColor color] blueComponent]*255*a);
                            }
                        }
                    }
                    
                    if (![lightmapMode state])
                    {
                        
                        //Dont need this save?
                        if (![pixelPaint state])
                        {
                            [NSGraphicsContext saveGraphicsState];
                            [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:imgRepalpha]];
                            
                            if ([clipPaint state])
                            [path addClip];
                            
                            if ([grassMode state])
                                [[NSColor colorWithCalibratedHue:0.0 saturation:0.0 brightness:0.0 alpha:[[paintColor color] alphaComponent]] set];
                            else
                                [[NSColor colorWithCalibratedHue:1.0 saturation:1.0 brightness:1.0 alpha:[[paintColor color] alphaComponent]] set];
                            
                            [circlePath fill];
                            
                            data = [imgRep bitmapData];
                            unsigned char *alpha = [imgRepalpha bitmapData];
                            
                            [NSGraphicsContext restoreGraphicsState];
                        
                        
                            for (as = 0; as < size.width * size.height * 4; as += 4)
                            {
                                unsigned char r, g, b, a;
                                r = *(data + as+0);
                                g = *(data + as+1);
                                b = *(data + as+2);
                                a = *(alpha + as+0);
                                
                                //*(data + as + 0) = r;
                                //*(data + as + 1) = g;
                                //*(data + as + 2) = b;
                                *(data + as + 3) = a;
                            }
                        }
                        else
                        {
                            //Paint only a single pixel
                            
                            /*
                            int xap = size.width*x;
                            int yap =  size.height- size.height*y;
                            
                            int as = (size.height-yap-1)*(size.width)*4 + xap*4;
                            if (as < size.width * size.height * 4 && as >=0)
                            {
                                unsigned char r, g, b, a;
                                r = *(data + as+0);
                                g = *(data + as+1);
                                b = *(data + as+2);
                                
                                if ([grassMode state])
                                    a=0;
                                else
                                    a=255;
                                *(data + as + 3) = a;
                            }
                             */
                            
                            
                                //*(data + as + 0) = r;
                                //*(data + as + 1) = g;
                                //*(data + as + 2) = b;
                            
                            
                        }
                    }
                    
                    //Update the bitmap data
                    if (![lightmapMode state])
                    {
                        [_texManager updateBitmapDataWithIdent:pMesha->baseMap data:[imgRep bitmapData] index:index];
                    }
                    else
                        [_texManager updateBitmapDataWithIdent:pMesha->LightmapIndex data:[imgRep bitmapData] index:index];
                    
                    [imgRep release];
                    
                    if (![lightmapMode state])
                    {
                        [imgRepalpha release];
                    }
                    
                    free(pixels_alpha);
                    
                    needsPaintRefresh = YES;
                }

                /*
                //Erase image :P
                NSImage *renderImage = [[NSImage alloc] initWithContentsOfFile:alphaim];
                NSImage *colorImage = [[NSImage alloc] initWithContentsOfFile:file];

                
                
                float brush_size = [paintSize floatValue];
                
                NSRect rect = NSMakeRect(xa-brush_size/2.0, ya-brush_size/2.0, brush_size, brush_size);
                NSBezierPath* circlePath = [NSBezierPath bezierPath];
                [circlePath appendBezierPathWithOvalInRect: rect];
                
                [renderImage lockFocus];
                
                if ([grassMode state])
                    [[NSColor blackColor] set];
                else
                    [[NSColor whiteColor] set];
                
                [circlePath fill];
                [renderImage unlockFocus];
                
                
                [colorImage lockFocus];
                [[paintColor color] set];
                

                
                [circlePath fill];
                [colorImage unlockFocus];
                
                
                //NSBitmapImageRep *alpha = [NSBitmapImageRep imageRepWithContentsOfFile:alphaim];
                //unsigned char *from = [alpha bitmapData];
                
                */
                
                
                /*
                NSLog(@"%d %d %f %f", xa, ya, x,y );
                NSImage *renderImage = [[NSImage alloc] initWithSize:NSMakeSize(alpha.pixelsWide, alpha.pixelsHigh)];
                
                //Paint in a circle around it
                int brushSize = 1;
                
                int as, j = 0;
                for (as = 0; as < alpha.pixelsWide * alpha.pixelsHigh * 4; as += 4)
                {
                    unsigned char r, g, b, a;
                    r = *(from + as+0);
                    g = *(from + as+1);
                    b = *(from + as+2);
                    a = *(from + as+3);
                    
                    
                    
                    if (as == ya*(alpha.pixelsWide)*4 + xa*4)
                    {
                        *(from + as + 0) = 0;
                        *(from + as + 1) = 0;
                        *(from + as + 2) = 0;
                        *(from + as + 3) = 255;
                    }
                    else
                    {
                        *(from + as + 0) = r;
                        *(from + as + 1) = g;
                        *(from + as + 2) = b;
                        *(from + as + 3) = a;
                    }
                    
                    
                    j += 4;
                }
                [renderImage addRepresentation:alpha];
                */
                //Update the texture. horrible method this is. would be shit on non SSD's
                
                
                /*
                [[NSFileManager defaultManager] removeItemAtPath:alphaim error:nil];
                [[renderImage TIFFRepresentation] writeToFile:alphaim atomically:NO];
                
                [[NSFileManager defaultManager] removeItemAtPath:file error:nil];
                [[colorImage TIFFRepresentation] writeToFile:file atomically:NO];
                
                
                [renderImage release];
                [colorImage release];*/
                //[NSThread sleepForTimeInterval:0.1];
            }
        }
    }
    
#ifdef MACVERSION
	if ((([theEvent modifierFlags] & NSControlKeyMask) != 0) && _mode != translate)
		[_camera HandleMouseMove:(dragPoint.x - prevDown.x) dy:(dragPoint.y - prevDown.y)];
#else
    if ((([theEvent modifierFlags] & NSCommandKeyMask) != 0) && _mode != translate)
		[_camera HandleMouseMove:(dragPoint.x - prevDown.x) dy:(dragPoint.y - prevDown.y)];
#endif
	prevDown = dragPoint;
}




- (void)mouseMoved:(NSEvent *)theEvent
{
    
    /*
    if ([first_person_mode state])
    {
        NSPoint dragPoint = [NSEvent mouseLocation];
        
        [_camera HandleMouseMove:(dragPoint.x - prevDown.x) dy:(dragPoint.y - prevDown.y)];
        
        prevDown = dragPoint;
    }
    */
	//NSPoint pt = [theEvent locationInWindow];
    
}
- (void)rightMouseDown:(NSEvent *)event
{
	NSPoint downPoint = [event locationInWindow];
	prevDown = [NSEvent mouseLocation];
}
- (void)rightMouseUp:(NSEvent *)theEvent
{
    
}

- (void)rightMouseDragged:(NSEvent *)theEvent
{
	NSPoint dragPoint = [NSEvent mouseLocation];
	
	[_camera HandleMouseMove:(dragPoint.x - prevDown.x) dy:(dragPoint.y - prevDown.y)];
	
	prevDown = dragPoint;
}

#include <assert.h>
#include <CoreServices/CoreServices.h>

//#include <mach/mach.h>
//#include <mach/mach_time.h>

#include <unistd.h>


- (void)timerTick:(NSTimer *)timer
{

    uint64_t current = mach_absolute_time();
    
    // In here we handle a few things, mmk?
	acceleration = 0;//(int)[cspeed doubleValue] * (current - previous) / 1000000000.0;
    

    
   
        USEDEBUG NSLog(@"TICK");
    

    long double value = pow(10,9)*1.0;
    
    
#ifndef MACVERSION
    value = pow(10,8)*1.0;
    [tickSlider setMaxValue:10000000];
    
    if ([tickSlider doubleValue] > 10000000)
        [tickSlider setDoubleValue:3500000];
#endif
    
    
    value = [tickSlider doubleValue];
    
	long double adjustment = ((current - previous) / value);
    
    uint64_t elapsed;
    elapsed = current - previous;

    //double seconds =  (* (uint64_t *) &elapsedNano)/(pow(10,10) *1.0);
    
    if (adjustment > 5000)
        adjustment = 0.0;
	//NSLog(@"%f", adjustment);
	int x;
	BOOL key_is_down = NO;
	float oldView = _camera.vView[2];
    float oldPosition = _camera.position[2];
	for (x = 0; x < 6; x++)
	{
		if (move_keys_down[x].isDown)
		{
			key_is_down = YES;
			switch (move_keys_down[x].direction)
			{
				case forward:
                {
                    if ([first_person_mode state] && !isInAir)
                    {
                        [cspeed setDoubleValue:[forwardSpeed floatValue]];
                        
                        
                        [_camera MoveCamera:([cspeed doubleValue] * adjustment)];
                       
                    }
                    else if (!([first_person_mode state] && isInAir))
                        [_camera MoveCamera:([cspeed doubleValue] * adjustment)];
					break;
                }
				case back:
                {
                    if ([first_person_mode state] && !isInAir)
                    {
                        [cspeed setDoubleValue:2];
                        
                        float oldView = _camera.vView[2];
                        [_camera MoveCamera:-1*([cspeed doubleValue] * adjustment)];
                        _camera.vView[2] = oldView;
                    }
                    else
                    {
                        if (!([first_person_mode state] && isInAir))
                            [_camera MoveCamera:(-1 * ([cspeed doubleValue] * adjustment))];
                    }
					break;
                }
				case left:
                    if (!([first_person_mode state] && isInAir))
					[_camera StrafeCamera:(-1.0 * ([cspeed doubleValue] * adjustment))];
					break;
				case right:
                    if (!([first_person_mode state] && isInAir))
					[_camera StrafeCamera:([cspeed doubleValue] * adjustment)];
					break;
				case down:
                    if (!([first_person_mode state] && isInAir))
					[_camera LevitateCamera:(-1 * ([cspeed doubleValue] * adjustment))]; 
					break;
				case up:
                {
                    if (![first_person_mode state])
                    {
                    unsigned int	i,
                    nameLookup,
                    type,
                    index;
                    
                    for (i = 0; i < [selections count]; i++)
                    {
                        nameLookup = [[selections objectAtIndex:i] unsignedIntValue];
                        type = (unsigned int)(nameLookup / MAX_SCENARIO_OBJECTS);
                        index = (unsigned int)(nameLookup % MAX_SCENARIO_OBJECTS);
                        
                        
                        
                        switch (type)
                        {
                            case s_vehicle:
                            {
                                float *gg = (float*)[self coordtoGround:(float*)[_scenario vehi_spawns][index].coord];
                                if (gg[0] != 0.0)
                                {
                                    [_scenario vehi_spawns][index].coord[0] = gg[0];
                                    [_scenario vehi_spawns][index].coord[1] = gg[1];
                                    [_scenario vehi_spawns][index].coord[2] = gg[2]+0.01;
                                }
                                free(gg);
                                break;
                            }
                            case s_scenery:
                            {
                                float *gg = (float*)[self coordtoGround:(float*)[_scenario scen_spawns][index].coord];
                                if (gg[0] != 0.0)
                                {
                                    [_scenario scen_spawns][index].coord[0] = gg[0];
                                    [_scenario scen_spawns][index].coord[1] = gg[1];
                                    [_scenario scen_spawns][index].coord[2] = gg[2]+0.01;
                                }
                                free(gg);
                                break;
                            }
                            case s_playerspawn:
                            {
                                float *gg = (float*)[self coordtoGround:(float*)[_scenario spawns][index].coord];
                                if (gg[0] != 0.0)
                                {
                                    [_scenario spawns][index].coord[0] = gg[0];
                                    [_scenario spawns][index].coord[1] = gg[1];
                                    [_scenario spawns][index].coord[2] = gg[2]+0.01;
                                }
                                free(gg);
                                break;
                            }
                            case s_netgame:
                            {
                                float *gg = (float*)[self coordtoGround:(float*)[_scenario netgame_flags][index].coord];
                                if (gg[0] != 0.0)
                                {
                                    [_scenario netgame_flags][index].coord[0] = gg[0];
                                    [_scenario netgame_flags][index].coord[1] = gg[1];
                                    [_scenario netgame_flags][index].coord[2] = gg[2]+0.01;
                                }
                                free(gg);
                                break;
                            }
                            case s_item:
                            {
                                float *gg = (float*)[self coordtoGround:(float*)[_scenario item_spawns][index].coord];
                                if (gg[0] != 0.0)
                                {
                                    [_scenario item_spawns][index].coord[0] = gg[0];
                                    [_scenario item_spawns][index].coord[1] = gg[1];
                                    [_scenario item_spawns][index].coord[2] = gg[2]+0.01;
                                }
                                free(gg);
                                break;
                            }
                            case s_machine:
                            {
                                float *gg = (float*)[self coordtoGround:(float*)[_scenario mach_spawns][index].coord];
                                if (gg[0] != 0.0)
                                {
                                    [_scenario mach_spawns][index].coord[0] = gg[0];
                                    [_scenario mach_spawns][index].coord[1] = gg[1];
                                    [_scenario mach_spawns][index].coord[2] = gg[2]+0.01;
                                }
                                free(gg);
                                break;
                            }
                        }
                    }
                    
                    //Drop the current selection to the ground
					//[_camera LevitateCamera:([cspeed doubleValue] * adjustment)];
					break;
                }
                }
			}
		}
	}
   USEDEBUG  NSLog(@"TICK2");
    previous = current;
    
    
    if ([first_person_mode state])
    {
        
        if (move_keys_down[5].isDown)
            goalHeight = [crouchHeight floatValue];
        else
            goalHeight = [normalHeight floatValue];
        
        float transition = [changeSpeed floatValue]*adjustment;
        if (currentHeight > goalHeight)
        {
            if (currentHeight-transition < goalHeight)
                currentHeight=goalHeight;
            else
                currentHeight-=transition;
        }
        else
        {
            if (currentHeight+transition > goalHeight)
                currentHeight=goalHeight;
            else
                currentHeight+=transition;
        }
        
        //currentHeight
        
        
        [cspeed setDoubleValue:[forwardSpeed floatValue]];
        
        Gg[0] = _camera.position[0];
        Gg[1] = _camera.position[1];
        Gg[2] = _camera.position[2]-0.3;
        
        _camera.position[2]=_camera.position[2]-currentHeight;
        float *gg = (float*)[self coordtoGround:(float*)_camera.position];
        float *gg2 = (float*)[self coordtoGround:(float*)Gg];
        
        //double t = (current/value)-(initialTime/value);
        
        uint64_t end = mach_absolute_time ();
        uint64_t elapsed = end - initialTime;
        

        uint64_t nanos = elapsed;
        //CGFloat t =  (CGFloat)nanos / NSEC_PER_SEC;
        
        CGFloat t = -1*[jumpTime timeIntervalSinceNow];
        double_t a = [gravityAmount floatValue];
        
        double newZ = a*t*t + zv*t;//zv + (powf(9.8, ((current-initialTime)/value)) - 1);
        
        //How high can we go up
        float maxWall = 2;
        if (gg[0] != 0.0)
        {
            _camera.position[0] = gg[0];
            _camera.position[1] = gg[1];
            
            
            //Drop
            if ((isJumping&&jumpZ-newZ > gg[2]) || jumpZ-newZ-0.2 > gg[2])
            {
                
                isInAir=YES;
                
                float oldPosition = _camera.position[2];
                float oldView = _camera.vView[2];
                
                //[cspeed setDoubleValue:0.02];
                if (move_keys_down[1].isDown)
                    jumpSpeed-=0.01;
                else if (move_keys_down[0].isDown)
                    jumpSpeed+=0.01;
                
                if (move_keys_down[2].isDown)
                    jumpStrafe-=0.01;
                else if (move_keys_down[3].isDown)
                    jumpStrafe+=0.01;
                
      
                    [_camera MoveCamera:(jumpSpeed * adjustment)];
                    [_camera StrafeCamera:(jumpStrafe * adjustment)];
            
                
   
                //[_camera LevitateCamera:(-1 * ([cspeed doubleValue] * adjustment))];
                _camera.position[2] = oldPosition;
                _camera.position[2]=jumpZ+currentHeight-newZ;
                
                _camera.vView[2] = oldView-(oldPosition-(jumpZ-newZ));

    
            }
            else
            {
                
                if (jumpTime)
                    [jumpTime release];
                jumpTime=[NSDate date];
                [jumpTime retain];
                
                isJumping=NO;
                initialTime = mach_absolute_time();
                jumpZ = gg[2];
                
                //NSLog(@"%f", (gg[2] - _camera.position[2])/adjustment);
                if (0)//(gg[2] - _camera.position[2])/adjustment > maxWall || (gg2[2] - Gg[2])/adjustment > maxWall)
                {
                    _camera.position[0]=lastPosition[0];
                    _camera.position[1]=lastPosition[1];
                    _camera.position[2]=lastPosition[2];
                }
                else
                {
                    isInAir=NO;
                    
                    if (move_keys_down[0].isDown && !move_keys_down[1].isDown)
                        xv=1;
                    else if (move_keys_down[2].isDown && !move_keys_down[3].isDown)
                        xv=2;
                    else if (move_keys_down[3].isDown && !move_keys_down[2].isDown)
                        xv=3;
                    else if (move_keys_down[1].isDown && !move_keys_down[0].isDown)
                        xv=-1;
                    else
                        xv=0;
                    
                    zv=0;
                   
                    
                    //Is there a teleporter near our feet?
                    BOOL found = false;
                    multiplayer_flags *mp_flags = [_scenario netgame_flags];
                    
                    int a;
                    for (a = 0; a < [_scenario multiplayer_flags_count]; a++)
                    {
                        if (mp_flags[a].type == teleporter_entrance)
                        {
                            float *position = mp_flags[a].coord;
                            float distance = (float)sqrt(powf(position[0] - [_camera position][0],2) + powf(position[1] - [_camera position][1], 2) + powf(position[2] - [_camera position][2], 2)); //[self distanceToObject:(float *)position];
                            
                            if (distance < currentHeight)
                            {
                                //Teleport! Find the exit.
                                
                                multiplayer_flags mp_exit;
                                int e;
                                for (e = 0; e < [_scenario multiplayer_flags_count]; e++)
                                {
                                    if (e == a)
                                        continue;
                                    
                                    if (mp_flags[e].type == teleporter_exit)
                                    {
                                        if (mp_flags[e].team_index == mp_flags[a].team_index)
                                        {
                                            found = true;
                                            mp_exit = mp_flags[e];
                                            
                                            isInAir=NO;
                                            
                               
                                            _camera.position[0]=mp_exit.coord[0];
                                            _camera.position[1]=mp_exit.coord[1];
                                            _camera.position[2]=mp_exit.coord[2]+currentHeight;
                                            
                                            jumpZ = mp_exit.coord[2];
                                            
                                            float y_angle = mp_exit.rotation;
                                            
                                            float x = cos(y_angle);
                                            float y = sin(y_angle);
                                            float r = 10;
                                            
                                            _camera.vView[0] = mp_exit.coord[0] + x*r;
                                            _camera.vView[1] = mp_exit.coord[1] + y*r;
                                            
                                            
                                            //_camera.vView[2] = 10;
                                            
                                            
                                            break;
                                        }
                                    }
                                    
                                }
                                
                                if (found)
                                break;
                            }
                        }
                    }
                    
                    
                    if (!found)
                    {
                        _camera.position[2]= gg[2]+currentHeight;
                        
                    
                    }
                        float newPosition = _camera.position[2];
                        _camera.vView[2] = oldView + (newPosition-oldPosition);
                    
                    
                    if (move_keys_down[4].isDown)
                    {
                        jumpStrafe=0;
                        jumpSpeed=0;
                        if (xv == 1)
                            jumpSpeed=2.25;
                        else if (xv == -1)
                            jumpSpeed=-2.25;
                        else if (xv == 2)
                            jumpStrafe=-2.25;
                        else if (xv == 3)
                            jumpStrafe=2.25;
                        
      
                        zv=-[jumpVelocity floatValue];
                        isJumping=YES;
                        
                        
                    }
                }
            }
       
            lastPosition[0] = _camera.position[0];
            lastPosition[1] = _camera.position[1];
            lastPosition[2] = _camera.position[2];
            
        }
        free(gg);
    }
    else
    {
        goalHeight = [normalHeight floatValue];
        currentHeight = [normalHeight floatValue];
        
        if (jumpTime)
            [jumpTime release];
        jumpTime=[NSDate date];
        [jumpTime retain];
        
        jumpZ = _camera.position[2];
        initialTime = mach_absolute_time();
    }
  USEDEBUG NSLog(@"TICK3");
	if (key_is_down)
	{
		
		
		
		/*
		if (accelerationCounter > 10 && accelerationCounter < 15)
			acceleration += 0.1;
		if (accelerationCounter > 15 && accelerationCounter < 20)
			acceleration += 0.2;
		if (accelerationCounter > 20 && accelerationCounter < 25 && _fps < 40)
			acceleration += 0.2;
		if (accelerationCounter > 25 && acceleration < 30 && _fps < 30)
			acceleration += 0.2;
		
		accelerationCounter += 1;
		 */
		 
	}
	else
	{
		acceleration = 0;
		accelerationCounter = 0;
	}
	USEDEBUG NSLog(@"TICK4");
    if ([render_reshape state])
        [self performSelectorOnMainThread:@selector(reshape) withObject:nil waitUntilDone:YES];
    [self setNeedsDisplay:YES];
    
	if (shouldDraw)
	{
		
        USEDEBUG NSLog(@"TICK4.5");
		
       USEDEBUG  NSLog(@"TICK5");
	}
    else
    {
        
    }
}
/*
	Override the view's drawRect: to draw our GL content.
*/	 

-(IBAction)DropCamera:(id)sender
{
	unsigned int	i,
	nameLookup,
	type,
	index;
	
	i = 0;
	
	nameLookup = [[selections objectAtIndex:i] unsignedIntValue];
	type = (unsigned int)(nameLookup / MAX_SCENARIO_OBJECTS);
	index = (unsigned int)(nameLookup % MAX_SCENARIO_OBJECTS);
		
		
		
	switch (type)
	{
		case s_vehicle:
			
			[self centerObj3:[_scenario vehi_spawns][index].coord move:[_scenario vehi_spawns][index].rotation];
			break;
		case s_scenery:
			[self centerObj3:[_scenario scen_spawns][index].coord move:[_scenario scen_spawns][index].rotation];
			break;
		case s_playerspawn:
			[self centerObj3:[_scenario spawns][index].coord move:nil];
			break;
		case s_netgame:
			[self centerObj3:[_scenario netgame_flags][index].coord move:nil];
			break;
		case s_item:
			[self centerObj3:[_scenario item_spawns][index].coord move:nil];
			break;
		case s_machine:
			[self centerObj3:[_scenario mach_spawns][index].coord move:[_scenario mach_spawns][index].rotation];
			break;
	}
	
}

-(int)usesColor
{
	return 4;
}


-(void)drawView
{
    
    /*
    if ([_scenario scen_ref_count] <=0)
        return;
    
    long modelIdent = [_scenario baseModelIdent:[_scenario scen_references][0].scen_ref.TagId];
    ModelTag *model = [_mapfile tagForId:modelIdent];
    
    const int width = 512;
    const int height = 512;

    
    glLoadIdentity();
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glClearColor(1,1,1,1.0);          // We'll Clear To The Color Of The Fog ( Modified )
    glDepthFunc(GL_LESS);
    
    //Render things
    float *pt = malloc(sizeof(float)*6);
    pt[0]=-10.0;
    pt[1]=0.0;
    pt[2]=0.0;
    pt[3]=0.0;
    pt[4]=0.0;
    pt[5]=0.0;
    
    
    glViewport(0,0,width,height);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	gluPerspective(45.0f,
                   (width / height),
                   0.1f,
                   4000.0f);
	glMatrixMode(GL_MODELVIEW);

    CVector3 vPosition	= NewCVector3(-7.470679f, 2.161628f, 2.085556f);
	CVector3 vView		= NewCVector3(-13.156720f, -2.724668f, -2.249794f);
	CVector3 vUpVector	= NewCVector3(0.0f, 0.0f, 1.0f);

    gluLookAt(vPosition.x, vPosition.y, vPosition.z,
			  vView.x,	 vView.y,     vView.z,
			  vUpVector.x, vUpVector.y, vUpVector.z);
    
    [self renderVisibleBSP:FALSE];
    
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glColor3f(1.0f,1.0f,1.0f);
    
    [model drawAtPoint:pt lod:4 isSelected:NO useAlphas:YES distance:0.0f];
    
    glDisableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    
    glDisable(GL_TEXTURE_2D);
    glDisable(GL_BLEND);
    
    [[self openGLContext] flushBuffer];
    
    return;
    
    */
    
    
    
    
    
    //Moving
    if (![[self window] isKeyWindow] || ![NSApp isActive])
    {
        move_keys_down[0].isDown = NO;
        move_keys_down[1].isDown = NO;
        move_keys_down[2].isDown = NO;
        move_keys_down[3].isDown = NO;
        move_keys_down[4].isDown = NO;
        move_keys_down[5].isDown = NO;
    }
    
    if ([render_flush state] )
    {
    glLoadIdentity();
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glClearColor(100/100.0,90/100.0,76/100.0,1.0);          // We'll Clear To The Color Of The Fog ( Modified )
    
  
    if (![NSApp isActive])
    {
        //[[self openGLContext] flushBuffer];
        return;
    }
    
   
    
   
	[_camera Look];
	[_camera Update];
}
    
	//NSLog(@"%f %f %f", [_camera position][0], [_camera position][1], [_camera position][2]);
	//[self drawAxes];
	
    //shouldDraw = FALSE;
	if (shouldDraw)
	{
        if ([render_settings state])
        {
        if (useNewRenderer() >= 2)
        {

             
            GLfloat fogColor[4];     // Fog Color
            fogColor[0] = 1.0f;
            fogColor[1] = 1.0f;
            fogColor[2] = 1.0f;
            fogColor[3] = 1.0f;
            
            if (useNewRenderer() == 3)
            {

                fogColor[0] = 0.5f;
                 fogColor[1] = 0.5f;
                 fogColor[2] = 0.5f;
  
            }// Fog Color
            
            
            
            glFogi(GL_FOG_MODE, GL_LINEAR);        // Fog Mode
            glFogfv(GL_FOG_COLOR, fogColor);            // Set Fog Color
            glFogf(GL_FOG_DENSITY, 0.5f);              // How Dense Will The Fog Be
            glHint(GL_FOG_HINT, GL_NICEST);          // Fog Hint Value
            glFogf(GL_FOG_START, 0.3f);             // Fog Start Depth
            glFogf(GL_FOG_END, 200.0f);               // Fog End Depth
                           // Enables GL_FOG
            
        }
        
        if (useNewRenderer() >= 2)
        {
            glEnable(GL_FOG);
            glEnable(GL_MULTISAMPLE);
            glHint(GL_MULTISAMPLE_FILTER_HINT_NV, GL_NICEST);
            
        }
        else
        {
            glDisable(GL_FOG);
            
            if (useNewRenderer() >= 1)
            {
   
                glEnable(GL_MULTISAMPLE);
                glHint(GL_MULTISAMPLE_FILTER_HINT_NV, GL_NICEST);
                
            }
            
        }
        }
        
        
        /*
        if (lightScene)
        {
        
            glPushMatrix();
            glTranslatef(lightPos[0], lightPos[1], lightPos[2]);
            glColor3f(1.0, 1.0, 0.0);
                
            GLUquadric *sphere=gluNewQuadric();
            gluQuadricDrawStyle( sphere, GLU_FILL);
            gluQuadricNormals( sphere, GLU_SMOOTH);
            gluQuadricOrientation( sphere, GLU_OUTSIDE);
            gluQuadricTexture( sphere, GL_TRUE);
            
            gluSphere(sphere,0.5,10,10);
            gluDeleteQuadric ( sphere );
            glPopMatrix();
        
        
        
        }
        */
        
        if (true)
        {
            if ([render_sky state])
            {
            glDisable(GL_DEPTH_TEST);
            if (TRUE)//useNewRenderer())
            {
                glEnableClientState(GL_VERTEX_ARRAY);
                glEnableClientState(GL_TEXTURE_COORD_ARRAY);
                
                glEnable(GL_TEXTURE_2D);
                glEnable(GL_BLEND);
            }
            if (useNewRenderer() >= 2)
                glDisable(GL_FOG);
            
            SkyBox *skies;
            skies = [_scenario sky];

            
            USEDEBUG NSLog(@"MP8");
            int x; float pos[6];
            for (x = 0; x < [_scenario skybox_count]; x++)
            {
                // Lookup goes hur
                
                if ([_mapfile isTag:skies[x].modelIdent])
                {
                    
                    pos[0]=0;
                    pos[1]=0;
                    pos[2]=0;//-10000;
                    pos[3]=0;
                    pos[4]=0;
                    pos[5]=0;
                    
                    [[_mapfile tagForId:skies[x].modelIdent] drawAtPoint:pos lod:_LOD isSelected:NO useAlphas:NO distance:0];
                }
            }
            USEDEBUG NSLog(@"MP9");
            if (useNewRenderer() >= 2)
                glEnable(GL_FOG);
            USEDEBUG NSLog(@"MP10");
            if (TRUE)//useNewRenderer())
            {
                glDisableClientState(GL_VERTEX_ARRAY);
                glDisableClientState(GL_TEXTURE_COORD_ARRAY);
                
                glDisable(GL_TEXTURE_2D);
                glDisable(GL_BLEND);
            }
            glEnable(GL_DEPTH_TEST);
            }
        }
        
		if (mapBSP)
		{
            if ([render_bsp state])
            {
                [self renderVisibleBSP:FALSE];
            }
		}

		if (_scenario)
		{
            if ([render_objects state])
            {
                [self renderAllMapObjects];
            }
			
		}

       
        
	}
    else
    {
    }

    
	[[self openGLContext] flushBuffer];
    
}

-(void)updateObjectTable
{
    needsReshape = YES;
    
    [stamp refresh];
}

- (void)drawRect:(NSRect)rect
{
    [self drawView];
    //[NSThread sleepForTimeInterval:0.01];
}
- (void)loadPrefs
{
	NSLog(@"Loading preferences!");
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	_useAlphas = [userDefaults boolForKey:@"_useAlphas"];
	[useAlphaCheckbox setState:_useAlphas];
	
	NSString *size = [userDefaults stringForKey:@"windowsize"];
	
	if (size)
	{
		
	NSArray *objs = [size componentsSeparatedByString:@","];
	[[self window] setFrame:NSMakeRect([[objs objectAtIndex:0] floatValue], [[objs objectAtIndex:1] floatValue], [[objs objectAtIndex:2] floatValue], [[objs objectAtIndex:3] floatValue]) display:YES];
	
	}
	
	[lodDropdownButton setDoubleValue:[userDefaults integerForKey:@"_LOD"]];
	switch ((int)[lodDropdownButton doubleValue])
	{
		case 0:
			_LOD = 0;
			break;
		case 1:
			_LOD = 2;
			break;
		case 2:
			_LOD = 4;
			break;
	}
}
- (void)releaseMapObjects
{
	shouldDraw = NO;
	[[self openGLContext] flushBuffer];
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
	[self initGL];
	[_texManager release];
	[_mapfile release];
	[_scenario release];
	[mapBSP release];
	
	[self deselectAllObjects];
}
- (void)setMapObject:(HaloMap *)mapfile
{
	int i;
	float x,y,z;
	
	_mapfile = [mapfile retain];
	_scenario = [[mapfile scenario] retain];
	mapBSP = [[mapfile bsp] retain];
	_texManager = [[mapfile _texManager] retain];
	if (_mapfile && _scenario && mapBSP)
		shouldDraw = YES;
	[bspNumbersButton removeAllItems];
	for (i = 0; i < [mapBSP NumberOfBsps]; i++)
		[bspNumbersButton addItemWithTitle:[[NSNumber numberWithInt:i+1] stringValue]];
	[mapBSP GetActiveBspCentroid:&x center_y:&y center_z:&z];
	
    [self recenterCamera:self];
    
	if ([[[NSUserDefaults standardUserDefaults]objectForKey:@"automatic"] isEqualToString:@"NO"])
	{
		[self recenterCamera:self];
	}
	else
	{
		
	

	NSString *autoa = [NSString stringWithContentsOfFile:@"/tmp/starlight.auto"];
	
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:@"/tmp/starlight.auto"])
	{
		NSLog(@"Loading map file");
		NSArray *settings = [autoa componentsSeparatedByString:@","];
		NSString *pat = [settings objectAtIndex:0];
		if ([[NSFileManager defaultManager] fileExistsAtPath:pat])
		{
			
			[_camera PositionCamera:[[settings objectAtIndex:1] floatValue] positionY:[[settings objectAtIndex:2] floatValue] positionZ:[[settings objectAtIndex:3] floatValue] viewX:[[settings objectAtIndex:4] floatValue] viewY:[[settings objectAtIndex:5] floatValue] viewZ:[[settings objectAtIndex:6] floatValue] upVectorX:0.0f upVectorY:0.0f upVectorZ:1.0f];
			[@"" writeToFile:@"/tmp/starlight.auto" atomically:YES];
			
		}
		
	}
	else
	{
		[self recenterCamera:self];
	}
		}
	activeBSPNumber = 0;
	
	SUBMESH_INFO *pMeshaa;
	
	
	unsigned int mesh_count;
	int m;

	mesh_count = [mapBSP GetActiveBspSubmeshCount];
	
	
	int point = 0;
	for (m = 0; m < mesh_count; m++)
	{
		pMeshaa = [mapBSP GetActiveBspPCSubmesh:m];
		point+=pMeshaa->VertCount;
	}
	
	bsp_point_count=point;
	
	///Create the bsp points
	bsp_points = malloc(bsp_point_count * sizeof(bsp_point));
	
	
	
	int b = 0;
	for (m = 0; m < mesh_count; m++)
	{
				
		pMeshaa = [mapBSP GetActiveBspPCSubmesh:m];
		for (i = 0; i < pMeshaa->VertCount; i++)
		{
			
			float *coord = (float *)(pMeshaa->pVert[i].vertex_k);
			bsp_points[b].coord[0]= coord[0];
			bsp_points[b].coord[1]= coord[1];
			bsp_points[b].coord[2]= coord[2];
			bsp_points[b].mesh=m;
			bsp_points[b].index = 0;
			bsp_points[b].amindex = i;
            bsp_points[b].isSelected = NO;

			b+=1;
		}
	}
	
	//Look, we have all of the collision data
	editable = 1;
	
}
- (void)lookAt:(float)x y:(float)y z:(float)z
{
	//[_camera PositionCamera:[_camera position][0] positionY:[_camera position][1] positionZ:[_camera position][2] 
				//viewX:x viewY:y viewZ:z 
				//upVectorX:0.0f upVectorY:0.0f upVectorZ:1.0f];
}
- (void)stopDrawing
{
	//int i;
	shouldDraw = NO;
	[[self openGLContext] flushBuffer];
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
}
- (void)resetTimerWithClassVariable
{
	[drawTimer invalidate];
	[drawTimer release];
	drawTimer = [[NSTimer timerWithTimeInterval:(1.0/_fps)
						target:self
						selector:@selector(timerTick:)
						userInfo:nil
						repeats:YES]
						retain];
	
	[[NSRunLoop currentRunLoop] addTimer:drawTimer forMode:(NSString *)kCFRunLoopCommonModes];
	shouldDraw = YES;
}
/* 
*
*		End RenderView Functions 
*
*/

/* 
*
*		Begin BSP Rendering 
*
*/
- (void)renderVisibleBSP:(BOOL)selectMode
{
	unsigned int mesh_count;
	int i;
	int m;
	
    
	if (shouldDraw)
	{
		mesh_count = [mapBSP GetActiveBspSubmeshCount];
		
        if ([render_colours state])
        {
            [self resetMeshColors];
		}
        
		NSString *points = @"";
		
		for (i = 0; i < mesh_count; i++)
		{
            
            
			
			/*SUBMESH_INFO *pMesh;
			pMesh = [mapBSP GetActiveBspPCSubmesh:i];
	
			for (m = 0; m < pMesh->IndexCount; m++)
			{
				points = [points stringByAppendingString:[NSString stringWithFormat:@"%f,%f,%f,", (float)(pMesh->pVert[pMesh->pIndex[m].tri_ind[0]].vertex_k[0]), (float)(pMesh->pVert[pMesh->pIndex[m].tri_ind[0]].vertex_k[1]), (float)(pMesh->pVert[pMesh->pIndex[m].tri_ind[0]].vertex_k[2])]];
				points = [points stringByAppendingString:[NSString stringWithFormat:@"%f,%f,%f,", (float)(pMesh->pVert[pMesh->pIndex[m].tri_ind[1]].vertex_k[0]), (float)(pMesh->pVert[pMesh->pIndex[m].tri_ind[1]].vertex_k[1]), (float)(pMesh->pVert[pMesh->pIndex[m].tri_ind[1]].vertex_k[2])]];
				points = [points stringByAppendingString:[NSString stringWithFormat:@"%f,%f,%f,", (float)(pMesh->pVert[pMesh->pIndex[m].tri_ind[2]].vertex_k[0]), (float)(pMesh->pVert[pMesh->pIndex[m].tri_ind[2]].vertex_k[1]), (float)(pMesh->pVert[pMesh->pIndex[m].tri_ind[2]].vertex_k[2])]];
			}*/
			//[points writeToFile:@"/tmp/BSPPoint.txt" atomically:YES];
			//NSRunAlertPanel(@"DUN", @"", @"", @"", @"");
			//sleep(2000)
            if ([render_colours state])
            {
                if ((currentRenderStyle == point) || (currentRenderStyle == wireframe) || (currentRenderStyle == flat_shading))
                    [self setNextMeshColor];
			}
            currentRenderStyle = textured_tris;
			switch (currentRenderStyle)
			{
				case point:
					[self renderBSPAsPoints:i];
					break;
				case wireframe:
					glLineWidth(1.0f);
					[self renderBSPAsWireframe:i];
					break;
				case flat_shading:
					[self renderBSPAsFlatShadedPolygon:i];
					break;
				case textured_tris:
                    if ([render_junk state])
                    {
                    glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
                    }
                    
					[self renderBSPAsTexturedAndLightmaps:i];
                    
                    if ([wireframeBSP state])
                    {
                        [self renderBSPAsWireframe:i];
                    }
                    
                    if ([paintDebug state])
                    {
                        glEnable(GL_BLEND);
                        glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
                        [self renderHighlighted:indexMesh];
                        glDisable(GL_BLEND);
                    }
                    
                    if ([render_junk state])
                    {
                    //glLineWidth(1.0f);
					//[self renderBSPAsWireframe:i];
					//[self renderBSPAsPoints:i];
					glLineWidth(2.0f);
					glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
                    }
					break;
			}
			 
		}
		
		
	}
}
- (void)renderBSPAsPoints:(int)mesh_index
{
	SUBMESH_INFO *pMesh;
	int i;
	
	pMesh = [mapBSP GetActiveBspPCSubmesh:mesh_index];
	
	glPointSize(15.0);
	glBegin(GL_POINTS);
	glPointSize(15.0);
	
	BspMesh *mesh = [mapBSP mesh];
	
	for (i = 0; i < [mesh coll_count]; i++)
	{
		vert *v = [mesh collision_verticies];
		
		float *coord = malloc(12);
		coord[0]=v[i].x;
		coord[1]=v[i].y;
		coord[2]=v[i].z;
		
		glVertex3fv(coord);
	}
	glEnd();

	//sleep(20000);
}

static const GLfloat g_color_buffer_data[] = {
    1.0f,  0.0f,  0.0f,
    1.0f,  0.0f,  0.0f,
    1.0f,  0.0f,  0.0f,
};

- (void)renderBSPAsWireframe:(int)mesh_index
{
	SUBMESH_INFO *pMesh;
	int i;
	
	pMesh = [mapBSP GetActiveBspPCSubmesh:mesh_index];
	
	
	glLineWidth(_lineWidth);
	
	glBegin(GL_LINES);
	for (i = 0; i < pMesh->IndexCount; i++)
	{
		// First line:(0 -> 1)
		{
			glVertex3fv(pMesh->pVert[pMesh->pIndex[i].tri_ind[0]].vertex_k);
			glVertex3fv(pMesh->pVert[pMesh->pIndex[i].tri_ind[1]].vertex_k);
		}
		// Second line :(1 -> 2)
		{
			glVertex3fv(pMesh->pVert[pMesh->pIndex[i].tri_ind[1]].vertex_k);
			glVertex3fv(pMesh->pVert[pMesh->pIndex[i].tri_ind[2]].vertex_k);
		}
		// Third line :(2 -> 0)
		{
			glVertex3fv(pMesh->pVert[pMesh->pIndex[i].tri_ind[2]].vertex_k);
			glVertex3fv(pMesh->pVert[pMesh->pIndex[i].tri_ind[0]].vertex_k);
		}
	}
	glEnd();
}
- (void)renderHighlighted:(int)mesh_index
{
    glDepthFunc(GL_LEQUAL);
    
	SUBMESH_INFO *pMesh;
	int i;
	
	pMesh = [mapBSP GetActiveBspPCSubmesh:mesh_index];
	//NSLog(@"%d %d", indexMesh, indexHighlight);
    
    glLineWidth(5.0f);
	glColor4f(1.0f, 0.0f, 0.0f, 1.0f);
    
	glBegin(GL_LINES);
   
	i=selectedPIndex;
    
    glVertex3fv((float *)(pMesh->pVert[pMesh->pIndex[i].tri_ind[0]].vertex_k));
    glVertex3fv((float *)(pMesh->pVert[pMesh->pIndex[i].tri_ind[1]].vertex_k));
    
    glVertex3fv((float *)(pMesh->pVert[pMesh->pIndex[i].tri_ind[1]].vertex_k));
    glVertex3fv((float *)(pMesh->pVert[pMesh->pIndex[i].tri_ind[2]].vertex_k));

    glVertex3fv((float *)(pMesh->pVert[pMesh->pIndex[i].tri_ind[2]].vertex_k));
    glVertex3fv((float *)(pMesh->pVert[pMesh->pIndex[i].tri_ind[0]].vertex_k));
    
    
	glEnd();
    
    
    glDepthFunc(GL_LEQUAL);
}

- (void)renderBSPAsFlatShadedPolygon:(int)mesh_index
{
	SUBMESH_INFO *pMesh;
	int i;
	
	pMesh = [mapBSP GetActiveBspPCSubmesh:mesh_index];
	
	glBegin(GL_TRIANGLES);
	//[self setNextMeshColor];
	for (i = 0; i < pMesh->IndexCount; i++)
	{
		glVertex3fv((float *)(pMesh->pVert[pMesh->pIndex[i].tri_ind[0]].vertex_k));
		glVertex3fv((float *)(pMesh->pVert[pMesh->pIndex[i].tri_ind[1]].vertex_k));
		glVertex3fv((float *)(pMesh->pVert[pMesh->pIndex[i].tri_ind[2]].vertex_k));
	}
	glEnd();
}

-(void)renderSkybox
{
    NSLog(@"Rendering skyboxes");
    
	SkyBox *skies;
	skies = [_scenario sky];

	float pos[6];
	pos[0] = 0;
	pos[1] = 0;
	pos[2] = 0;
	pos[3] = 0;
	pos[4] = 0;
	pos[5] = 0;
    
    
    
    
    [[_mapfile bipd] drawAtPoint:pos lod:_LOD isSelected:YES useAlphas:NO];
    
    BOUNDING_BOX*bb = [[_mapfile bipd] bounding_box];
    if (bb != NULL)
        NSLog(@"Determining bounding box %f %f %f %f %f %f", bb->min[0], bb->min[1], bb->min[2], bb->max[0], bb->max[1], bb->max[2]);

    
	//[[_mapfile tagForId:skies[0].modelIdent] drawAtPoint:pos lod:_LOD isSelected:YES useAlphas:_useAlphas];
}

-(void)refreshTextureWithMesh:(NSArray*)mesh_index
{
   
    if (alreadyRefreshing)
        return;
    [[mesh_index objectAtIndex:1] makeCurrentContext];

   
    
    pMesh = [mapBSP GetActiveBspPCSubmesh:[[mesh_index objectAtIndex:0] intValue]];
    
    alreadyRefreshing = YES;
    
    //Can we do this on another thread?
    if (pMesh->baseMap != -1)
        [_texManager refreshTextureOfIdent:pMesh->baseMap];
    
    if (pMesh->LightmapIndex != -1)
        [_texManager refreshTextureOfIdent:pMesh->DefaultLightmapIndex index:pMesh->LightmapIndex];
    
    alreadyRefreshing = NO;
}

- (void)renderBSPAsTexturedAndLightmaps:(int)mesh_index
{
    
	pMesh = [mapBSP GetActiveBspPCSubmesh:mesh_index];
	
    
    if (mesh_index == selectedBSP)
    {
        //Update the texture using the photoshop file
#ifdef THREADREFRESH
        
        
        if (needsPaintRefresh)
        {
            [self performSelectorInBackground:@selector(refreshTextureWithMesh:) withObject:[NSArray arrayWithObjects:[NSNumber numberWithInt:mesh_index], [NSOpenGLContext currentContext], nil]];
            needsPaintRefresh=NO;
        }
        
#else
        if (needsPaintRefresh)
        {
            if (pMesh->baseMap != -1)
                [_texManager refreshTextureOfIdent:pMesh->baseMap];
            
            if (pMesh->DefaultLightmapIndex != -1 && pMesh->LightmapIndex != -1)
                [_texManager refreshTextureOfIdent:pMesh->DefaultLightmapIndex index:pMesh->LightmapIndex];
            needsPaintRefresh=NO;
        }
#endif
        //[_texManager exportTextureOfIdent:pMesh->baseMap subImage:0];
    }
   
    
	/*if (pMesh->ShaderIndex == -1)
	{
        NSLog(@"Missing shader!");
		//glColor3f(0.1f, 0.1f, 0.1f);
        glColor3f(1.0f, 1.0f, 1.0f);
	}
	else
	{*/
	
		if (pMesh->LightmapIndex != -1)
		{
			//glEnable(GL_TEXTURE_2D);
		}
        
        if (useNewRenderer() != 2)
        {
            glDisable(GL_ALPHA_TEST);
            glDisable(GL_BLEND);
        }
        
        if (pMesh->baseMap != -1 && useNewRenderer() >= 1)
        {
           
            
            
            //glEnable(GL_DEPTH_TEST);
            bool useLightmaps = TRUE;
            
        if (useNewRenderer() == 1)
        {
            useLightmaps = FALSE;
        }
            if (!useLightmaps)
            {
                glDepthFunc(GL_LEQUAL);
                
                
                /*
                glDisable(GL_BLEND);
                glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                glDepthMask(1); // Disable writing to depth buffer
                
                [_texManager activateTextureOfIdent:pMesh->secondaryMap subImage:0 useAlphas:NO];
                glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
                
                glColor4f(1,1,1,1);
                
                glEnableClientState(GL_VERTEX_ARRAY);
                glEnableClientState(GL_TEXTURE_COORD_ARRAY);
                glMatrixMode(GL_TEXTURE);
                glPushMatrix();
                glScalef(pMesh->secondaryMapScale,pMesh->secondaryMapScale, 0.0);
                glVertexPointer(3, GL_FLOAT, 56, pMesh->pVert[0].vertex_k);
                glTexCoordPointer(2, GL_FLOAT, 56, pMesh->pVert[0].uv);
                
                glDrawElements(GL_TRIANGLES, (pMesh->IndexCount * 3), GL_UNSIGNED_SHORT, pMesh->pIndex);
                glPopMatrix();
                glDisableClientState(GL_VERTEX_ARRAY);
                glDisableClientState(GL_TEXTURE_COORD_ARRAY);
                
                glDisable(GL_TEXTURE_2D);
                glDisable(GL_BLEND);
                */
                
                
                
                glDisable(GL_BLEND);
                glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                //glDepthMask(1); // Disable writing to depth buffer
                
                [_texManager activateTextureOfIdent:pMesh->baseMap subImage:0 useAlphas:NO];
                glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
                
                glColor4f(1,1,1,1);
                
                glEnableClientState(GL_VERTEX_ARRAY);
                glEnableClientState(GL_TEXTURE_COORD_ARRAY);
                
                glVertexPointer(3, GL_FLOAT, 56, pMesh->pVert[0].vertex_k);
                glTexCoordPointer(2, GL_FLOAT, 56, pMesh->pVert[0].uv);
                
                glDrawElements(GL_TRIANGLES, (pMesh->IndexCount * 3), GL_UNSIGNED_SHORT, pMesh->pIndex);
                
                glDisableClientState(GL_VERTEX_ARRAY);
                glDisableClientState(GL_TEXTURE_COORD_ARRAY);
                
                glDisable(GL_TEXTURE_2D);
                glDisable(GL_BLEND);
                
                
                //Need to make the lightmap fully transparent (on lite anyway)
                [_texManager activateTextureOfIdent:pMesh->DefaultLightmapIndex subImage:pMesh->LightmapIndex useAlphas:YES];
                
                glEnable(GL_BLEND);
                glBlendFunc(GL_DST_ALPHA,GL_ONE_MINUS_DST_ALPHA);
                glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
   
                
                glColor4f(1,1,1,0.2);
                
                glEnableClientState(GL_VERTEX_ARRAY);
                glEnableClientState(GL_TEXTURE_COORD_ARRAY);
                
                glVertexPointer(3, GL_FLOAT, 56, pMesh->pVert[0].vertex_k);
                glTexCoordPointer(2, GL_FLOAT, 20, pMesh->pLightmapVert[0].uv);
                
                glDrawElements(GL_TRIANGLES, (pMesh->IndexCount * 3), GL_UNSIGNED_SHORT, pMesh->pIndex);
                
                glDisableClientState(GL_VERTEX_ARRAY);
                glDisableClientState(GL_TEXTURE_COORD_ARRAY);
                
                glDisable(GL_TEXTURE_2D);
                glDisable(GL_BLEND);
                
                
                glDisable(GL_BLEND);
                glDepthMask(1); // Re-enable writing to depth buffer

                
                glDepthFunc(GL_LEQUAL);
                
                return;
            }
            else
            {
                
                
                
if (useNewRenderer() != 1)
{
    
#ifdef LOWRAM
    [_texManager activateTextureOfIdent:pMesh->DefaultLightmapIndex subImage:pMesh->LightmapIndex useAlphas:YES];
    
#endif
    
                glActiveTextureARB(GL_TEXTURE3_ARB);
                glDisable(GL_TEXTURE_2D);
                
                glActiveTextureARB(GL_TEXTURE2_ARB);
                glDisable(GL_TEXTURE_2D);
                
                glActiveTextureARB(GL_TEXTURE1_ARB);
                glDisable(GL_TEXTURE_2D);
                
                glActiveTextureARB(GL_TEXTURE0_ARB);
                glDisable(GL_TEXTURE_2D);
                
                
                    glDepthFunc(GL_LEQUAL);
                
                
                    glDisable(GL_BLEND);
                    glColor4f(1.0f,1.0f,1.0f,1.0f);
                
                    //if (mesh_index == selectedBSP)
                    //    glColor4f(0,1,1,5);
                
                    bool showDetail = [render_det1 state];
                    bool showDetail2 = [render_det2 state];
                    useLightmaps = [render_LM state];
    
                
                
                    //glPushMatrix();
    if ([render_idents state])
    {
                    [_texManager activateTextureAndLightmap:pMesh->baseMap lightmap:pMesh->secondaryMap secondary:pMesh->DefaultLightmapIndex subImage:pMesh->LightmapIndex];
    }
                    //[_texManager activateTextureOfIdent:pMesh->baseMap subImage:0 useAlphas:NO];
                
                    //Whats the diffuse colour? Really need to extend this class to use the shaders
                    //senv
                
                    //
                    glActiveTextureARB(GL_TEXTURE2_ARB);
                
                    glEnableClientState(GL_VERTEX_ARRAY);
                    glVertexPointer(3, GL_FLOAT, 56, pMesh->pVert[0].vertex_k);
    
                    if ([render_meshc state])
                    {
                                    if (useNewRenderer() == 3)
                                    {
                                        if (pMesh->isWaterShader)
                                        {
                                            glEnable(GL_BLEND);
                                            glColor4f(1.0, 0, 0, 0.3f);
                                        }
                                        else
                                        {
                                            glColor4f(pMesh->r, pMesh->g, pMesh->b, 1.0);
                                        }
                                    }
                                    else
                                    {
                                         glColor4f(pMesh->r, pMesh->g, pMesh->b, 1.0f);
                                    }
                    }
    
                //
                
                    // texture coord 0
                    glClientActiveTextureARB(GL_TEXTURE0_ARB); // program texcoord unit 0
                    glTexCoordPointer(2, GL_FLOAT, 56, pMesh->pVert[0].uv);
                    glNormalPointer(GL_FLOAT, 56, pMesh->pVert[0].normal);
                    
                    glEnableClientState(GL_TEXTURE_COORD_ARRAY); // enable array data to shader
                
                    if (useLightmaps)
                    {
                        glClientActiveTextureARB(GL_TEXTURE2_ARB);
                        glTexCoordPointer(2, GL_FLOAT, 20, pMesh->pLightmapVert[0].uv);
                        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
                    }
                
                   
                
                    if (showDetail)
                    {
                        //texture coord 1
                        glClientActiveTextureARB(GL_TEXTURE1_ARB);
                        glTexCoordPointer(2, GL_FLOAT, 56, pMesh->pVert[0].uv);
                        glNormalPointer(GL_FLOAT, 56, pMesh->pVert[0].normal);
                        
                        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
                        
                        if ([render_scaling state])
                        {
                        glActiveTextureARB(GL_TEXTURE1_ARB);
                        glMatrixMode(GL_TEXTURE);
                        glPushMatrix();
                        glScalef(pMesh->secondaryMapScale,pMesh->secondaryMapScale, 0.0);
                        }
                    }
                    else
                    {
                        glActiveTextureARB(GL_TEXTURE1_ARB);
                        glDisable(GL_TEXTURE_2D);
                        
                        glClientActiveTextureARB(GL_TEXTURE0_ARB);
                        glActiveTextureARB(GL_TEXTURE0_ARB);
                    }
                
                
                    
                    glDrawElements(GL_TRIANGLES, (pMesh->IndexCount * 3), GL_UNSIGNED_SHORT, pMesh->pIndex);
                    
                    if (showDetail)
                    {
                        glActiveTextureARB(GL_TEXTURE1_ARB);
                        glPopMatrix();
                        glMatrixMode(GL_MODELVIEW);
                        
                        glClientActiveTextureARB(GL_TEXTURE1_ARB);
                        glDisableClientState(GL_TEXTURE_COORD_ARRAY);
                    }
                    
                    glClientActiveTextureARB(GL_TEXTURE0_ARB);
                    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
                    
                    glDisableClientState(GL_VERTEX_ARRAY);
                
                    glActiveTextureARB(GL_TEXTURE2_ARB);
                    glDisable(GL_TEXTURE_2D);
                
                    glActiveTextureARB(GL_TEXTURE1_ARB);
                    glDisable(GL_TEXTURE_2D);
                    
                    glActiveTextureARB(GL_TEXTURE0_ARB);
                    glDisable(GL_TEXTURE_2D);
                    glDisable(GL_BLEND);
                
                    
                    
                    
                    
                    
                    
                    
                
                    if (showDetail2)
                    {
                    //[_texManager activateTextureOfIdent:pMesh->DefaultBitmapIndex subImage:0 useAlphas:NO];
                        glEnable(GL_BLEND);
                        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                        glBlendFunc(GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA);
            
                //glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
                
 
                //if (mesh_index == selectedBSP)
                //    glColor4f(0.5,1,1,1);
                
                    //glPushMatrix();
                        if ([render_idents state])
                        {
                    [_texManager activateTextureAndLightmap:pMesh->baseMap lightmap:pMesh->primaryMap secondary:pMesh->DefaultLightmapIndex subImage:pMesh->LightmapIndex];
                        }
                        
                    //glColor4f(1,1,1,1);
                glActiveTextureARB(GL_TEXTURE0_ARB);
                
                glEnableClientState(GL_VERTEX_ARRAY);
                glVertexPointer(3, GL_FLOAT, 56, pMesh->pVert[0].vertex_k);
                
                // texture coord 0
                glClientActiveTextureARB(GL_TEXTURE0_ARB); // program texcoord unit 0
                glTexCoordPointer(2, GL_FLOAT, 56, pMesh->pVert[0].uv);
                glNormalPointer(GL_FLOAT, 56, pMesh->pVert[0].normal);
                
                glEnableClientState(GL_TEXTURE_COORD_ARRAY); // enable array data to shader
                
                if (useLightmaps)
                {
                    glClientActiveTextureARB(GL_TEXTURE2_ARB);
                    glTexCoordPointer(2, GL_FLOAT, 20, pMesh->pLightmapVert[0].uv);
                    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
                }
                
                if (showDetail)
                {
                    //texture coord 1
                    glClientActiveTextureARB(GL_TEXTURE1_ARB);
                    glTexCoordPointer(2, GL_FLOAT, 56, pMesh->pVert[0].uv);
                    glNormalPointer(GL_FLOAT, 56, pMesh->pVert[0].normal);
                    
                    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
                    
                    if ([render_scaling state])
                    {
                    glActiveTextureARB(GL_TEXTURE1_ARB);
                    glMatrixMode(GL_TEXTURE);
                    glPushMatrix();
                    glScalef(pMesh->primaryMapScale,pMesh->primaryMapScale, 0.0);
                    }
                }
                    
                    else
                    {
                        glActiveTextureARB(GL_TEXTURE1_ARB);
                        glDisable(GL_TEXTURE_2D);
                        
                        glClientActiveTextureARB(GL_TEXTURE0_ARB);
                        glActiveTextureARB(GL_TEXTURE0_ARB);
                    }
                
                
                
                
                glDrawElements(GL_TRIANGLES, (pMesh->IndexCount * 3), GL_UNSIGNED_SHORT, pMesh->pIndex);
                
                if (showDetail)
                {
                    if ([render_scaling state])
                    {
                    glActiveTextureARB(GL_TEXTURE1_ARB);
                    glPopMatrix();
                    glMatrixMode(GL_MODELVIEW);
                    }
                    
                    glClientActiveTextureARB(GL_TEXTURE1_ARB);
                    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
                }
                
                glClientActiveTextureARB(GL_TEXTURE0_ARB);
                glDisableClientState(GL_TEXTURE_COORD_ARRAY);
                
                glDisableClientState(GL_VERTEX_ARRAY);
                
                glActiveTextureARB(GL_TEXTURE2_ARB);
                glDisable(GL_TEXTURE_2D);
                
                glActiveTextureARB(GL_TEXTURE1_ARB);
                glDisable(GL_TEXTURE_2D);
                
                glActiveTextureARB(GL_TEXTURE0_ARB);
                glDisable(GL_TEXTURE_2D);
                glDisable(GL_BLEND);
                    }
                
                
                
                //No fog ;)
                
if (useNewRenderer() == 3 && [render_sun state])
{
                //Third pass - brighten your day!
                if (showDetail2 && pMesh->isWaterShader == NO)
                {
                    glEnable(GL_BLEND);
                    glBlendFunc(GL_DST_COLOR, GL_ONE);
                    
                    glColor4f(1.0f,1.0f,1.0f,0.8f);
                    
                    glEnableClientState(GL_VERTEX_ARRAY);
                    glVertexPointer(3, GL_FLOAT, 56, pMesh->pVert[0].vertex_k);
                    glDrawElements(GL_TRIANGLES, (pMesh->IndexCount * 3), GL_UNSIGNED_SHORT, pMesh->pIndex);
                    glDisableClientState(GL_VERTEX_ARRAY);
                }
            }
            
                
                
                
                    glDepthFunc(GL_LEQUAL);
}
            
            }
            //glPopMatrix();
        }

        else if (true)
        {
            //glAlphaFunc ( GL_GREATER, 0.1 ) ;
            //glEnable ( GL_ALPHA_TEST ) ;
            if (![render_SP state])
                return;
            
            glColor4f(1.0f, 1.0f, 1.0f, 0.5f);
            
   
            if (useNewRenderer() != 1)
            {
                glActiveTextureARB(GL_TEXTURE2_ARB);
                glDisable(GL_TEXTURE_2D);
                glActiveTextureARB(GL_TEXTURE1_ARB);
                glDisable(GL_TEXTURE_2D);
                glActiveTextureARB(GL_TEXTURE0_ARB);
                glDisable(GL_TEXTURE_2D);
                glDisable(GL_BLEND);
            }
            
            glActiveTextureARB(GL_TEXTURE0_ARB);
            glEnable(GL_TEXTURE_2D);
            
            if (useNewRenderer() >= 2)
                [_texManager activateTextureOfIdent:pMesh->DefaultBitmapIndex subImage:0 useAlphas:YES];
            else
                [_texManager activateTextureOfIdent:pMesh->DefaultBitmapIndex subImage:0 useAlphas:NO];
            
            
            if (pMesh->isWaterShader)
            {
                glEnable(GL_BLEND);
                glColor4f((CGFloat)(pMesh->r), (CGFloat)(pMesh->g), (CGFloat)(pMesh->b), 0.5f);
                
                glDisable(GL_FOG);
            }
            
           
            
            glEnableClientState(GL_VERTEX_ARRAY);
            glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        
            glVertexPointer(3, GL_FLOAT, 56, pMesh->pVert[0].vertex_k);
            glTexCoordPointer(2, GL_FLOAT, 56, pMesh->pVert[0].uv);
            
            glDrawElements(GL_TRIANGLES, (pMesh->IndexCount * 3), GL_UNSIGNED_SHORT, pMesh->pIndex);
            
            glDisableClientState(GL_TEXTURE_COORD_ARRAY);
            glDisableClientState(GL_VERTEX_ARRAY);
            
                
            glDisable(GL_TEXTURE_2D);
            glDisable(GL_BLEND);
            
            if (pMesh->isWaterShader)
            {
                glDisable(GL_BLEND);
                glEnable(GL_FOG);
            }

        }
		else
        {
            int x;
            unsigned short index, index2, index3;
            
    
            [_texManager activateTextureOfIdent:pMesh->DefaultBitmapIndex subImage:0 useAlphas:NO];
            
            
            glBegin(GL_TRIANGLES);
            for (x = 0; x < (pMesh->IndexCount); x++)
            {
                index = pMesh->pIndex[x].tri_ind[0];
                index2 = pMesh->pIndex[x].tri_ind[1];
                index3 = pMesh->pIndex[x].tri_ind[2];
                
                Vector *tempVector = pMesh->pVert[index].vertex_k;
                glNormal3f(tempVector->normalx,tempVector->normaly,tempVector->normalz);
                glTexCoord2f(pMesh->pVert[index].uv[0],pMesh->pVert[index].uv[1]);
                glVertex3f(tempVector->x,tempVector->y,tempVector->z);
                
                Vector *tempVector2 = pMesh->pVert[index2].vertex_k;
                glNormal3f(tempVector2->normalx,tempVector2->normaly,tempVector2->normalz);
                glTexCoord2f(pMesh->pVert[index2].uv[0], pMesh->pVert[index2].uv[1]);
                glVertex3f(tempVector2->x,tempVector2->y,tempVector2->z);
                
                Vector *tempVector3 = pMesh->pVert[index3].vertex_k;
                glNormal3f(tempVector3->normalx,tempVector3->normaly,tempVector3->normalz);
                glTexCoord2f(pMesh->pVert[index3].uv[0],pMesh->pVert[index3].uv[1]);
                glVertex3f(tempVector3->x,tempVector3->y,tempVector3->z);
            }
            glEnd();
        }
	//}
    
    
    
}
- (void)drawAxes
{
	// Red is X
	// White is Y
	// Blue is Z
	/*glBegin(GL_LINES);
		glColor3f(1.0f,0.0f,0.0f);
		glVertex3f(15.0f,0.0f,0.0f);
		glVertex3f(-15.0f,0.0f,0.0f);
		
		glColor3f(1.0f, 1.0f, 1.0f);
		glVertex3f(0.0f,15.0f,0.0f);
		glVertex3f(0.0f,-15.0f,0.0f);
		
		glColor3f(0.0f,0.0f, 1.0f);
		glVertex3f(0.0f, 0.0f, 15.0f);
		glVertex3f(0.0f, 0.0f, -15.0f);
	glEnd();*/
        glBegin(GL_LINES);
		// Z
		glColor3f(0,0,1);
		glVertex3f(0,0,0);
		glVertex3f(0,0,20);

		// Y
		glColor3f(0,1,0);
		glVertex3f(0,0,0);
		glVertex3f(0,20,0);
  
		// X
		glColor3f(1,0,0);
		glVertex3f(0,0,0);
		glVertex3f(20,0,0);
	
	
		// Z
		//glColor3f(1,1,0);
		//glVertex3f(0,0,0);
		//glVertex3f(0,0,20);
	
	
  glEnd();
}
- (void)resetMeshColors
{
	meshColor.red = meshColor.green = meshColor.blue = 1.0f;
	meshColor.color_count = 0;
}
- (void)setNextMeshColor
{
	if (meshColor.red < 0.2)
		meshColor.red = 1;
	if (meshColor.blue < 0.2)
		meshColor.blue = 1;
	if (meshColor.green < 0.2)
		meshColor.green = 1;
	
	if ((meshColor.color_count%3) == 0);
		meshColor.red -= 0.1f;
	if ((meshColor.color_count%3) == 1)
		meshColor.blue -= 0.1f;
	if ((meshColor.color_count%3) == 2)
		meshColor.green -= 0.1f;
	
	meshColor.color_count++;
	
	glColor4f(1.0f, 0.0f, 0.0f, 1.0f);
}
/* 
*
*		End BSP Rendering 
*
*/

/*
* 
*		Begin scenario rendering
* 
*/
- (float)distanceToObject:(float *)d
{
	return (float)sqrt(powf(d[0] - [_camera position][0],2) + powf(d[1] - [_camera position][1], 2) + powf(d[2] - [_camera position][2], 2));
}

- (void)renderAllMapObjects
{
	/*double time = mach_absolute_time();
     NSLog(@"%fd", (mach_absolute_time()-time)/100000000.0);*/
    
   USEDEBUG NSLog(@"RENDERING MAP OBJECTS");
    bool nameBSP = false;
	
	int x, i, name = 1;
	float pos[6], distanceTo;
	
    vehicle_reference *vehi_refs;
	vehicle_spawn *vehi_spawns;
	scenery_spawn *scen_spawns;
	mp_equipment *equipSpawns;
	machine_spawn *mach_spawns;
	encounter *encounters;
	SkyBox *skies;
	player_spawn *spawns;
	bipd_reference *bipd_refs;
    
	glInitNames();
	glPushName(0);
    
    
	
	// This one does its own namings
    USEDEBUG NSLog(@"Render netgames");
    if ([render_netgame state])
    {
    if (!nameBSP)
        [self renderNetgameFlags:&name];
    }
	USEDEBUG NSLog(@"Load others");
	bipd_refs = [_scenario bipd_references];
    vehi_refs = [_scenario vehi_references];
	vehi_spawns = [_scenario vehi_spawns];
	scen_spawns = [_scenario scen_spawns];
	equipSpawns = [_scenario item_spawns];
	spawns = [_scenario spawns];
	mach_spawns = [_scenario mach_spawns];
	encounters = [_scenario encounters];
	skies = [_scenario sky];
    
    //--------------------------------
    //The copyright for the following code is owned by Samuel Colbran (Samuco).
    //The copyright for other smaller segments that are not identified by these comments are also owned by Samuel Colbran (Samuco).
    //--------------------------------
    
    
if ([paintDebug state])
{
    glLineWidth(_lineWidth);
	
	glBegin(GL_LINES);
    glVertex3f(fromPt[0], fromPt[1], fromPt[2]);
    glVertex3f(toPt[0], toPt[1], toPt[2]);
	glEnd();
}

    MapTag *bipd = [_mapfile bipd];

	glColor4f(0.0f,0.0f,0.0f,1.0f);
	
    BOOL ignoreDrawing = FALSE;
    //rendDistance = 50;
    
    USEDEBUG NSLog(@"MP0");
    if (!ignoreDrawing)
    {
        USEDEBUG NSLog(@"MP0.1");
    if (TRUE)//useNewRenderer())
    {
        USEDEBUG NSLog(@"MP0.2");
        glEnableClientState(GL_VERTEX_ARRAY);
        USEDEBUG NSLog(@"MP0.3");
        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        USEDEBUG NSLog(@"MP0.4");
    }
        
        if ([render_playerSpawns state])
        {
	for (x = 0; x < [_scenario player_spawn_count]; x++)
	{
        USEDEBUG NSLog(@"MP0.5 %d", x );
        if (!nameBSP)
        {
            // Lookup goes hur
            if (_lookup)
                _lookup[name] = (long)(s_playerspawn * MAX_SCENARIO_OBJECTS + x);
            glLoadName(name);
            name++;
        }
        USEDEBUG NSLog(@"MP0.6 %d", x );
		if (spawns[x].bsp_index == activeBSPNumber)
        {
             if (TRUE)//useNewRenderer())
            {
                if (bipd && [bipd respondsToSelector:@selector(drawAtPoint:lod:isSelected:useAlphas:)])
                {
                    
                    USEDEBUG NSLog(@"MP0.7 %d", x );
                    int type1 = spawns[x].type1;
          
                    USEDEBUG NSLog(@"MP0.8 %d", x );
                    int showType = [[renderGametype selectedItem] tag];
                    
                    if (showType == -1)
                        continue;
                    
                    USEDEBUG NSLog(@"MP0.9 %d", x );
                    //This visbility is a mess xD
                    BOOL visible = FALSE;
                    if (showType == 12 || showType == 15)
                        visible = TRUE;
                    else if (showType == 13)
                    {
                        if (type1 != 1)
                            visible = TRUE;
                    }
                    else if (showType == 14)
                    {
                        if (type1 != 1 && type1 != 5)
                            visible = TRUE;
                    }
                    else
                    {
                        if (type1 == showType)
                            visible = TRUE;
                        else if (type1 == 12||type1 == 15)
                            visible = TRUE;
                        else if (type1 == 13)
                        {
                            if (showType != 1)
                                visible = TRUE;
                        }
                        else if (type1 == 14)
                        {
                            if (showType != 1 && showType != 5)
                                visible = TRUE;
                        }
                    }
                    USEDEBUG NSLog(@"MP1.1 %d", x );
                    int team = spawns[x].team_index;
                    if (type1 != 1  && !((type1 == 12 ||type1 == 15)&& showType == 1))
                    {
                        glColor4f(1.0,1.0,1.0, 1.0);
                        if (spawns[x].isSelected)
                        {
                            glColor4f(1.0,1.0,0.0, 1.0);
                        }
                    }
                    else
                    {
                        if (team == 0)
                        {
                            glColor4f(1.0,0.3,0.3, 1.0);
                            
                            if (spawns[x].isSelected)
                            {
                                glColor4f(1.0,0.8,0.0, 1.0);
                            }
                        }
                        else if (team == 1)
                        {
                            glColor4f(0.3,0.3,1.0, 1.0);
                            if (spawns[x].isSelected)
                            {
                                glColor4f(0.0,1.0,1.0, 1.0);
                            }
                        }
                        else if (team == 5)
                            glColor4f(1.0,1.0,0.0, 1.0);
                        else if (team == 3)
                            glColor4f(0.0,1.0,0.0, 1.0);
                        else if (team == 2)
                            glColor4f(1.0,1.0,0.0, 1.0);
                        else if (team == 9)
                            glColor4f(0.0,1.0,1.0, 1.0);
                        else
                            if (spawns[x].isSelected)
                            {
                                glColor4f(1.0,1.0,0.0, 1.0);
                            }
                    }
                    
                     USEDEBUG NSLog(@"MP1.2 %d", x );
                    
                    
                    if (visible)
                    {
                         USEDEBUG NSLog(@"MP1.3 %d", x );
                        for (i = 0; i < 3; i++)
                            pos[i] = spawns[x].coord[i];
                         USEDEBUG NSLog(@"MP1.4 %d", x );
                        pos[3] = 0;
                        pos[4] = pos[5] = 0.0f;
                         USEDEBUG NSLog(@"MP1.5 %d", x );
                        distanceTo = [self distanceToObject:pos];
                         USEDEBUG NSLog(@"MP1.6 %d", x );
                        if (distanceTo < rendDistance || spawns[x].isSelected)
                        {
                             USEDEBUG NSLog(@"MP1.7 %d", x );
                            [bipd drawAtPoint:spawns[x].coord lod:5 isSelected:NO useAlphas:_useAlphas distance:distanceTo];
                        }
                    }
                }
                else
                {
                    [self renderPlayerSpawn:spawns[x].coord team:spawns[x].team_index isSelected:spawns[x].isSelected];
                }
                
            }
            else
            {
                [self renderPlayerSpawn:spawns[x].coord team:spawns[x].team_index isSelected:spawns[x].isSelected];
            }
        }
	}
    }
    
     if (TRUE)//useNewRenderer())
    {
        glDisableClientState(GL_VERTEX_ARRAY);
        glDisableClientState(GL_TEXTURE_COORD_ARRAY);
        
        glDisable(GL_TEXTURE_2D);
        glDisable(GL_BLEND);
    }
        
    
    
        /*
        
	for (x = 0; x < bsp_point_count; x++)
	{
		// Lookup goes hur
		if (_lookup)
			_lookup[name] = (long)(s_bsppoint * MAX_SCENARIO_OBJECTS + x);
		glLoadName(name);
		name++;
		[self renderPoint:bsp_points[x].coord isSelected:bsp_points[x].isSelected];
	}
         */
        
    
        /*
	for (x = 0; x < [[mapBSP mesh] coll_count]; x++)
	{
		// Lookup goes hur
		if (_lookup)
			_lookup[name] = (long)(s_colpoint * MAX_SCENARIO_OBJECTS + x);
		glLoadName(name);
		name++;
		
		pos[0]=[[mapBSP mesh] collision_verticies][x].x;
		pos[1]=[[mapBSP mesh] collision_verticies][x].y;
		pos[2]=[[mapBSP mesh] collision_verticies][x].z;
		
		//NSLog(@"%f", pos[0]);
	
		
		
		[self renderCP:pos isSelected:[[mapBSP mesh] collision_verticies][x].isSelected];
	}
         */
     
        
    //--------------------------------
    //END CODE
    //--------------------------------
    
        USEDEBUG NSLog(@"Encounters");
        if ([render_Encounters state])
        {
    glColor4f(0.0f,0.0f,0.0f,1.0f);
	for (i=0; i < [_scenario encounter_count]; i++)
	{
		player_spawn *encounter_spawns;
		encounter_spawns = encounters[i].start_locs;
		
		for (x = 0; x < encounters[i].start_locs_count; x++)
		{
            if (!nameBSP)
            {
                // Lookup goes hur
                if (_lookup)
                    _lookup[name] = (long)(s_encounter * MAX_SCENARIO_OBJECTS + i);
                glLoadName(name);
                name++;
            }
			
			if (encounter_spawns[x].bsp_index == activeBSPNumber)
				[self renderPlayerSpawn:encounter_spawns[x].coord team:1 isSelected:encounter_spawns[x].isSelected];
		}
	}
        }
}
USEDEBUG NSLog(@"MP1");
    
    
if (drawObjects())
{
    USEDEBUG NSLog(@"MP2");
    if (TRUE)//useNewRenderer())
    {
        glEnableClientState(GL_VERTEX_ARRAY);
        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        glColor3f(1.0f,1.0f,1.0f);
    }
    USEDEBUG NSLog(@"MP3");
    glColor4f(1.0f,1.0f,1.0f,1.0f);
    
    if ([render_itemSpawns state])
    {
	for (x = 0; x < [_scenario item_spawn_count]; x++)
	{
		// Lookup goes hur
        if (!nameBSP)
        {
            if (_lookup)
                _lookup[name] = (long)(s_item * MAX_SCENARIO_OBJECTS + x); 
            glLoadName(name);
            name++;
        }
		if ([_mapfile isTag:equipSpawns[x].modelIdent])
		{
			//NSRunAlertPanel([NSString stringWithFormat:@"%d",(int)equipSpawns[x].modelIdent], @"", @"", @"", @"");
			
			for (i = 0; i < 3; i++)
				pos[i] = equipSpawns[x].coord[i];
			pos[3] = equipSpawns[x].yaw;
			pos[4] = pos[5] = 0.0f;
			distanceTo = [self distanceToObject:pos];
			if (distanceTo < rendDistance || equipSpawns[x].isSelected)
				[[_mapfile tagForId:equipSpawns[x].modelIdent] drawAtPoint:pos lod:_LOD isSelected:equipSpawns[x].isSelected useAlphas:_useAlphas distance:distanceTo];
		}
	}
    }
    USEDEBUG NSLog(@"MP4");

    if ([render_machines state])
    {
	for (x = 0; x < [_scenario mach_spawn_count]; x++)
	{
        if (!nameBSP)
        {
		if (_lookup)
			_lookup[name] = (long)(s_machine * MAX_SCENARIO_OBJECTS + x);
		glLoadName(name);
		name++;
        }
		if ([_mapfile isTag:[_scenario mach_references][mach_spawns[x].numid].machTag.TagId])
		{
			distanceTo = [self distanceToObject:pos];
			
			if ((distanceTo < rendDistance || mach_spawns[x].isSelected) && mach_spawns[x].desired_permutation == activeBSPNumber)
				[[_mapfile tagForId:[_scenario mach_references][mach_spawns[x].numid].modelIdent] drawAtPoint:mach_spawns[x].coord lod:_LOD isSelected:mach_spawns[x].isSelected useAlphas:_useAlphas distance:distanceTo];
		}
	}
    }
    
        USEDEBUG NSLog(@"MP5");
    if ([render_vehicles state])
    {
	for (x = 0; x < [_scenario vehicle_spawn_count]; x++)
	{
        if (!nameBSP)
        {
		// Lookup goes hur
		if (_lookup)
			_lookup[name] = (long)(s_vehicle * MAX_SCENARIO_OBJECTS + x);
		glLoadName(name);
		name++;
        }
		if ([_mapfile isTag:vehi_spawns[x].modelIdent])
		{
            
            //Do we even render this guy?
            int showType = [[renderGametype selectedItem] tag];
            if (showType != -1)
            {
                short *pointer;
                pointer = &([_scenario vehi_spawns][x].unknown2[14]);
                pointer = pointer + 1;
                
                //Is this vehicle on CTF?
                short sel = *pointer;
                
                
                if (showType == 1 && !(((sel>>(31-30)) & 1))) //CTF
                {
                    continue;
                }
                else if (showType == 4 && !(((sel>>(31-29)) & 1))) //King
                {
                    continue;
                }
                else if (showType == 3 && !(((sel>>(31-28)) & 1))) //Oddball
                {
                    continue;
                }
                else if (showType == 2 && !(((sel>>(31-31)) & 1))) //Slayer
                {
                    continue;
                }
            
			//NSLog(@"%d", (int)vehi_spawns[x].modelIdent);
			//NSLog(@"Vehi Model Ident: 0x%x", vehi_spawns[x].modelIdent);
			for (i = 0; i < 3; i++)
				pos[i] = vehi_spawns[x].coord[i];
			for (i = 3; i < 6; i++)
				pos[i] = vehi_spawns[x].rotation[i - 3];
            
			distanceTo = [self distanceToObject:pos];
			if ((distanceTo < rendDistance || vehi_spawns[x].isSelected) && vehi_spawns[x].desired_permutation == activeBSPNumber)
				[[_mapfile tagForId:vehi_spawns[x].modelIdent] drawAtPoint:pos lod:_LOD isSelected:vehi_spawns[x].isSelected useAlphas:_useAlphas distance:distanceTo];
                
            }
		}
	}
    }
USEDEBUG NSLog(@"MP6");
    
    if ([render_scen state])
    {
	for (x = 0; x < [_scenario scenery_spawn_count]; x++)
	{
        if (!nameBSP)
        {
		// Lookup goes hur
		if (_lookup)
			_lookup[name] = (long)(s_scenery * MAX_SCENARIO_OBJECTS + x);
		glLoadName(name);
        
		name++;
        }
        
		if ([_mapfile isTag:scen_spawns[x].modelIdent])
		{
			for (i = 0; i < 3; i++)
				pos[i] = scen_spawns[x].coord[i];
			for (i = 3; i < 6; i++)
				pos[i] = scen_spawns[x].rotation[i - 3];
			distanceTo = [self distanceToObject:pos];

			if ((distanceTo < rendDistance || scen_spawns[x].isSelected) && scen_spawns[x].desired_permutation == activeBSPNumber)
				[[_mapfile tagForId:scen_spawns[x].modelIdent] drawAtPoint:pos lod:_LOD isSelected:scen_spawns[x].isSelected useAlphas:_useAlphas distance:distanceTo];
		}
	}
    }
USEDEBUG NSLog(@"MP7");
    
    

     if (TRUE)//useNewRenderer())
    {
        glDisableClientState(GL_VERTEX_ARRAY);
        glDisableClientState(GL_TEXTURE_COORD_ARRAY);
        
        glDisable(GL_TEXTURE_2D);
        glDisable(GL_BLEND);
    }
    USEDEBUG NSLog(@"MP11");
}


}


- (void)renderObject:(dynamic_object)obj
{
	
	float x = obj.x;
	float y = obj.y;
	float z = obj.z;
	
	glColor3f(1.0,1.0,1.0);
	
	glPushMatrix();
	glTranslatef(x, y, z);
	//glRotatef(coord[3] * 57.29577, 0, 0,1);
	float height = 0.6;
	glBegin(GL_QUADS);
	{
		glVertex3f(0.2f,0.2f,height);
		glVertex3f(0.2f,-0.2f,height);
		glVertex3f(-0.2f,-0.2f,height);
		glVertex3f(-0.2f,0.2f,height);
		
		glVertex3f(0.2f,0.2f,height);
		glVertex3f(0.2f,-0.2f,height);
		glVertex3f(0.2f,-0.2f,-height);
		glVertex3f(0.2f,0.2f,-height);
		
		glVertex3f(-0.2f,-0.2f,height);
		glVertex3f(0.2f,-0.2f,height);
		glVertex3f(0.2f,-0.2f,-height);
		glVertex3f(-0.2f,-0.2f,-height);
		
		glVertex3f(-0.2f,-0.2f,height);
		glVertex3f(-0.2f,0.2f,height);
		glVertex3f(-0.2f,0.2f,-height);
		glVertex3f(-0.2f,-0.2f,-height);
		
		glVertex3f(0.2f,0.2f,height);
		glVertex3f(-0.2f,0.2f,height);
		glVertex3f(-0.2f,0.2f,-height);
		glVertex3f(0.2f,0.2f,-height);
		
		glVertex3f(0.2f,0.2f,-height);
		glVertex3f(0.2f,-0.2f,-height);
		glVertex3f(-0.2f,-0.2f,-height);
		glVertex3f(-0.2f,0.2f,-height);	
	}
	glEnd();
	glPopMatrix();
	glEndList();
}

- (void)renderPlayerCharacter:(int)player_number team:(int)teamss
{
	
	float x = playercoords[(player_number * 8) + 0];
	float y = playercoords[(player_number * 8) + 1];
	float z = playercoords[(player_number * 8) + 2];
	float team = playercoords[(player_number * 8) + 3];
	float isSelected = playercoords[(player_number * 8) + 4];
	
	if (team == 0.0)
		glColor3f(1.0,0.0,0.0);
	else if (team == 1.0)
		glColor3f(0.0,0.0,1.0);
	else if (team == 8.0)
		glColor3f(0.0,1.0,1.0);

	if (isSelected == 1.0)
		glColor3f(1.0,1.0,0.0);
	
	glPushMatrix();
	glTranslatef(x, y, z);
	
	
	glRotatef(piradToDeg( playercoords[(player_number * 8) + 6]),0,0,1);
	
	float height = 0.6;
	glBegin(GL_QUADS);
	{
		glVertex3f(0.2f,0.2f,height);
		glVertex3f(0.2f,-0.2f,height);
		glVertex3f(-0.2f,-0.2f,height);
		glVertex3f(-0.2f,0.2f,height);
		
		glVertex3f(0.2f,0.2f,height);
		glVertex3f(0.2f,-0.2f,height);
		glVertex3f(0.2f,-0.2f,-height);
		glVertex3f(0.2f,0.2f,-height);
		
		glVertex3f(-0.2f,-0.2f,height);
		glVertex3f(0.2f,-0.2f,height);
		glVertex3f(0.2f,-0.2f,-height);
		glVertex3f(-0.2f,-0.2f,-height);
		
		glVertex3f(-0.2f,-0.2f,height);
		glVertex3f(-0.2f,0.2f,height);
		glVertex3f(-0.2f,0.2f,-height);
		glVertex3f(-0.2f,-0.2f,-height);
		
		glVertex3f(0.2f,0.2f,height);
		glVertex3f(-0.2f,0.2f,height);
		glVertex3f(-0.2f,0.2f,-height);
		glVertex3f(0.2f,0.2f,-height);
		
		glVertex3f(0.2f,0.2f,-height);
		glVertex3f(0.2f,-0.2f,-height);
		glVertex3f(-0.2f,-0.2f,-height);
		glVertex3f(-0.2f,0.2f,-height);	
		
	}
	glEnd();
	glBegin(GL_LINES);
	{
		// Now to try some other stuffs! Bwahaha!
		// set these lines to white
		glLineWidth(2.0f);
		// x
		glColor3f(1.0f,1.0f,1.0f);
		glVertex3f(0.0f,0.0f,0.0f);
		glVertex3f(50.0f,0.0f,0.0f);
		
	
		
		
	}
	glEnd();
	glPopMatrix();
	glEndList();
}

- (void)renderPlayerSpawn:(float *)coord team:(int)team isSelected:(BOOL)isSelected
{
    
    
    
    
    
    
	if (team == 0)
		glColor3f(1.0,0.0,0.0);
	else if (team == 1)
		glColor3f(0.0,0.0,1.0);
	else if (team == 5)
		glColor3f(1.0,1.0,0.0);
	else if (team == 3)
		glColor3f(0.0,1.0,0.0);
	else if (team == 2)
		glColor3f(1.0,1.0,0.0);
	else if (team == 9)
		glColor3f(0.0,1.0,1.0);
	
	if (isSelected)
		glColor3f(0.0f, 1.0f, 0.0f);
	
	
	glPushMatrix();
	glTranslatef(coord[0], coord[1], coord[2]);
	glRotatef(coord[3] * 57.29577, 0, 0,1);

	glBegin(GL_QUADS);
	{
		glVertex3f(0.2f,0.2f,0.1f);
		glVertex3f(0.2f,-0.2f,0.1f);
		glVertex3f(-0.2f,-0.2f,0.1f);
		glVertex3f(-0.2f,0.2f,0.1f);
		
		glVertex3f(0.2f,0.2f,0.1f);
		glVertex3f(0.2f,-0.2f,0.1f);
		glVertex3f(0.2f,-0.2f,-0.1f);
		glVertex3f(0.2f,0.2f,-0.1f);
		
		glVertex3f(-0.2f,-0.2f,0.1f);
		glVertex3f(0.2f,-0.2f,0.1f);
		glVertex3f(0.2f,-0.2f,-0.1f);
		glVertex3f(-0.2f,-0.2f,-0.1f);
		
		glVertex3f(-0.2f,-0.2f,0.1f);
		glVertex3f(-0.2f,0.2f,0.1f);
		glVertex3f(-0.2f,0.2f,-0.1f);
		glVertex3f(-0.2f,-0.2f,-0.1f);
		
		glVertex3f(0.2f,0.2f,0.1f);
		glVertex3f(-0.2f,0.2f,0.1f);
		glVertex3f(-0.2f,0.2f,-0.1f);
		glVertex3f(0.2f,0.2f,-0.1f);
		
		glVertex3f(0.2f,0.2f,-0.1f);
		glVertex3f(0.2f,-0.2f,-0.1f);
		glVertex3f(-0.2f,-0.2f,-0.1f);
		glVertex3f(-0.2f,0.2f,-0.1f);	
	}
	glEnd();
	if (isSelected)
	{
		glBegin(GL_LINES);
		{
			// Now to try some other stuffs! Bwahaha!
			// set these lines to white
			glLineWidth(2.0f);
			// x
			glColor3f(1.0f,0.0f,0.0f);
			glVertex3f(0.0f,0.0f,0.0f);
			glVertex3f(50.0f,0.0f,0.0f);
			// y
			glColor3f(0.0f,1.0f,0.0f);
			glVertex3f(0.0f,0.0f,0.0f);
			glVertex3f(0.0f,50.0f,0.0f);
			// z
			glColor3f(0.0f,0.0f,1.0f);
			glVertex3f(0.0f,0.0f,0.0f);
			glVertex3f(0.0f,0.0f,50.0f);
			
			
			/*
			float my_x = coord[0];
			float my_y = coord[1];
			float my_z = coord[2];
			
			float c_x = [_camera position][0];
			float c_y = [_camera position][1];
			float c_z = [_camera position][2];
			
			c_x = my_x - c_x;
			c_y = my_y - c_y;
			c_z = my_z - c_z;
			
			glColor3f(1.0f, 1.0f, 0.0f);
			glVertex3f(0.0f,0.0f,0.0f);
			glVertex3f(c_x, c_y, c_z);
			
			//COMEBACK*/
		}
		glEnd();
	}
	glPopMatrix();
	glEndList();
}

- (void)renderCube:(float *)coord rotation:(float *)rotation color:(float *)color selected:(BOOL)selected
{
	glPushMatrix();
	glTranslatef(coord[0], coord[1], coord[2]);
	glRotatef(piradToDeg( rotation[0]),0,0,1);
	glColor3f(color[0],color[1],color[2]);
	
	// lol, override
	if (selected)
		glColor3f(0.0f, 1.0f, 0.0f);
	
	glBegin(GL_QUADS);
	{
		glVertex3f(0.2f,0.2f,0.1f);
		glVertex3f(0.2f,-0.2f,0.1f);
		glVertex3f(-0.2f,-0.2f,0.1f);
		glVertex3f(-0.2f,0.2f,0.1f);
		
		glVertex3f(0.2f,0.2f,0.1f);
		glVertex3f(0.2f,-0.2f,0.1f);
		glVertex3f(0.2f,-0.2f,-0.1f);
		glVertex3f(0.2f,0.2f,-0.1f);
		
		glVertex3f(-0.2f,-0.2f,0.1f);
		glVertex3f(0.2f,-0.2f,0.1f);
		glVertex3f(0.2f,-0.2f,-0.1f);
		glVertex3f(-0.2f,-0.2f,-0.1f);
		
		glVertex3f(-0.2f,-0.2f,0.1f);
		glVertex3f(-0.2f,0.2f,0.1f);
		glVertex3f(-0.2f,0.2f,-0.1f);
		glVertex3f(-0.2f,-0.2f,-0.1f);
		
		glVertex3f(0.2f,0.2f,0.1f);
		glVertex3f(-0.2f,0.2f,0.1f);
		glVertex3f(-0.2f,0.2f,-0.1f);
		glVertex3f(0.2f,0.2f,-0.1f);
		
		glVertex3f(0.2f,0.2f,-0.1f);
		glVertex3f(0.2f,-0.2f,-0.1f);
		glVertex3f(-0.2f,-0.2f,-0.1f);
		glVertex3f(-0.2f,0.2f,-0.1f);
	}
	glEnd();
	glPopMatrix();
}


- (void)renderBox:(float *)coord rotation:(float *)rotation color:(float *)color selected:(BOOL)selected
{

    if (useNewRenderer() >= 2)
    {
        glPushMatrix();
        glTranslatef(coord[0], coord[1], coord[2]);
        glRotatef(piradToDeg( rotation[0]),0,0,1);
        glColor3f(color[0],color[1],color[2]);
        
        if (selected)
            glColor3f(0.0f, 1.0f, 0.0f);
		if (selected)
        {
            /*
            glBegin(GL_LINES);
            {
                // Now to try some other stuffs! Bwahaha!
                // set these lines to white
                glLineWidth(4.0f);
                // x
                glColor3f(1.0f,0.0f,0.0f);
                glVertex3f(0.0f,0.0f,0.0f);
                glVertex3f(50.0f,0.0f,0.0f);
                // y
                glColor3f(0.0f,1.0f,0.0f);
                glVertex3f(0.0f,0.0f,0.0f);
                glVertex3f(0.0f,50.0f,0.0f);
                // z
                glColor3f(0.0f,0.0f,1.0f);
                glVertex3f(0.0f,0.0f,0.0f);
                glVertex3f(0.0f,0.0f,50.0f);
                
                // pointer arrow
                glColor3f(1.0f,1.0f,1.0f);
                glVertex3f(0.5f,0.0f,0.0f);
                glVertex3f(0.3f,0.2f,0.0f);
                glVertex3f(0.5f,0.0f,0.0f);
                glVertex3f(0.3f,-0.2f,0.0f);
            }
            glEnd();
             */
        }
        
        
        GLUquadric *sphere=gluNewQuadric();
        gluQuadricDrawStyle( sphere, GLU_FILL);
        gluQuadricOrientation( sphere, GLU_OUTSIDE);

        gluSphere(sphere,[netgamesize floatValue],[spherequality integerValue],[spherequality integerValue]);
        gluDeleteQuadric ( sphere );
        glPopMatrix();
        return;
    }
    
	glPushMatrix();
	glTranslatef(coord[0], coord[1], coord[2]);
	glRotatef(piradToDeg( rotation[0]),0,0,1);
	glColor3f(color[0],color[1],color[2]);
	
	// lol, override
	if (selected)
		glColor3f(0.0f, 1.0f, 0.0f);
		
	glBegin(GL_QUADS);
	{
		glVertex3f(0.2f,0.2f,0.1f);
		glVertex3f(0.2f,-0.2f,0.1f);
		glVertex3f(-0.2f,-0.2f,0.1f);
		glVertex3f(-0.2f,0.2f,0.1f);
		
		glVertex3f(0.2f,0.2f,0.1f);
		glVertex3f(0.2f,-0.2f,0.1f);
		glVertex3f(0.2f,-0.2f,-0.1f);
		glVertex3f(0.2f,0.2f,-0.1f);
		
		glVertex3f(-0.2f,-0.2f,0.1f);
		glVertex3f(0.2f,-0.2f,0.1f);
		glVertex3f(0.2f,-0.2f,-0.1f);
		glVertex3f(-0.2f,-0.2f,-0.1f);
		
		glVertex3f(-0.2f,-0.2f,0.1f);
		glVertex3f(-0.2f,0.2f,0.1f);
		glVertex3f(-0.2f,0.2f,-0.1f);
		glVertex3f(-0.2f,-0.2f,-0.1f);
		
		glVertex3f(0.2f,0.2f,0.1f);
		glVertex3f(-0.2f,0.2f,0.1f);
		glVertex3f(-0.2f,0.2f,-0.1f);
		glVertex3f(0.2f,0.2f,-0.1f);
		
		glVertex3f(0.2f,0.2f,-0.1f);
		glVertex3f(0.2f,-0.2f,-0.1f);
		glVertex3f(-0.2f,-0.2f,-0.1f);
		glVertex3f(-0.2f,0.2f,-0.1f);	
	}
	glEnd();
	if (selected)
	{
		glBegin(GL_LINES);
		{
			// Now to try some other stuffs! Bwahaha!
			// set these lines to white
			glLineWidth(4.0f);
			// x
			glColor3f(1.0f,0.0f,0.0f);
			glVertex3f(0.0f,0.0f,0.0f);
			glVertex3f(50.0f,0.0f,0.0f);
			// y
			glColor3f(0.0f,1.0f,0.0f);
			glVertex3f(0.0f,0.0f,0.0f);
			glVertex3f(0.0f,50.0f,0.0f);
			// z
			glColor3f(0.0f,0.0f,1.0f);
			glVertex3f(0.0f,0.0f,0.0f);
			glVertex3f(0.0f,0.0f,50.0f);
			
			//glColor3f(1.0f,1.0f, 0.0f);
		//	glVertex3f(0.0f,0.0f,0.0f);
			//glVertex3f([_camera position][0], [_camera position][1], [_camera position][2]);
			
			
			// pointer arrow
			glColor3f(1.0f,1.0f,1.0f);
			glVertex3f(0.5f,0.0f,0.0f);
			glVertex3f(0.3f,0.2f,0.0f);
			glVertex3f(0.5f,0.0f,0.0f);
			glVertex3f(0.3f,-0.2f,0.0f);
		}
		glEnd();
	}
	glPopMatrix();
}

- (void)renderCP:(float *)coord isSelected:(BOOL)isSelected
{	
	glPushMatrix();
	glTranslatef(coord[0], coord[1], coord[2]);
	
	if (isSelected)
		glColor3f(1.0f, 1.0f, 0.0f);
	else 
		glColor3f(0.0,1.0,1.0);
	
	glBegin(GL_QUADS);
	{
		glVertex3f(0.1f,0.05f,0.05f);
		glVertex3f(0.1f,-0.05f,0.05f);
		glVertex3f(-0.1f,-0.05f,0.05f);
		glVertex3f(-0.1f,0.05f,0.05f);
		
		glVertex3f(0.1f,0.05f,0.05f);
		glVertex3f(0.1f,-0.05f,0.05f);
		glVertex3f(0.1f,-0.05f,-0.05f);
		glVertex3f(0.1f,0.05f,-0.05f);
		
		glVertex3f(-0.1f,-0.05f,0.05f);
		glVertex3f(0.1f,-0.05f,0.05f);
		glVertex3f(0.1f,-0.05f,-0.05f);
		glVertex3f(-0.1f,-0.05f,-0.05f);
		
		glVertex3f(-0.1f,-0.05f,0.05f);
		glVertex3f(-0.1f,0.05f,0.05f);
		glVertex3f(-0.1f,0.05f,-0.05f);
		glVertex3f(-0.1f,-0.05f,-0.05f);
		
		glVertex3f(0.1f,0.05f,0.05f);
		glVertex3f(-0.1f,0.05f,0.05f);
		glVertex3f(-0.1f,0.05f,-0.05f);
		glVertex3f(0.1f,0.05f,-0.05f);
		
		glVertex3f(0.1f,0.05f,-0.05f);
		glVertex3f(0.1f,-0.05f,-0.05f);
		glVertex3f(-0.1f,-0.05f,-0.05f);
		glVertex3f(-0.1f,0.05f,-0.05f);
	}
	glEnd();
	if (isSelected)
	{
		glBegin(GL_LINES);
		{
			// Now to try some other stuffs! Bwahaha!
			// set these lines to white
			glLineWidth(2.0f);
			// x
			glColor3f(1.0f,0.0f,0.0f);
			glVertex3f(0.0f,0.0f,0.0f);
			glVertex3f(50.0f,0.0f,0.0f);
			// y
			glColor3f(0.0f,1.0f,0.0f);
			glVertex3f(0.0f,0.0f,0.0f);
			glVertex3f(0.0f,50.0f,0.0f);
			// z
			glColor3f(0.0f,0.0f,1.0f);
			glVertex3f(0.0f,0.0f,0.0f);
			glVertex3f(0.0f,0.0f,50.0f);
		}
		glEnd();
	}
	glPopMatrix();
}

- (void)renderPoint:(float *)coord isSelected:(BOOL)isSelected
{
    
    glPushMatrix();
    glTranslatef(coord[0], coord[1], coord[2]);
    glColor3f(0.0, 1.0, 1.0);
    
    if (isSelected)
        glColor3f(0.0f, 1.0f, 0.0f);
    
    GLUquadric *sphere=gluNewQuadric();
    gluQuadricDrawStyle( sphere, GLU_FILL);
    gluQuadricNormals( sphere, GLU_SMOOTH);
    gluQuadricOrientation( sphere, GLU_OUTSIDE);
    gluQuadricTexture( sphere, GL_TRUE);
    
    gluSphere(sphere,0.01,10,10);
    gluDeleteQuadric ( sphere );
    glPopMatrix();
    
    return;
    
	glPushMatrix();
	glTranslatef(coord[0], coord[1], coord[2]);
	
	if (isSelected)
		glColor3f(1.0f, 1.0f, 0.0f);
	else
		glColor3f(0.0,1.0,0.0);
	
	glBegin(GL_QUADS);
	{
		glVertex3f(0.1f,0.05f,0.05f);
		glVertex3f(0.1f,-0.05f,0.05f);
		glVertex3f(-0.1f,-0.05f,0.05f);
		glVertex3f(-0.1f,0.05f,0.05f);
		
		glVertex3f(0.1f,0.05f,0.05f);
		glVertex3f(0.1f,-0.05f,0.05f);
		glVertex3f(0.1f,-0.05f,-0.05f);
		glVertex3f(0.1f,0.05f,-0.05f);
		
		glVertex3f(-0.1f,-0.05f,0.05f);
		glVertex3f(0.1f,-0.05f,0.05f);
		glVertex3f(0.1f,-0.05f,-0.05f);
		glVertex3f(-0.1f,-0.05f,-0.05f);
		
		glVertex3f(-0.1f,-0.05f,0.05f);
		glVertex3f(-0.1f,0.05f,0.05f);
		glVertex3f(-0.1f,0.05f,-0.05f);
		glVertex3f(-0.1f,-0.05f,-0.05f);
		
		glVertex3f(0.1f,0.05f,0.05f);
		glVertex3f(-0.1f,0.05f,0.05f);
		glVertex3f(-0.1f,0.05f,-0.05f);
		glVertex3f(0.1f,0.05f,-0.05f);
		
		glVertex3f(0.1f,0.05f,-0.05f);
		glVertex3f(0.1f,-0.05f,-0.05f);
		glVertex3f(-0.1f,-0.05f,-0.05f);
		glVertex3f(-0.1f,0.05f,-0.05f);
	}
	glEnd();
	if (isSelected)
	{
		glBegin(GL_LINES);
		{
			// Now to try some other stuffs! Bwahaha!
			// set these lines to white
			glLineWidth(2.0f);
			// x
			glColor3f(1.0f,0.0f,0.0f);
			glVertex3f(0.0f,0.0f,0.0f);
			glVertex3f(50.0f,0.0f,0.0f);
			// y
			glColor3f(0.0f,1.0f,0.0f);
			glVertex3f(0.0f,0.0f,0.0f);
			glVertex3f(0.0f,50.0f,0.0f);
			// z
			glColor3f(0.0f,0.0f,1.0f);
			glVertex3f(0.0f,0.0f,0.0f);
			glVertex3f(0.0f,0.0f,50.0f);
		}
		glEnd();
	}
	glPopMatrix();
}

- (void)renderFlag:(float *)coord team:(int)team isSelected:(BOOL)isSelected
{	
	glPushMatrix();
	glTranslatef(coord[0], coord[1], coord[2]);
	
	if (team == 0)
		glColor3f(1.0,0.0,0.0);
	else if (team == 1)
		glColor3f(0.0,0.0,1.0);
	if (isSelected)
		glColor3f(0.0f, 1.0f, 0.0f);
		
	glBegin(GL_QUADS);
	{
		glVertex3f(0.1f,0.05f,0.6f);
		glVertex3f(0.1f,-0.05f,0.6f);
		glVertex3f(-0.1f,-0.05f,0.6f);
		glVertex3f(-0.1f,0.05f,0.6f);
		
		glVertex3f(0.1f,0.05f,0.6f);
		glVertex3f(0.1f,-0.05f,0.6f);
		glVertex3f(0.1f,-0.05f,-0.2f);
		glVertex3f(0.1f,0.05f,-0.2f);
		
		glVertex3f(-0.1f,-0.05f,0.6f);
		glVertex3f(0.1f,-0.05f,0.6f);
		glVertex3f(0.1f,-0.05f,-0.2f);
		glVertex3f(-0.1f,-0.05f,-0.2f);
		
		glVertex3f(-0.1f,-0.05f,0.6f);
		glVertex3f(-0.1f,0.05f,0.6f);
		glVertex3f(-0.1f,0.05f,-0.2f);
		glVertex3f(-0.1f,-0.05f,-0.2f);
		
		glVertex3f(0.1f,0.05f,0.6f);
		glVertex3f(-0.1f,0.05f,0.6f);
		glVertex3f(-0.1f,0.05f,-0.2f);
		glVertex3f(0.1f,0.05f,-0.2f);
		
		glVertex3f(0.1f,0.05f,-0.2f);
		glVertex3f(0.1f,-0.05f,-0.2f);
		glVertex3f(-0.1f,-0.05f,-0.2f);
		glVertex3f(-0.1f,0.05f,-0.2f);
	}
	glEnd();
	if (isSelected)
	{
		glBegin(GL_LINES);
		{
			// Now to try some other stuffs! Bwahaha!
			// set these lines to white
			glLineWidth(2.0f);
			// x
			glColor3f(1.0f,0.0f,0.0f);
			glVertex3f(0.0f,0.0f,0.0f);
			glVertex3f(50.0f,0.0f,0.0f);
			// y
			glColor3f(0.0f,1.0f,0.0f);
			glVertex3f(0.0f,0.0f,0.0f);
			glVertex3f(0.0f,50.0f,0.0f);
			// z
			glColor3f(0.0f,0.0f,1.0f);
			glVertex3f(0.0f,0.0f,0.0f);
			glVertex3f(0.0f,0.0f,50.0f);
		}
		glEnd();
	}
	glPopMatrix();
}

-(IBAction)changeGametype:(id)sender
{
    //Play a sound
    int tag = [sender tag];
    if (tag == 1)
    {
        //CTF
        
    }
}

- (void)renderNetgameFlags:(int *)name
{
	int i;
	float color[3];
	float rotation[3];
	multiplayer_flags *mp_flags;
	
	mp_flags = [_scenario netgame_flags];
	
	for (i = 0; i < [_scenario multiplayer_flags_count]; i++)
	{	
		// Name convention is going to be the following:
		/*
			10000 * the type + the index
			This way, I can go like so:
		*/
		
		rotation[0] = mp_flags[i].rotation; rotation[1] = rotation[2] = 0.0f;
		
        
		glLoadName(*name);
		// Lookup goes hur
		if (_lookup)
			_lookup[*name] = (long)((s_netgame * MAX_SCENARIO_OBJECTS) + i);
		*name += 1; // For some reason it won't increment when I go *name++;
        
        int showType = [[renderGametype selectedItem] tag];
        
        
		switch (mp_flags[i].type)
		{
			case ctf_flag:
                if (showType == 1||showType == 12||showType == 15)
                {
                    [self renderFlag:mp_flags[i].coord team:mp_flags[i].team_index isSelected:mp_flags[i].isSelected];
                }
				break;
			case ctf_vehicle:
				break;
			case oddball:
                
                if (showType == 3||showType == 12||showType == 15)
                {
                    color[0] = 1.0f; color [1] = 1.0f; color[2] = 0.3f;
                    [self renderBox:mp_flags[i].coord rotation:rotation color:color selected:mp_flags[i].isSelected];
                }
                
				
				break;
			case race_track:
                //Only show if race is selected
                if (showType == 5||showType == 12||showType == 13||showType == 15)
                {
                    
                    color[0] = 1.0f; color [1] = 0.2f; color[2] = 0.0f;
                    [self renderBox:mp_flags[i].coord rotation:rotation color:color selected:mp_flags[i].isSelected];
                    
                    
                    //How many race tracks are there?
                    int highest=0;
                    int count = 0;
                    int a;
                    for (a = 0; a < [_scenario multiplayer_flags_count]; a++)
                    {
                        if (mp_flags[a].type == race_track)
                        {
                            if (mp_flags[a].team_index > highest)
                                highest = mp_flags[a].team_index;
                            count++;
                        }
                    }
                    
                    if (showType == 5)
                    {
                        [statusMessage setStringValue:[NSString stringWithFormat:@"Track: %d/32", highest+1]];
                    }
                    
                    if ([raceLines state] && showType != 15)
                    {
                    //Create lines between this and the one to the immediate right.
                    BOOL found = false;
                    int smallest = 1000;
                    multiplayer_flags nextItem;
                    for (a = 0; a < [_scenario multiplayer_flags_count]; a++)
                    {
                        if (a == i)
                            continue;
                        
                        if (mp_flags[a].type == race_track)
                        {
                            if (mp_flags[i].team_index == highest)
                            {
                                //Link to 0
                                if (mp_flags[a].team_index == 0)
                                {
                                    found = true;
                                    nextItem = mp_flags[a];
                                }
                            }
                            else
                            {
                                if (mp_flags[a].team_index > mp_flags[i].team_index && mp_flags[a].team_index < smallest)
                                {
                                    smallest=mp_flags[a].team_index;
                                    found = true;
                                    nextItem = mp_flags[a];
                                }
                            }
                        }
                        
                    }
                    
                    if (found)
                    {
                        //Connect these two objects with a line.
                        //mp_flags[i].coord
                        //mp_flags[i+1].coord
                        
                        
                        
                        float *coord = mp_flags[i].coord;
                        float *coord2 = nextItem.coord;
                        
                        glLineWidth(5.0f);
                        glBegin(GL_LINES);
                        {
                            // pointer arrow
                            glColor3f(((mp_flags[i].team_index)/(highest*1.0)),((mp_flags[i].team_index)/(highest*1.0)),((highest-mp_flags[i].team_index)/(highest*1.0)));
                            
                            glVertex3f(coord[0],coord[1],coord[2]);
                            glVertex3f(coord2[0],coord2[1],coord2[2]);
                        }
                        glEnd();
                        
                        
                        
                    }
                    }
                    
                }
				break;
			case race_vehicle:
                //Only show if race is selected
                if (showType == 5||showType == 12||showType == 13||showType == 15)
                {
                    color[0] = 1.0f; color [1] = 0.6f; color[2] = 0.3f;
                    [self renderBox:mp_flags[i].coord rotation:rotation color:color selected:mp_flags[i].isSelected];
                }
                
				break;
			case vegas_bank:
				break;
			case teleporter_entrance:
				color[0] = 1.0f; color[1] = 1.0f; color[2] = 0.2f;
                
                if ([teleporterLines state] && showType != 15)
                {
                BOOL found = false;
                multiplayer_flags mp_exit;
                int a;
                for (a = 0; a < [_scenario multiplayer_flags_count]; a++)
                {
                    if (a == i)
                        continue;
                    
                    if (mp_flags[a].type == teleporter_exit)
                    {
                        if (mp_flags[a].team_index == mp_flags[i].team_index)
                        {
                            found = true;
                            mp_exit = mp_flags[a];
                            break;
                        }
                    }
                        
                }
                
                if (found)
                {
                    //Connect these two objects with a line.
                    //mp_flags[i].coord
                    //mp_flags[i+1].coord
  
                    
                    
                    float *coord = mp_flags[i].coord;
                    float *coord2 = mp_exit.coord;
                    
                    glLineWidth(0.01f);
                    glBegin(GL_LINES);
                    {
                        // Now to try some other stuffs! Bwahaha!
                        // set these lines to white
                        
                        
                        // pointer arrow
                        glColor3f(1.0f,0.5f,0.5f);
                        glVertex3f(coord[0],coord[1],coord[2]);
                        glVertex3f(coord2[0],coord2[1],coord2[2]);
                    }
                    glEnd();
                 
                    
                    
                }
                }
				[self renderBox:mp_flags[i].coord rotation:rotation color:color selected:mp_flags[i].isSelected];
				break;
			case teleporter_exit:
				color[0] = 0.2f; color[1] = 1.0f; color[2] = 1.0f;
                
                //mp_flags[i].team_index
                
				[self renderBox:mp_flags[i].coord rotation:rotation color:color selected:mp_flags[i].isSelected];
				break;
			case hill_flag:
                if (showType == 4||showType == 12||showType == 13||showType == 14||showType == 15)
                {
                    color[0] = 0.4f; color [1] = color[2] = 0.0f;
                    [self renderBox:mp_flags[i].coord rotation:rotation color:color selected:mp_flags[i].isSelected];
                    
                    if ([hillLines state]&&showType != 15)
                    {
                    //Link each hill marker
                    //Create lines between this and the one to the immediate right.
                    BOOL found = false;
                    
                    float closestDistance = 1000;
                    float secondcloSsestDistance = 1000;
                    int nid = -1;
                    struct multiplayer_flags nextItem;
                    struct  multiplayer_flags nextItem1 ;
                    int a;
                    for (a = 0; a < [_scenario multiplayer_flags_count]; a++)
                    {
                        if (a == i)
                            continue;
                        
              
                        if (mp_flags[a].type == hill_flag)
                        {
                            if (mp_flags[a].team_index == mp_flags[i].team_index)
                            {
                                float *coord = mp_flags[i].coord;
                                float *coord2 = mp_flags[a].coord;
                                
                                float distance = sqrtf(powf(coord[0]-coord2[0], 2) + powf(coord[1]-coord2[1], 2) + powf(coord[2]-coord2[2], 2));
                            
                                if (distance < closestDistance)
                                {
                                    closestDistance = distance;
                                    nextItem = mp_flags[a];
                                    nid=a;
                                    found = YES;
                                }
                            }
                        }
                        
                    }
                    
                    
                    for (a = 0; a < [_scenario multiplayer_flags_count]; a++)
                    {
                        if (a == i || a == nid)
                            continue;
                        
                        
                        if (mp_flags[a].type == hill_flag)
                        {
                            if (mp_flags[a].team_index == mp_flags[i].team_index)
                            {
                                float *coord = mp_flags[i].coord;
                                float *coord2 = mp_flags[a].coord;
                                
                                float distance = sqrtf(powf(coord[0]-coord2[0], 2) + powf(coord[1]-coord2[1], 2) + powf(coord[2]-coord2[2], 2));
                                
                                if (distance < secondcloSsestDistance)
                                {
                                    secondcloSsestDistance = distance;
                                    nextItem1 = mp_flags[a];
                                    
                                    found = YES;
                                }
                            }
                        }
                        
                    }
                    
                    
                    
                    if (found)
                    {
                        //Connect these two objects with a line.
                        //mp_flags[i].coord
                        //mp_flags[i+1].coord
                        
                        
                        
                        float *coord = mp_flags[i].coord;
                        float *coord2 = nextItem.coord;
                        float *coord3 = nextItem1.coord;
                        
                        glLineWidth(5.0f);
                        glBegin(GL_LINES);
                        {
                            // pointer arrow
                            glColor3f(1.0, 0.8, 0.3);
                            
                            glVertex3f(coord[0],coord[1],coord[2]);
                            glVertex3f(coord2[0],coord2[1],coord2[2]);
                            
                            glVertex3f(coord[0],coord[1],coord[2]);
                            glVertex3f(coord3[0],coord3[1],coord3[2]);
                        }
                        glEnd();
                        
                        
                        
                    }
                    }
                    
                }
				break;
		}
	}
}
/*
* 
*		End scenario rendering
* 
*/

/*
* 
*		Begin GUI interfacing functions
* 
*/
- (IBAction)renderBSPNumber:(id)sender
{
	activeBSPNumber = [sender indexOfSelectedItem];
	[mapBSP setActiveBsp:[sender indexOfSelectedItem]];
	[self recenterCamera:self];
}
- (IBAction)sliderChanged:(id)sender
{
    if (sender == tickSlider)
	{
        [tickAmount setDoubleValue:[tickSlider doubleValue]];
        
    }
	else if (sender == framesSlider)
	{
        if (performanceMode)
        {
            NSRunAlertPanel(@"You cannot change the frames per second while in performance mode.", @"Please turn off performance mode and try again.", @"OK", nil, nil);
            return;
        }
		_fps = roundf([framesSlider floatValue]);
		[fpsText setFloatValue:_fps];
		[self resetTimerWithClassVariable];
	}
	else if (sender == s_accelerationSlider)
	{
		// Time to abuse floor()
		s_acceleration = floorf([s_accelerationSlider floatValue] * 10 + 0.5)/10;
		[s_accelerationText setStringValue:[[[NSNumber numberWithFloat:s_acceleration] stringValue] stringByAppendingString:@"x"]];
	}
	else if ((sender == s_xRotation) || (sender == s_yRotation) || (sender == s_zRotation))
	{
		[self rotateFocusedItem:[s_xRotation floatValue] y:[s_yRotation floatValue] z:[s_zRotation floatValue]];
        [self setNeedsDisplay:YES];
	}
	else if ((sender == s_xRotText) || (sender == s_yRotText) || (sender == s_zRotText))
	{
		[s_xRotation setFloatValue:[[s_xRotText stringValue] floatValue]];
		[s_yRotation setFloatValue:[[s_yRotText stringValue] floatValue]];
		[s_zRotation setFloatValue:[[s_zRotText stringValue] floatValue]];
        
		[self rotateFocusedItem:[s_xRotText floatValue] y:[s_yRotText floatValue] z:[s_zRotText floatValue]];
	}
    else if ((sender == s_xText) || (sender == s_yText) || (sender == s_zText))
	{
		[self moveFocusedItem:[s_xText floatValue] y:[s_yText floatValue] z:[s_zText floatValue]];
	}
}


-(IBAction)SelectAll:(id)sender;
{
	unsigned int type, index, nameLookup;
	if (!selections || [selections count] == 0)
		return;
	
	nameLookup = [[selections objectAtIndex:0] unsignedIntValue];
	
	type = (unsigned int)(nameLookup / MAX_SCENARIO_OBJECTS);
	index = (unsigned int)(nameLookup % MAX_SCENARIO_OBJECTS);
	
	@try {
		int i;
		for (i = 0; i < 200; i++)
		{
			[_scenario vehi_spawns][i].isSelected = YES;
		}
	}
	@catch (NSException * e) {
		
	}
	@finally {
		
	}
	
}


-(void)writeFloat:(float)value to:(int)address
{
	// Kill the host!
	float new_value = value;
	
	int *valueP = (int *)&new_value;
	*valueP = CFSwapInt32HostToBig(*((int *)&new_value));
	
	//(haloProcessID, address, &new_value, sizeof(float));
}

-(void)writeUInt16:(int)value to:(int)address
{
	// Kill the host!
	int new_value = value;
	short teamNumber = CFSwapInt16HostToBig(new_value);
	//(haloProcessID, address, &teamNumber, sizeof(short));
}



-(void)setSpeed:(float)speed_number player:(int)index
{
	[self writeFloat:8.0 to:0x4BD7B038 + 0x200 * index];
}


-(void)setSize:(float)plsize player:(int)index
{
	float newHostXValue = plsize;
	
	int haloObjectPointer = [self getDynamicPlayer:index];
	if (haloObjectPointer)
	{
		
		const int offsetToPlayerXCoordinate = 0x5C + 0x4 + 0x4+ 0x4+ 0x4+ 0x4+ 0x4+ 0x4+ 0x4+ 0x4;
		
		// Kill the host!
		[self writeFloat:newHostXValue to:haloObjectPointer + offsetToPlayerXCoordinate];
		[self writeFloat:newHostXValue to:haloObjectPointer + offsetToPlayerXCoordinate + 0x4];
		[self writeFloat:newHostXValue to:haloObjectPointer + offsetToPlayerXCoordinate + 0x8];
	}
	
}

-(void)setShield:(float)shield player:(int)index
{
	float newHostXValue = shield;
	
	int haloObjectPointer = [self getDynamicPlayer:index];
	if (haloObjectPointer)
	{
			
		const int offsetToPlayerXCoordinate = 0x5C + 0x4 + 0x4+ 0x4+ 0x4+ 0x4+ 0x4+ 0x4+ 0x4+ 0x4+ 0x4+ 0x4 + 0x58;
			
		// Kill the host!
		[self writeFloat:newHostXValue to:haloObjectPointer + offsetToPlayerXCoordinate];
		[self writeFloat:newHostXValue to:haloObjectPointer + offsetToPlayerXCoordinate + 0x4];
	}
	
}


-(void)setTeam:(int)team_number player:(int)index
{
	[self writeUInt16:team_number to:0x4BD7AFD0 + 0x1E + 0x200 * index];
	[self killPlayer:index];
}



-(IBAction)REDTEAM:(id)sender
{
	unsigned int type, index, nameLookup;
	
	if (!selections || [selections count] == 0)
		return;
	
	nameLookup = [[selections objectAtIndex:0] unsignedIntValue];
	
	type = (unsigned int)(nameLookup / MAX_SCENARIO_OBJECTS);
	index = (unsigned int)(nameLookup % MAX_SCENARIO_OBJECTS);
	
	//Tell the server to delete the player
	int player_number = index;
	
	[self setTeam:0	player:player_number];
}


-(IBAction)BLUETEAM:(id)sender
{
	unsigned int type, index, nameLookup;
	
	if (!selections || [selections count] == 0)
		return;
	
	nameLookup = [[selections objectAtIndex:0] unsignedIntValue];
	
	type = (unsigned int)(nameLookup / MAX_SCENARIO_OBJECTS);
	index = (unsigned int)(nameLookup % MAX_SCENARIO_OBJECTS);
	
	//Tell the server to delete the player
	int player_number = index;
	[self setTeam:1	player:player_number];
}

-(IBAction)GODPOWER:(id)sender
{
	unsigned int type, index, nameLookup;
	
	if (!selections || [selections count] == 0)
		return;
	
	nameLookup = [[selections objectAtIndex:0] unsignedIntValue];
	
	type = (unsigned int)(nameLookup / MAX_SCENARIO_OBJECTS);
	index = (unsigned int)(nameLookup % MAX_SCENARIO_OBJECTS);
	
	//Tell the server to delete the player
	int player_number = index;
	
	[self setShield:100000000.0 player:player_number];
	[self setSpeed:8.0 player:player_number];
	[self setSize:12.0 player:player_number];
}

-(IBAction)GUARDIANTEAM:(id)sender
{
	unsigned int type, index, nameLookup;
	
	if (!selections || [selections count] == 0)
		return;
	
	nameLookup = [[selections objectAtIndex:0] unsignedIntValue];
	
	type = (unsigned int)(nameLookup / MAX_SCENARIO_OBJECTS);
	index = (unsigned int)(nameLookup % MAX_SCENARIO_OBJECTS);
	
	//Tell the server to delete the player
	int player_number = index;
	
	[self setTeam:8	player:player_number];
	[self setSpeed:8.0	player:player_number];
}

-(IBAction)JAILTEAM:(id)sender
{
	unsigned int type, index, nameLookup;
	
	if (!selections || [selections count] == 0)
		return;
	
	nameLookup = [[selections objectAtIndex:0] unsignedIntValue];
	
	type = (unsigned int)(nameLookup / MAX_SCENARIO_OBJECTS);
	index = (unsigned int)(nameLookup % MAX_SCENARIO_OBJECTS);
	
	//Tell the server to delete the player
	int player_number = index;
	
	[self setTeam:3	player:player_number];
}

- (IBAction)buttonPressed:(id)sender
{
	if (sender == selectMode || sender == m_SelectMode)
	{
		_mode = select;
		[self unpressButtons];
		[selectMode setState:NSOnState];
	}
	else if (sender == translateMode || sender == m_TranslateMode)
	{
		_mode = translate;
		[self unpressButtons];
		[translateMode setState:NSOnState];
	}
	else if (sender == moveCameraMode || sender == m_MoveCamera)
	{
		_mode = rotate_camera;
		[self unpressButtons];
		[moveCameraMode setState:NSOnState];
	}
    /*else if (sender == grassMode || sender == dirtMode || sender == eyedropperMode || sender == lightmapMode)
	{
        [self unpressButtons];
        NSRunAlertPanel(@"Painting has been disabled in this version of swordedit.", @"Please try using a newer version.", @"OK", nil, nil);
    }*/
    else if (sender == grassMode)
	{
		_mode = grass;
		[self unpressButtons];
		[grassMode setState:NSOnState];
	}
    else if (sender == dirtMode )
	{
		_mode = dirt;
		[self unpressButtons];
		[dirtMode setState:NSOnState];
	}
    else if (sender == eyedropperMode)
	{
		_mode = eyedrop;
		[self unpressButtons];
		[eyedropperMode setState:NSOnState];
	}
    else if (sender == lightmapMode )
	{
		_mode = lightmapMode;
		[self unpressButtons];
		[lightmapMode setState:NSOnState];
	}
	else if (sender == duplicateSelected || sender == m_duplicateSelected)
	{
		unsigned int type, index, nameLookup;

		if (!selections || [selections count] == 0)
			return;
		
		nameLookup = [[selections objectAtIndex:0] unsignedIntValue];
	
		type = (unsigned int)(nameLookup / MAX_SCENARIO_OBJECTS);
		index = (unsigned int)(nameLookup % MAX_SCENARIO_OBJECTS);
		[selections replaceObjectAtIndex:0 withObject:[NSNumber numberWithUnsignedInt:[_scenario duplicateScenarioObject:type index:index]]];
		_selectFocus = [[selections objectAtIndex:0] longValue];
	}
	else if (sender == s_spawnCreateButton)
	{
		// Since I only have the option to create a teleporter pair now, lets just do that.
		if (_mapfile)
		{
			[self deselectAllObjects];
            
            if ([[[createType selectedItem] title] isEqualToString:@"Teleporter Pair"])
                [self processSelection:(unsigned int)[_scenario createTeleporterPair:[_camera vView]]];
            else if ([[[createType selectedItem] title] isEqualToString:@"Scenery"])
                [self processSelection:(unsigned int)[_scenario createSkull:[_camera vView]]];
            else if ([[[createType selectedItem] title] isEqualToString:@"Vehicle"])
                [self processSelection:(unsigned int)[_scenario createVehicle:[_camera vView]]];
            else if ([[[createType selectedItem] title] isEqualToString:@"Item"])
                [self processSelection:(unsigned int)[_scenario createItem:[_camera vView]]];
            else if ([[[createType selectedItem] title] isEqualToString:@"Red Spawn"])
                [self processSelection:(unsigned int)[_scenario createRedSpawn:[_camera vView]]];
            else if ([[[createType selectedItem] title] isEqualToString:@"Blue Spawn"])
                [self processSelection:(unsigned int)[_scenario createBlueSpawn:[_camera vView]]];
            else if ([[[createType selectedItem] title] isEqualToString:@"Machine"])
                [self processSelection:(unsigned int)[_scenario createMachine:[_camera vView]]];
		}
	}
	else if (sender == s_skullCreateButton)
	{
		// Since I only have the option to create a teleporter pair now, lets just do that.
		if (_mapfile)
		{
			[self deselectAllObjects];
			[self processSelection:(unsigned int)[_scenario createSkull:[_camera vView]]];
		}
	}
	else if (sender == s_machineCreateButton)
	{
		// Since I only have the option to create a teleporter pair now, lets just do that.
		if (_mapfile)
		{
			[self deselectAllObjects];
			[self processSelection:(unsigned int)[_scenario createMachine:[_camera vView]]];
		}
	}
	else if (sender == b_deleteSelected || sender == m_deleteFocused)
	{
		unsigned int type, index, nameLookup;

		if (!selections || [selections count] == 0)
			return;
		for (id loopItem in selections)
		{
		
		nameLookup = [loopItem unsignedIntValue];
	
		type = (unsigned int)(nameLookup / MAX_SCENARIO_OBJECTS);
		index = (unsigned int)(nameLookup % MAX_SCENARIO_OBJECTS);
		
		
		if (type == s_playerobject)
		{
			//Tell the server to delete the player
			int player_number = index;

			//[self setTeam:1	player:player_number];
					
			[self killPlayer:player_number];
			
		}
		else if (type == s_mapobject)
		{
			//Tell the server to delete the object
			int player_number = index;
			
			//[self setTeam:1	player:player_number];
			
			int object = map_objects[index].address;
			[self writeFloat:10000.0 to:object + 0x5C];
		}
		else
		{
		
		[_scenario deleteScenarioObject:type index:index];
		}
		}
		
		[self deselectAllObjects];
		
		[_spawnEditor reloadAllData];
	}
	else if (sender == selectedTypeSwapButton)
	{
		unsigned int type, index;
		short *numid;
		
		type = (unsigned int)(_selectFocus / MAX_SCENARIO_OBJECTS);
		index = (unsigned int)(_selectFocus % MAX_SCENARIO_OBJECTS);
		
		switch (type)
		{
			case s_scenery:
				//Delete this as a scenery
				//[_scenario scen_spawns][index].modelIdent = [_scenario baseModelIdent:[_scenario scen_references][*numid].scen_ref.TagId];
				
				
				break;
		}
	}
	else if (sender == selectedSwapButton)
	{
		unsigned int type, index;
		short *numid;
		
		type = (unsigned int)(_selectFocus / MAX_SCENARIO_OBJECTS);
		index = (unsigned int)(_selectFocus % MAX_SCENARIO_OBJECTS);
		
		switch (type)
		{
			case s_scenery:
				numid = &[_scenario scen_spawns][index].numid;
				*numid = [sender indexOfSelectedItem];
				[_scenario scen_spawns][index].modelIdent = [_scenario baseModelIdent:[_scenario scen_references][*numid].scen_ref.TagId];
				#ifdef __DEBUG__
				NSLog([[_mapfile tagForId:[_scenario scen_spawns][index].modelIdent] tagName]);
				#endif
				break;
			case s_item:
				[_scenario item_spawns][index].itmc.TagId = [_mapfile itmcIdForKey:[sender indexOfSelectedItem]];
				[_scenario item_spawns][index].modelIdent = [_scenario itmcModelForId:[_scenario item_spawns][index].itmc.TagId];
				break;
			case s_machine:
               // NSLog(@"%d", [sender indexOfSelectedItem]);
				[_scenario mach_spawns][index].numid = [sender indexOfSelectedItem];
				break;
			case s_vehicle:
				NSLog(@"Change vehicle ref");
				numid = [_scenario vehi_spawns][index].numid;
				
				//Switch the types of vehicles
				//long original_mt = [_scenario vehi_references][*numid].vehi_ref.TagId;
				//long new_mt = [_scenario vehi_references][[sender indexOfSelectedItem]].vehi_ref.TagId;
				
				//[_scenario vehi_references][*numid].vehi_ref.TagId = new_mt;
				//[_scenario vehi_references][[sender indexOfSelectedItem]].vehi_ref.TagId = original_mt;
                
                [_scenario vehi_spawns][index].numid = [sender indexOfSelectedItem];
				[_scenario vehi_spawns][index].modelIdent = [_scenario baseModelIdent:[_scenario vehi_references][[sender indexOfSelectedItem]].vehi_ref.TagId];
                
                //[_scenario pairModelsWithSpawn];
				break;
		}
		[self fillSelectionInfo];
	}
	else if (sender == useAlphaCheckbox)
	{
		_useAlphas = ([useAlphaCheckbox state] ? TRUE : FALSE);
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		[userDefaults setBool:_useAlphas forKey:@"_useAlphas"];
		[userDefaults synchronize];
	}
	else if (sender == lodDropdownButton)
	{
		
		int ti = (int)[lodDropdownButton doubleValue];
		
		if (ti == 0) _LOD = 0;
		else if (ti == 2) _LOD = 4;
		else _LOD = 2;


	}
    
    //[self loadPrefs];
}
- (void)lookAtFocusedItem
{
	float *coord;
	unsigned int type, index;
	type = (unsigned int)(_selectFocus / MAX_SCENARIO_OBJECTS);
	index = (unsigned int)(_selectFocus % MAX_SCENARIO_OBJECTS);
	
	switch (type)
	{
		case s_scenery:
			coord = [_scenario scen_spawns][index].coord;
			break;
		case s_item:
			coord = [_scenario item_spawns][index].coord;
			break;
		case s_playerspawn:
			coord = [_scenario spawns][index].coord;
			break;
		
	}
	
	//[_camera PositionCamera:[_camera position][0] positionY:[_camera position][1] positionZ:[_camera position][2] 
	//						viewX:coord[0] viewY:coord[1] viewZ:coord[2] 
	//						upVectorX:0.0f upVectorY:0.0f upVectorZ:1.0f];
}

-(float *)getCameraPos
{
	return [_camera position];
}

-(float *)getCameraView
{
	return [_camera vView];
}




- (IBAction)recenterCamera:(id)sender
{
	float x,y,z;
		[mapBSP GetActiveBspCentroid:&x center_y:&y center_z:&z];
		[_camera PositionCamera:(x + 5.0f) positionY:(y + 5.0f) positionZ:(z + 5.0f)
						viewX:x viewY:y viewZ:z
						upVectorX:0.0f upVectorY:0.0f upVectorZ:1.0f];
}
- (IBAction)orientCamera:(id)sender
{

}
- (IBAction)changeRenderStyle:(id)sender
{
	[pointsItem setState:NSOffState];
	[wireframeItem setState:NSOffState];
	[shadedTrisItem setState:NSOffState];
	[texturedItem setState:NSOffState];
	if (sender == pointsItem || sender == buttonPoints)
		currentRenderStyle = point;
	else if (sender == wireframeItem || sender == buttonWireframe)
		currentRenderStyle = wireframe;
	else if (sender == shadedTrisItem || sender == buttonShadedFaces)
		currentRenderStyle = flat_shading;
	else if (sender == texturedItem || sender == buttonTextured)
		currentRenderStyle = textured_tris;
	[sender setState:NSOnState];
}
- (IBAction)setCameraSpawn:(id)sender
{
	NSData *camDat = [NSData dataWithBytes:&camCenter[0] length:12];
	[prefs setObject:camDat forKey:[[_mapfile mapName] stringByAppendingFormat:@"camDat_0%d", activeBSPNumber]];
	//[prefs setObject:camDat forKey:[[[_mapfile mapName] stringByAppendingString:@"camDat_0"] stringByAppendingString:[[NSNumber numberWithInt:activeBSPNumber] stringValue]]];
	camDat = [NSData dataWithBytes:&camCenter[1] length:12];
	[prefs setObject:camDat forKey:[[[_mapfile mapName] stringByAppendingString:@"camDat_1"] stringByAppendingString:[[NSNumber numberWithInt:activeBSPNumber] stringValue]]];
	camDat = [NSData dataWithBytes:&camCenter[2] length:12];
	[prefs setObject:camDat forKey:[[[_mapfile mapName] stringByAppendingString:@"camDat_@"] stringByAppendingString:[[NSNumber numberWithInt:activeBSPNumber] stringValue]]];
	[prefs synchronize];
	
}
- (IBAction)setSelectionMode:(id)sender
{
	_selectType = [sender indexOfSelectedItem];
}
- (IBAction)killKeys:(id)sender
{
	int i;
	for (i = 0; i < 6; i++)
		move_keys_down[i].isDown = NO;
}

- (void)setPositionSliders:(NSNumber*)aax y:(NSNumber*)aay z:(NSNumber*)aaz
{
    [s_xText setStringValue:[aax stringValue]];
	[s_yText setStringValue:[aay stringValue]];
	[s_zText setStringValue:[aaz stringValue]];
	
	[s_xText setEnabled:YES];
	[s_yText setEnabled:YES];
	[s_zText setEnabled:YES];
	[s_xText setEditable:YES];
	[s_yText setEditable:YES];
	[s_zText setEditable:YES];
}

- (void)setPositionSlidersOld:(float)aax y:(float)aay z:(float)aaz
{
	[s_xText setStringValue:[NSString stringWithFormat:@"%f",aax]];
	[s_yText setStringValue:[NSString stringWithFormat:@"%f",aay]];
	[s_zText setStringValue:[NSString stringWithFormat:@"%f",aaz]];
	
	[s_xText setEnabled:YES];
	[s_yText setEnabled:YES];
	[s_zText setEnabled:YES];
	[s_xText setEditable:YES];
	[s_yText setEditable:YES];
	[s_zText setEditable:YES];
}
- (void)setRotationSliders:(float)x y:(float)y z:(float)z
{
	x = fabs(piradToDeg(x));
	y = fabs(piradToDeg(y));
	z = fabs(piradToDeg(z));
	
	[s_xRotation setFloatValue:x];
	[s_yRotation setFloatValue:y];
	[s_zRotation setFloatValue:z];
	
	[s_xRotText setStringValue:[NSString stringWithFormat:@"%f",x]];
	[s_yRotText setStringValue:[NSString stringWithFormat:@"%f",y]];
	[s_zRotText setStringValue:[NSString stringWithFormat:@"%f",z]];
	
    [s_xRotation setEnabled:YES];
	[s_yRotation setEnabled:YES];
	[s_zRotation setEnabled:YES];
    
	[s_xRotText setEnabled:YES];
	[s_yRotText setEnabled:YES];
	[s_zRotText setEnabled:YES];
	[s_xRotText setEditable:YES];
	[s_yRotText setEditable:YES];
	[s_zRotText setEditable:YES];
}
- (void)unpressButtons
{
	[selectMode setState:NSOffState];
	[translateMode setState:NSOffState];
	[moveCameraMode setState:NSOffState];
    [dirtMode setState:NSOffState];
    [grassMode setState:NSOffState];
    [eyedropperMode setState:NSOffState];
    [lightmapMode setState:NSOffState];
}
- (void)updateSpawnEditorInterface
{
	unsigned int type, index;
	type = (unsigned int)(_selectFocus / MAX_SCENARIO_OBJECTS);
	index = (unsigned int)(_selectFocus % MAX_SCENARIO_OBJECTS);
	
	// Here we now send these values to the spawn editor.
}
// This little baby will go ahead and find the location of a spawn where the ray from the mouse intersects the BSP, thus you can select stuff.
- (void)findSelectedSpawnCoord
{
}
/*
* 
*		End GUI interfacing functions
* 
*/


/*
*
*	Begin Scenario Editing Functions
*
*/

-(IBAction)GoFullscreen:(id)sender
{
	if (!isfull)
	{
		
		NSWindow *main = [self window];
	
		//[main setLevel:100]; //Higher than the menu bar
		[spawne setLevel:101];
		[spawnc setLevel:101];
		[render setLevel:101];
		[camera setLevel:101];
		[select setLevel:101];
	
		[main setStyleMask:NSBorderlessWindowMask]; //Allow menu bar exceeding.
		//[main setFrame:NSMakeRect(0, 0, [[NSScreen mainScreen] frame].size.width, [[NSScreen mainScreen] frame].size.height /*for window title bar height*/) display:YES];
	
		//Make the application the 'main'
		[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
		[main makeKeyAndOrderFront:nil];
		
		[sender setTitle:@"Exit Fullscreen"];
		isfull = 1;	
	}
	else {
		
		NSWindow *main = [self window];
		
		[main setLevel:NSNormalWindowLevel]; //Higher than the menu bar
		[spawne setLevel:NSFloatingWindowLevel];
		[spawnc setLevel:NSFloatingWindowLevel];
		[render setLevel:NSFloatingWindowLevel];
		[camera setLevel:NSFloatingWindowLevel];
		[select setLevel:NSFloatingWindowLevel];
		[main setStyleMask:(NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask)]; //Allow menu bar exceeding.
		[main setFrame:NSMakeRect(0, 0, [[NSScreen mainScreen] frame].size.width, [[NSScreen mainScreen] frame].size.height /*for window title bar height*/) display:YES];
		
		[sender setTitle:@"Fullscreen"];
		isfull = 0;	
	}

	
}

float dp(float*v1,float*v2)
{
    return (float)((float)v1[0]*(float)v2[0] + (float)v1[1]*(float)v2[1]);// + (float)v1[2]*(float)v2[2]);
}

// Start Code
// must include at least these
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define SAME_CLOCKNESS 1
#define DIFF_CLOCKNESS 0

typedef struct fpoint_tag
{
    float x;
    float y;
    float z;
} fpoint;

fpoint pt1 = {0.0, 0.0, 0.0};
fpoint pt2 = {0.0, 3.0, 3.0};
fpoint pt3 = {2.0, 0.0, 0.0};
fpoint linept = {0.0, 0.0, 6.0};
fpoint vect = {0.0, 2.0, -4.0};
fpoint pt_int = {0.0, 0.0, 0.0};

int check_same_clock_dir(fpoint pt1, fpoint pt2, fpoint pt3, fpoint norm)
{
    float testi, testj, testk;
    float dotprod;
    // normal of trinagle
    testi = (((pt2.y - pt1.y)*(pt3.z - pt1.z)) - ((pt3.y - pt1.y)*(pt2.z - pt1.z)));
    testj = (((pt2.z - pt1.z)*(pt3.x - pt1.x)) - ((pt3.z - pt1.z)*(pt2.x - pt1.x)));
    testk = (((pt2.x - pt1.x)*(pt3.y - pt1.y)) - ((pt3.x - pt1.x)*(pt2.y - pt1.y)));
    
    // Dot product with triangle normal
    dotprod = testi*norm.x + testj*norm.y + testk*norm.z;
    
    //answer
    if(dotprod < 0)
        return DIFF_CLOCKNESS;
    else
        return SAME_CLOCKNESS;
}

int check_intersect_tri(fpoint pt1, fpoint pt2, fpoint pt3, fpoint linept, fpoint vect, fpoint* pt_int)
{
    float V1x, V1y, V1z;
    float V2x, V2y, V2z;
    fpoint norm;
    float dotprod;
    float t;
    
    // vector form triangle pt1 to pt2
    V1x = pt2.x - pt1.x;
    V1y = pt2.y - pt1.y;
    V1z = pt2.z - pt1.z;
    
    // vector form triangle pt2 to pt3
    V2x = pt3.x - pt2.x;
    V2y = pt3.y - pt2.y;
    V2z = pt3.z - pt2.z;
    
    // vector normal of triangle
    norm.x = V1y*V2z-V1z*V2y;
    norm.y = V1z*V2x-V1x*V2z;
    norm.z = V1x*V2y-V1y*V2x;
    
    // dot product of normal and line's vector if zero line is parallel to triangle
    dotprod = norm.x*vect.x + norm.y*vect.y + norm.z*vect.z;
    
    //if(dotprod < 0)
    //{
        //Find point of intersect to triangle plane.
        //find t to intersect point
        t = -(norm.x*(linept.x-pt1.x)+norm.y*(linept.y-pt1.y)+norm.z*(linept.z-pt1.z))/
        (norm.x*vect.x+norm.y*vect.y+norm.z*vect.z);
        
        // if ds is neg line started past triangle so can't hit triangle.
        if(t < 0) return 0;
            
        pt_int->x = linept.x + vect.x*t;
        pt_int->y = linept.y + vect.y*t;
        pt_int->z = linept.z + vect.z*t;
        
       
        if(check_same_clock_dir(pt1, pt2, *pt_int, norm) == SAME_CLOCKNESS)
        {
            if(check_same_clock_dir(pt2, pt3, *pt_int, norm) == SAME_CLOCKNESS)
            {
                if(check_same_clock_dir(pt3, pt1, *pt_int, norm) == SAME_CLOCKNESS)
                {
                    // answer in pt_int is insde triangle
                    return 1;
                }
            }
        }
    //}
    return 0;
}

-(float*)coordtoGround:(float*)pos
{
    SUBMESH_INFO *pMesh2;
	int a;
	int i;
    int mesh_count;
    float *closest;
    BOOL found = NO;
    BOOL collison = NO;
    float closestDistance = 10000;
    
    
    /*
    BspMesh *mesh = [mapBSP mesh];
    closest = [mesh findIntersection:pos withOther:pos];
    
    float *currentPos = malloc(sizeof(float)*3);
    currentPos[0] = pos[0];
    currentPos[1] = pos[1];
    currentPos[2] = pos[2];
    
    if (!closest)
    {
        currentPos[2] = pos[2]+30;
    }
    
    //LAZY METHOD (which MIGHT work!) Similar to newtons method
    int iterations = 20;
    float distance = 1000.0f;

    
    for (i=0; i < iterations; i++)
    {
        
        distance/=2.0;
        //First, is currentPos above or below the plane?
        float *closest = [mesh findIntersection:currentPos withOther:currentPos];
        if (closest)
        {
            //Above the plane. Move down by distance/=2.0
            currentPos[2] = currentPos[2] - distance;
        }
        else
        {
            //Below the plane
            currentPos[2] = currentPos[2] + distance;
        }
        
        
    }
    
    currentPos[2] = currentPos[2] + 0.01;
    closest = [mesh findIntersection:currentPos withOther:currentPos];
    if (!closest)
    {
        currentPos[2] = pos[2];
    }
    
    return currentPos;
    */
    
    mesh_count = [mapBSP GetActiveBspSubmeshCount];
    for (a = 0; a < mesh_count; a++)
    {
        
        pMesh2 = [mapBSP GetActiveBspPCSubmesh:a];
        
        //Find the closest x,y coordinate for this.
        for (i = 0; i < pMesh2->IndexCount; i++)
        {
            float *pt1 = ((pMesh2->pVert[pMesh2->pIndex[i].tri_ind[0]].vertex_k));
            float *pt2 = ((float *)(pMesh2->pVert[pMesh2->pIndex[i].tri_ind[1]].vertex_k));
            float *pt3 = ((float *)(pMesh2->pVert[pMesh2->pIndex[i].tri_ind[2]].vertex_k));
            
            //Calculate a distance function
            float dist1 = (float)sqrt(powf(pos[0] - pt1[0],2) + powf(pos[1] - pt1[1], 2) + powf(pos[2] - pt1[2], 2));
            float dist2 = (float)sqrt(powf(pos[0] - pt2[0],2) + powf(pos[1] - pt2[1], 2) + powf(pos[2] - pt2[2], 2));
            float dist3 = (float)sqrt(powf(pos[0] - pt3[0],2) + powf(pos[1] - pt3[1], 2) + powf(pos[2] - pt3[2], 2));
            
            float total = dist1+dist2+dist3;
            dist1=total-dist1;
            dist2=total-dist2;
            dist3=total-dist3;
            total = dist1+dist2+dist3;
            
            //if (total > closestDistance)
            //{
            //    continue;
            //}
            
            if (pt1[0] == pt2[0] || pt1[1] == pt2[1])
            {
                //continue;
            }
            
            fpoint fpt1 = {pt1[0], pt1[1], pt1[2]};
            fpoint fpt2 = {pt2[0], pt2[1], pt2[2]};
            fpoint fpt3 = {pt3[0], pt3[1], pt3[2]};
            fpoint fpt4 = {pos[0], pos[1], pos[2]+100};
            fpoint v = {0,0,-1};
            fpoint* pt_int = malloc(sizeof(fpoint));
            
            //Is our point on this plane (x,y) wise
            float *v0 = malloc(sizeof(float)*3);
            v0[0]=pt3[0]-pt1[0];
            v0[1]=pt3[1]-pt1[1];
            v0[2]=pt3[2]-pt1[2];
            
            float *v1 = malloc(sizeof(float)*3);
            v1[0]=pt2[0]-pt1[0];
            v1[1]=pt2[1]-pt1[1];
            v1[2]=pt2[2]-pt1[2];
            
            float *v2 = malloc(sizeof(float)*3);
            v2[0]=pos[0]-pt1[0];
            v2[1]=pos[1]-pt1[1];
            v2[2]=pos[2]-pt1[2];
            
            float dot00 = dp(v0,v0);
            float dot01 = dp(v0,v1);
            float dot02 = dp(v0,v2);
            float dot11 = dp(v1,v1);
            float dot12 = dp(v1,v2);
            
            float invDenom = 1/(dot00 * dot11 - dot01 * dot01);
            float u = (dot11 * dot02 - dot01 * dot12) * invDenom;
            float v32 = (dot00 * dot12 - dot01 * dot02) * invDenom;

            free(v0);
            free(v1);
            free(v2);
            
            if ((u >= 0) && (v32 >= 0) && (u + v32 < 1))
            {
                float dist1 = (float)sqrt(powf(pos[0] - pt1[0],2) + powf(pos[1] - pt1[1], 2) + powf(pos[2] - pt1[2], 2));
                float dist2 = (float)sqrt(powf(pos[0] - pt2[0],2) + powf(pos[1] - pt2[1], 2) + powf(pos[2] - pt2[2], 2));
                float dist3 = (float)sqrt(powf(pos[0] - pt3[0],2) + powf(pos[1] - pt3[1], 2) + powf(pos[2] - pt3[2], 2));
                
                float total = dist1+dist2+dist3;
                dist1=total-dist1;
                dist2=total-dist2;
                dist3=total-dist3;
                total = dist1+dist2+dist3;
                
                //float z=((dist3/total)*pt3[2]+(dist2/total)*pt2[2]+(dist1/total)*pt1[2]);
                
                if (check_intersect_tri(fpt1, fpt2, fpt3, fpt4, v, pt_int))
                {
                    indexMesh = a;
                    indexHighlight = i;

                    if (pt_int->z > pos[2] && pt_int->z - pos[2] > 0.3)
                    {
                        collison = YES;
                    }
                    
                    float dist = (float)sqrt(powf(pos[0] - pt_int->x,2) + powf(pos[1] - pt_int->y, 2) + powf(pos[2] - pt_int->z, 2));
                    if (dist < closestDistance)
                    {
                        if (found)
                            free(closest);
                        
                        closestDistance = dist;
                        
                        //Inside triangle
                        closest = malloc(sizeof(float)*3);
                        closest[0]=pt_int->x;
                        closest[1]=pt_int->y;
                        closest[2]=pt_int->z;
                        
                        
                        float *p = malloc(sizeof(float)*3);
                        float *q = malloc(sizeof(float)*3);
                        
                        p[0] = pt2[0] - pt1[0];
                        p[1] = pt2[1] - pt1[1];
                        p[2] = pt2[2] - pt1[2];
                        
                        q[0] = pt3[0] - pt1[0];
                        q[1] = pt3[1] - pt1[1];
                        q[2] = pt3[2] - pt1[2];
             
                        if (hasn)
                            free(n);
                        hasn=NO;
                        n = malloc(sizeof(float)*3);
                        n[0] = (p[1]*q[2]) - (p[2]*q[1]);
                        n[1] = -((p[0]*q[2]) - (p[2]*q[0]));
                        n[2] = (p[0]*q[1]) - (p[1]*q[0]);
                        
                        hasn=YES;
                        

                        free(p);
                        free(q);
                        
       
                        found = YES;
                    }
                }
            }
            
            free(pt_int);
              
             
        }
    }
	
    if (found)
        return closest;
    if (collison)
        return pos;
    
    float *ret = malloc(sizeof(float)*3);
    ret[0]=0;
    ret[1]=0;
    ret[2]=0;
    
    return ret;
}

-(BOOL)isAboveGround:(float*)pos
{
    //New smexy method
    BspMesh *mesh = [mapBSP mesh];
    float *closest = [mesh findIntersection:pos withOther:pos];
    if (closest)
    {
        return TRUE;
    }
    return FALSE;
}



float Dot(CVector3 vVector1, CVector3 vVector2);

BOOL isPainting;

- (int)tryBSPSelection:(NSPoint)downPoint shiftDown:(BOOL)shiftDown width:(CGFloat)w height:(CGFloat)h
{

    isPainting = YES;
   
    
    //Based on our mouse location and camera location.
    GLsizei bufferSize = (GLsizei) ([mapBSP GetActiveBspSubmeshCount]+1);
    
    GLuint nameBuf[bufferSize];
	GLuint tmpLookup[bufferSize];
	GLint viewport[4];
	GLuint hits;
	unsigned int i, j, z1, z2;
    int mesh_index;

	glGetIntegerv(GL_VIEWPORT,viewport);
	unsigned int mesh_count = [mapBSP GetActiveBspSubmeshCount];
    
	//glMatrixMode(GL_PROJECTION);
	
    /*
	glSelectBuffer(bufferSize,nameBuf);
	glRenderMode(GL_SELECT);
	
	glMatrixMode(GL_PROJECTION);
	glPushMatrix();
	glLoadIdentity();
	
	gluPickMatrix((GLdouble)downPoint.x + w / 2,(GLdouble)downPoint.y + h / 2,w,h,viewport);
	
    
    float z_distance = 400.0f;
    float n_distance = 0.1f;
    
	gluPerspective(45.0f,(GLfloat)(viewport[2] - viewport[0])/(GLfloat)(viewport[3] - viewport[1]),n_distance,z_distance);

	glMatrixMode(GL_MODELVIEW);
	glColor4f(1.0f,1.0f,1.0f,1.0f);
    
    glInitNames();
	glPushName(0);
    
	
     
	int m, mesh_index;
    
    int name = 1;

		mesh_count = [mapBSP GetActiveBspSubmeshCount];
		[self resetMeshColors];
	
		
            // Lookup goes hu
            glLoadName(name);
            name++;
            
            SUBMESH_INFO *pMesha;
            pMesha = [mapBSP GetActiveBspPCSubmesh:mesh_index];
            
            glBegin(GL_TRIANGLES);
            for (i = 0; i < pMesha->IndexCount; i++)
            {
                glVertex3fv((float *)(pMesha->pVert[pMesha->pIndex[i].tri_ind[0]].vertex_k));
                glVertex3fv((float *)(pMesha->pVert[pMesha->pIndex[i].tri_ind[1]].vertex_k));
                glVertex3fv((float *)(pMesha->pVert[pMesha->pIndex[i].tri_ind[2]].vertex_k));
            }
            glEnd();
    
    
    
	//[self reshape];
	hits = glRenderMode(GL_RENDER);
    glPopMatrix();
    
	GLuint names, *ptr = (GLuint *)nameBuf;
	unsigned int type;
	BOOL hasFound = FALSE;

    //glRasterPos() 
    if (hits != 0)
    {
        */
    
        //Where did the ray intersect?
        //ptr+=3;
       
        //selectedBSP = (*(ptr) -1 );
        
        
        //Calculate a vector using the camera
        float cx = [_camera position][0];
        float cy = [_camera position][1];
        float cz = [_camera position][2];
        
        float vx = [_camera vView][0];
        float vy = [_camera vView][1];
        float vz = [_camera vView][2];
        
        
        float sx = [_camera vStrafe][0];
        float sy = [_camera vStrafe][1];
        float sz = [_camera vStrafe][2];
        
        
        //How wide is the view?
        float nw = [self bounds].size.width;
        float nh = [self bounds].size.height;
        
        float far = 500;
        
        float xp = ((downPoint.x/nw)*2-1.0);
        float yp = -((downPoint.y/nh)*2-1.0);
        
        float vector_x = (vx-cx);
        float vector_y = (vy-cy);
        float vector_z = (vz-cz);
        
        NSSize sceneBounds = [self frame].size;
        
        
        float ySize = 1.01*sin((22.5*M_PI)/180);
        float xSize = (sceneBounds.width / sceneBounds.height) * ySize;
        
        fromPt[0] = cx+vector_x*0.1;
        fromPt[1] = cy+vector_y*0.1;
        fromPt[2] = cz+vector_z*0.1;
    
    
        /*
        
        //sx/=20;
        //sy/=20;
        ////sz/=20;
        
        //(z_distance / n_distance)
        
        CVector3 vView = NewCVector3(vx,vy,vz);
        CVector3 vPosition= NewCVector3(cx,cy,cz);
        CVector3 vStrage= NewCVector3(sx,sy,sz);
        
        CVector3 vCross = Cross(SubtractTwoVectors(vView , vPosition), vStrage);
        CVector3 upward = Normalize(vCross);
        
        toPt[0] = cx+ (cx+vector_x*0.1+(xp*xSize*sx + yp*ySize*upward.x)-cx)*far;
        toPt[1] = cy+ (cy+vector_y*0.1+(xp*xSize*sy + yp*ySize*upward.y)-cy)*far;
        toPt[2] = cz+ (cz+vector_z*0.1+(xp*xSize*sz + yp*ySize*upward.z)-cz)*far;
        
        */
        
        //get the matrices for their passing to gluUnProject
        double afModelviewMatrix[16];
        double afProjectionMatrix[16];
        glGetDoublev(GL_MODELVIEW_MATRIX, afModelviewMatrix);
        glGetDoublev(GL_PROJECTION_MATRIX, afProjectionMatrix);
        
        GLint anViewport[4];
        glGetIntegerv(GL_VIEWPORT, anViewport);
        
        float fMouseX, fMouseY, fMouseZ;
        fMouseX = downPoint.x;
        fMouseY = downPoint.y;
        fMouseZ = 0.0f;
        
        glReadPixels(fMouseX, fMouseY, 1, 1, GL_DEPTH_COMPONENT, GL_FLOAT, &fMouseZ);
    
        double dTempX, dTempY, dTempZ;
        gluUnProject(fMouseX, fMouseY, fMouseZ, afModelviewMatrix, afProjectionMatrix, anViewport, &dTempX, &dTempY, &dTempZ);
    //gluProject(<#GLdouble objX#>, <#GLdouble objY#>, <#GLdouble objZ#>, <#const GLdouble *model#>, <#const GLdouble *proj#>, <#const GLint *view#>, <#GLdouble *winX#>, <#GLdouble *winY#>, <#GLdouble *winZ#>)
    
     //ofObjX, Y and Z should be populated and returned now
    //NSLog(@"%f %f %f %f %f %f", dTempX, dTempY, dTempZ,fMouseX,fMouseY,fMouseZ);
   
        CVector3 vPosition= NewCVector3(cx,cy,cz);
        CVector3 vFar= NewCVector3(dTempX,dTempY,dTempZ);
        
        //Check intersection
        CVector3 l = SubtractTwoVectors(vFar, vPosition);
    
    
        if (Magnitude(l) > lastExtreme)
        {
            lastExtreme = Magnitude(l) + 10;
            return NO;
        }
        lastExtreme = Magnitude(l) + 10;
    
   // NSLog(@"%f", Magnitude(l));
     //NSLog(@"%f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f", afProjectionMatrix[0],afProjectionMatrix[1],afProjectionMatrix[2],afProjectionMatrix[3],afProjectionMatrix[4],afProjectionMatrix[5],afProjectionMatrix[6],afProjectionMatrix[7],afProjectionMatrix[8],afProjectionMatrix[9],afProjectionMatrix[10],afProjectionMatrix[11],afProjectionMatrix[12],afProjectionMatrix[13],afProjectionMatrix[14],afProjectionMatrix[15],afProjectionMatrix[16]);
    //NSLog(@"%f", Magnitude(l));
    
    
    
    toPt[0] = vPosition.x+l.x*100;
    toPt[1] = vPosition.y+l.y*100;
    toPt[2] = vPosition.z+l.z*100;
    
    
        float *closest;
        BOOL found = NO;
    float closestDistance = 1000;

        //mesh_index = selectedBSP;
        for (mesh_index = 0; mesh_index < mesh_count; mesh_index++)
		{
            
        SUBMESH_INFO *pMesha;
        pMesha = [mapBSP GetActiveBspPCSubmesh:mesh_index];
        
        
        for (i = 0; i < pMesha->IndexCount; i++)
        {
            float *vertex = pMesha->pVert[pMesha->pIndex[i].tri_ind[0]].vertex_k;
            float *vertex2 = pMesha->pVert[pMesha->pIndex[i].tri_ind[1]].vertex_k;
            float *vertex3 = pMesha->pVert[pMesha->pIndex[i].tri_ind[2]].vertex_k;
            float *normal = pMesha->pVert[pMesha->pIndex[i].tri_ind[0]].normal;
          
            //CVector3 a= NewCVector3(vertex[0],vertex[1],vertex[2]);
            //CVector3 n= NewCVector3(normal[0],normal[1],normal[2]);
            
            /*
            float dot = Dot(n, l);
            
            if (dot <= 0.0)
                continue;
            
            float d = Dot(n, SubtractTwoVectors(a, vPosition)) / dot;
            if (d < 0.0f || d > 1.0f) // plane is beyond the ray we consider
                continue;
            */
            
            //CVector3 p = AddTwoVectors(vPosition, NewCVector3(d*l.x, d*l.y, d*l.z)); // p intersect the plane (triangle)
            
            /*
            CVector3 b = NewCVector3(vertex2[0],vertex2[1],vertex2[2]);
            CVector3 cvec = NewCVector3(vertex3[0],vertex3[1],vertex3[2]);
            
            CVector3 n1 = Cross(SubtractTwoVectors(b, a), SubtractTwoVectors(p, a));
            CVector3 n2 = Cross(SubtractTwoVectors(cvec, b), SubtractTwoVectors(p, b));
            CVector3 n3 = Cross(SubtractTwoVectors(a, cvec), SubtractTwoVectors(p, cvec));
            
            if (Dot(n,n1) >= 0.0f &&
                Dot(n,n2) >= 0.0f &&
                Dot(n,n3) >= 0.0f)
            {*/
                /* We have found one of the triangle that
                 intersects the line/ray
                 */
            
                
                //Where does it intersect?
                
                
                
                float *pt1 = vertex;
                float *pt2 = vertex2;
                float *pt3 = vertex3;
                
                if (pt1[0] == pt2[0] || pt1[1] == pt2[1])
                {
                   // NSLog(@"Continuing");
                   // continue;
                }
                
                fpoint fpt1 = {pt1[0], pt1[1], pt1[2]};
                fpoint fpt2 = {pt2[0], pt2[1], pt2[2]};
                fpoint fpt3 = {pt3[0], pt3[1], pt3[2]};
                fpoint fpt4 = {vPosition.x, vPosition.y, vPosition.z};
                
                fpoint v = {l.x, l.y, l.z};
                fpoint* pt_int = malloc(sizeof(fpoint));
                
   
                if (check_intersect_tri(fpt1, fpt2, fpt3, fpt4, v, pt_int))
                {
                    float dist = (float)sqrt(powf(vPosition.x - pt_int->x,2) + powf(vPosition.y - pt_int->y, 2) + powf(vPosition.z - pt_int->z, 2));
                    
                    //Is this point infront of us
                    CVector3 vPosition = NewCVector3(cx,cy,cz);
                    CVector3 vFar = NewCVector3(dTempX,dTempY,dTempZ);
                    CVector3 l = SubtractTwoVectors(vFar, vPosition);
                    
                    float delta = (pt_int->x - vPosition.x)/(l.x/Magnitude(l));
                    
                    
                    //NSLog(@"%f",  delta);
                    
                   
                    if (delta < 0)
                        continue;
                    
                    
                    if (dist < closestDistance)
                    {
                        if (found)
                            free(closest);
                        
                        closestDistance = dist;
                        
                        //Inside triangle
                        closest = malloc(sizeof(float)*3);
                        closest[0]=pt_int->x;
                        closest[1]=pt_int->y;
                        closest[2]=pt_int->z;
                        
                        insX = pt_int->x;
                        insY = pt_int->y;
                        insZ = pt_int->z;
                        
                        //}
                        //return closest;
                     
                        selectedBSP = mesh_index;
                        indexMesh = selectedBSP;
                        //indexHighlight = i;
                        selectedPIndex = i;
              
                       
                        
                        //now, where ON the triangle does it intersect?
                        
                        // calculate vectors from point f to vertices p1, p2 and p3:
                        CVector3 f = NewCVector3(pt_int->x, pt_int->y, pt_int->z);
                        CVector3 p1 = NewCVector3(pt1[0], pt1[1], pt1[2]);
                        CVector3 p2 = NewCVector3(pt2[0], pt2[1], pt2[2]);
                        CVector3 p3 = NewCVector3(pt3[0], pt3[1], pt3[2]);
                        
                        CVector3 f1 = SubtractTwoVectors(p1, f);
                        CVector3 f2 = SubtractTwoVectors(p2, f);
                        CVector3 f3 = SubtractTwoVectors(p3, f);
                        
                        // calculate the areas and factors (order of parameters doesn't matter):
                        float a = Magnitude(Cross(SubtractTwoVectors(p1, p2), SubtractTwoVectors(p1, p3)));
                         uva1 = Magnitude(Cross(f2, f3)) / a;
                         uva2 = Magnitude(Cross(f3, f1)) / a;
                         uva3 = Magnitude(Cross(f1, f2)) / a;
                    
                   

                    // find the uv corresponding to point f (uv1/uv2/uv3 are associated to p1/p2/p3):
                    //var uv: Vector2 = uv1 * a1 + uv2 * a2 + uv3 * a3;
                    
                    
                        found = YES;
                    }
                    
                    
                   
                }
                //}
        }

        }
        
            
            

        //}

    
        if (found)
        {
          
            isPainting= NO;
            //NSLog(@"%f %f %f", p.x, p.y, p.z);
            return selectedBSP;
        }

    
        //This function is broken but it'll do for now. We can always hide the mouse cursor. Find where this line intersects the bsp
        

    
    isPainting = NO;
    return -1;
    
    
}

- (void)trySelection:(NSPoint)downPoint shiftDown:(BOOL)shiftDown width:(NSNumber*)aw height:(NSNumber*)ah
{
	_lookup = NULL;
	
	// Thank you, http://glprogramming.com/red/chapter13.html

		
	/*SHARPY NOTE
	 -----------------
	 The try statement has been added to this function to prevent the application crashing.
	 It's really frustrating to lose your map.
	 
	 
	 ------------------*/
	
	// Adjustment that, for some reason, is necessary.
	//downPoint.x -= 25.0f;
	//downPoint.y -= 71.0f;
	
	GLsizei bufferSize = (GLsizei) ([_scenario vehicle_spawn_count] + 
									[_scenario scenery_spawn_count] + 
									[_scenario item_spawn_count] + 
									[_scenario multiplayer_flags_count] +
									[_scenario player_spawn_count] +
									[_scenario mach_spawn_count]+
									[_scenario encounter_count]+bsp_point_count);
    
    GLdouble some_non_genericvaluew = [aw floatValue];
    GLdouble some_non_genericvalueh = [ah floatValue];

	bufferSize += 50;
	
	GLuint nameBuf[bufferSize];
	GLuint tmpLookup[bufferSize];
	GLint viewport[4];
	GLuint hits;
	unsigned int i, j, z1, z2;
	
	if (!selections)
		selections = [[NSMutableArray alloc] init]; // Three times too big for meh.
	
	// Lookup is our name lookup table for the hits we get.
	_lookup = (GLuint *)tmpLookup;
	
	
	glGetIntegerv(GL_VIEWPORT,viewport);
	glSelectBuffer(bufferSize,nameBuf);
	//glMatrixMode(GL_PROJECTION);
    
	glRenderMode(GL_SELECT);
	glMatrixMode(GL_PROJECTION);
    
    
	glPushMatrix();
	glLoadIdentity();
	
	gluPickMatrix((GLdouble)(downPoint.x + some_non_genericvaluew / 2),(GLdouble)(downPoint.y + some_non_genericvalueh / 2),(GLdouble)(some_non_genericvaluew),(GLdouble)(some_non_genericvalueh),viewport);
	gluPerspective(45.0f,(GLfloat)((GLfloat)(viewport[2] - viewport[0])/(GLfloat)(viewport[3] - viewport[1])),0.1f,400000.0f);
	
	glMatrixMode(GL_MODELVIEW);
    
	glColor4f(1.0f,1.0f,1.0f,1.0f);
    
    needsReshape = YES;
    
	// This kick starts names
	[self renderAllMapObjects];
	
	
	
	//[self reshape];
	hits = glRenderMode(GL_RENDER);

	GLuint names, *ptr = (GLuint *)nameBuf;
	unsigned int type;
	BOOL hasFound = FALSE;
	
	if (hits == 0 || !shiftDown)
	{
		[self deselectAllObjects];
	}
    
    glPopMatrix();
    
	/*
	type = (long)(tableVal / 10000);
	index = (tableVal % 10000);
	*/
    
   // NSLog(@"HIT: %d", hits);
    
        ignoreCSS = 0;
		for (i = 0; i < hits; i++)
		{
            
			names = *ptr;
            
    
			
            
			ptr++;
			z1 = (float)*ptr/0x7fffffff;
			ptr++;
			z2 = (float)*ptr/0x7fffffff;
			ptr++;
			for ( j = 0; j < names; j++)
			{
				if (z2 < selectDistance)
				{
					type = (unsigned int)(_lookup[*ptr] / MAX_SCENARIO_OBJECTS);
					if (type == _selectType || _selectType == s_all)
					{
						
						
						[self processSelection:(unsigned int)_lookup[*ptr]];
						hasFound = TRUE;
					}
					ptr++;
					
					if (![msel state])
					{
						if (hasFound)
							break;
					}
				}
			}
			if (![msel state])
			{
				if (hasFound)
					break;
			}
		}

	
	
	
	_lookup = NULL;
}


-(int)ID
{
	return haloProcessID;
}

- (void)deselectAllObjects
{
	//[self updateVehiclesLive];
	[spawne setAlphaValue:0.2];
	
	int x;
	for (x = 0; x < [_scenario vehicle_spawn_count]; x++)
		[_scenario vehi_spawns][x].isSelected = NO;
	for (x = 0; x < [_scenario scenery_spawn_count]; x++)
		[_scenario scen_spawns][x].isSelected = NO;
	for (x = 0; x < [_scenario item_spawn_count]; x++)
		[_scenario item_spawns][x].isSelected = NO;
	for (x = 0; x < [_scenario player_spawn_count]; x++)
		[_scenario spawns][x].isSelected = NO;
	for (x = 0; x < [_scenario encounter_count]; x++)
		[_scenario encounters][x].start_locs[0].isSelected = NO;
	for (x = 0; x < [_scenario multiplayer_flags_count]; x++)
		[_scenario netgame_flags][x].isSelected = NO;
	for (x = 0; x < [_scenario mach_spawn_count]; x++)
		[_scenario mach_spawns][x].isSelected = NO;
	for (x = 0; x < 16; x++)
		playercoords[(x * 8) + 4] = 0.0;
	
	
	
	if (editable)
	{
		for (x = 0; x < [[mapBSP mesh] coll_count]; x++)
			[[mapBSP mesh] collision_verticies][x].isSelected=NO;
		
		for (x = 0; x < bsp_point_count; x++)
			bsp_points[x].isSelected = NO;
	}
	
	[selectText setStringValue:[[NSNumber numberWithInt:0] stringValue]];
	[selectedName setStringValue:@""];
	[selectedType setStringValue:@""];
	[selectedAddress setStringValue:@""];
	[selections removeAllObjects];
	[selectedSwapButton removeAllItems];
}

#define kBitmask @"Bitmask"
#define kPopup @"Popup"
#define kName @"Name"
#define kType @"Type"
#define kData @"Data"
#define kSelection @"Selection"
#define kPointer @"Pointer"

-(IBAction)updateValueForUserInterface:(NSPopUpButton*)sender
{
    if ([selections count] == 1)
    {
        unsigned int nameLookup,
        type,
        index;
        
        nameLookup = [[selections objectAtIndex:0] unsignedIntValue];
		type = (unsigned int)(nameLookup / MAX_SCENARIO_OBJECTS);
		index = (unsigned int)(nameLookup % MAX_SCENARIO_OBJECTS);
		
		long *pointer = [[sender toolTip] longLongValue];
        (*pointer) = (short)[sender indexOfItem:[sender selectedItem]];
    }
}

-(IBAction)updateValueForBITMASKUserInterface:(NSPopUpButton*)sender
{
    //pointer|new value
    if ([selections count] == 1)
    {
        unsigned int nameLookup,
        type,
        index;
        
        nameLookup = [[selections objectAtIndex:0] unsignedIntValue];
		type = (unsigned int)(nameLookup / MAX_SCENARIO_OBJECTS);
		index = (unsigned int)(nameLookup % MAX_SCENARIO_OBJECTS);
		
        NSString *str = [sender toolTip];
        int d = (int)[[str substringFromIndex:[str rangeOfString:@"|"].location+1] intValue];
        
        long *pointer = [[str substringToIndex:[str rangeOfString:@"|"].location] longLongValue];
        short cVal = *pointer;
        
        //((sel>>(31-val)) & 1)
        
        if (cVal & (int)pow(2, (31-d)))
        {
            NSLog(@"Removing %ld %d %d", pointer, cVal, d);
            (*pointer) = (int)cVal & ~ (int)pow(2, (31-d));
        }
        else
        {
            NSLog(@"Adding %ld %d %d", pointer, cVal, d);
            (*pointer) = (int)cVal | (int)pow(2, (31-d)); //Add a value
        }
    }
}


char *int2bin(int a, char *buffer, int buf_size) {
    buffer += (buf_size - 1);

    int i;
    for (i = 31; i >= 0; i--) {
        *buffer-- = (a & 1) + '0';
        
        a >>= 1;
    }
    
    return buffer;
}

#define BUF_SIZE 33


-(void)createUserInterfaceForSettings:(NSArray*)settings;
{
    
    
    float maxWidth = 100;
    float border = 20;
    float elementHeight = 22;
    
    float totalHeight = border;
    
    //NSArray *subviews = [[settings_Window_Object contentView] subviews];
    
    [[settings_Window_Object contentView] setSubviews:[NSArray array]];
    
    int i;
    //for (i=0; i < [subviews count]; i++)
    //{
     //   [[subviews objectAtIndex:i] removeFromSuperview];
    //}
    
    
    
    NSRect old = [settings_Window_Object frame];
    NSRect new = NSMakeRect([settings_Window_Object frame].origin.x, settings_Window_Object.frame.origin.y, settings_Window_Object.frame.size.width, 2*border + (elementHeight+10)*([settings count]));
    
    [settings_Window_Object setFrame:NSMakeRect(new.origin.x - (new.size.width - old.size.width), new.origin.y - (new.size.height - old.size.height), new.size.width, new.size.height) display:YES];
    
    
    float y = [[settings_Window_Object contentView] bounds].size.height - border;
    
    
    
    for(i=0; i < [settings count]; i++)
    {
        float x = border;
        
        NSDictionary *data = [settings objectAtIndex:i];
        NSString *text = [data objectForKey:kName];

        y-=elementHeight;
        
        NSTextField *title = [[NSTextField alloc] initWithFrame:NSMakeRect(x, y, maxWidth, elementHeight)];
        [title setStringValue:text];
        [title sizeToFit];
        
        [title setBordered:NO];
        [title setEditable:NO];
        [title setSelectable:NO];
        [title setBackgroundColor:[NSColor clearColor]];
        
        x+=maxWidth;
        
        //Add the appropriate value
        if ([[data objectForKey:kType] isEqualToString:kPopup])
        {
            NSPopUpButton *button = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(x, y, [settings_Window_Object frame].size.width-border-x, elementHeight)];
            
            NSArray *kdata = [data objectForKey:kData];
            [button addItemsWithTitles:kdata];
            
            NSLog(@"%@: %d", text, [[data objectForKey:kSelection] intValue]);
        
            if ([[data objectForKey:kSelection] intValue] > 0 && [[data objectForKey:kSelection] intValue] < [kdata count])
                [button selectItemAtIndex:[[data objectForKey:kSelection] intValue]];
            
            [button setTarget:self];
            [button setAction:@selector(updateValueForUserInterface:)];
            
            if ([data objectForKey:kPointer])
                [button setToolTip:[NSString stringWithFormat:@"%ld", [[data objectForKey:kPointer] longValue]]];
            
            [[settings_Window_Object contentView] addSubview:button];
        }
        else if ([[data objectForKey:kType] isEqualToString:kBitmask])
        {
            NSButton *button = [[NSButton alloc] initWithFrame:NSMakeRect(x, y, [settings_Window_Object frame].size.width-border-x, elementHeight)];
            [button setButtonType:NSSwitchButton];
            [button setTitle:@""];
            
            
            int val = [[data objectForKey:kData] intValue];
            int sel = [[data objectForKey:kSelection] intValue];
            

      
            //NSLog(@"%@: %d %d %d %d", text, val, sel, sel&val, ((sel>>(31-val)) & 1));
            
            
        
            if ((sel>>(31-val)) & 1)
            {
                [button setState:1];
            }
            
            [button setTarget:self];
            [button setAction:@selector(updateValueForBITMASKUserInterface:)];
            
            
            if ([data objectForKey:kPointer])
                [button setToolTip:[NSString stringWithFormat:@"%ld|%d", [[data objectForKey:kPointer] longValue], (int)val]];
            
            
            [[settings_Window_Object contentView] addSubview:button];
        }
        
        [[settings_Window_Object contentView] addSubview:title];
        
        totalHeight+=elementHeight+10;
        y-=10;
    }
    totalHeight+=border;
    
    [[settings_Window_Object contentView] setNeedsDisplay:YES];
    
    //Type0 Popup
    //Type1 Popup
    //Type2 Popup
    //Type3 Popup
    //Team Index Popup
    
    //settings_Window_Object
}

- (void)processSelection:(unsigned int)tableVal
{
	[spawne setAlphaValue:1.0];
	
	unsigned int type, index;
	long mapIndex;
	BOOL overrideString;
	
	type = (long)(tableVal / MAX_SCENARIO_OBJECTS);
	index = (tableVal % MAX_SCENARIO_OBJECTS);
	
	_selectFocus = tableVal;
	
	[selections addObject:[NSNumber numberWithLong:tableVal]];
	[selectText setStringValue:[[NSNumber numberWithInt:[selections count]] stringValue]];
	
	[selectedSwapButton removeAllItems];
	
	[_spawnEditor loadFocusedItemData:_selectFocus];
	
    //NSLog(@"%d", type);
	switch (type)
	{
		case s_scenery:
			if (_selectType == s_all || _selectType == s_scenery)
			{
				/*
                if (ignoreCSS)
                {
                    [self deselectAllObjects];
                    break;
                }
				else if (is_css)
				{
					if (NSRunAlertPanel(@"Cascading Server Side (CSS)", @"If you move this object (scenery), other players will not be able to see it without the mod. Lag may occur when players collide with it.", @"Cancel", @"Continue", nil) == NSOKButton)
					{
                        ignoreCSS = 1;
						[self deselectAllObjects];
						break;
					}
				else
                {
					is_css = NO;
                }
				}
				*/
                
				[_scenario scen_spawns][index].isSelected = YES;
				mapIndex = [_scenario scen_references][[_scenario scen_spawns][index].numid].scen_ref.TagId;
				[self setRotationSliders:[_scenario scen_spawns][index].rotation[0] y:[_scenario scen_spawns][index].rotation[1] z:[_scenario scen_spawns][index].rotation[2]];
				[self setPositionSliders:[NSNumber numberWithFloat:[_scenario scen_spawns][index].coord[0]] y:[NSNumber numberWithFloat:[_scenario scen_spawns][index].coord[1]] z:[NSNumber numberWithFloat:[_scenario scen_spawns][index].coord[2]]];
				[selectedSwapButton addItemsWithTitles:(NSArray *)[_scenario scenTagArray]];
			}
			break;
		case s_playerspawn:
			if (_selectType == s_all || _selectType == s_playerspawn)
			{
                
#ifdef MACVERSION
                NSArray *gametypeList = @[@"None", @"CTF", @"Slayer", @"Oddball", @"King of the Hill", @"Race", @"Terminator", @"Stub", @"Ignored 1", @"Ignored 2", @"Ignored 3", @"Ignored 4", @"All Games", @"All except CTF", @"All except Race and CTF"];
                NSArray *settings = @[@{kName:@"Gametype 1", kType:kPopup, kData:gametypeList, kSelection:[NSNumber numberWithShort:[_scenario spawns][index].type1], kPointer:[NSNumber numberWithLong:&([_scenario spawns][index].type1)]},
                                      @{kName:@"Gametype 2", kType:kPopup, kData:gametypeList, kSelection:[NSNumber numberWithShort:[_scenario spawns][index].type2], kPointer:[NSNumber numberWithLong:&([_scenario spawns][index].type2)]},
                                      @{kName:@"Gametype 3", kType:kPopup, kData:gametypeList, kSelection:[NSNumber numberWithShort:[_scenario spawns][index].type3], kPointer:[NSNumber numberWithLong:&([_scenario spawns][index].type3)]},
                                      @{kName:@"Gametype 4", kType:kPopup, kData:gametypeList, kSelection:[NSNumber numberWithShort:[_scenario spawns][index].type4], kPointer:[NSNumber numberWithLong:&([_scenario spawns][index].type4)]},
                                      @{kName:@"Team Index", kType:kPopup, kData:@[@"Red", @"Blue", @"2", @"3"], kSelection:[NSNumber numberWithShort:[_scenario spawns][index].team_index], kPointer:[NSNumber numberWithLong:&([_scenario spawns][index].team_index)]}];
                
                [self performSelectorOnMainThread:@selector(createUserInterfaceForSettings:) withObject:settings waitUntilDone:YES];
      #endif
                
				[_scenario spawns][index].isSelected = YES;
				switch ([_scenario spawns][index].team_index)
				{
					case 0:
						[selectedType setStringValue:@"Red Team"];
						break;
					case 1:
						[selectedType setStringValue:@"Blue Team"];
						break;
                    case 2:
						[selectedType setStringValue:@"2"];
						break;
                    case 3:
						[selectedType setStringValue:@"3"];
						break;
				}
				[self setRotationSliders:[_scenario spawns][index].rotation y:0 z:0];
                [self setPositionSliders:[NSNumber numberWithFloat:[_scenario spawns][index].coord[0]] y:[NSNumber numberWithFloat:[_scenario spawns][index].coord[1]] z:[NSNumber numberWithFloat:[_scenario spawns][index].coord[2]]];
				overrideString = TRUE;

			}
			break;
		case s_encounter:
			if (_selectType == s_all)
			{
				[_scenario encounters][index].start_locs[0].isSelected = YES;
				switch ([_scenario encounters][index].start_locs[0].team_index)
				{
					case 0:
						[selectedType setStringValue:@"Red Team"];
						break;
					case 1:
						[selectedType setStringValue:@"AI Encounter"];
						break;
				}
				[self setRotationSliders:[_scenario encounters][index].start_locs[0].rotation y:0 z:0];
                //[self setPositionSliders:[NSNumber numberWithFloat:[_scenario encounters][index].start_locs.coord[0]] y:[NSNumber numberWithFloat:[_scenario encounters][index].start_locs.coord[1]] z:[NSNumber numberWithFloat:[_scenario encounters][index].coord[2]]];
				overrideString = TRUE;
			}
			break;
		case s_mapobject:
			if (_selectType == s_all || _selectType == s_mapobject)
			{
				map_objects[index].isSelected = YES;
				[selectedType setStringValue:[NSString stringWithFormat:@"%d",map_objects[index].address]];
				[self setRotationSliders:0 y:0 z:0];
                //[self setPositionSliders:[_scenario scen_spawns][index].coord[0] y:[_scenario scen_spawns][index].coord[1] z:[_scenario scen_spawns][index].coord[2]];
			}
			break;
		case s_vehicle:
			if (_selectType == s_all || _selectType == s_vehicle)
			{
                //88 //56
                
                #ifdef MACVERSION
                short *pointer;
                pointer = &([_scenario vehi_spawns][index].unknown2[14]);
                pointer = pointer + 1;
                
                NSArray *settings = @[@{kName:@"Team Index", kType:kPopup, kData:@[@"Red", @"Blue"], kSelection:[NSNumber numberWithShort:[_scenario vehi_spawns][index].unknown2[14]], kPointer:[NSNumber numberWithLong:&([_scenario vehi_spawns][index].unknown2[14])]},
                                      @{kName:@"CTF", kType:kBitmask, kData:[NSNumber numberWithInteger:30], kSelection:[NSNumber numberWithInteger:*pointer], kPointer:[NSNumber numberWithLong:pointer]},
                                      @{kName:@"Slayer", kType:kBitmask, kData:[NSNumber numberWithInteger:31], kSelection:[NSNumber numberWithInteger:*pointer], kPointer:[NSNumber numberWithLong:pointer]},
                                      @{kName:@"King", kType:kBitmask, kData:[NSNumber numberWithInteger:29], kSelection:[NSNumber numberWithInteger:*pointer], kPointer:[NSNumber numberWithLong:pointer]},
                                      @{kName:@"Oddball", kType:kBitmask, kData:[NSNumber numberWithInteger:28], kSelection:[NSNumber numberWithInteger:*pointer], kPointer:[NSNumber numberWithLong:pointer]}];
                [self performSelectorOnMainThread:@selector(createUserInterfaceForSettings:) withObject:settings waitUntilDone:YES];
                #endif
                
				[_scenario vehi_spawns][index].isSelected = YES;
				mapIndex = [_scenario vehi_references][[_scenario vehi_spawns][index].numid].vehi_ref.TagId;
				[self setRotationSliders:[_scenario vehi_spawns][index].rotation[0] y:[_scenario vehi_spawns][index].rotation[1] z:[_scenario vehi_spawns][index].rotation[2]];
				[self setPositionSliders:[NSNumber numberWithFloat:[_scenario vehi_spawns][index].coord[0]] y:[NSNumber numberWithFloat:[_scenario vehi_spawns][index].coord[1]] z:[NSNumber numberWithFloat:[_scenario vehi_spawns][index].coord[2]]];
				[selectedSwapButton addItemsWithTitles:(NSArray *)[_scenario vehiTagArray]];

			}
			break;
		case s_machine:
			if (_selectType == s_all || _selectType == s_machine)
			{
                #ifdef MACVERSION
                
                NSArray *shorts = @[@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10",
                                    @"11", @"12", @"13", @"14", @"15", @"16", @"17", @"18", @"19", @"20",
                                    @"21", @"22", @"23", @"24", @"25", @"26", @"27", @"28", @"29", @"30",
                                    @"31", @"32", @"33", @"34", @"35", @"36", @"37", @"38", @"39", @"40",
                                    @"41", @"42", @"43", @"44", @"45", @"46", @"47", @"48", @"49", @"50",
                                    @"51", @"52", @"53", @"54", @"55", @"56", @"57", @"58", @"59", @"60"];
                NSArray *settings = @[@{kName:@"Power Group", kType:kPopup, kData:shorts, kSelection:[NSNumber numberWithShort:[_scenario mach_spawns][index].powerGroup], kPointer:[NSNumber numberWithLong:&([_scenario mach_spawns][index].powerGroup)]},
                                      @{kName:@"Position Group", kType:kPopup, kData:shorts, kSelection:[NSNumber numberWithShort:[_scenario mach_spawns][index].positionGroup], kPointer:[NSNumber numberWithLong:&([_scenario mach_spawns][index].positionGroup)]}
                                      ];
                [self performSelectorOnMainThread:@selector(createUserInterfaceForSettings:) withObject:settings waitUntilDone:YES];
                #endif
                
				[_scenario mach_spawns][index].isSelected = YES;
				mapIndex = [_scenario mach_references][[_scenario mach_spawns][index].numid].machTag.TagId;
				[self setRotationSliders:[_scenario mach_spawns][index].rotation[0] y:[_scenario mach_spawns][index].rotation[1] z:[_scenario mach_spawns][index].rotation[2]];
                [self setPositionSliders:[NSNumber numberWithFloat:[_scenario mach_spawns][index].coord[0]] y:[NSNumber numberWithFloat:[_scenario mach_spawns][index].coord[1]] z:[NSNumber numberWithFloat:[_scenario mach_spawns][index].coord[2]]];
				[selectedSwapButton addItemsWithTitles:(NSArray *)[_scenario machTagArray]];

			}
			break;
		case s_netgame:
			if (_selectType == s_all || _selectType == s_netgame)
			{
                #ifdef MACVERSION
                NSArray *gametypeList = @[@"CTF Flag", @"CTF Vehicle", @"Oddball Spawn", @"Race Track", @"Race Vehicle", @"Vegas Bank", @"Teleport From", @"Teleport To", @"Hill Flag"];
                NSArray *settings = nil;
                NSArray *channels = @[@"Alpha", @"Bravo", @"Charlie", @"Delta", @"Echo", @"Foxtrot", @"Golf", @"Hotel", @"India", @"Juliet", @"Kilo",
                                      @"Lima", @"Mike", @"November", @"Oscar", @"Papa", @"Quebec", @"Romeo", @"Sierra", @"Tango", @"Uniform", @"Victor", @"Whiskey", @"X-ray", @"Yankee", @"Zulu"];
                NSArray *teams = @[@"Red", @"Blue"];
                
                NSMutableArray *teamIndicies = [[NSMutableArray alloc] init];
                
                int a;
                for (a=0; a < 255; a++)
                {
                    [teamIndicies addObject:[NSString stringWithFormat:@"%d", a]];
                }
                
               // NSArray *teamIndicies = @[@"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10", @"11", @"12", @"13", @"14", @"15", @"16", @"17", @"18", @"19", @"20"];
                
                switch ([_scenario netgame_flags][index].type)
				{
					case teleporter_entrance:
						settings = @[@{kName:@"Type", kType:kPopup, kData:gametypeList, kSelection:[NSNumber numberWithShort:[_scenario netgame_flags][index].type], kPointer:[NSNumber numberWithLong:&([_scenario netgame_flags][index].type)]},
                                     @{kName:@"Channel", kType:kPopup, kData:channels, kSelection:[NSNumber numberWithShort:[_scenario netgame_flags][index].team_index], kPointer:[NSNumber numberWithLong:&([_scenario netgame_flags][index].team_index)]}];
						break;
					case teleporter_exit:
						settings = @[@{kName:@"Type", kType:kPopup, kData:gametypeList, kSelection:[NSNumber numberWithShort:[_scenario netgame_flags][index].type], kPointer:[NSNumber numberWithLong:&([_scenario netgame_flags][index].type)]},
                                     @{kName:@"Channel", kType:kPopup, kData:channels, kSelection:[NSNumber numberWithShort:[_scenario netgame_flags][index].team_index], kPointer:[NSNumber numberWithLong:&([_scenario netgame_flags][index].team_index)]}];
						break;
                    case hill_flag:
                        settings = @[@{kName:@"Type", kType:kPopup, kData:gametypeList, kSelection:[NSNumber numberWithShort:[_scenario netgame_flags][index].type], kPointer:[NSNumber numberWithLong:&([_scenario netgame_flags][index].type)]},
                                     @{kName:@"Hill Index", kType:kPopup, kData:teamIndicies, kSelection:[NSNumber numberWithShort:[_scenario netgame_flags][index].team_index], kPointer:[NSNumber numberWithLong:&([_scenario netgame_flags][index].team_index)]}];
                        break;
                    case race_track:
                        settings = @[@{kName:@"Type", kType:kPopup, kData:gametypeList, kSelection:[NSNumber numberWithShort:[_scenario netgame_flags][index].type], kPointer:[NSNumber numberWithLong:&([_scenario netgame_flags][index].type)]},
                                     @{kName:@"Track Index", kType:kPopup, kData:teamIndicies, kSelection:[NSNumber numberWithShort:[_scenario netgame_flags][index].team_index], kPointer:[NSNumber numberWithLong:&([_scenario netgame_flags][index].team_index)]}];
                        break;
					default:
                        settings = @[@{kName:@"Type", kType:kPopup, kData:gametypeList, kSelection:[NSNumber numberWithShort:[_scenario netgame_flags][index].type], kPointer:[NSNumber numberWithLong:&([_scenario netgame_flags][index].type)]},
                                     @{kName:@"Team Index", kType:kPopup, kData:teams, kSelection:[NSNumber numberWithShort:[_scenario netgame_flags][index].team_index], kPointer:[NSNumber numberWithLong:&([_scenario netgame_flags][index].team_index)]}];
                        
                        break;
                }
                
                
                
                if (settings != nil)
                    [self performSelectorOnMainThread:@selector(createUserInterfaceForSettings:) withObject:settings waitUntilDone:YES];
                #endif
				[_scenario netgame_flags][index].isSelected = YES;
				switch ([_scenario netgame_flags][index].type)
				{
					case teleporter_entrance:
						[selectedType setStringValue:@"Teleporter Entrance"];
						break;
					case teleporter_exit:
						[selectedType setStringValue:@"Teleporter Exit"];
						break;
					case ctf_flag:
						[selectedType setStringValue:@"CTF Flag"];
						break;
					case ctf_vehicle:
						[selectedType setStringValue:@"CTF Vehicle"];
						break;
					case oddball:
						[selectedType setStringValue:@"Oddball"];
						break;
					case race_track:
						[selectedType setStringValue:@"Race Track Marker"];
						break;
					case race_vehicle:
						[selectedType setStringValue:@"Race Vehicle"];
						break;
					case vegas_bank:
						[selectedType setStringValue:@"Vegas Bank?"];
						break;
					case hill_flag:
						[selectedType setStringValue:@"KotH Hill Marker"];
						break;
				}
				[self setRotationSliders:[_scenario netgame_flags][index].rotation y:0 z:0];
                [self setPositionSliders:[NSNumber numberWithFloat:[_scenario netgame_flags][index].coord[0]] y:[NSNumber numberWithFloat:[_scenario netgame_flags][index].coord[1]] z:[NSNumber numberWithFloat:[_scenario netgame_flags][index].coord[2]]];
				overrideString = YES;

			}
			break;
		case s_item:
			if (_selectType == s_all || _selectType == s_item)
			{
                #ifdef MACVERSION
                NSLog(@"%ld", [_scenario item_spawns][index].bitmask32);
                NSArray *gametypeList = @[@"None", @"CTF", @"Slayer", @"Oddball", @"King of the Hill", @"Race", @"Terminator", @"Stub", @"Ignored 1", @"Ignored 2", @"Ignored 3", @"Ignored 4", @"All Games", @"All except CTF", @"All except Race and CTF"];
                NSArray *settings = @[@{kName:@"Levitate", kType:kPopup, kData:@[@"No", @"Yes"], kSelection:[NSNumber numberWithShort:[_scenario item_spawns][index].bitmask32], kPointer:[NSNumber numberWithLong:&([_scenario item_spawns][index].bitmask32)]},
                                      @{kName:@"Gametype 1", kType:kPopup, kData:gametypeList, kSelection:[NSNumber numberWithShort:[_scenario item_spawns][index].type1], kPointer:[NSNumber numberWithLong:&([_scenario item_spawns][index].type1)]},
                                      @{kName:@"Gametype 2", kType:kPopup, kData:gametypeList, kSelection:[NSNumber numberWithShort:[_scenario item_spawns][index].type2], kPointer:[NSNumber numberWithLong:&([_scenario item_spawns][index].type2)]},
                                      @{kName:@"Gametype 3", kType:kPopup, kData:gametypeList, kSelection:[NSNumber numberWithShort:[_scenario item_spawns][index].type3], kPointer:[NSNumber numberWithLong:&([_scenario item_spawns][index].type3)]},
                                      @{kName:@"Gametype 4", kType:kPopup, kData:gametypeList, kSelection:[NSNumber numberWithShort:[_scenario item_spawns][index].type4], kPointer:[NSNumber numberWithLong:&([_scenario item_spawns][index].type4)]},
                                      @{kName:@"Team Index", kType:kPopup, kData:@[@"Red", @"Blue"], kSelection:[NSNumber numberWithShort:[_scenario item_spawns][index].team_index], kPointer:[NSNumber numberWithLong:&([_scenario item_spawns][index].team_index)]}];
                [self createUserInterfaceForSettings:settings];
                #endif
				[_scenario item_spawns][index].isSelected = YES;
				mapIndex = [_scenario item_spawns][index].itmc.TagId;
				[self setRotationSliders:[_scenario item_spawns][index].yaw y:0 z:0];
				[self setPositionSliders:[NSNumber numberWithFloat:[_scenario item_spawns][index].coord[0]] y:[NSNumber numberWithFloat:[_scenario item_spawns][index].coord[1]] z:[NSNumber numberWithFloat:[_scenario item_spawns][index].coord[2]]];
				
				[selectedSwapButton addItemsWithTitles:(NSArray *)[_mapfile itmcList]];
                //[selectedSwapButton setTitle:[_mapfile keyForItemid:[_scenario item_spawns][index].itmc.TagId]];
			}
			break;
		case s_playerobject:
			if (_selectType == s_all || _selectType == s_item)
			{
				//LIVE
				playercoords[(index * 8) + 4] = 1.0;
				[self setRotationSliders:0 y:0 z:0];
				//[self setPositionSliders:[_scenario scen_spawns][index].coord[0] y:[_scenario scen_spawns][index].coord[1] z:[_scenario scen_spawns][index].coord[2]];
				[selectedType setStringValue:[new_characters objectAtIndex:index]];
			}
			break;
		case s_bsppoint:
			if (_selectType == s_all || _selectType == s_item)
			{
                NSLog(@"BSP POINT");
				bsp_points[index].isSelected = YES;
				
				//LIVE
				[self setRotationSliders:0 y:0 z:0];
                //[self setPositionSliders:[_scenario scen_spawns][index].coord[0] y:[_scenario scen_spawns][index].coord[1] z:[_scenario scen_spawns][index].coord[2]];
				[selectedName setStringValue:@"BSP Point"];
			}
			break;
		case s_colpoint:
			if (_selectType == s_all || _selectType == s_item)
			{
				[[mapBSP mesh] collision_verticies][index].isSelected = YES;
				
				//LIVE
				[self setRotationSliders:0 y:0 z:0];
                //[self setPositionSliders:[_scenario scen_spawns][index].coord[0] y:[_scenario scen_spawns][index].coord[1] z:[_scenario scen_spawns][index].coord[2]];
				[selectedName setStringValue:@"Collision Point"];
			}
			break;
	}
	if (type == s_playerspawn)
		[selectedName setStringValue:@"Player Spawn"];
	else if (type == s_netgame)
		[selectedName setStringValue:@"Netgame Flag"];
	else if (type == s_playerobject)
		[selectedName setStringValue:[new_characters objectAtIndex:index]];
	else
    {
        [selectedSwapButton setTitle:[[_mapfile tagForId:mapIndex] tagName]];
		[selectedName setStringValue:[[_mapfile tagForId:mapIndex] tagName]];
    }
		 
	if (type != s_netgame && type != s_playerspawn && type != s_playerobject)
		[selectedType setStringValue:[[NSString stringWithCString:[[_mapfile tagForId:mapIndex] tagClassHigh]] substringToIndex:4]];
	else if (overrideString)
		return; // lol, quick fix hur
	else
		[selectedType setStringValue:@"Non-Tag Object"];
}
- (void)fillSelectionInfo
{
	int type = (long)(_selectFocus / MAX_SCENARIO_OBJECTS);
	int index = (_selectFocus % MAX_SCENARIO_OBJECTS);
	long mapIndex;
	
	switch (type)
	{
		case s_scenery:
			if (_selectType == s_all || _selectType == s_scenery)
			{
				[_scenario scen_spawns][index].isSelected = YES;
				mapIndex = [_scenario scen_references][[_scenario scen_spawns][index].numid].scen_ref.TagId;
				[selectedName setStringValue:[[_mapfile tagForId:mapIndex] tagName]];
				[self setRotationSliders:[_scenario scen_spawns][index].rotation[0] y:[_scenario scen_spawns][index].rotation[1] z:[_scenario scen_spawns][index].rotation[2]];
                [self setPositionSliders:[NSNumber numberWithFloat:[_scenario scen_spawns][index].coord[0]] y:[NSNumber numberWithFloat:[_scenario scen_spawns][index].coord[1]] z:[NSNumber numberWithFloat:[_scenario scen_spawns][index].coord[2]]];
			}
			break;
		case s_item:
			if (_selectType == s_all || _selectType == s_item)
			{
				[_scenario item_spawns][index].isSelected = YES;
				mapIndex = [_scenario item_spawns][index].itmc.TagId;
				[self setRotationSliders:[_scenario item_spawns][index].yaw y:0 z:0];
                [self setPositionSliders:[NSNumber numberWithFloat:[_scenario item_spawns][index].coord[0]] y:[NSNumber numberWithFloat:[_scenario item_spawns][index].coord[1]] z:[NSNumber numberWithFloat:[_scenario item_spawns][index].coord[2]]];
			}
			break;
	}
}
/*

*	Object Translation

*/

-(IBAction)MovetoBSD:(id)sender;
{
	//[self DropCamera:sender];
	
	
	unsigned int	i,
	nameLookup,
	type,
	index;
	
	for (i = 0; i < [selections count]; i++)
	{
		nameLookup = [[selections objectAtIndex:i] unsignedIntValue];
		type = (unsigned int)(nameLookup / MAX_SCENARIO_OBJECTS);
		index = (unsigned int)(nameLookup % MAX_SCENARIO_OBJECTS);
		
		
		
		switch (type)
		{
			case s_vehicle:
				
				[self centerObj:[_scenario vehi_spawns][index].coord move:nil];
				break;
			case s_scenery:
				[self centerObj:[_scenario scen_spawns][index].coord move:nil];
				break;
			case s_playerspawn:
				[self centerObj:[_scenario spawns][index].coord move:nil];
				break;
			case s_netgame:
				[self centerObj:[_scenario netgame_flags][index].coord move:nil];
				break;
			case s_item:
				[self centerObj:[_scenario item_spawns][index].coord move:nil];
				break;
			case s_machine:
				[self centerObj:[_scenario mach_spawns][index].coord move:nil];
				break;
		}
	}
	
}

- (void)calculatePlayer:(int)player move:(float *)move
{
	
	int offsetToPlayerXCoordinate = 0x5C;
	int offsetToPlayerYCoordinate = 0x5C + 0x4;
	int offsetToPlayerZCoordinate = 0x5C + 0x4 + 0x4;
	
	
	int haloObjectPointer = [self getDynamicPlayer:player];
	
	int xCoord = [self readFloat:(haloObjectPointer + offsetToPlayerXCoordinate)];
	int yCoord = [self readFloat:(haloObjectPointer + offsetToPlayerYCoordinate)];
	int zCoord = [self readFloat:(haloObjectPointer + offsetToPlayerZCoordinate)];
	
	/* God damn this is being a bitch with the vector functions */
	CVector3 viewDirection, cross;
	
	// Z-axis movement, return after done since we don't want this to conflict with xy plane movement.
	if (move[2])
	{
		zCoord += (move[2] * s_acceleration);
		return;
	}
	
	//viewDirection = (CVector3)SubtractTwoVectors(NewCVector3([_camera position][0],[_camera position][1],[_camera position][2]),NewCVector3(coord[0], coord[1], coord[2]));
	viewDirection.x = [_camera position][0] - xCoord;
	viewDirection.y = [_camera position][1] - yCoord;
	viewDirection.z = [_camera position][2] - zCoord;
	
	
	xCoord += (s_acceleration * move[1] * viewDirection.x);
	yCoord += (s_acceleration * move[1] * viewDirection.y);
	
	//cross = (CVector3)Cross(NewCVector3(0,0,1),viewDirection);
	cross.x = ((0 * viewDirection.z) - (1 * viewDirection.y));
	cross.y = ((1 * viewDirection.x) - (0 * viewDirection.z));
	
	
	xCoord += (s_acceleration * move[0] * cross.x);
	yCoord += (s_acceleration * move[0] * cross.y);
	
	[self writeFloat:xCoord to:(haloObjectPointer + offsetToPlayerXCoordinate)];
	[self writeFloat:yCoord to:(haloObjectPointer + offsetToPlayerYCoordinate)];
	[self writeFloat:zCoord to:(haloObjectPointer + offsetToPlayerZCoordinate)];
}

-(void)movePlayer:(int)playern move:(float *)mo
{	
	int offsetToPlayerXCoordinate = 0x5C;
	int offsetToPlayerYCoordinate = 0x5C + 0x4;
	int offsetToPlayerZCoordinate = 0x5C + 0x4 + 0x4;
	
	int haloObjectPointer = [self getDynamicPlayer:playern];
	
	int xCoord = [self readFloat:(haloObjectPointer + offsetToPlayerXCoordinate)];
	int yCoord = [self readFloat:(haloObjectPointer + offsetToPlayerYCoordinate)];
	int zCoord = [self readFloat:(haloObjectPointer + offsetToPlayerZCoordinate)];
	
	xCoord = xCoord + mo[0];
	yCoord = yCoord + mo[1];
	zCoord = zCoord + mo[2];
	
	[self writeFloat:xCoord to:(haloObjectPointer + offsetToPlayerXCoordinate)];
	[self writeFloat:yCoord to:(haloObjectPointer + offsetToPlayerYCoordinate)];
	[self writeFloat:zCoord to:(haloObjectPointer + offsetToPlayerZCoordinate)];
}

- (void)performTranslation:(NSPoint)downPoint zEdit:(BOOL)zEdit
{
	// Ok, lets see exactly where it is that the mouse is down and see what the delta value is.
	float move[3];
	unsigned int	i,
					nameLookup,
					type,
					index;
	
	move[2] = 0;
	
	if (!zEdit)
	{
		move[0] = (downPoint.x - prevDown.x);
		move[1] = (downPoint.y - prevDown.y);
		move[2] = 0;
	}
	else
	{
		move[0] = 0;
		move[1] = 0;
		move[2] = (downPoint.y - prevDown.y)/10;
	}
	
	// Lets proportion the changes.
	move[0] /= 200;
	move[1] /= 200;
	move[2] /= 10;
	
	// correct something now
	move[1] *= -1;
	
	if ([selections count] > 1)
	{
		//[self calculateTranslation:multi_move move:move];
		float *rMove;
		nameLookup = [[selections objectAtIndex:0] unsignedIntValue];
		type = (unsigned int)(nameLookup / MAX_SCENARIO_OBJECTS);
		index = (unsigned int)(nameLookup % MAX_SCENARIO_OBJECTS);
		
		/*
			Bad code standards from the start means that I have to explicetly choose the array of spawns to edit
			This looks so shitty
		*/
		switch (type)
		{
			case s_vehicle:
				rMove = [self getTranslation:[_scenario vehi_spawns][index].coord move:move];
				break;
			case s_scenery:
				rMove = [self getTranslation:[_scenario scen_spawns][index].coord move:move];
				break;
			case s_playerspawn:
				rMove = [self getTranslation:[_scenario spawns][index].coord move:move];
				break;
			case s_netgame:
				rMove = [self getTranslation:[_scenario netgame_flags][index].coord move:move];
				break;
			case s_item:
				rMove = [self getTranslation:[_scenario item_spawns][index].coord move:move];
				break;
			case s_machine:
				rMove = [self getTranslation:[_scenario mach_spawns][index].coord move:move];
				break;
			case s_bsppoint:
				rMove = [self getTranslation:bsp_points[index].coord move:move];
				break;
			case s_colpoint:
			{
				float *coord = malloc(12);
				coord[0]=[[mapBSP mesh] collision_verticies][index].x;
				coord[1]=[[mapBSP mesh] collision_verticies][index].y;
				coord[2]=[[mapBSP mesh] collision_verticies][index].z;
				rMove = [self getTranslation:coord move:move];
				free(coord);
				break;
			}
			case s_playerobject:
				rMove = [self getPTranslation:index move:move];
				break;
				
		}
		
		/*
			Now we apply these moves.
			
			Oh my god this code looks like shit. 
			
			Sorry about this, when I began writing this program I didn't think it was necessary to
			have a way to ambiguously access scenario attributes.
		*/
		
		
		
		for (i = 0; i < [selections count]; i++)
		{
			nameLookup = [[selections objectAtIndex:i] unsignedIntValue];
			type = (unsigned int)(nameLookup / MAX_SCENARIO_OBJECTS);
			index = (unsigned int)(nameLookup % MAX_SCENARIO_OBJECTS);
			
			
			
			switch (type)
			{
				case s_vehicle:
					//[self centerObj:[_scenario vehi_spawns][index].coord move:rMove];
					[self applyMove:[_scenario vehi_spawns][index].coord move:rMove];
					break;
				case s_scenery:
					[self applyMove:[_scenario scen_spawns][index].coord move:rMove];
					break;
				case s_playerspawn:
					[self applyMove:[_scenario spawns][index].coord move:rMove];
					break;
				case s_netgame:
					[self applyMove:[_scenario netgame_flags][index].coord move:rMove];
					break;
				case s_item:
					[self applyMove:[_scenario item_spawns][index].coord move:rMove];
					break;
				case s_machine:
					[self applyMove:[_scenario mach_spawns][index].coord move:rMove];
					break;
				case s_bsppoint:
					[self applyMove:bsp_points[index].coord move:rMove];
					[self updateBSPPoint:bsp_points[index].coord index:bsp_points[index].index amindex:bsp_points[index].amindex mesh:bsp_points[index].mesh];
					break;
				case s_colpoint:
				{
					float *coord = malloc(12);
					coord[0]=[[mapBSP mesh] collision_verticies][index].x;
					coord[1]=[[mapBSP mesh] collision_verticies][index].y;
					coord[2]=[[mapBSP mesh] collision_verticies][index].z;
					[self applyMove:coord move:rMove];
					[[mapBSP mesh] collision_verticies][index].x = coord[0];
					[[mapBSP mesh] collision_verticies][index].y = coord[1];
					[[mapBSP mesh] collision_verticies][index].z = coord[2];
					free(coord);
					break;
				}
				case s_encounter:
					[self applyMove:[_scenario encounters][index].start_locs[0].coord move:rMove];
					break;
				case s_playerobject:
					[self movePlayer:index move:rMove];
					break;
			}
		}
		
		free(rMove);
	}
	else if ([selections count] == 1)
	{
		nameLookup = [[selections objectAtIndex:0] unsignedIntValue];
		type = (unsigned int)(nameLookup / MAX_SCENARIO_OBJECTS);
		index = (unsigned int)(nameLookup % MAX_SCENARIO_OBJECTS);
		
		switch (type)
		{
			case s_vehicle:
				[self calculateTranslation:[_scenario vehi_spawns][index].coord move:move];
				break;
			case s_scenery:
				[self calculateTranslation:[_scenario scen_spawns][index].coord move:move];
				break;
			case s_playerspawn:
				[self calculateTranslation:[_scenario spawns][index].coord move:move];
				break;
			case s_encounter:
				[self calculateTranslation:[_scenario encounters][index].start_locs[0].coord move:move];
				break;
			case s_netgame:
				[self calculateTranslation:[_scenario netgame_flags][index].coord move:move];
				break;
			case s_item:
				[self calculateTranslation:[_scenario item_spawns][index].coord move:move];
				break;
			case s_bsppoint:
				[self calculateTranslation:bsp_points[index].coord move:move];
				[self updateBSPPoint:bsp_points[index].coord index:bsp_points[index].index amindex:bsp_points[index].amindex mesh:bsp_points[index].mesh];
				break;
			case s_colpoint:
			{
				float *coord = malloc(12);
				coord[0]=[[mapBSP mesh] collision_verticies][index].x;
				coord[1]=[[mapBSP mesh] collision_verticies][index].y;
				coord[2]=[[mapBSP mesh] collision_verticies][index].z;
				[self calculateTranslation:coord move:move];
				[[mapBSP mesh] collision_verticies][index].x = coord[0];
				[[mapBSP mesh] collision_verticies][index].y = coord[1];
				[[mapBSP mesh] collision_verticies][index].z = coord[2];
				free(coord);
				
				break;
			}
			case s_machine:
				[self calculateTranslation:[_scenario mach_spawns][index].coord move:move];
				break;
			case s_playerobject:
				[self calculatePlayer:index move:move];
		}
	}
	
    
    
    
	
	[_spawnEditor loadFocusedItemData:_selectFocus];
}

-(void)updateBSPPoint:(float*)coord index:(int)ind amindex:(int)amindex mesh:(int)me
{
	
	
	SUBMESH_INFO *pMesh;
	pMesh = [mapBSP GetActiveBspPCSubmesh:me];
	
	pMesh->pVert[amindex].vertex_k[0] = coord[0];
	pMesh->pVert[amindex].vertex_k[1] = coord[1];
	pMesh->pVert[amindex].vertex_k[2] = coord[2];

}

- (void)calculateTranslation:(float *)coord move:(float *)move
{
	/* God damn this is being a bitch with the vector functions */
	CVector3 viewDirection, cross;
	
	// Z-axis movement, return after done since we don't want this to conflict with xy plane movement.
	if (move[2])
	{
		coord[2] += (move[2] * s_acceleration);
		return;
	}
	
	//viewDirection = (CVector3)SubtractTwoVectors(NewCVector3([_camera position][0],[_camera position][1],[_camera position][2]),NewCVector3(coord[0], coord[1], coord[2]));
	viewDirection.x = [_camera position][0] - coord[0];
	viewDirection.y = [_camera position][1] - coord[1];
	viewDirection.z = [_camera position][2] - coord[2];
	
	
	coord[0] += (s_acceleration * move[1] * viewDirection.x);
	coord[1] += (s_acceleration * move[1] * viewDirection.y);
	
	//cross = (CVector3)Cross(NewCVector3(0,0,1),viewDirection);
	cross.x = ((0 * viewDirection.z) - (1 * viewDirection.y));
	cross.y = ((1 * viewDirection.x) - (0 * viewDirection.z));
	
	
	coord[0] += (s_acceleration * move[0] * cross.x);
	coord[1] += (s_acceleration * move[0] * cross.y);
}
- (float *)getTranslation:(float *)coord move:(float *)move
{
	CVector3 viewDirection, cross;
	float *rMove;
	
	rMove = malloc(sizeof(float) * 3);
	
	rMove[0] = rMove[1] = rMove[2] = 0.0f;
	
	if (move[2])
	{
		rMove[2] = (move[2] * s_acceleration);
		return rMove;
	}
	
	viewDirection.x = [_camera position][0] - coord[0];
	viewDirection.y = [_camera position][1] - coord[1];
	viewDirection.z = [_camera position][2] - coord[2];
	
	rMove[0] = (s_acceleration * move[1] * viewDirection.x);
	rMove[1] = (s_acceleration * move[1] * viewDirection.y);
	
	cross.x = ((0 * viewDirection.z) - (1 * viewDirection.y));
	cross.y = ((1 * viewDirection.x) - (0 * viewDirection.z));
	
	rMove[0] += (s_acceleration * move[0] * cross.x);
	rMove[1] += (s_acceleration * move[0] * cross.y);
	
	return rMove;
}

- (float *)getPTranslation:(int)index move:(float *)move
{
	CVector3 viewDirection, cross;
	float *rMove;
	
	rMove = malloc(sizeof(float) * 3);
	
	rMove[0] = rMove[1] = rMove[2] = 0.0f;
	
	if (move[2])
	{
		rMove[2] = (move[2] * s_acceleration);
		return rMove;
	}
	
	int offsetToPlayerXCoordinate = 0x5C;
	int offsetToPlayerYCoordinate = 0x5C + 0x4;
	int offsetToPlayerZCoordinate = 0x5C + 0x4 + 0x4;
	
	int haloObjectPointer = [self getDynamicPlayer:index];
	
	int xCoord = [self readFloat:(haloObjectPointer + offsetToPlayerXCoordinate)];
	int yCoord = [self readFloat:(haloObjectPointer + offsetToPlayerYCoordinate)];
	int zCoord = [self readFloat:(haloObjectPointer + offsetToPlayerZCoordinate)];
	
	viewDirection.x = [_camera position][0] - xCoord;
	viewDirection.y = [_camera position][1] - yCoord;
	viewDirection.z = [_camera position][2] - zCoord;
	
	rMove[0] = (s_acceleration * move[1] * viewDirection.x);
	rMove[1] = (s_acceleration * move[1] * viewDirection.y);
	
	cross.x = ((0 * viewDirection.z) - (1 * viewDirection.y));
	cross.y = ((1 * viewDirection.x) - (0 * viewDirection.z));
	
	rMove[0] += (s_acceleration * move[0] * cross.x);
	rMove[1] += (s_acceleration * move[0] * cross.y);
	
	return rMove;
}



//[self centerObj:[_scenario vehi_spawns][index].coord move:rMove];
- (void)centerObj:(float *)coord move:(float *)move
{
	float x,y,z;
	[mapBSP GetActiveBspCentroid:&x center_y:&y center_z:&z];
	
	coord[0] = x;
	coord[1] = y;
	coord[2] = z;
}
//renderPlayerCharacter
-(void)getPlayers
{

}

- (void)applyMove:(float *)coord move:(float *)move
{
	coord[0] += move[0];
	coord[1] += move[1];
	coord[2] += move[2];
}

- (void)moveFocusedItem:(float)x y:(float)y z:(float)z
{
	int type, index;
	type = (_selectFocus / MAX_SCENARIO_OBJECTS);
	index = (_selectFocus % MAX_SCENARIO_OBJECTS);
	
	switch (type)
	{
		case s_vehicle:
			[_scenario vehi_spawns][index].coord[0] = x;
			[_scenario vehi_spawns][index].coord[1] = y;
			[_scenario vehi_spawns][index].coord[2] = z;
			break;
		case s_scenery:
			[_scenario scen_spawns][index].coord[0] = x;
			[_scenario scen_spawns][index].coord[1] = y;
			[_scenario scen_spawns][index].coord[2] = z;
			break;
		case s_playerspawn:
			[_scenario spawns][index].coord[0] = x;
			[_scenario spawns][index].coord[1] = y;
			[_scenario spawns][index].coord[2] = z;
			break;
		case s_netgame:
			[_scenario netgame_flags][index].coord[0] = x;
			[_scenario netgame_flags][index].coord[1] = y;
			[_scenario netgame_flags][index].coord[2] = z;
			break;
		case s_item:
			[_scenario item_spawns][index].coord[0] = x;
			[_scenario item_spawns][index].coord[1] = y;
			[_scenario item_spawns][index].coord[2] = z;
			break;
		case s_machine:
			[_scenario mach_spawns][index].coord[0] = x;
			[_scenario mach_spawns][index].coord[1] = y;
			[_scenario mach_spawns][index].coord[2] = z;
			break;
	}
	[_spawnEditor loadFocusedItemData:_selectFocus];
}

- (void)rotateFocusedItem:(float)x y:(float)y z:(float)z
{
	int type, index;
	type = (_selectFocus / MAX_SCENARIO_OBJECTS);
	index = (_selectFocus % MAX_SCENARIO_OBJECTS);
	
	switch (type)
	{
		case s_vehicle:
			[_scenario vehi_spawns][index].rotation[0] = degToPiRad(x);
			[_scenario vehi_spawns][index].rotation[1] = degToPiRad(y);
			[_scenario vehi_spawns][index].rotation[2] = degToPiRad(z);
			[s_xRotText setFloatValue:x];
			[s_yRotText setFloatValue:y];
			[s_zRotText setFloatValue:z];
			break;
		case s_scenery:
			[_scenario scen_spawns][index].rotation[0] = degToPiRad(x);
			[_scenario scen_spawns][index].rotation[1] = degToPiRad(y);
			[_scenario scen_spawns][index].rotation[2] = degToPiRad(z);
			[s_xRotText setFloatValue:x];
			[s_yRotText setFloatValue:y];
			[s_zRotText setFloatValue:z];
			break;
		case s_playerspawn:
			[_scenario spawns][index].rotation = degToPiRad(x);
			[s_xRotText setFloatValue:x];
			[s_yRotText setFloatValue:0];
			[s_zRotText setFloatValue:0];
			break;
		case s_netgame:
			[_scenario netgame_flags][index].rotation = degToPiRad(x);
			[s_xRotText setFloatValue:x];
			[s_yRotText setFloatValue:0];
			[s_zRotText setFloatValue:0];
			break;
		case s_item:
			[_scenario item_spawns][index].yaw = degToPiRad(x);
			[s_xRotText setFloatValue:x];
			[s_yRotText setFloatValue:0];
			[s_zRotText setFloatValue:0];
			break;
		case s_machine:
			[_scenario mach_spawns][index].rotation[0] = degToPiRad(x);
			[_scenario mach_spawns][index].rotation[1] = degToPiRad(y);
			[_scenario mach_spawns][index].rotation[2] = degToPiRad(z);
			[s_xRotText setFloatValue:x];
			[s_yRotText setFloatValue:y];
			[s_zRotText setFloatValue:z];
			break;
	}
	[_spawnEditor loadFocusedItemData:_selectFocus];
}
/*
*
*	End Scenario Editing Functions
*
*/

/*
*
*	Begin miscellaneous functions
*
*/
- (void)loadCameraPrefs
{
	if (!_mapfile)
		return;
		
	NSData *camDat;
	
	camDat = [prefs objectForKey:[[[_mapfile mapName] stringByAppendingString:@"camDat_0"] stringByAppendingString:[[NSNumber numberWithInt:activeBSPNumber] stringValue]]];
	[camDat getBytes:&camCenter[0] length:12];
	camDat = [prefs objectForKey:[[[_mapfile mapName] stringByAppendingString:@"camDat_1"] stringByAppendingString:[[NSNumber numberWithInt:activeBSPNumber] stringValue]]];
	[camDat getBytes:&camCenter[1] length:12];
	camDat = [prefs objectForKey:[[[_mapfile mapName] stringByAppendingString:@"camDat_2"] stringByAppendingString:[[NSNumber numberWithInt:activeBSPNumber] stringValue]]];
	[camDat getBytes:&camCenter[2] length:12];
	
	[self recenterCamera:self];
}

- (void)renderPartyTriangle
{
	
	glTranslatef(2.0f,2.0f,0.0f);
	
	glBegin( GL_TRIANGLES );              // Draw a triangle
		glColor3f( 1.0f, 0.0f, 0.0f );        // Set color to red
		glVertex3f(  0.0f,  1.0f, 0.0f );     // Top of front
		glColor3f( 0.0f, 1.0f, 0.0f );        // Set color to green
		glVertex3f( -1.0f, -1.0f, 1.0f );     // Bottom left of front
		glColor3f( 0.0f, 0.0f, 1.0f );        // Set color to blue
		glVertex3f(  1.0f, -1.0f, 1.0f );     // Bottom right of front
			
		glColor3f( 1.0f, 0.0f, 0.0f );        // Red
		glVertex3f( 0.0f, 1.0f, 0.0f );       // Top of right side
		glColor3f( 0.0f, 0.0f, 1.0f );        // Blue
		glVertex3f( 1.0f, -1.0f, 1.0f );      // Left of right side
		glColor3f( 0.0f, 1.0f, 0.0f );        // Green
		glVertex3f( 1.0f, -1.0f, -1.0f );     // Right of right side

		glColor3f( 1.0f, 0.0f, 0.0f );        // Red
		glVertex3f( 0.0f, 1.0f, 0.0f );       // Top of back side
		glColor3f( 0.0f, 1.0f, 0.0f );        // Green
		glVertex3f( 1.0f, -1.0f, -1.0f );     // Left of back side
		glColor3f( 0.0f, 0.0f, 1.0f );        // Blue
		glVertex3f( -1.0f, -1.0f, -1.0f );    // Right of back side

		glColor3f( 1.0f, 0.0f, 0.0f );        // Red
		glVertex3f( 0.0f, 1.0f, 0.0f );       // Top of left side
		glColor3f( 0.0f, 0.0f, 1.0f );        // Blue
		glVertex3f( -1.0f, -1.0f, -1.0f );    // Left of left side
		glColor3f( 0.0f, 1.0f, 0.0f );        // Green
		glVertex3f( -1.0f, -1.0f, 1.0f );     // Right of left side
	glEnd();  // Done with triangle
}
/*
*
*	End miscellaneous functions
*
*/
    
    
@synthesize pointsItem;
@synthesize wireframeItem;
@synthesize shadedTrisItem;
@synthesize texturedItem;
@synthesize view_glo;
@synthesize my_pid_v;
@synthesize haloProcessID;
@synthesize buttonPoints;
@synthesize buttonWireframe;
@synthesize buttonShadedFaces;
@synthesize buttonTextured;
@synthesize wall;
@synthesize selecte;
@synthesize bspNumbersButton;
@synthesize framesSlider;
@synthesize fpsText;
@synthesize lodDropdownButton;
@synthesize useAlphaCheckbox;
@synthesize opened;
@synthesize cam_p;
@synthesize selectMode;
@synthesize translateMode;
@synthesize moveCameraMode;
@synthesize duplicateSelected;
@synthesize b_deleteSelected;
@synthesize cspeed;
@synthesize m_MoveCamera;
@synthesize m_SelectMode;
@synthesize m_TranslateMode;
@synthesize m_duplicateSelected;
@synthesize m_deleteFocused;
@synthesize selectText;
@synthesize selectedName;
@synthesize selectedAddress;
@synthesize selectedType;
@synthesize selectedSwapButton;
@synthesize s_accelerationText;
@synthesize s_accelerationSlider;
@synthesize s_xRotation;
@synthesize s_yRotation;
@synthesize s_zRotation;
@synthesize s_xRotText;
@synthesize s_yRotText;
@synthesize s_zRotText;
@synthesize s_spawnTypePopupButton;
@synthesize s_spawnCreateButton;
@synthesize s_spawnEditWindowButton;
@synthesize _spawnEditor;
@synthesize prefs;
@synthesize shouldDraw;
@synthesize FullScreen;
@synthesize first;
@synthesize _useAlphas;
@synthesize _LOD;
@synthesize _camera;
@synthesize drawTimer;
@synthesize _mapfile;
@synthesize _scenario;
@synthesize mapBSP;
@synthesize _texManager;
@synthesize activeBSPNumber;
@synthesize _fps;
@synthesize rendDistance;
@synthesize currentRenderStyle;
@synthesize maxRenderDistance;
@synthesize dup;
@synthesize cameraMoveSpeed;
@synthesize acceleration;
@synthesize accelerationCounter;
@synthesize is_css;
@synthesize new_characters;
@synthesize _mode;
@synthesize selee;
@synthesize selections;
@synthesize _lookup;
@synthesize _selectType;
@synthesize _selectFocus;
@synthesize s_acceleration;
@synthesize isfull;
@synthesize should_update;
@synthesize _lineWidth;
@synthesize selectDistance;
@synthesize msel;
@synthesize camera;
@synthesize render;
@synthesize spawnc;
@synthesize spawne;
@synthesize select_panel;
@synthesize player_1;
@synthesize player_2;
@synthesize player_3;
@synthesize player_4;
@synthesize player_5;
@synthesize player_6;
@synthesize player_7;
@synthesize player_8;
@synthesize player_9;
@synthesize player_10;
@synthesize player_11;
@synthesize player_12;
@synthesize player_13;
@synthesize player_14;
@synthesize player_15;
@synthesize duplicate_amount;
@end
