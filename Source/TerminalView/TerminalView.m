/*
copyright 2002 Alexander Malmberg <alexander@malmberg.org>
*/

#include <math.h>
#include <unistd.h>

#ifdef freebsd
#  include <sys/types.h>
#  include <sys/ioctl.h>
#  include <termios.h>
#  include <libutil.h>
#  include <pcap.h>
#else
#  include <termio.h>
#endif
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>
#ifndef freebsd
#  include <pty.h>
#endif

#include <Foundation/NSBundle.h>
#include <Foundation/NSDebug.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSRunLoop.h>
#include <Foundation/NSUserDefaults.h>
#include <gnustep/base/Unicode.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSPasteboard.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSGraphics.h>
#include <AppKit/NSScroller.h>
#include <AppKit/DPSOperators.h>

#include "TerminalView.h"

#include "TerminalViewPrefs.h"


/* TODO */
@interface NSView (unlockfocus)
-(void) unlockFocusNeedsFlush: (BOOL)flush;
@end


NSString
	*TerminalViewBecameIdleNotification=@"TerminalViewBecameIdle",
	*TerminalViewBecameNonIdleNotification=@"TerminalViewBecameNonIdle",

	*TerminalViewTitleDidChangeNotification=@"TerminalViewTitleDidChange";



@interface TerminalView (scrolling)
-(void) _scrollTo: (int)new_scroll  update: (BOOL)update;
-(void) setScroller: (NSScroller *)sc;
@end

@interface TerminalView (keyboard)
-(void) _sendString: (NSString *)s; /* TODO: move? */
@end

@interface TerminalView (selection)
-(void) _clearSelection;
@end

@interface TerminalView (input) <RunLoopEvents>
-(void) closeProgram;
-(void) runShell;
-(void) runProgram: (NSString *)path
	withArguments: (NSArray *)args
	initialInput: (NSString *)d;
@end


/**
TerminalScreen protocol implementation and rendering methods
**/

@implementation TerminalView (display)

#define ADD_DIRTY(ax0,ay0,asx,asy) do { \
		if (dirty.x0==-1) \
		{ \
			dirty.x0=(ax0); \
			dirty.y0=(ay0); \
			dirty.x1=(ax0)+(asx); \
			dirty.y1=(ay0)+(asy); \
		} \
		else \
		{ \
			if (dirty.x0>(ax0)) dirty.x0=(ax0); \
			if (dirty.y0>(ay0)) dirty.y0=(ay0); \
			if (dirty.x1<(ax0)+(asx)) dirty.x1=(ax0)+(asx); \
			if (dirty.y1<(ay0)+(asy)) dirty.y1=(ay0)+(asy); \
		} \
	} while (0)


#define SCREEN(x,y) (screen[(y)*sx+(x)])


-(void) _handlePendingScroll: (BOOL)lockFocus
{
	float x0,y0,w,h,dx,dy;

	if (!pending_scroll)
		return;

	if (pending_scroll>=sy || pending_scroll<=-sy)
	{
		pending_scroll=0;
		return;
	}

	NSDebugLLog(@"draw",@"_handlePendingScroll %i %i",pending_scroll,lockFocus);

	dx=x0=0;
	w=fx*sx;

	if (pending_scroll>0)
	{
		y0=0;
		h=(sy-pending_scroll)*fy;
		dy=pending_scroll*fy;
		y0=sy*fy-y0-h;
		dy=sy*fy-dy-h;
	}
	else
	{
		pending_scroll=-pending_scroll;

		y0=pending_scroll*fy;
		h=(sy-pending_scroll)*fy;
		dy=0;
		y0=sy*fy-y0-h;
		dy=sy*fy-dy-h;
	}

	if (lockFocus)
		[self lockFocus];
	DPScomposite(GSCurrentContext(),border_x+x0,border_y+y0,w,h,
		[self gState],border_x+dx,border_y+dy,NSCompositeCopy);
	if (lockFocus)
		[self unlockFocusNeedsFlush: NO];

	num_scrolls++;
	pending_scroll=0;
}


static int total_draw=0;


static const float col_h[8]={  0,240,120,180,  0,300, 60,  0};
static const float col_s[8]={0.0,1.0,1.0,1.0,1.0,1.0,1.0,0.0};

static void set_background(NSGraphicsContext *gc,
	unsigned char color,unsigned char in)
{
	float bh,bs,bb;
	int bg=color>>4;

	if (bg==0)
		bb=0.0;
	else if (bg>=8)
		bg-=8,bb=1.0;
	else
		bb=0.6;
	bs=col_s[bg];
	bh=col_h[bg]/360.0;

	DPSsethsbcolor(gc,bh,bs,bb);
}

static void set_foreground(NSGraphicsContext *gc,
	unsigned char color,unsigned char in)
{
	int fg=color;
	float h,s,b;

	if (fg>=8)
	{
		in++;
		fg-=8;
	}

	if (fg==0)
		b=0.0;
	else if (in==0)
		b=0.6;
	else if (in==1)
		b=0.8;
	else
		b=1.0;

	h=col_h[fg]/360.0;
	s=col_s[fg];
	if (in==2)
		s*=0.75;

	DPSsethsbcolor(gc,h,s,b);
}


