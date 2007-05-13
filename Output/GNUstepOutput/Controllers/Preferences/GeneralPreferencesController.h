/***************************************************************************
                        GeneralPreferencesController.h
                          -------------------
    begin                : Sat Aug 14 19:19:30 CDT 2004
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

@class GeneralPreferencesController;
@class NSString;

extern NSString *GNUstepOutputBufferLines;
extern NSString *GNUstepOutputDefaultQuitMessage;
extern NSString *GNUstepOutputAliases;
extern NSString *GNUstepOutputTimestampFormat;
extern NSString *GNUstepOutputTimestampEnabled;

#ifndef GENERAL_PREFERENCES_CONTROLLER_H
#define GENERAL_PREFERENCES_CONTROLLER_H

#import <Foundation/NSObject.h>

@class NSImage, NSButton;
@class NSView, NSImage;
@class NSTextField, PreferencesController;

@interface GeneralPreferencesController : NSObject 
	{
		NSView *preferencesView;
		NSImage *preferencesIcon;
		NSTextField *userView;
		NSTextField *nameView;
		NSTextField *passwordView;
		NSTextField *nickView;
		NSTextField *quitView;
		NSTextField *timestampFormatField;
		NSButton *timestampButton;
		BOOL activated;
	}
+ (BOOL)timestampEnabled;

- (void)setTimestampEnabled: (NSButton *)aSender;
- (void)setText: (NSTextField *)aField;
- (NSString *)preferencesName;
- (NSImage *)preferencesIcon;
- (NSView *)preferencesView;
- (void)activate: (PreferencesController *)aPrefs;
- (void)deactivate;
@end

#endif
