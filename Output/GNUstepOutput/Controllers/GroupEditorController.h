/***************************************************************************
                                GroupEditorController.h
                          -------------------
    begin                : Tue May  6 14:34:46 CDT 2003
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

@class GroupEditorController;

#ifndef GROUP_EDITOR_CONTROLLER_H
#define GROUP_EDITOR_CONTROLLER_H

#import <Foundation/NSObject.h>

@class NSTextField, NSWindow, NSButton;

@interface GroupEditorController : NSObject
	{
		NSTextField *entryField;
		NSTextField *extraField;
		NSButton *okButton;
		NSWindow *window;
	}

- (NSButton *)okButton;
- (NSTextField *)extraField;
- (NSTextField *)entryField;
- (NSWindow *)window;

- (void)setEntry: (NSTextField *)sender;
@end

#endif 
 