-(void) drawRect: (NSRect)r
{
	int ix,iy;
	unsigned char buf[8];
	NSGraphicsContext *cur=GSCurrentContext();
	int x0,y0,x1,y1;
	NSFont *f,*current_font=nil;

	int encoding;


	NSDebugLLog(@"draw",@"drawRect: (%g %g)+(%g %g) %i\n",
		r.origin.x,r.origin.y,r.size.width,r.size.height,
		draw_all);

	if (pending_scroll)
		[self _handlePendingScroll: NO];

	{
		float a,b;
		DPSsetgray(cur,0.0);
		if (r.origin.x<border_x)
			DPSrectfill(cur,r.origin.x,r.origin.y,border_x-r.origin.x,r.size.height);
		if (r.origin.y<border_y)
			DPSrectfill(cur,r.origin.x,r.origin.y,r.size.width,border_y-r.origin.y);

		a=border_x+sx*fx;
		b=r.origin.x+r.size.width;
		if (b>a)
			DPSrectfill(cur,a,r.origin.y,b-a,r.size.height);
		a=border_y+sy*fy;
		b=r.origin.y+r.size.height;
		if (b>a)
			DPSrectfill(cur,r.origin.x,a,r.size.width,b-a);
	}

	r.origin.x-=border_x;
	r.origin.y-=border_y;

	x0=floor(r.origin.x/fx);
	x1=ceil((r.origin.x+r.size.width)/fx);
	if (x0<0) x0=0;
	if (x1>=sx) x1=sx;

	y1=floor(r.origin.y/fy);
	y0=ceil((r.origin.y+r.size.height)/fy);
	y0=sy-y0;
	y1=sy-y1;
	if (y0<0) y0=0;
	if (y1>=sy) y1=sy;

	NSDebugLLog(@"draw",@"dirty (%i %i)-(%i %i)\n",x0,y0,x1,y1);

	draw_cursor=draw_cursor || draw_all ||
	            (SCREEN(cursor_x,cursor_y).attr&0x80)!=0;

	{
		int ry;
		screen_char_t *ch;
		float scr_y,scr_x,start_x;

		unsigned char l_color,l_attr,color;

		l_color=0;
		l_attr=0;
		set_foreground(cur,l_color,l_attr);
		for (iy=y0;iy<y1;iy++)
		{
			ry=iy+current_scroll;
			if (ry>=0)
				ch=&SCREEN(x0,ry);
			else
				ch=&sbuf[x0+(max_scrollback+ry)*sx];

			scr_y=(sy-1-iy)*fy+border_y;
/*
#define R(scr_x,scr_y,fx,fy) \
				DPSgsave(cur); \
				DPSsetgray(cur,0.0); \
				DPSrectfill(cur,scr_x,scr_y,fx,fy); \
				DPSgrestore(cur); \
				DPSrectstroke(cur,scr_x,scr_y,fx,fy); \
*/

/* ~400 cycles/cell on average */
#define R(scr_x,scr_y,fx,fy) DPSrectfill(cur,scr_x,scr_y,fx,fy)
			start_x=-1;
			for (ix=x0;ix<x1;ix++,ch++)
			{
				if (!draw_all && !(ch->attr&0x80))
				{
					if (start_x!=-1)
					{
						scr_x=ix*fx+border_x;
						R(start_x,scr_y,scr_x-start_x,fy);
						start_x=-1;
					}
					continue;
				}

				scr_x=ix*fx+border_x;

				if (ch->attr&0x8)
				{
					color=ch->color&0xf;
					if (color!=l_color || (ch->attr&0x03)!=l_attr)
					{
						if (start_x!=-1)
						{
							R(start_x,scr_y,scr_x-start_x,fy);
							start_x=scr_x;
						}

						l_color=color;
						l_attr=ch->attr&0x03;
						set_foreground(cur,l_color,l_attr);
					}
				}
				else
				{
					color=ch->color&0xf0;
					if (color!=l_color)
					{
						if (start_x!=-1)
						{
							R(start_x,scr_y,scr_x-start_x,fy);
							start_x=scr_x;
						}

						l_color=color;
						l_attr=ch->attr&0x03;
						set_background(cur,l_color,l_attr);
					}
				}

				if (start_x==-1)
					start_x=scr_x;
			}

			if (start_x!=-1)
			{
				scr_x=ix*fx+border_x;
				R(start_x,scr_y,scr_x-start_x,fy);
			}
		}
		for (iy=y0;iy<y1;iy++)
		{
			ry=iy+current_scroll;
			if (ry>=0)
				ch=&SCREEN(x0,ry);
			else
				ch=&sbuf[x0+(max_scrollback+ry)*sx];

			scr_y=(sy-1-iy)*fy+border_y;

			for (ix=x0;ix<x1;ix++,ch++)
			{
				if (!draw_all && !(ch->attr&0x80))
					continue;

				ch->attr&=0x7f;

				scr_x=ix*fx+border_x;

				/* ~1700 cycles/change */
				if (ch->attr&0x02 || (ch->ch!=0 && ch->ch!=32))
				{
					if (!(ch->attr&0x8))
					{
						color=ch->color&0xf;
						if (color!=l_color || (ch->attr&0x03)!=l_attr)
						{
							l_color=color;
							l_attr=ch->attr&0x03;
							set_foreground(cur,l_color,l_attr);
						}
					}
					else
					{
						color=ch->color&0xf0;
						if (color!=l_color)
						{
							l_color=color;
							l_attr=ch->attr&0x03;
							set_background(cur,l_color,l_attr);
						}
					}
				}

				if (ch->ch!=0 && ch->ch!=32)
				{
					total_draw++;
					if ((ch->attr&3)==2)
					{
						encoding=boldFont_encoding;
						f=boldFont;
					}
					else
					{
						encoding=font_encoding;
						f=font;
					}
					if (f!=current_font)
					{
					/* ~190 cycles/change */
						[f set];
						current_font=f;
					}

					if (encoding==NSUTF8StringEncoding)
					{
						unichar uch=ch->ch;
						if (uch>=0x10000)
							buf[0]=0;
						else if (uch>=0x800)
						{
							buf[2]=(uch&0x3f)|0x80;
							uch>>=6;
							buf[1]=(uch&0x3f)|0x80;
							uch>>=6;
							buf[0]=(uch&0x0f)|0xe0;
							buf[3]=0;
						}
						else if (uch>=0x80)
						{
							buf[1]=(uch&0x3f)|0x80;
							uch>>=6;
							buf[0]=(uch&0x1f)|0xc0;
							buf[2]=0;
						}
						else
						{
							buf[0]=uch;
							buf[1]=0;
						}
					}
					else
					{
						unichar uch=ch->ch;
						if (uch<=0x80)
						{
							buf[0]=uch;
							buf[1]=0;
						}
						else
						{
							unsigned char *pbuf=buf;
							int dlen=sizeof(buf)-1;
							GSFromUnicode(&pbuf,&dlen,&uch,1,encoding,NULL,GSUniTerminate);
						}
					}
					/* ~580 cycles */
					DPSmoveto(cur,scr_x+fx0,scr_y+fy0);
					/* baseline here for mc-case 0.65 */
					/* ~3800 cycles */
					DPSshow(cur,buf);

					/* ~95 cycles to ARTGState -DPSshow:... */
					/* ~343 cycles to isEmpty */
					/* ~593 cycles to currentpoint */
					/* ~688 cycles to transform */
					/* ~1152 cycles to FTFont -drawString:... */
					/* ~1375 cycles to -drawString:... setup */
					/* ~1968 cycles cmap lookup */
					/* ~2718 cycles sbit lookup */
					/* ~~2750 cycles blit setup */
					/* ~3140 cycles blit loop, empty call */
					/* ~3140 cycles blit loop, setup */
					/* ~3325 cycles blit loop, no write */
					/* ~3800 cycles total */
				}

				if (ch->attr&0x4)
					DPSrectfill(cur,scr_x,scr_y,fx,1);

				if (ch->attr&0x40)
					DPScompositerect(cur,scr_x,scr_y,fx,fy,NSCompositeHighlight);
			}
		}
	}

	if (draw_cursor)
	{
		float x,y;
		[[TerminalViewDisplayPrefs cursorColor] set];

		x=cursor_x*fx+border_x;
		y=(sy-1-cursor_y+current_scroll)*fy+border_y;

		switch ([TerminalViewDisplayPrefs cursorStyle])
		{
		case CURSOR_LINE:
			DPSrectfill(cur,x,y,fx,fy*0.1);
			break;
		case CURSOR_BLOCK_STROKE:
			DPSrectstroke(cur,x,y,fx,fy);
			break;
		case CURSOR_BLOCK_FILL:
			DPSrectfill(cur,x,y,fx,fy);
			break;
		case CURSOR_BLOCK_INVERT:
			DPScompositerect(cur,x,y,fx,fy,
				NSCompositeHighlight);
			break;
		}
		draw_cursor=NO;
	}

	NSDebugLLog(@"draw",@"total_draw=%i",total_draw);

	draw_all=NO;
}

