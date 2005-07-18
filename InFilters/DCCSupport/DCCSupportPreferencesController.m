/***************************************************************************
                    DCCSupportPreferencesController.m
                          -------------------
    begin                : Wed Jan  7 20:54:25 CST 2004
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

#import "DCCSupportPreferencesController.h"
#import "DCCSupport.h"

#import <AppKit/NSWindow.h>
#import <AppKit/NSButton.h>
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSTextField.h>
#import <AppKit/NSOpenPanel.h>
#import <AppKit/NSImage.h>

#import <Foundation/NSDictionary.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDebug.h>
#import <Foundation/NSPathUtilities.h>
#import <AppKit/NSView.h>
#import <AppKit/NSPanel.h>

#define get_default(_x) [DCCSupport defaultsObjectForKey: _x]
#define set_default(_x, _y) \
{	[DCCSupport setDefaultsObject: _y forKey: _x]; }

#define GET_DEFAULT_INT(_x) [get_default(_x) intValue]
#define SET_DEFAULT_INT(_x, _y) set_default(_x, ([NSString stringWithFormat: @"%d", _y]))

@implementation DCCSupportPreferencesController
- init
{
	id bundle, path;

	if (!(self = [super init])) return nil;

	bundle = [NSBundle bundleForClass: [DCCSupport class]];

	if (![bundle loadNibFile: @"DCCSupportPreferences"
	  externalNameTable: [NSDictionary dictionaryWithObjectsAndKeys:
	    self, @"NSOwner",
	    nil] withZone: 0])
	{
		[super dealloc];
		return nil;
	}

	path = [bundle pathForResource: @"dccsupport_prefs" ofType: @"tiff"];
	if (!path) 
	{
		NSLog(@"Could not find dccsupport_prefs.tiff");
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

	return self;
}
- (void)awakeFromNib
{
	NSWindow *tempWindow;

	tempWindow = (NSWindow *)window;
	window = RETAIN([tempWindow contentView]);
	RELEASE(tempWindow);
	[window setAutoresizingMask:
	  NSViewWidthSizable | NSViewHeightSizable];

	[blockSizeField setNextKeyView: portRangeField];
	[portRangeField setNextKeyView: blockSizeField];
	[self reloadData];
}
- (void)reloadData
{
	id path1 = get_default(DCCCompletedDirectory);
	id path2 = get_default(DCCDownloadDirectory);

	path1 = [path1 stringByStandardizingPath];
	path2 = [path2 stringByStandardizingPath];
	
	set_default(DCCCompletedDirectory, path1);
	set_default(DCCDownloadDirectory, path2);
	
	[changeCompletedField setStringValue: 
	  get_default(DCCCompletedDirectory)];
	[changeDownloadField setStringValue:
	  get_default(DCCDownloadDirectory)];
	[blockSizeField setStringValue: [NSString stringWithFormat: @"%d",
	  GET_DEFAULT_INT(DCCBlockSize)]];
	[portRangeField setStringValue:
	  get_default(DCCPortRange)];
}
- (void)dealloc
{
	RELEASE(preferencesIcon);
	DESTROY(window);
	[super dealloc];
}
- (NSView *)preferencesView
{
	return window;
}
- (NSImage *)preferencesIcon
{
	return preferencesIcon;
}
- (NSString *)preferencesName
{
	return _l(@"DCC Support");
}
- (void)activate: aPrefs
{
	isActive = YES;	

	[self reloadData];

	[[aPrefs window] makeFirstResponder: changeDownloadButton];
}
- (void)deactivate
{
	isActive = NO;
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
	if (result == NSOKButton)
	{
		id tmp;
	
		tmp = [openPanel filenames];
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
	if (result == NSOKButton)
	{
		id tmp;
	
		tmp = [openPanel filenames];
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
		int x1;

		x1 = [[array objectAtIndex: 0] intValue];

		if (x1 < 0)
		{
			set_default(DCCPortRange, @"");
		}
		else
		{
			if (x1 > 65535) x1 = 65535;
	
			tmp = [NSString stringWithFormat: @"%d", x1];

			set_default(DCCPortRange, ([NSString stringWithFormat: @"%@-%@",
			  tmp, tmp]));
		}
	}
	else
	{
		int x1,x2;
		NSString *tmp;

		x1 = [[array objectAtIndex: 0] intValue];
		x2 = [[array objectAtIndex: 1] intValue];

		if (x1 < 0 || x2 < 0)
		{
			set_default(DCCPortRange, @"");
		}
		else
		{
			if (x1 > 65535) x1 = 65535;
			if (x2 > 65535) x2 = 65535;

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
	}
		
	[self reloadData];		
}
@end
