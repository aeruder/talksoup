/*
copyright 2002 Alexander Malmberg <alexander@malmberg.org>
*/

#ifndef TerminalView_h
#define TerminalView_h

#include <AppKit/NSView.h>


extern NSString
	*TerminalViewBecameIdleNotification,
	*TerminalViewBecameNonIdleNotification,

	*TerminalViewTitleDidChangeNotification;


#include "Terminal.h"

/* TODO: this is slightly ugly */
@class TerminalParser_Linux;


@class NSScroller;

struct selection_range
{
	int location,length;
};

@interface TerminalView : NSView
{
	NSScroller *scroller;

	NSFont *font,*boldFont;
	int font_encoding,boldFont_encoding;
	float fx,fy,fx0,fy0;

	struct
	{
		int x0,y0,x1,y1;
	} dirty;

	int master_fd;

	int max_scrollback;
	int sb_length,current_scroll;
	screen_char_t *sbuf;

	int sx,sy;
	screen_char_t *screen;

	int cursor_x,cursor_y;
	int current_x,current_y;

	NSString *title_window,*title_miniwindow;

	NSObject<TerminalParser> *tp;

	BOOL draw_all,draw_cursor;

	struct selection_range selection;

	/* scrolling by compositing takes a long while, so we break out of such
	loops fairly often to process other events */
	/* TODO: collect scrolls and do the compositing in drawRect */
	int num_scrolls;

	int pending_scroll;

	BOOL ignore_resize;

	float border_x,border_y;
}

-(void) setIgnoreResize: (BOOL)ignore;

-(void) setBorder: (float)x : (float)y;

-(NSString *) windowTitle;
-(NSString *) miniwindowTitle;

+(NSFont *) terminalFont;

+(void) registerPasteboardTypes;
/* Begin Added By Luis */
-(void)writeMessage:(NSString *)text from:(NSString *)sender;
-(void)writeAction:(NSString *)text from:(NSString *)sender;
-(void)writeNSString:(NSString *)text;
/* End Added By Luis */

@end

@interface TerminalView (display) <TerminalScreen>
@end

/* TODO: this is ugly */
@interface TerminalView (scrolling_2)
-(void) setScroller: (NSScroller *)sc;
@end

@interface TerminalView (input_2)
-(void) closeProgram;
-(void) runShell;
-(void) runProgram: (NSString *)path
	withArguments: (NSArray *)args
	initialInput: (NSString *)d;
-(void) runProgram: (NSString *)path
	withArguments: (NSArray *)args
	initialInput: (NSString *)d
	arg0: (NSString *)arg0;
@end

#endif

