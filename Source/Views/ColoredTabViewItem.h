/***************************************************************************
                                ColoredTabViewItem.h
                          -------------------
    begin                : Thu Dec  5 00:25:40 CST 2002
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

#import <AppKit/NSTabViewItem.h>

@class NSColor;

@interface ColoredTabViewItem : NSTabViewItem
	{
		NSColor *color;
	}
- setLabelColor: (NSColor *)aColor;
@end
