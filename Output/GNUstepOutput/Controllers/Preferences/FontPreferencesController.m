/***************************************************************************
                      FontPreferencesController.m
                          -------------------
    begin                : Sat Aug 14 19:19:31 CDT 2004
    copyright            : (C) 2004 by Andrew Ruder
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

#import "Controllers/Preferences/FontPreferencesController.h"
#import "Controllers/Preferences/PreferencesController.h"
#import "GNUstepOutput.h"

#import <AppKit/NSImage.h>
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSView.h>
#import <AppKit/NSWindow.h>
#import <Foundation/NSString.h>
#import <Foundation/NSNotification.h>

@implementation FontPreferencesController
- init
{
	id path;
	if (!(self = [super init])) return nil;

	if (!([NSBundle loadNibNamed: @"FontPreferences" owner: self]))
	{
		[self dealloc];
		return nil;
	}

	path = [[NSBundle bundleForClass: [GNUstepOutput class]] 
	  pathForResource: @"font_prefs" ofType: @"tiff"];
	if (!path) 
	{
		NSLog(@"Could not find font_prefs.tiff");
		[self dealloc];
		return nil;
	}

	preferencesIcon = [[NSImage alloc] initWithContentsOfFile:
	  path];
	if (!preferencesIcon)
	{
		NSLog(@"Could not load image %@", path);
		[self dealloc];
		return nil;
	}

	[[NSNotificationCenter defaultCenter]
	 postNotificationName: PreferencesModuleAdditionNotification 
	 object: self];

	return self;
}
- (void)awakeFromNib
{
	NSWindow *tempWindow;

	tempWindow = (NSWindow *)preferencesView;
	preferencesView = RETAIN([tempWindow contentView]);
	RELEASE(tempWindow);
}
- (void)dealloc
{
	RELEASE(preferencesView);
	RELEASE(preferencesIcon);
	[super dealloc];
}
- (NSString *)preferencesName
{
	return @"Fonts";
}
- (NSImage *)preferencesIcon
{
	return preferencesIcon;
}
- (NSView *)preferencesView
{
	NSLog(@"preferencesView: %@", preferencesView);
	return preferencesView;
}
- (void)activate
{
	NSLog(@"Activated!");
	// FIXME
}
- (void)deactivate
{
	NSLog(@"Deactivated!");
	// FIXME
}
@end