-(BOOL) isOpaque
{
	return YES;
}


-(void) benchmark: (id)sender
{
	int i;
	double t1,t2;
	NSRect r=[self frame];
	t1=[NSDate timeIntervalSinceReferenceDate];
	total_draw=0;
	for (i=0;i<100;i++)
	{
		draw_all=YES;
		[self lockFocus];
		[self drawRect: r];
		[self unlockFocusNeedsFlush: NO];
	}
	t2=[NSDate timeIntervalSinceReferenceDate];
	t2-=t1;
	fprintf(stderr,"%8.4f  %8.5f/redraw   total_draw=%i\n",t2,t2/i,total_draw);
}


-(void) ts_setTitle: (NSString *)new_title  type: (int)title_type
{
	NSDebugLLog(@"ts",@"setTitle: %@  type: %i",new_title,title_type);
	if (title_type==1 || title_type==0)
		ASSIGN(title_miniwindow,new_title);
	if (title_type==2 || title_type==0)
		ASSIGN(title_window,new_title);
	[[NSNotificationCenter defaultCenter]
		postNotificationName: TerminalViewTitleDidChangeNotification
		object: self];
}


-(void) ts_goto: (int)x:(int)y
{
	NSDebugLLog(@"ts",@"goto: %i:%i",x,y);
	cursor_x=x;
	cursor_y=y;
	if (cursor_x>=sx) cursor_x=sx-1;
	if (cursor_x<0) cursor_x=0;
	if (cursor_y>=sy) cursor_y=sy-1;
	if (cursor_y<0) cursor_y=0;
}

-(void) ts_putChar: (screen_char_t)ch  count: (int)c  at: (int)x:(int)y
{
	int i;
	screen_char_t *s;

	NSDebugLLog(@"ts",@"putChar: '%c' %02x %02x count: %i at: %i:%i",
		ch.ch,ch.color,ch.attr,c,x,y);

	if (y<0 || y>=sy) return;
	if (x+c>sx)
		c=sx-x;
	if (x<0)
	{
		c-=x;
		x=0;
	}
	s=&SCREEN(x,y);
	ch.attr|=0x80;
	for (i=0;i<c;i++)
		*s++=ch;
	ADD_DIRTY(x,y,c,1);
}

-(void) ts_putChar: (screen_char_t)ch  count: (int)c  offset: (int)ofs
{
	int i;
	screen_char_t *s;

	NSDebugLLog(@"ts",@"putChar: '%c' %02x %02x count: %i offset: %i",
		ch.ch,ch.color,ch.attr,c,ofs);

	if (ofs+c>sx*sy)
		c=sx*sy-ofs;
	if (ofs<0)
	{
		c-=ofs;
		ofs=0;
	}
	s=&SCREEN(ofs,0);
	ch.attr|=0x80;
	for (i=0;i<c;i++)
		*s++=ch;
	ADD_DIRTY(0,0,sx,sy); /* TODO */
}

-(void) ts_scrollUp: (int)t:(int)b  rows: (int)nr  save: (BOOL)save
{
	screen_char_t *d, *s;

	NSDebugLLog(@"ts",@"scrollUp: %i:%i  rows: %i  save: %i",
		t,b,nr,save);

	if (save && t==0 && b==sy) /* TODO? */
	{
		int num;
		if (nr<max_scrollback)
		{
			memmove(sbuf,&sbuf[sx*nr],sizeof(screen_char_t)*sx*(max_scrollback-nr));
			num=nr;
		}
		else
			num=max_scrollback;

		if (num<sy)
		{
			memmove(&sbuf[sx*(max_scrollback-num)],screen,num*sx*sizeof(screen_char_t));
		}
		else
		{
			memmove(&sbuf[sx*(max_scrollback-num)],screen,sy*sx*sizeof(screen_char_t));

			/* TODO: should this use video_erase_char? */
			memset(&sbuf[sx*(max_scrollback-num+sy)],0,sx*(num-sy)*sizeof(screen_char_t));
		}
		sb_length+=num;
		if (sb_length>max_scrollback)
			sb_length=max_scrollback;
	}

	if (t+nr >= b)
		nr = b - t - 1;
	if (b > sy || t >= b || nr < 1)
		return;
	d = &SCREEN(0,t);
	s = &SCREEN(0,t+nr);

	if (current_y>=t && current_y<=b)
	{
		SCREEN(current_x,current_y).attr|=0x80;
		draw_cursor=YES;
		/*
		TODO: does this properly handle the case when the cursor is in
		an area that gets scrolled 'over'?

		now it does, but not in an optimal way. handling of this could be
		optimized in all scrolling methods, but it probably won't make
		much difference
		*/
	}
	memmove(d, s, (b-t-nr) * sx * sizeof(screen_char_t));
	if (!current_scroll)
	{
		if (t==0 && b==sy)
		{
			pending_scroll-=nr;
		}
		else
		{
			float x0,y0,w,h,dx,dy;

			if (pending_scroll)
				[self _handlePendingScroll: YES];

			x0=0;
			w=fx*sx;
			y0=(t+nr)*fy;
			h=(b-t-nr)*fy;
			dx=0;
			dy=t*fy;
			y0=sy*fy-y0-h;
			dy=sy*fy-dy-h;
			[self lockFocus];
			DPScomposite(GSCurrentContext(),border_x+x0,border_y+y0,w,h,
				[self gState],border_x+dx,border_y+dy,NSCompositeCopy);
			[self unlockFocusNeedsFlush: NO];
			num_scrolls++;
		}
	}
	ADD_DIRTY(0,t,sx,b-t);
}

-(void) ts_scrollDown: (int)t:(int)b  rows: (int)nr
{
	screen_char_t *s;
	unsigned int step;

	NSDebugLLog(@"ts",@"scrollDown: %i:%i  rows: %i",
		t,b,nr);

	if (t+nr >= b)
		nr = b - t - 1;
	if (b > sy || t >= b || nr < 1)
		return;
	s = &SCREEN(0,t);
	step = sx * nr;
	if (current_y>=t && current_y<=b)
	{
		SCREEN(current_x,current_y).attr|=0x80;
		draw_cursor=YES;
	}
	memmove(s + step, s, (b-t-nr)*sx*sizeof(screen_char_t));
	if (!current_scroll)
	{
		if (t==0 && b==sy)
		{
			pending_scroll+=nr;
		}
		else
		{
			float x0,y0,w,h,dx,dy;

			if (pending_scroll)
				[self _handlePendingScroll: YES];

			x0=0;
			w=fx*sx;
			y0=(t)*fy;
			h=(b-t-nr)*fy;
			dx=0;
			dy=(t+nr)*fy;
			y0=sy*fy-y0-h;
			dy=sy*fy-dy-h;
			[self lockFocus];
			DPScomposite(GSCurrentContext(),border_x+x0,border_y+y0,w,h,
				[self gState],border_x+dx,border_y+dy,NSCompositeCopy);
			[self unlockFocusNeedsFlush: NO];
			num_scrolls++;
		}
	}
	ADD_DIRTY(0,t,sx,b-t);
}

