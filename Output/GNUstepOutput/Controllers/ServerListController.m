/***************************************************************************
                                ServerListController.m
                          -------------------
    begin                : Wed Apr 30 14:30:59 CDT 2003
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

#include "Controllers/ServerListController.h"
#include "Controllers/GroupEditorController.h"
#include "Controllers/ServerEditorController.h"
#include "GNUstepOutput.h"

#include <Foundation/NSNotification.h>
#include <AppKit/NSButton.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSTableColumn.h>
#include <AppKit/NSScrollView.h>
#include <AppKit/NSNibLoading.h>
#include <AppKit/NSTextField.h>
#include <AppKit/NSBrowser.h>
#include <AppKit/NSBrowserCell.h>

static inline NSMutableArray *mutablized_prefs()
{
	id tmp = [[_TS_ pluginForOutput] defaultsObjectForKey:
		  GNUstepOutputServerList];
	NSEnumerator *iter, *iter2;
	id o1, o2;
	id t1, t2;
	id work = AUTORELEASE([NSMutableArray new]);
	
	if (!tmp) return work;
	
	iter = [tmp objectEnumerator];
	
	while ((o1 = [iter nextObject]))
	{
		o1 = [NSMutableDictionary dictionaryWithDictionary: o1];
		
		t1 = [o1 objectForKey: @"Entries"];
		if (!t1)
		{
			t2 = AUTORELEASE([NSMutableArray new]);
		}
		else
		{
			t2 = AUTORELEASE([NSMutableArray new]);
			iter2 = [t1 objectEnumerator];
			while ((o2 = [iter2 nextObject]))
			{
				o2 = [NSMutableDictionary dictionaryWithDictionary: o2];
				[t2 addObject: o2];
			}
		}
		
		[o1 setObject: t2 forKey: @"Entries"];
		
		[work addObject: o1];
	}
	
	return work;
}

@implementation ServerListController
- (void)awakeFromNib
{
	[browser setMaxVisibleColumns: 2];
	[browser setHasHorizontalScroller: NO];
	[browser setAllowsMultipleSelection: NO];
	[browser setAllowsEmptySelection: NO];
	[browser setAllowsBranchSelection: NO];
	
	[browser setDelegate: self];
	[window setDelegate: self];
	RETAIN(self);
	[window makeKeyAndOrderFront: nil];
	
	wasEditing = -1;
}
- (void)dealloc
{
	[browser setDelegate: nil];
	RELEASE(browser);
	RELEASE(scrollView);
	RELEASE(addGroupButton);
	RELEASE(removeButton);
	RELEASE(addEntryButton);
	RELEASE(editButton);
	RELEASE(serverColumn);
	RELEASE(connectButton);
	[window close];
	[[editor window] close];
	
	[super dealloc];
}
- (void)editorDone: (id)sender
{
	id string;
	
	if (!editor) return;
	
	string = [[editor entryField] stringValue];
	
	if ([string length] == 0)
	{
		[[editor extraField] setStringValue:
		  @"Specify entry name"];
		[[editor window] makeFirstResponder: [editor entryField]]; 
		return;
	}
	
	if ([editor isKindOf: [GroupEditorController class]])
	{
		NSMutableArray *x;
		id newOne;
		x = mutablized_prefs();
		
		if (wasEditing != -1 && wasEditing < [x count])
		{
			newOne = [x objectAtIndex: wasEditing];
			[newOne setObject: string forKey: @"Name"];
			
			[x replaceObjectAtIndex: wasEditing withObject: newOne];
		}
		else
		{
			newOne = [NSDictionary dictionaryWithObjectsAndKeys:
			  string, @"Name",
			  AUTORELEASE([NSArray new]), @"Entries",
			  nil];

			[x addObject: newOne]; 
		}
	
		[[_TS_ pluginForOutput] setDefaultsObject: x
		 forKey: GNUstepOutputServerList];
	
		[browser reloadColumn: 0]; 
		
		[[editor window] close];
	}
	else if ([editor isKindOf: [ServerEditorController class]])
	{
		id server = [[editor serverField] stringValue];
		id commands = [[editor commandsField] stringValue];
		id nick = [[editor nickField] stringValue];
		id user = [[editor userField] stringValue];
		id real = [[editor realField] stringValue];
		id password = [[editor passwordField] stringValue];
		id port = [[editor portField] stringValue];
		int first = [browser selectedRowInColumn: 0];
		id array;
		id newOne;
		id prefs = mutablized_prefs();
		
		if ([server length] == 0)
		{
			[[editor extraField] setStringValue: 
			  @"Specify the server"];
			[[editor window] makeFirstResponder: [editor extraField]];
			return;
		}
		
		if ([port length] == 0)
		{
			port = @"6667";
		}
		
		if (first >= [prefs count] || first < 0)
		{			
			return;
		}
		
		array = [[prefs objectAtIndex: first] objectForKey: @"Entries"];
		
		newOne = [NSDictionary dictionaryWithObjectsAndKeys:
		  server, @"Server",
		  commands, @"Commands",
		  nick, IRCDefaultsNick,
		  real, IRCDefaultsRealName,
		  password, IRCDefaultsPassword,
		  user, IRCDefaultsUserName,
		  port, @"Port",
		  string, @"Name",
		  nil];
		
		if (wasEditing != -1 || wasEditing < [array count])
		{
			[array replaceObjectAtIndex: wasEditing withObject: newOne];
		}
		else
		{
			[array addObject: newOne];
		}
	
		[[_TS_ pluginForOutput] setDefaultsObject: prefs
		 forKey: GNUstepOutputServerList];
	
		[browser reloadColumn: 1]; 
		
		[[editor window] close];
	}
}
- (void)addEntryHit: (NSButton *)sender
{
	if (editor)
	{
		[[editor window] makeKeyAndOrderFront: nil];
		return;
	}
	
	if ([browser selectedColumn] < 0) return;
	
	editor = [[ServerEditorController alloc] init];
	if (![NSBundle loadNibNamed: @"ServerEditor" owner: editor])
	{
		DESTROY(editor);
		return;
	}
	
	[[editor window] setDelegate: self];
	[[editor okButton] setTarget: self];
	[[editor okButton] setAction: @selector(editorDone:)];
}
- (void)addGroupHit: (NSButton *)sender
{
	if (editor)
	{
		[[editor window] makeKeyAndOrderFront: nil];
		return;
	}
	
	editor = [[GroupEditorController alloc] init];
	if (![NSBundle loadNibNamed: @"GroupEditor" owner: editor])
	{
		DESTROY(editor);
		return;
	}
	
	[[editor window] setDelegate: self];
	[[editor okButton] setTarget: self];
	[[editor okButton] setAction: @selector(editorDone:)];
}
- (void)editHit: (NSButton *)sender
{
	id tmp = [[_TS_ pluginForOutput] defaultsObjectForKey:
	  GNUstepOutputServerList];
	int row;
	id o;

	if ([browser selectedColumn] == 0)
	{
		row = [browser selectedRowInColumn: 0];
		
		if (row >= [tmp count] || row < 0) return;
		
		[self addGroupHit: nil];
		
		o = [tmp objectAtIndex: row];
		[[editor entryField] setStringValue: [o objectForKey: @"Name"]];
		
		wasEditing = row;
	}
	else
	{
		int first = [browser selectedRowInColumn: 0];
		row = [browser selectedRowInColumn: 1];
		
		if (first >= [tmp count] || first < 0) return;
		
		o = [[tmp objectAtIndex: first] objectForKey: @"Entries"];
		
		if (row >= [o count] || row < 0) return;
		
		[self addEntryHit: nil];

		o = [o objectAtIndex: row];
		
		[[editor entryField] setStringValue: [o objectForKey: @"Name"]]; 
		[[editor nickField] setStringValue: [o objectForKey: IRCDefaultsNick]]; 
		[[editor realField] setStringValue: [o objectForKey: IRCDefaultsRealName]]; 
		[[editor passwordField] setStringValue: [o objectForKey: IRCDefaultsPassword]]; 
		[[editor userField] setStringValue: [o objectForKey: IRCDefaultsUserName]]; 
		[[editor serverField] setStringValue: [o objectForKey: @"Server"]]; 
		[[editor portField] setStringValue: [o objectForKey: @"Port"]];
		[[editor commandsField] setStringValue: [o objectForKey: @"Commands"]];
		
		wasEditing = row;
	}
}
- (void)removeHit: (NSButton *)sender
{
	id prefs = mutablized_prefs();
	int row;
	
	if ([browser selectedColumn] == 0)
	{
		row = [browser selectedRowInColumn: 0];
		
		if (row >= [prefs count]) return;
		
		[prefs removeObjectAtIndex: row];
		
		[[_TS_ pluginForOutput] setDefaultsObject: prefs
		 forKey: GNUstepOutputServerList];
	
		[browser reloadColumn: 0];
	}
	else
	{
		id x;
		int first = [browser selectedRowInColumn: 0];
		row = [browser selectedRowInColumn: 1];
		
		if (first >= [prefs count]) return;
		
		x = [[prefs objectAtIndex: first] objectForKey: @"Entries"];
		
		if (row >= [x count]) return;
		
		[x removeObjectAtIndex: row];
		
		[[_TS_ pluginForOutput] setDefaultsObject: prefs
		 forKey: GNUstepOutputServerList];
	
		[browser reloadColumn: 1];
	}		
}
- (void)connectHit: (NSButton *)sender
{
	NSLog(@"Connect button hit!");
}
- (NSBrowser *)browser
{
	return browser;
}
- (NSWindow *)window
{
	return window;
}
@end

@interface ServerListController (WindowDelegate)
@end

@implementation ServerListController (WindowDelegate)
- (void)windowWillClose: (NSNotification *)aNotification
{
	if ([aNotification object] == window)
	{
		[window setDelegate: nil];
		DESTROY(window);
		RELEASE(self);
	}
	else if ([aNotification object] == [editor window])
	{
		[[editor window] setDelegate: nil];
		[[editor okButton] setTarget: nil];
		DESTROY(editor);
		wasEditing = -1;
	}
}	
@end

@interface ServerListController (BrowserDelegate)
@end

@implementation ServerListController (BrowserDelegate)
- (int)browser: (NSBrowser *)sender numberOfRowsInColumn: (int)column
{
	id serverList = [[_TS_ pluginForOutput] defaultsObjectForKey:
	  GNUstepOutputServerList];
	
	if (!serverList)
	{
		return 0;
	}
	
	if (column == 0)
	{
		return [serverList count]; 
	}
	if (column == 1)
	{
		int col = [sender selectedRowInColumn: 0];
		id group;
		
		if (col >= [serverList count])
		{
			return 0;
		}
		
		group = [serverList objectAtIndex: col];
		
		group = [group objectForKey: @"Entries"];
		
		return [group count];
	}
		
	return 0;	
}
- (NSString *)browser: (NSBrowser *)sender titleOfColumn: (int)column
{
	if (column == 0)
	{
		return @"Groups";
	}
	if (column == 1)
	{
		return @"Entries";
	}
	
	return @"Unknown";
}
- (void)browser: (NSBrowser *)sender willDisplayCell: (id)cell
  atRow: (int)row column: (int)column
{
	id serverList = [[_TS_ pluginForOutput] defaultsObjectForKey:
	  GNUstepOutputServerList];

	if (!serverList) return;
	
	if (column == 0)
	{
		id tmp;
		
		if (row >= [serverList count]) return;
		
		tmp = [serverList objectAtIndex: row];
		[cell setStringValue: [tmp objectForKey: @"Name"]];
		[cell setLeaf: NO];
	}
	else if (column == 1)
	{
		id tmp;
		int first;
		
		first = [sender selectedRowInColumn: 0];
		
		if (first >= [serverList count]) return;
		
		tmp = [serverList objectAtIndex: first];
		tmp = [tmp objectForKey: @"Entries"];
		
		if (row >= [tmp count]) return;
		
		tmp = [tmp objectAtIndex: row];
		
		[cell setStringValue: [tmp objectForKey: @"Name"]];
		[cell setLeaf: YES];
	}
}
@end
