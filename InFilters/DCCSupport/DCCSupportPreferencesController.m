/***************************************************************************
                    DCCSupportPreferencesController.m
                          -------------------
    begin                : Wed Jan  7 20:54:25 CST 2004
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

#import "DCCSupportPreferencesController.h"
#import "DCCSupport.h"

#ifdef USE_APPKIT
#import <AppKit/NSWindow.h>
#import <AppKit/NSButton.h>
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSTextField.h>
#endif

#import <Foundation/NSDictionary.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>

@implementation DCCSupportPreferencesController
#ifndef USE_APPKIT
- (void)reloadData
{
	return;
}
#else
- (void)awakeFromNib
{
	[self reloadData];
}
- (void)reloadData
{
}
- (void)shouldDisplay
{
	id bundle;

	if (window)
	{
		[window makeKeyAndOrderFront: nil];
		return;
	}

	bundle = [NSBundle bundleForClass: [DCCSupport class]];

	if (![bundle loadNibFile: @"DCCSupportPreferences"
	  externalNameTable: [NSDictionary dictionaryWithObjectsAndKeys:
	  self, @"NSOwner",
	  nil] withZone: 0])
	{
		return;
	}

	[window makeKeyAndOrderFront: nil];
}
- (void)dealloc
{
	[self shouldHide];
	[super dealloc];
}
- (void)shouldHide
{
	[window close];
	DESTROY(window);

	blockSizeField = nil;
	portRangeField = nil;
	changeCompletedField = nil;
	changeDownloadField = nil;
	changeCompletedButton = nil;
	changeDownloadButton = nil;
}
- (void)changeCompletedHit: (NSButton *)sender
{
}
- (void)changeDownloadHit: (NSButton *)sender
{
}
- (void)blockSizeHit: (NSTextField *)sender
{
}
- (void)portRangeHit: (NSTextField *)sender
{
}
#endif
@end
