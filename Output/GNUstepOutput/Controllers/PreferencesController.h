/***************************************************************************
                                PreferencesController.h
                          -------------------
    begin                : Thu Apr  3 08:09:15 CST 2003
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

@class PreferencesController;

#ifndef PREFERENCES_CONTROLLER_H
#define PREFERENCES_CONTROLLER_H

#include <Foundation/NSObject.h>

@class NSColorWell, NSTextField, NSButton, NSWindow;

@interface PreferencesController : NSObject
	{
		NSTextField *fontField;
		NSButton *setFontButton;
		NSColorWell *personalBracketColor;
		NSColorWell *backgroundColor;
		NSColorWell *otherBracketColor;
		NSColorWell *textColor;
		NSTextField *nick;
		NSTextField *realName;
		NSTextField *userName;
		NSTextField *password;
		NSButton *resetButton;
		NSWindow *window;
	}
- (void)loadCurrentDefaults;
	
- nickSet: (NSTextField *)sender;

- passwordSet: (NSTextField *)sender;

- userNameSet: (NSTextField *)sender;

- realNameSet: (NSTextField *)sender;

- personalBracketColorSet: (NSColorWell *)sender;

- backgroundColorSet: (NSColorWell *)sender;

- otherBracketColorSet: (NSColorWell *)sender;

- textColorSet: (NSColorWell *)sender;

- resetColors: (NSButton *)sender;

- fontSet: (NSButton *)sender;

- (NSWindow *)window;
@end

#endif
