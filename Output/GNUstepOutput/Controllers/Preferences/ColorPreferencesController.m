/***************************************************************************
                      ColorPreferencesController.m
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

#import "Controllers/Preferences/ColorPreferencesController.h"

#import <AppKit/NSNibLoading.h>
#import <AppKit/NSColorWell.h>
#import <AppKit/NSView.h>
#import <AppKit/NSWindow.h>

@implementation ColorPreferencesController
- init
{
	if (!(self = [super init])) return nil;

	if (!([NSBundle loadNibNamed: @"ColorPreferences" owner: self]))
	{
		[self dealloc];
		return nil;
	}

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
	[preferencesView dealloc];
	[super dealloc];
}
- (NSImage *)preferencesIcon
{
	// FIXME
	return nil;
}
- (NSView *)preferencesView
{
	NSLog(@"preferencesView: %@", preferencesView);
	return preferencesView;
}
- (void)activate
{
	// FIXME
}
- (void)deactivate
{
	// FIXME
}
@end
