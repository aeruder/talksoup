/***************************************************************************
                                PreferencesController.h
                          -------------------
    begin                : Thu Apr  3 08:09:15 CST 2003
    copyright            : (C) 2003 by Andy Ruder
	                       w/ much of the code borrowed from Preferences.app
						   by Jeff Teunissen
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

@class PreferencesController, NSString;

extern NSString *GNUstepOutputPersonalBracketColor;
extern NSString *GNUstepOutputOtherBracketColor;
extern NSString *GNUstepOutputTextColor;
extern NSString *GNUstepOutputBackgroundColor;
extern NSString *GNUstepOutputServerList;
extern NSString *GNUstepOutputFontName;
extern NSString *GNUstepOutputFontSize;
extern NSString *GNUstepOutputScrollBack;

#ifndef PREFERENCES_CONTROLLER_H
#define PREFERENCES_CONTROLLER_H

#import <Foundation/NSObject.h>

@class NSScrollView, NSWindow, NSMatrix, NSMutableArray;

@protocol GNUstepOutputPrefsModule
@end

@interface PreferencesController : NSObject
	{
		NSScrollView *scrollView;
		NSWindow *window;
		NSMatrix *prefsList;
		NSScrollView *moduleScrollView;
		int currentPrefs;
		NSMutableArray *prefsModules;
	}
- (NSWindow *)window;

- (BOOL)setCurrentModule: (id <GNUstepOutputPrefsModule>) aPrefsModule;
- (void)refreshCurrentPanel;

- (void)refreshAvailablePreferences;
@end

#endif
