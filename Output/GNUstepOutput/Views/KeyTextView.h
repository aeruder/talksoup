/***************************************************************************
                                KeyTextView.h
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

@class KeyTextView;

#ifndef KEY_TEXT_VIEW_H
#define KEY_TEXT_VIEW_H

#import <AppKit/NSTextView.h>

@interface KeyTextView : NSTextView
	{
		id keyTarget;	
		SEL keyAction;
	}
- setKeyTarget: (id)aTarget;
- setKeyAction: (SEL)aSel;

- (void)setStringValue: (NSString *)aValue; 
@end

#endif

