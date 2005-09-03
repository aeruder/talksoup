/***************************************************************************
                         PreferencesController.m
                          -------------------
    begin                : Thu Apr  3 08:09:15 CST 2003
    copyright            : (C) 2005 by Andrew Ruder
	                       w/ much of the code borrowed from Preferences.app
						   by Jeff Teunissen
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

#import "Controllers/Preferences/PreferencesController.h"
#import "Misc/NSColorAdditions.h"
#import "GNUstepOutput.h"
#import "Controllers/Preferences/ColorPreferencesController.h"

#import <TalkSoupBundles/TalkSoup.h>

#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSString.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSButtonCell.h>
#import <AppKit/NSCell.h>
#import <AppKit/NSScrollView.h>
#import <AppKit/NSButton.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSView.h>
#import <AppKit/NSMatrix.h>
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSBox.h>

NSString *PreferencesChangedNotification = @"PreferencesChangedNotification";

NSString *PreferencesModuleAdditionNotification = @"PreferencesModuleAdditionNotification";
NSString *PreferencesModuleRemovalNotification = @"PreferencesModuleRemovalNotification";

NSString *GNUstepOutputServerList = @"GNUstepOutputServerList";

@interface PreferencesController (PrivateMethods)
- (void)buttonClicked: (NSMatrix *)aCell;

- (void)registerPreferencesModule: aPreferencesModule;
- (void)unregisterPreferencesModule: aPreferencesModule;

- (void)preferencesModuleAdded: (NSNotification *)aNotification;
- (void)preferencesModuleRemoved: (NSNotification *)aNotification;
@end

@implementation PreferencesController
- init
{
	if (!(self = [super init])) return self;

	prefsModules = [NSMutableArray new];

	if (![NSBundle loadNibNamed: @"Preferences" owner: self])
	{
		[self dealloc];
		return nil;
	}

	defaultPreferences = [[NSMutableDictionary alloc] initWithContentsOfFile: 
	  [[NSBundle bundleForClass: [GNUstepOutput class]] 
	  pathForResource: @"Defaults"
	  ofType: @"plist"]];

	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(preferencesModuleAdded:)
	  name: PreferencesModuleAdditionNotification
	  object: nil];

	[[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(preferencesModuleRemoved:)
	  name: PreferencesModuleRemovalNotification
	  object: nil];

	return self;
}	
- (void)awakeFromNib
{
	/* much of this setup code was shamelessly ripped
	 * from preferences.app.  Why redo what works
	 * so nicely? 
	 */
	prefsList = AUTORELEASE([[NSMatrix alloc] initWithFrame: 
	  NSMakeRect(0, 0, 64*30, 64) mode: NSRadioModeMatrix cellClass: [NSButtonCell class]
	  numberOfRows: 1 numberOfColumns: 0]);
	[prefsList setCellSize: NSMakeSize(64, 64)];
	[prefsList setIntercellSpacing: NSZeroSize];

	[labelBox setAutoresizesSubviews: YES];
	[[labelBox contentView] setAutoresizingMask: 
	  NSViewHeightSizable | NSViewWidthSizable];

	[prefsList setTarget: self];
	[prefsList setAction: @selector(buttonClicked:)];
	
	[scrollView setDocumentView: prefsList];
	[scrollView setHasHorizontalScroller: YES];
	[scrollView setHasVerticalScroller: NO];
	[scrollView setBorderType: NSBezelBorder];
}
- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	DESTROY(window);
	DESTROY(prefsModules);

	[super dealloc];
}
- setPreference: (id)aPreference forKey: (NSString *)aKey
{
	if ([aKey hasPrefix: @"GNUstepOutput"])
	{
		NSMutableDictionary *aDict = AUTORELEASE([NSMutableDictionary new]);
		id newKey = [aKey substringFromIndex: 13];
		id y;
		
		if ((y = [[NSUserDefaults standardUserDefaults] 
			  objectForKey: @"GNUstepOutput"]))
		{
			[aDict addEntriesFromDictionary: y];
		}
		
		if (aPreference)
		{
			[aDict setObject: aPreference forKey: newKey];
		}
		else
		{
			[aDict removeObjectForKey: newKey];
		}
		
		[[NSUserDefaults standardUserDefaults]
		   setObject: aDict forKey: @"GNUstepOutput"];
	}
	else
	{
		if (aPreference)
		{
			[[NSUserDefaults standardUserDefaults]
			  setObject: aPreference forKey: aKey];
		}
		else
		{
			[[NSUserDefaults standardUserDefaults]
			  removeObjectForKey: aKey];
		}
	}
	
	return self;
}		
- (id)preferenceForKey: (NSString *)aKey
{
	id z;
	
	if ([aKey hasPrefix: @"GNUstepOutput"])
	{
		NSDictionary *y;
		id newKey = [aKey substringFromIndex: 13];
		
		y = [[NSUserDefaults standardUserDefaults] 
		   objectForKey: @"GNUstepOutput"];
		
		if ((z = [y objectForKey: newKey]))
		{
			return z;
		}
		
		z = [defaultPreferences objectForKey: newKey];
		
		[self setPreference: z forKey: aKey];
		
		return z;
	}
	
	if ((z = [[NSUserDefaults standardUserDefaults]
	     objectForKey: aKey]))
	{
		return z;
	}
	
	z = [defaultPreferences objectForKey: aKey];
	
	[self setPreference: z forKey: aKey];
	
	return z;
}
- (id)defaultPreferenceForKey: (NSString *)aKey
{
	if ([aKey hasPrefix: @"GNUstepOutput"])
	{
		aKey = [aKey substringFromIndex: 13];
	}
	return [defaultPreferences objectForKey: aKey];
}	  
- (NSWindow *)window 
{
	return window;
}
@end

