/***************************************************************************
                                NamePromptController.h
                          -------------------
    begin                : Thu May  1 11:45:04 CDT 2003
    copyright            : (C) 2005 by Andrew Ruder
    email                : aeruder@ksu.edu
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

@class NamePromptController;

#ifndef NAME_PROMPT_CONTROLLER_H
#define NAME_PROMPT_CONTROLLER_H

#import <Foundation/NSObject.h>

@class NSTextField, NSWindow;

@interface NamePromptController : NSObject
	{
		NSTextField *typeView;
		NSWindow *window;
	}
- (void)returnHit: (NSTextField *)sender;

- (NSWindow *)window;
- (NSTextField *)typeView;
@end

#endif
