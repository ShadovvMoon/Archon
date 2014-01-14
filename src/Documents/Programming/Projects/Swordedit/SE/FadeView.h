
// **********************************************************************
// The Cheat - A universal game cheater for Mac OS X
// (C) 2003-2005 Chaz McGarvey (BrokenZipper)
// 
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 1, or (at your option)
// any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
// 


#import <Cocoa/Cocoa.h>


@interface FadeView : NSView
{
	NSImage *_fadeImage;
	double _fadeAlpha;
	
	NSTimeInterval _fadeDuration;
	NSTimeInterval _fadeInterval;
	NSTimer *_fadeTimer;
	
	id _delegate;
}

- (NSImage *)image;
- (NSTimeInterval)fadeDuration;
- (NSTimeInterval)fadeInterval;
- (double)alpha;

- (void)setImage:(NSImage *)image;
- (void)setFadeDuration:(NSTimeInterval)seconds;
- (void)setFadeInterval:(NSTimeInterval)seconds;

- (void)startFadeAnimation;
- (void)stopFadeAnimation;

- (id)delegate;
- (void)setDelegate:(id)delegate;

@property (retain,getter=image) NSImage *_fadeImage;
@property (getter=alpha) double _fadeAlpha;
@property (getter=fadeDuration) NSTimeInterval _fadeDuration;
@property (getter=fadeInterval,setter=setFadeInterval:) NSTimeInterval _fadeInterval;
@property (retain) NSTimer *_fadeTimer;
@property (assign,getter=delegate,setter=setDelegate:) id _delegate;
@end


@interface NSObject ( FadeViewDelegate )

- (void)fadeViewFinishedAnimation:(FadeView *)theView;

@end