-(void) ts_shiftRow: (int)y  at: (int)x0  delta: (int)delta
{
	screen_char_t *s,*d;
	int x1,c;
	NSDebugLLog(@"ts",@"shiftRow: %i  at: %i  delta: %i",
		y,x0,delta);

	if (y<0 || y>=sy) return;
	if (x0<0 || x0>=sx) return;

	if (current_y==y)
	{
		SCREEN(current_x,current_y).attr|=0x80;
		draw_cursor=YES;
	}

	s=&SCREEN(x0,y);
	x1=x0+delta;
	c=sx-x0;
	if (x1<0)
	{
		x0-=x1;
		c+=x1;
		x1=0;
	}
	if (x1+c>sx)
		c=sx-x1;
	d=&SCREEN(x1,y);
	memmove(d,s,sizeof(screen_char_t)*c);
	if (!current_scroll)
	{
		float cx0,y0,w,h,dx,dy;

		if (pending_scroll)
			[self _handlePendingScroll: YES];

		cx0=x0*fx;
		w=fx*c;
		dx=x1*fx;

		y0=y*fy;
		h=fy;
		dy=y0;

		y0=sy*fy-y0-h;
		dy=sy*fy-dy-h;
		[self lockFocus];
		DPScomposite(GSCurrentContext(),border_x+cx0,border_y+y0,w,h,
			[self gState],border_x+dx,border_y+dy,NSCompositeCopy);
		[self unlockFocusNeedsFlush: NO];
		num_scrolls++;
	}
	ADD_DIRTY(0,y,sx,1);
}

-(screen_char_t) ts_getCharAt: (int)x:(int)y
{
	NSDebugLLog(@"ts",@"getCharAt: %i:%i",x,y);
	return SCREEN(x,y);
}

-(void) ts_sendCString: (const char *)msg
{
	int len=strlen(msg);
	if (master_fd!=-1)
		write(master_fd,msg,len);
}

@end


/**
Scrolling
**/

@implementation TerminalView (scrolling)

-(void) _scrollTo: (int)new_scroll  update: (BOOL)update
{
	if (new_scroll>0)
		new_scroll=0;
	if (new_scroll<-sb_length)
		new_scroll=-sb_length;

	if (new_scroll==current_scroll)
		return;
	current_scroll=new_scroll;

	if (update)
	{
		if (sb_length)
			[scroller setFloatValue: (current_scroll+sb_length)/(float)(sb_length)
				knobProportion: sy/(float)(sy+sb_length)];
		else
			[scroller setFloatValue: 1.0 knobProportion: 1.0];
	}

	draw_all=YES;
	[self setNeedsDisplay: YES];
}

-(void) scrollWheel: (NSEvent *)e
{
	float delta=[e deltaY];
	int new_scroll;
	int mult;

	if ([e modifierFlags]&NSShiftKeyMask)
		mult=1;
	else if ([e modifierFlags]&NSControlKeyMask)
		mult=sy;
	else
		mult=5;

	new_scroll=current_scroll-delta*mult;
	[self _scrollTo: new_scroll  update: YES];
}

-(void) _updateScroll: (id)sender
{
	int new_scroll;
	int part=[scroller hitPart];
	BOOL update=YES;

	if (part==NSScrollerKnob ||
	    part==NSScrollerKnobSlot)
	{
		float f=[scroller floatValue];
		new_scroll=(f-1.0)*sb_length;
		update=NO;
	}
	else if (part==NSScrollerDecrementLine)
		new_scroll=current_scroll-1;
	else if (part==NSScrollerDecrementPage)
		new_scroll=current_scroll-sy/2;
	else if (part==NSScrollerIncrementLine)
		new_scroll=current_scroll+1;
	else if (part==NSScrollerIncrementPage)
		new_scroll=current_scroll+sy/2;
	else
		return;

	[self _scrollTo: new_scroll  update: update];
}

-(void) setScroller: (NSScroller *)sc
{
	[scroller setTarget: nil];
	ASSIGN(scroller,sc);
	if (sb_length)
		[scroller setFloatValue: (current_scroll+sb_length)/(float)(sb_length)
			knobProportion: sy/(float)(sy+sb_length)];
	else
		[scroller setFloatValue: 1.0 knobProportion: 1.0];
	[scroller setTarget: self];
	[scroller setAction: @selector(_updateScroll:)];
}

@end


/**
Keyboard events
**/

@implementation TerminalView (keyboard)

-(void) _sendString: (NSString *)s
{
	int i;
	unsigned char tmp;
	unichar ch;
	if (master_fd==-1)
		return;
	for (i=0;i<[s length];i++)
	{
		ch=[s characterAtIndex: i];
		if (ch>256)
			NSBeep();
		else
		{
			tmp=ch;
			write(master_fd,&tmp,1);
		}
	}
}


