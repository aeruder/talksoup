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
#import <AppKit/NSOpenPanel.h>
#endif

#import <Foundation/NSDictionary.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>

#define get_default(_x) [DCCSupport defaultsObjectForKey: _x]
#define set_default(_x, _y) \
{	[DCCSupport setDefaultsObject: _y forKey: _x]; }

#define GET_DEFAULT_INT(_x) [get_default(_x) intValue]
#define SET_DEFAULT_INT(_x, _y) set_default(_x, ([NSString stringWithFormat: @"%d", _y]))

@implementation DCCSupportPreferencesController
#ifndef USE_APPKIT
- (void)reloadData
{
	return;
}
#else
- (void)awakeFromNib
{
	[blockSizeField setNextKeyView: portRangeField];
	[portRangeField setNextKeyView: blockSizeField];
	[self reloadData];
}
- (void)reloadData
{
	[changeCompletedField setStringValue: 
	  get_default(DCCCompletedDirectory)];
	[changeDownloadField setStringValue:
	  get_default(DCCDownloadDirectory)];
	[blockSizeField setStringValue: [NSString stringWithFormat: @"%d",
	  GET_DEFAULT_INT(DCCBlockSize)]];
	[portRangeField setStringValue:
	  get_default(DCCPortRange)];
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
	id openPanel;
	int result;
	
	openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseFiles: NO];
	[openPanel setCanChooseDirectories: YES];
	[openPanel setAllowsMultipleSelection: NO];
	
	result = [openPanel runModalForDirectory: nil file: nil types: nil];
	if (result == NSOkButton)
	{
		id tmp;
	
		tmp = [openPanel fileNames];
		if ([tmp count] == 0) return;

		tmp = [tmp objectAtIndex: 0];
		
		set_default(DCCCompletedDirectory, tmp);
		[self reloadData];
	}
}
- (void)changeDownloadHit: (NSButton *)sender
{
	id openPanel;
	int result;
	
	openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseFiles: NO];
	[openPanel setCanChooseDirectories: YES];
	[openPanel setAllowsMultipleSelection: NO];
	
	result = [openPanel runModalForDirectory: nil file: nil types: nil];
	if (result == NSOkButton)
	{
		id tmp;
	
		tmp = [openPanel fileNames];
		if ([tmp count] == 0) return;

		tmp = [tmp objectAtIndex: 0];
		
		set_default(DCCDownloadDirectory, tmp);
		[self reloadData];
	}
}
- (void)blockSizeHit: (NSTextField *)sender
{
	SET_DEFAULT_INT(DCCBlockSize, [[sender stringValue] intValue]);
	[self reloadData];
}
- (void)portRangeHit: (NSTextField *)sender
{
	NSMutableArray *array;
	
	array = [NSMutableArray arrayWithArray: 
	  [[sender stringValue] componentsSeparatedByString: @"-"]];

	[array removeObject: @""];

	if ([array count] == 0)
	{
		set_default(DCCPortRange, @"");
	}
	else if ([array count] == 1)
	{
		NSString *tmp;

		tmp = [NSString stringWithFormat: @"%d", 
		  [[array objectAtIndex: 0] intValue]];

		set_default(DCCPortRange, ([NSString stringWithFormat: @"%@-%@",
		  tmp, tmp]));
	}
	else
	{
		int x1,x2;
		NSString *tmp;

		x1 = [[array objectAtIndex: 0] intValue];
		x2 = [[array objectAtIndex: 1] intValue];

		if (x1 > x2)
		{
			int tmp2;
			tmp2 = x2;
			x2 = x1;
			x1 = tmp2;
		}

		tmp = [NSString stringWithFormat: @"%d-%d",
		  x1, x2];

		set_default(DCCPortRange, tmp);
	}
		
	[self reloadData];		
}
#endif
@end
