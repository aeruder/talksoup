/*
copyright 2002 Alexander Malmberg <alexander@malmberg.org>
*/

/* parses escape sequences for 'TERM=linux' */

#ifndef LinuxParser_h
#define LinuxParser_h

#include "Terminal.h"

@interface TerminalParser_Linux : NSObject <TerminalParser>
{
	id<TerminalScreen> ts;
	int width,height;

	unsigned int tab_stop[8];

	int x,y;

	int top,bottom;

	unsigned int unich;
	int utf_count;

#define TITLE_BUF_SIZE 255
	char title_buf[TITLE_BUF_SIZE+1];
	int title_len, title_type;

enum { ESnormal, ESesc, ESsquare, ESgetpars, ESgotpars, ESfunckey,
	EShash, ESsetG0, ESsetG1, ESpercent, ESignore, ESnonstd,
	ESpalette, EStitle_semi, EStitle_buf } ESstate;
	int vc_state;

	unsigned char decscnm,decom,decawm,deccm,decim;
	unsigned char ques;
	unsigned char charset,utf,disp_ctrl,toggle_meta;
	int G0_charset,G1_charset;

	const unichar *translate;

	unsigned int intensity,underline,reverse,blink;
	unsigned int color,def_color;
#define foreground (color & 0x0f)
#define background (color & 0xf0)

	screen_char_t video_erase_char;

#define NPAR 16
	int npar;
	int par[NPAR];

	int saved_x,saved_y;
	unsigned int s_intensity,s_underline,s_blink,s_reverse,s_charset,s_color;
	int saved_G0,saved_G1;
}
@end

#endif