-(void) keyDown: (NSEvent *)e
{
/* TODO: what do we do with non-ascii characters? */
	NSString *s=[e charactersIgnoringModifiers];
	unsigned int mask=[e modifierFlags];
	unichar ch,ch2;
	unsigned char tmp;

	const char *str;
	NSString *nstr;

	NSDebugLLog(@"key",@"got key flags=%08x  repeat=%i '%@' '%@' %4i %04x %i %04x %i\n",
		[e modifierFlags],[e isARepeat],[e characters],[e charactersIgnoringModifiers],[e keyCode],
		[[e characters] characterAtIndex: 0],[[e characters] length],
		[[e charactersIgnoringModifiers] characterAtIndex: 0],[[e charactersIgnoringModifiers] length]);

	if ([s length]>1)
	{
		s=[e characters];
		NSDebugLLog(@"key",@" writing '%@'\n",s);
		[self _sendString: s];
		return;
	}

	ch=[s characterAtIndex: 0];
	str=NULL;
	nstr=nil;
	ch2=0;
	switch (ch)
	{
	case '\e':
		if ([TerminalViewKeyboardPrefs doubleEscape])
			str="\e\e";
		else
			str="\e";
		break;

	case NSUpArrowFunctionKey   : str="\e[A"; break;
	case NSDownArrowFunctionKey : str="\e[B"; break;
	case NSLeftArrowFunctionKey : str="\e[D"; break;
	case NSRightArrowFunctionKey: str="\e[C"; break;

	case NSF1FunctionKey : str="\e[[A"; break;
	case NSF2FunctionKey : str="\e[[B"; break;
	case NSF3FunctionKey : str="\e[[C"; break;
	case NSF4FunctionKey : str="\e[[D"; break;
	case NSF5FunctionKey : str="\e[[E"; break;

	case NSF6FunctionKey : str="\e[17~"; break;
	case NSF7FunctionKey : str="\e[18~"; break;
	case NSF8FunctionKey : str="\e[19~"; break;
	case NSF9FunctionKey : str="\e[20~"; break;
	case NSF10FunctionKey: str="\e[21~"; break;
	case NSF11FunctionKey: str="\e[23~"; break;
	case NSF12FunctionKey: str="\e[24~"; break;

	case NSF13FunctionKey: str="\e[25~"; break;
	case NSF14FunctionKey: str="\e[26~"; break;
	case NSF15FunctionKey: str="\e[28~"; break;
	case NSF16FunctionKey: str="\e[29~"; break;
	case NSF17FunctionKey: str="\e[31~"; break;
	case NSF18FunctionKey: str="\e[32~"; break;
	case NSF19FunctionKey: str="\e[33~"; break;
	case NSF20FunctionKey: str="\e[34~"; break;

	case NSHomeFunctionKey    : str="\e[1~"; break;
	case NSInsertFunctionKey  : str="\e[2~"; break;
	case NSDeleteFunctionKey  : str="\e[3~"; break;
	case NSEndFunctionKey     : str="\e[4~"; break;
	case NSPageUpFunctionKey  :
		if (mask&NSShiftKeyMask)
		{
			[self _scrollTo: current_scroll-sy+1  update: YES];
			return;
		}
		str="\e[5~";
		break;
	case NSPageDownFunctionKey:
		if (mask&NSShiftKeyMask)
		{
			[self _scrollTo: current_scroll+sy-1  update: YES];
			return;
		}
		str="\e[6~";
		break;

	case 8: ch2=0x7f; break;
	case 3: ch2=0x0d; break;

	default:
		nstr=[e characters];;
		break;
	}

	/* don't check until we get here so we handle scrollback page-up/down
	even when the view's idle */
	if (master_fd==-1)
		return;

	if (mask&(NSAlternateKeyMask|NSCommandKeyMask))
	{
		NSDebugLLog(@"key",@"  meta");
		write(master_fd,"\e",1);
	}

	if (nstr)
	{
		NSDebugLLog(@"key",@"  send NSString '%@'",nstr);
		[self _sendString: nstr];
	}
	else if (str)
	{
		NSDebugLLog(@"key",@"  send '%s'",str);
		[self ts_sendCString: str];
	}
	else if (ch2>256)
	{
		NSDebugLLog(@"key",@"  couldn't send %04x",ch2);
		NSBeep();
	}
	else if (ch2>0)
	{
		tmp=ch2;
		NSDebugLLog(@"key",@"  send %02x",ch2);
		write(master_fd,&tmp,1);
	}
}

-(BOOL) acceptsFirstResponder
{
	return YES;
}
-(BOOL) becomeFirstResponder
{
	return YES;
}
-(BOOL) resignFirstResponder
{
	return YES;
}

@end


/**
Selection, copy/paste/services
**/

@implementation TerminalView (selection)

-(NSString *) _selectionAsString
{
	int ofs=max_scrollback*sx;
	NSMutableString *mstr;
	NSString *tmp;
	unichar buf[32];
	unichar ch;
	int len;
	int i,j;

	if (selection.length==0)
		return nil;

	mstr=[[NSMutableString alloc] init];
	j=selection.location+selection.length;
	len=0;
	for (i=selection.location;i<j;i++)
	{
		if (i%sx==0 && i>selection.location)
		{
			buf[len++]='\n';
			if (len==32)
			{
				tmp=[[NSString alloc] initWithCharacters: buf length: 32];
				[mstr appendString: tmp];
				DESTROY(tmp);
				len=0;
			}
		}
		if (i<0)
			ch=sbuf[ofs+i].ch;
		else
			ch=screen[i].ch;
		if (ch)
		{
			buf[len++]=ch;
			if (len==32)
			{
				tmp=[[NSString alloc] initWithCharacters: buf length: 32];
				[mstr appendString: tmp];
				DESTROY(tmp);
				len=0;
			}
		}
	}

	if (len)
	{
		tmp=[[NSString alloc] initWithCharacters: buf length: len];
		[mstr appendString: tmp];
		DESTROY(tmp);
	}

	return AUTORELEASE(mstr);
}

-(void) _setSelection: (struct selection_range)s
{
	int i,j,ofs2;
	if (!s.length && !selection.length)
		return;
	if (s.length==selection.length && s.location==selection.location)
		return;

	if (s.location<-sb_length*sx)
	{
		s.length+=sb_length*sx+s.location;
		s.location=-sb_length*sx;
	}
	if (s.location+s.length>sx*sy)
	{
		s.length=sx*sy-s.location;
	}
	if (s.length<0)
		s.length=0;

	ofs2=max_scrollback*sx;

	j=selection.location+selection.length;
	if (j>s.location)
		j=s.location;

	for (i=selection.location;i<j && i<0;i++)
	{
		sbuf[ofs2+i].attr&=0xbf;
		sbuf[ofs2+i].attr|=0x80;
	}
	for (;i<j;i++)
	{
		screen[i].attr&=0xbf;
		screen[i].attr|=0x80;
	}

	i=s.location+s.length;
	if (i<selection.location)
		i=selection.location;
	j=selection.location+selection.length;
	for (;i<j && i<0;i++)
	{
		sbuf[ofs2+i].attr&=0xbf;
		sbuf[ofs2+i].attr|=0x80;
	}
	for (;i<j;i++)
	{
		screen[i].attr&=0xbf;
		screen[i].attr|=0x80;
	}

	i=s.location;
	j=s.location+s.length;
	for (;i<j && i<0;i++)
	{
		if (!(sbuf[ofs2+i].attr&0x40))
			sbuf[ofs2+i].attr|=0xc0;
	}
	for (;i<j;i++)
	{
		if (!(screen[i].attr&0x40))
			screen[i].attr|=0xc0;
	}

	selection=s;
	[self setNeedsDisplay: YES];
}

-(void) _clearSelection
{
	struct selection_range s;
	s.location=s.length=0;
	[self _setSelection: s];
}


-(void) copy: (id)sender
{
	NSPasteboard *pb=[NSPasteboard generalPasteboard];
	NSString *s=[self _selectionAsString];
	if (!s)
	{
		NSBeep();
		return;
	}
	[pb declareTypes: [NSArray arrayWithObject: NSStringPboardType]
		owner: self];
	[pb setString: s forType: NSStringPboardType];
}

-(void) paste: (id)sender
{
	NSPasteboard *pb=[NSPasteboard generalPasteboard];
	NSString *type;
	NSString *str;

	type=[pb availableTypeFromArray: [NSArray arrayWithObject: NSStringPboardType]];
	if (!type)
		return;
	str=[pb stringForType: NSStringPboardType];
	[self _sendString: str];
}

-(BOOL) writeSelectionToPasteboard: (NSPasteboard *)pb
	types: (NSArray *)t
{
	int i;
	[pb declareTypes: t  owner: self];
	for (i=0;i<[t count];i++)
	{
		if ([[t objectAtIndex: i] isEqual: NSStringPboardType])
		{
			[pb setString: [self _selectionAsString]
				forType: NSStringPboardType];
			return YES;
		}
	}
	return NO;
}

