/***************************************************************************
                                ScrollingTextView.h
                          -------------------
    begin                : Tue Nov  5 22:24:03 CST 2002
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

#import <AppKit/NSTextView.h>

@interface ScrollingTextView : NSTextView
@end

@interface NSTextView (appendText)
- appendText: aText;
@end
