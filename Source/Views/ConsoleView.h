/***************************************************************************
                                ConsoleView.h
                          -------------------
    begin                : Thu Oct 24 13:05:09 CDT 2002
    copyright            : (C) 2002 by Andy Ruder
    email                : aeruder@yahoo.com
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#import <AppKit/NSView.h>
#import <AppKit/NSTextView.h>

@class NSScrollView, NSTextView, NSBox;

@interface NSTextView (appendText)
- appendText: aText;
@end
	
@interface ConsoleView : NSView
	{
		NSScrollView *chatScroll;
		NSTextView *chatView;
	}
- initWithBorder: (BOOL)border;

- putMessage: message;

- (NSScrollView *)chatScroll;
- (NSTextView *)chatView;
@end