-(BOOL) readSelectionFromPasteboard: (NSPasteboard *)pb
{ /* TODO: is it really necessary to implement this? */
	return YES;
}

-(id) validRequestorForSendType: (NSString *)st
	returnType: (NSString *)rt
{
	if (!selection.length)
		return nil;
	if (st!=nil && ![st isEqual: NSStringPboardType])
		return nil;
	if (rt!=nil)
		return nil;
	return self;
}


-(void) mouseDown: (NSEvent *)e
{
	int ofs0,ofs1,first;
	NSPoint p;
	struct selection_range s;

	first=YES;
	ofs0=0; /* get compiler to shut up */
	while ([e type]!=NSLeftMouseUp)
	{
		p=[e locationInWindow];

		p=[self convertPoint: p  fromView: nil];
		p.x=floor((p.x-border_x)/fx);
		if (p.x<0) p.x=0;
		if (p.x>=sx) p.x=sx-1;
		p.y=ceil((p.y-border_y)/fy);
		if (p.y<-1) p.y=-1;
		if (p.y>sy) p.y=sy;
		p.y=sy-p.y+current_scroll;
		ofs1=((int)p.x)+((int)p.y)*sx;

		if (first)
		{
			ofs0=ofs1;
			first=0;
		}

		if (ofs1>ofs0)
		{
			s.location=ofs0;
			s.length=ofs1-ofs0;
		}
		else
		{
			s.location=ofs1;
			s.length=ofs0-ofs1;
		}

		[self _setSelection: s];
		[self displayIfNeeded];

		e=[NSApp nextEventMatchingMask: NSLeftMouseDownMask|NSLeftMouseUpMask|
		                                NSLeftMouseDraggedMask|NSMouseMovedMask
			untilDate: [NSDate distantFuture]
			inMode: NSEventTrackingRunLoopMode
			dequeue: YES];
	}
}

@end


/**
Handle master_fd
**/

@implementation TerminalView (input)

-(NSDate *) timedOutEvent: (void *)data type: (RunLoopEventType)t
	forMode: (NSString *)mode
{
	NSLog(@"timedOutEvent:type:forMode: ignored");
	return nil;
}

-(void) receivedEvent: (void *)data
	type: (RunLoopEventType)t
	extra: (void *)extra
	forMode: (NSString *)mode
{
	char buf[8];
	int size,total;

//	get_zombies();

//	printf("got event %i %i\n",(int)data,t);
	total=0;
	num_scrolls=0;
	dirty.x0=-1;

	current_x=cursor_x;
	current_y=cursor_y;

	[self _clearSelection]; /* TODO? */

	NSDebugLLog(@"term",@"receiving output");

	while (1)
	{
		{
			fd_set s;
			struct timeval tv;
			FD_ZERO(&s);
			FD_SET(master_fd,&s);
			tv.tv_sec=0;
			tv.tv_usec=0;
			if (!select(master_fd+1,&s,NULL,NULL,&tv)) break;
		}

		size=read(master_fd,buf,1);
		if (size<=0)
		{
			NSString *msg;
			int i,c;
			unichar ch;

//			get_zombies();
			[[NSNotificationCenter defaultCenter]
				postNotificationName: TerminalViewBecameIdleNotification
				object: self];
			[self closeProgram];

			msg=_(@"[Process exited]");
			c=[msg length];
			for (i=0;i<c;i++)
			{
				ch=[msg characterAtIndex: i];
				if (ch<256)
					[tp processByte: ch];
			}
			[tp processByte: '\n'];
			[tp processByte: '\r'];

			break;
		}
//		printf("got %i bytes, %02x '%c'\n",size,buf[0],buf[0]);


		[tp processByte: buf[0]];

		total++;
		if (total>=8192 || (num_scrolls+abs(pending_scroll))>10)
			break; /* give other things a chance */
	}

	if (cursor_x!=current_x || cursor_y!=current_y)
	{
		ADD_DIRTY(current_x,current_y,1,1);
		SCREEN(current_x,current_y).attr|=0x80;
		ADD_DIRTY(cursor_x,cursor_y,1,1);
		draw_cursor=YES;
	}

	NSDebugLLog(@"term",@"done (%i %i) (%i %i)\n",
		dirty.x0,dirty.y0,dirty.x1,dirty.y1);

	if (dirty.x0>=0)
	{
		NSRect dr;

		if (sb_length)
			[scroller setFloatValue: (current_scroll+sb_length)/(float)(sb_length)
				knobProportion: sy/(float)(sy+sb_length)];
		else
			[scroller setFloatValue: 1.0 knobProportion: 1.0];

//		NSLog(@"dirty=(%i %i)-(%i %i)\n",dirty.x0,dirty.y0,dirty.x1,dirty.y1);
		dr.origin.x=dirty.x0*fx;
		dr.origin.y=dirty.y0*fy;
		dr.size.width=(dirty.x1-dirty.x0)*fx;
		dr.size.height=(dirty.y1-dirty.y0)*fy;
		dr.origin.y=fy*sy-(dr.origin.y+dr.size.height);
//		NSLog(@"-> dirty=(%g %g)+(%g %g)\n",dirty.origin.x,dirty.origin.y,dirty.size.width,dirty.size.height);
		dr.origin.x+=border_x;
		dr.origin.y+=border_y;
		[self setNeedsDisplayInRect: dr];

		if (current_scroll!=0)
		{ /* TODO */
			current_scroll=0;
			draw_all=YES;
			[self setNeedsDisplay: YES];
		}
	}
}


-(void) closeProgram
{
	if (master_fd==-1)
		return;
	NSDebugLLog(@"pty",@"closing master fd=%i\n",master_fd);
	[[NSRunLoop currentRunLoop] removeEvent: (void *)master_fd
		type: ET_RDESC
		forMode: NSDefaultRunLoopMode
		all: YES];
	close(master_fd);
	master_fd=-1;
}


