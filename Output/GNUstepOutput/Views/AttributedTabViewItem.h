/***************************************************************************
                                ColoredTabViewItem.h
                          -------------------
    begin                : Thu Dec  5 00:25:40 CST 2002
    copyright            : (C) 2003 by Andy Ruder
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

@class AttributedTabViewItem;

#ifndef ATTRIBUTED_TAB_VIEW_ITEM_H
#define ATTRIBUTED_TAB_VIEW_ITEM_H

#import <AppKit/NSTabViewItem.h>

@class NSAttributedString, NSColor, NSMutableAttributedString;

@interface AttributedTabViewItem : NSTabViewItem
	{
		NSMutableAttributedString *attributedLabel;		
	}
- setLabelColor: (NSColor *)aColor;
- setAttributedLabel: (NSAttributedString *)label;
- (NSAttributedString *)attributedLabel;
@end

#endif