@implementation PreferencesController (PrivateMethods)
- (void)buttonClicked: (NSMatrix *)aMatrix
{
	id array = [prefsList cells];
	int index;
	id module;
	id object;
	NSView *view;
	NSEnumerator *iter;
	NSButtonCell *aCell;

	aCell = [aMatrix selectedCell];

	if (![array containsObject: aCell])
		return;

	index = [array indexOfObject: aCell];

	if (index >= [prefsModules count])
		return;

	module = [prefsModules objectAtIndex: index];

	if (currentPrefs == module) 
		return;

	view = [module preferencesView];
	if (!view) 
		return;

	[currentPrefs deactivate];
	iter = [[preferencesView subviews] objectEnumerator];
	while ((object = [iter nextObject])) 
	{
		[object removeFromSuperview];
	}

	[view setFrame: [preferencesView frame]];
	[view setFrameOrigin: NSMakePoint(0,0)];
	[preferencesView addSubview: view];
	currentPrefs = module;
	[labelBox setTitle: [module preferencesName]];
	[module activate: self];
}
- (void)registerPreferencesModule: aPreferencesModule
{
	id bCell;
	id icon;
	id name;
	
	if (!(aPreferencesModule)) 
		return;
	
	if (!(icon = [aPreferencesModule preferencesIcon]))
		return;

	if (!(name = [aPreferencesModule preferencesName]))
		return;

	bCell = AUTORELEASE([NSButtonCell new]);
	if (!(bCell))
		return;

	[bCell setImage: icon];
	[bCell setButtonType: NSOnOffButton];
	[bCell setTitle: name];
	[bCell setImagePosition: NSImageOnly];
	[bCell setShowsStateBy: NSPushInCellMask];
	[bCell setBordered: YES];
	[bCell setBezelStyle: NSRegularSquareBezelStyle];

	[prefsModules addObject: aPreferencesModule];
	[prefsList addColumnWithCells: [NSArray arrayWithObject: bCell]];
	[prefsList sizeToCells];
	[prefsList setNeedsDisplay: YES];

	// If its the first one, we should auto-click it
	if ([prefsModules count] == 1)
	{
		[prefsList selectCellAtRow: 0 column: 0];
		[self buttonClicked: prefsList];
		[window makeFirstResponder: prefsList];
	}
}
- (void)unregisterPreferencesModule: aPreferencesModule
{
	int index;
	if (!(aPreferencesModule))
		return;

	if (!([prefsModules containsObject: aPreferencesModule]))
		return;

	index = [prefsModules indexOfObject: aPreferencesModule];

	if (index == [prefsList selectedColumn])
	{
		[prefsList selectCellAtRow: 0 column: 0];
		[self buttonClicked: prefsList];
		[window makeFirstResponder: prefsList];
	}

	[prefsModules removeObjectAtIndex: index];
	[prefsList removeColumn: index];
	[prefsList sizeToCells];
	[prefsList setNeedsDisplay: YES];
}
- (void)preferencesModuleAdded: (NSNotification *)aNotification
{
	id object;

	if (![[aNotification name] isEqualToString: PreferencesModuleAdditionNotification])
		return;

	if (!(object = [aNotification object]))
		return;

	[self registerPreferencesModule: object];
}	
- (void)preferencesModuleRemoved: (NSNotification *)aNotification;
{
	id object;

	if (![[aNotification name] isEqualToString: PreferencesModuleRemovalNotification])
		return;

	if (!(object = [aNotification object]))
		return;

	[self unregisterPreferencesModule: object];
}
@end
