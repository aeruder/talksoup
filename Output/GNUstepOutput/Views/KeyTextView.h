/***************************************************************************
                                TabTextView.h
                          -------------------
    begin                : Fri Apr 11 14:14:45 CDT 2003
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

@class TabTextView;

#ifndef TAB_TEXT_VIEW_H
#define TAB_TEXT_VIEW_H

#include <AppKit/NSTextView.h>

@interface TabTextView : NSTextView
	{
		id tabTarget;
		
		SEL tabAction;
		SEL nonTabAction;
	}

- setTabTarget: (id)aTarget;
- setTabAction: (SEL)aSel;
- setNonTabAction: (SEL)aSel;

- (void)setStringValue: (NSString *)aValue; 
@end

#endif