-(void) runProgram: (NSString *)path
	withArguments: (NSArray *)args
	initialInput: (NSString *)d
	arg0: (NSString *)arg0
{
	int ret;
	struct winsize ws;
	NSRunLoop *rl;
	const char *cpath;
	const char *cargs[[args count]+2];
	int i;

	int pipefd[2];

	NSDebugLLog(@"pty",@"-runProgram: %@ withArguments: %@ initialInput: %@",
		path,args,d);

	[self closeProgram];

	cpath=[path cString];
	cargs[0]=[arg0 cString];
	for (i=0;i<[args count];i++)
	{
		cargs[i+1]=[[args objectAtIndex: i] cString];
	}
	cargs[i+1]=NULL;

	if (d)
	{
		if (pipe(pipefd))
		{
			NSLog(_(@"Unable to open pipe for input: %m."));
			return;
		}
		NSDebugLLog(@"pty",@"creating pipe for initial data, got %i %i",
			pipefd[0],pipefd[1]);
	}

	ws.ws_row=sy;
	ws.ws_col=sx;
	ret=forkpty(&master_fd,NULL,NULL,&ws);
	if (ret<0)
	{
		NSLog(_(@"Unable to fork: %m."));
		return;
	}

	if (ret==0)
	{
		if (d)
		{
			close(pipefd[1]);
			dup2(pipefd[0],0);
		}
	
		putenv("TERM=linux");
		putenv("TERM_PROGRAM=GNUstep_Terminal");
		execv(cpath,(char *const*)cargs);
		fprintf(stderr,"Unable to spawn process '%s': %m!",cpath);
		exit(1);
	}

	NSDebugLLog(@"pty",@"forked child %i, fd %i",ret,master_fd);

	rl=[NSRunLoop currentRunLoop];
	[rl addEvent: (void *)master_fd
		type: ET_RDESC
		watcher: self
		forMode: NSDefaultRunLoopMode];

	[[NSNotificationCenter defaultCenter]
		postNotificationName: TerminalViewBecameNonIdleNotification
		object: self];

	if (d)
	{
		const char *s=[d UTF8String];
		close(pipefd[0]);
		write(pipefd[1],s,strlen(s));
		close(pipefd[1]);
	}

	DESTROY(title_window);
	if (args)
		title_window=[[NSString stringWithFormat: @"%@ %@",
			path,[args componentsJoinedByString: @" "]] retain];
	else
		title_window=[path copy];

	ASSIGN(title_miniwindow,path);
	[[NSNotificationCenter defaultCenter]
		postNotificationName: TerminalViewTitleDidChangeNotification
		object: self];
}

-(void) runProgram: (NSString *)path
	withArguments: (NSArray *)args
	initialInput: (NSString *)d
{
	[self runProgram: path
		withArguments: args
		initialInput: d
		arg0: path];
}

-(void) runShell
{
	NSString *arg0;
	NSString *path;

	path=[TerminalViewShellPrefs shell];
	if ([TerminalViewShellPrefs loginShell])
		arg0=[@"-" stringByAppendingString: path];
	else
		arg0=path;
	[self runProgram: path
		withArguments: nil
		initialInput: nil
		arg0: arg0];
}

@end


/**
misc. stuff
**/

@implementation TerminalView
/* Begin Luis Stuff */
-(void)dirtyJob
{
        if (cursor_x!=current_x || cursor_y!=current_y)
        {
                ADD_DIRTY(current_x,current_y,1,1);
                SCREEN(current_x,current_y).attr|=0x80;
                ADD_DIRTY(cursor_x,cursor_y,1,1);
                draw_cursor=YES;
        }

        NSDebugLLog(@"term",@"done (%i %i) (%i %i)\n",
                dirty.x0,dirty.y0,dirty.x1,dirty.y1);

        if (dirty.x0>=0)
        {
                NSRect dr;

                if (sb_length)
                        [scroller setFloatValue: (current_scroll+sb_length)/(float)(sb_length)
                                knobProportion: sy/(float)(sy+sb_length)];
                else
                        [scroller setFloatValue: 1.0 knobProportion: 1.0];
                dr.origin.x=dirty.x0*fx;
                dr.origin.y=dirty.y0*fy;
                dr.size.width=(dirty.x1-dirty.x0)*fx;
                dr.size.height=(dirty.y1-dirty.y0)*fy;
                dr.origin.y=fy*sy-(dr.origin.y+dr.size.height);
                dr.origin.x+=border_x;
                dr.origin.y+=border_y;
                [self setNeedsDisplayInRect: dr];

                if (current_scroll!=0)
                { /* TODO */
                        current_scroll=0;
                        draw_all=YES;
                        [self setNeedsDisplay: YES];
                }
        }
};
-(void)writeAction:(NSString *)text from:(NSString *)sender
{
    char *cText, *cSender;
    int index, writtingNick;
    BOOL needsLineJump;
    screen_char_t ch;

    cText=(char *)[text cString];
    cSender=(char *)[sender cString];
    index=1;
    needsLineJump=YES;
    ch.attr=2;
    writtingNick=1;

        while(*cSender)
        {
                if(needsLineJump==YES)
                {
                        needsLineJump=NO;
                        [self ts_scrollUp:0 :sy rows:1 save:YES];
                }
                if(writtingNick)
                {
                        writtingNick=0;
                        ch.color=2;
                        ch.ch='*';
                        [self ts_putChar:ch count:1 at:index :sy-1];
                        index++;
                        ch.color=7;
                }
                ch.ch=*cSender;
                [self ts_putChar:ch count:1 at:index :sy-1];

                index++;
                cSender++;
                if(index==sx)
                {
                index=1;
                needsLineJump=YES;
                }
        }
      //  ch.color=1;
      //  ch.ch='>';
      //  [self ts_putChar:ch count:1 at:index :sy-1];
     //   index++;
        ch.color=0;
        ch.ch=' ';
        [self ts_putChar:ch count:1 at:index :sy-1];
        index++;

        ch.color=7;
        while(*cText)
        {
                if(needsLineJump==YES)
                {
                        needsLineJump=NO;
                        [self ts_scrollUp:0 :sy rows:1 save:YES];
                }
                ch.ch=*cText;
                [self ts_putChar:ch count:1 at:index :sy-1];

                index++;
                cText++;
                if(index==sx)
                {
                        index=1;
                        needsLineJump=YES;
                }
        };
        ch.ch=' ';
        while(index<sx)
        {
                [self ts_putChar:ch count:1 at:index :sy-1];
                index++;
        }

        [self dirtyJob];
        
}
-(void)writeMessage:(NSString *)text from:(NSString *)sender
{
    char *cText, *cSender;
    int index, writtingNick;
    BOOL needsLineJump;
    screen_char_t ch;

    cText=(char *)[text cString];
    cSender=(char *)[sender cString];
    index=1;
    needsLineJump=YES;
    ch.attr=2;
    writtingNick=1;

        while(*cSender)
        {
                if(needsLineJump==YES)
                {
                        needsLineJump=NO;
                        [self ts_scrollUp:0 :sy rows:1 save:YES];
                }
                if(writtingNick)
                {
                        writtingNick=0;
                        ch.color=1;
                        ch.ch='<';
                        [self ts_putChar:ch count:1 at:index :sy-1];
                        index++;
                        ch.color=7;
                }
                ch.ch=*cSender;
                [self ts_putChar:ch count:1 at:index :sy-1];

                index++;
                cSender++;
                if(index==sx)
                {
                index=1;
                needsLineJump=YES;
                }
        }
        ch.color=1;
        ch.ch='>';
        [self ts_putChar:ch count:1 at:index :sy-1];
        index++;
        ch.color=0;
        ch.ch=' ';
        [self ts_putChar:ch count:1 at:index :sy-1];
        index++;

        ch.color=7;
        while(*cText)
        {
                if(needsLineJump==YES)
                {
                        needsLineJump=NO;
                        [self ts_scrollUp:0 :sy rows:1 save:YES];
                }
                ch.ch=*cText;
                [self ts_putChar:ch count:1 at:index :sy-1];

                index++;
                cText++;
                if(index==sx)
                {
                        index=1;
                        needsLineJump=YES;
                }
        };
        ch.ch=' ';
        while(index<sx)
        {
                [self ts_putChar:ch count:1 at:index :sy-1];
                index++;
        }

        [self dirtyJob];
        
}

-(void) writeNSString:(NSString *)text
{
	char *cText;
	int index, writtingNick;
	BOOL needsLineJump;
	screen_char_t ch;
	
	cText = (char *) [text cString];

	index=1;
	needsLineJump=YES;
	ch.attr=2;
    ch.color=7;
	
        while(*cText)
        {
                if(needsLineJump==YES)
                {
                        needsLineJump=NO;
                        [self ts_scrollUp:0 :sy rows:1 save:YES];
                }

                ch.ch=*cText;
                [self ts_putChar:ch count:1 at:index :sy-1];
		
                index++;
                cText++;
                if(index==sx)
                {
			index=1;
			needsLineJump=YES;
                }
        }

	[self dirtyJob];
}

/* End Luis Stuff */
-(void) _resizeTerminalTo: (NSSize)size
{
	int nsx,nsy;
	struct winsize ws;
	screen_char_t *nscreen,*nsbuf;
	int iy,ny;
	int copy_sx;

	nsx=(size.width-border_x)/fx;
	nsy=(size.height-border_y)/fy;

	NSDebugLLog(@"term",@"_resizeTerminalTo: (%g %g) %i %i (%g %g)\n",
		size.width,size.height,
		nsx,nsy,
		nsx*fx,nsy*fy);

	if (ignore_resize)
	{
		NSDebugLLog(@"term",@"ignored");
		return;
	}

	if (nsx<1) nsx=1;
	if (nsy<1) nsy=1;

	if (nsx==sx && nsy==sy)
	{
		/* Do a complete redraw anyway. Even though we don't really need it,
		the resize might have caused other things to overwrite our part of the
		window. */
		draw_all=YES;
		return;
	}

	[self _clearSelection]; /* TODO? */

	nscreen=malloc(nsx*nsy*sizeof(screen_char_t));
	nsbuf=malloc(nsx*max_scrollback*sizeof(screen_char_t));
	if (!nscreen || !nsbuf)
	{
		NSLog(@"Failed to allocate screen buffer!");
		return;
	}
	memset(nscreen,0,sizeof(screen_char_t)*nsx*nsy);
	memset(nsbuf,0,sizeof(screen_char_t)*nsx*max_scrollback);

	copy_sx=sx;
	if (copy_sx>nsx)
		copy_sx=nsx;

//	NSLog(@"copy %i+%i %i  (%ix%i)-(%ix%i)\n",start,num,copy_sx,sx,sy,nsx,nsy);

/* TODO: handle resizing and scrollback */
	for (iy=-sb_length;iy<sy;iy++)
	{
		screen_char_t *src,*dst;
		ny=iy-sy+nsy;
		if (ny<-max_scrollback)
			continue;

		if (iy<0)
			src=&sbuf[sx*(max_scrollback+iy)];
		else
			src=&screen[sx*iy];

		if (ny<0)
			dst=&nsbuf[nsx*(max_scrollback+ny)];
		else
			dst=&nscreen[nsx*ny];

		memcpy(dst,src,copy_sx*sizeof(screen_char_t));
	}

	sb_length=sb_length+sy-nsy;
	if (sb_length>max_scrollback)
		sb_length=max_scrollback;
	if (sb_length<0)
		sb_length=0;

	sx=nsx;
	sy=nsy;
	free(screen);
	free(sbuf);
	screen=nscreen;
	sbuf=nsbuf;

	if (cursor_x>sx) cursor_x=sx-1;
	if (cursor_y>sy) cursor_y=sy-1;

	if (sb_length)
		[scroller setFloatValue: (current_scroll+sb_length)/(float)(sb_length)
			knobProportion: sy/(float)(sy+sb_length)];
	else
		[scroller setFloatValue: 1.0 knobProportion: 1.0];

	[tp setTerminalScreenWidth: sx height: sy];

	if (master_fd!=-1)
	{
		ws.ws_row=nsy;
		ws.ws_col=nsx;
		ioctl(master_fd,TIOCSWINSZ,&ws);
	}

	draw_all=YES;
	[self setNeedsDisplay: YES];
}

-(void) setFrame: (NSRect)frame
{
	[super setFrame: frame];
	[self _resizeTerminalTo: frame.size];
}

-(void) setFrameSize: (NSSize)size
{
	[super setFrameSize: size];
	[self _resizeTerminalTo: size];
}


- initWithFrame: (NSRect)frame
{
	sx=80;
	sy=25;

	if (!(self=[super initWithFrame: frame])) return nil;

	{
		NSRect r;
		font=[TerminalView terminalFont];
		boldFont=[TerminalViewDisplayPrefs boldTerminalFont];
		r=[font boundingRectForFont];
		fx=r.size.width;
		fy=r.size.height;
		/* TODO: clear up font metrics issues with xlib/backart */
		fx0=fabs(r.origin.x);
		if (r.origin.y<0)
			fy0=fy+r.origin.y;
		else
			fy0=r.origin.y;
		NSDebugLLog(@"term",@"Bounding (%g %g)+(%g %g)",fx0,fy0,fx,fy);
		font_encoding=[font mostCompatibleStringEncoding];
		boldFont_encoding=[boldFont mostCompatibleStringEncoding];
		NSDebugLLog(@"term",@"encoding %i and %i",
			font_encoding,boldFont_encoding);
	}

	screen=malloc(sizeof(screen_char_t)*sx*sy);
	memset(screen,0,sizeof(screen_char_t)*sx*sy);
	draw_all=YES;

	max_scrollback=256;
	sbuf=malloc(sizeof(screen_char_t)*sx*max_scrollback);
	memset(sbuf,0,sizeof(screen_char_t)*sx*max_scrollback);

	tp=[[TerminalParser_Linux alloc] initWithTerminalScreen: self
		width: sx  height: sy];

	master_fd=-1;

	return self;
}

-(void) dealloc
{
	[self closeProgram];

	DESTROY(tp);

	[scroller setTarget: nil];
	DESTROY(scroller);

	free(screen);
	free(sbuf);
	screen=NULL;
	sbuf=NULL;

	DESTROY(title_window);
	DESTROY(title_miniwindow);

	[super dealloc];
}


-(NSString *) windowTitle
{
	return title_window;
}

-(NSString *) miniwindowTitle
{
	return title_miniwindow;
}


-(void) setIgnoreResize: (BOOL)ignore
{
	ignore_resize=ignore;
}

-(void) setBorder: (float)x : (float)y
{
	border_x=x;
	border_y=y;
}


+(NSFont *) terminalFont
{
	return [TerminalViewDisplayPrefs terminalFont];
}

+(void) registerPasteboardTypes
{
	NSArray *types=[NSArray arrayWithObject: NSStringPboardType];
	[NSApp registerServicesMenuSendTypes: types returnTypes: nil];
}

@end

