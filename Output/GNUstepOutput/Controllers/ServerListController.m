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
#include "Controllers/ServerListConnectionController.h"
#include "Controllers/ContentController.h"
#include "GNUstepOutput.h"

#include <Foundation/NSNotification.h>
#include <Foundation/NSEnumerator.h>
#include <AppKit/NSButton.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSTableColumn.h>
#include <AppKit/NSScrollView.h>
#include <AppKit/NSNibLoading.h>
#include <AppKit/NSTextField.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSBrowser.h>
#include <AppKit/NSBrowserCell.h>
#include <AppKit/NSTextView.h>

NSString *ServerListInfoEncoding = @"Encoding";
NSString *ServerListInfoWindowFrame = @"WindowFrame";
NSString *ServerListInfoCommands = @"Commands";
NSString *ServerListInfoServer = @"Server";
NSString *ServerListInfoPort = @"Port";
NSString *ServerListInfoName = @"Name";
NSString *ServerListInfoEntries = @"Entries";
NSString *ServerListInfoAutoConnect = @"AutoConnect";

static inline NSMutableArray *mutablized_prefs()
{
	id tmp = [_GS_ defaultsObjectForKey:
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
		
		t1 = [o1 objectForKey: ServerListInfoEntries];
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
		
		[o1 setObject: t2 forKey: ServerListInfoEntries];
		
		[work addObject: o1];
	}
	
	return work;
}
static int sort_server_dictionary(id first, id second, void *x)
{
	return [[first objectForKey: ServerListInfoName] caseInsensitiveCompare:
	  [second objectForKey: ServerListInfoName]];
}

@implementation ServerListController
+ (BOOL)startAutoconnectServers
{
	id tmp = [_GS_ defaultsObjectForKey:
		  GNUstepOutputServerList];
	NSEnumerator *iter;
	NSEnumerator *iter2;
	BOOL hadOne = NO;
	id o1, o2;
	int g = 0, r; 
	
	iter = [tmp objectEnumerator];
	while ((o1 = [iter nextObject]))
	{
		iter2 = [[o1 objectForKey: ServerListInfoEntries] objectEnumerator];
		r = 0;
		while ((o2 = [iter2 nextObject]))
		{
			if ([[o2 objectForKey: ServerListInfoAutoConnect]
			  isEqualToString: @"YES"])
			{
				AUTORELEASE([[ServerListConnectionController alloc]
				 initWithServerListDictionary: o2 inGroup: g atRow: r]);
				hadOne = YES;
			}	
			r++;
		}
		g++;
	}

	return hadOne;
}
+ (NSDictionary *)serverInGroup: (int)group row: (int)row
{
	id tmp = [_GS_ defaultsObjectForKey:
		  GNUstepOutputServerList];
	
	if (group >= [tmp count] || group < 0) return nil;
	
	tmp = [[tmp objectAtIndex: group] 
	  objectForKey: ServerListInfoEntries];
	
	if (row >= [tmp count] || row < 0) return nil;
	
	return [tmp objectAtIndex: row];
}
+ (void)setServer: (NSDictionary *)x inGroup: (int)group row: (int)row
{
	id tmp = mutablized_prefs();
	id array;
	
	if (group >= [tmp count] || group < 0) return;
	
	array = [[tmp objectAtIndex: group]
	  objectForKey: ServerListInfoEntries];
	  
	if (row >= [tmp count] || row < 0) return;
	
	[array replaceObjectAtIndex: row withObject: x];

	[_GS_ setDefaultsObject: tmp forKey: 
	  GNUstepOutputServerList];
}
+ (BOOL)serverFound: (NSDictionary *)x inGroup: (int *)group row: (int *)row
{
	id tmp = [_GS_ defaultsObjectForKey:
		  GNUstepOutputServerList];
	NSEnumerator *iter;
	NSEnumerator *iter2;
	id o1, o2;
	int g = 0, r;
	
	iter = [tmp objectEnumerator];
	while ((o1 = [iter nextObject]))
	{
		iter2 = [[o1 objectForKey: ServerListInfoEntries] objectEnumerator];
		r = 0;
		while ((o2 = [iter2 nextObject]))
		{
			if ([o2 isEqual: x])
			{
				if (group) *group = g;
				if (row) *row = r;
				return YES;
			}
			r++;
		}
		g++;
	}
	
	return NO;
}
- (void)awakeFromNib
{
	[browser setMaxVisibleColumns: 2];
	[browser setHasHorizontalScroller: NO];
	[browser setAllowsMultipleSelection: NO];
	[browser setAllowsEmptySelection: NO];
	[browser setAllowsBranchSelection: NO];
	
	[browser setDoubleAction: @selector(connectHit:)];
	[browser setDelegate: self];
	[browser setTarget: self];
	[window setDelegate: self];
	[window makeKeyAndOrderFront: nil];
	
	[_GS_ addServerList: self];
	
	wasEditing = -1;
}
- (void)dealloc
{
/* FIXME	[browser setDelegate: nil]; */
	[browser setDoubleAction: 0];
	[browser setTarget: nil];
	RELEASE(browser);
	RELEASE(scrollView);
	RELEASE(addGroupButton);
	RELEASE(removeButton);
	RELEASE(addEntryButton);
	RELEASE(editButton);
	RELEASE(serverColumn);
	RELEASE(connectButton);
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
		  _l(@"Specify entry name")];
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
			[newOne setObject: string forKey: ServerListInfoName];
			
			[x replaceObjectAtIndex: wasEditing withObject: newOne];
		}
		else
		{
			newOne = [NSDictionary dictionaryWithObjectsAndKeys:
			  string, ServerListInfoName,
			  AUTORELEASE([NSArray new]), ServerListInfoEntries,
			  nil];

			[x addObject: newOne]; 
		}
	
		[x sortUsingFunction: sort_server_dictionary context: 0]; 
		[_GS_ setDefaultsObject: x
		 forKey: GNUstepOutputServerList];
	
		[browser reloadColumn: 0]; 
		
		[[editor window] close];
		[window makeKeyAndOrderFront: nil];
	}
	else if ([editor isKindOf: [ServerEditorController class]])
	{
		id server = [[editor serverField] stringValue];
		id commands = [[editor commandsText] string];
		id nick = [[editor nickField] stringValue];
		id user = [[editor userField] stringValue];
		id real = [[editor realField] stringValue];
		id password = [[editor passwordField] stringValue];
		id port = [[editor portField] stringValue];
		int first = [browser selectedRowInColumn: 0];
		id autoconnect;
		
		id array;
		id newOne;
		id prefs = mutablized_prefs();
		
		if ([server length] == 0)
		{
			[[editor extraField] setStringValue: 
			  _l(@"Specify the server")];
			[[editor window] makeFirstResponder: [editor serverField]];
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
		
		if ([[editor connectButton] state] == NSOnState)
		{
			autoconnect = @"YES";
		}
		else
		{
			autoconnect = @"NO";
		}
		
		array = [[prefs objectAtIndex: first] objectForKey: ServerListInfoEntries];
				
		if (wasEditing != -1 || wasEditing < [array count])
		{
			newOne = [array objectAtIndex: wasEditing];
			[newOne setObject: server forKey: ServerListInfoServer];
			[newOne setObject: commands forKey: ServerListInfoCommands];
			[newOne setObject: nick forKey: IRCDefaultsNick];
			[newOne setObject: real forKey: IRCDefaultsRealName];
			[newOne setObject: password forKey: IRCDefaultsPassword];
			[newOne setObject: user forKey: IRCDefaultsUserName];
			[newOne setObject: port forKey: ServerListInfoPort];
			[newOne setObject: string forKey: ServerListInfoName];
			[newOne setObject: autoconnect forKey: ServerListInfoAutoConnect];
			[array replaceObjectAtIndex: wasEditing withObject: newOne];
		}
		else
		{
			newOne = [NSDictionary dictionaryWithObjectsAndKeys:
			 server, ServerListInfoServer,
			 commands, ServerListInfoCommands,
			 nick, IRCDefaultsNick,
			 real, IRCDefaultsRealName,
			 password, IRCDefaultsPassword,
			 user, IRCDefaultsUserName,
			 port, ServerListInfoPort,
			 string, ServerListInfoName,
			 autoconnect, ServerListInfoAutoConnect,
			 nil];
			[array addObject: newOne];
		}
	
		[array sortUsingFunction: sort_server_dictionary context: 0];
		[_GS_ setDefaultsObject: prefs
		 forKey: GNUstepOutputServerList];
	
		[browser reloadColumn: 1]; 
		
		[[editor window] close];
		[window makeKeyAndOrderFront: nil];
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
	id tmp = [_GS_ defaultsObjectForKey:
	  GNUstepOutputServerList];
	int row;
	id o;

	if ([browser selectedColumn] == 0)
	{
		row = [browser selectedRowInColumn: 0];
		
		if (row >= [tmp count] || row < 0) return;
		
		[self addGroupHit: nil];
		
		o = [tmp objectAtIndex: row];
		[[editor entryField] setStringValue: [o objectForKey: ServerListInfoName]];
		
		wasEditing = row;
	}
	else
	{
		int first = [browser selectedRowInColumn: 0];
		row = [browser selectedRowInColumn: 1];
		
		if (first >= [tmp count] || first < 0) return;
		
		o = [[tmp objectAtIndex: first] objectForKey: ServerListInfoEntries];
		
		if (row >= [o count] || row < 0) return;
		
		[self addEntryHit: nil];

		o = [o objectAtIndex: row];
		
		[[editor entryField] setStringValue: [o objectForKey: ServerListInfoName]]; 
		[[editor nickField] setStringValue: [o objectForKey: IRCDefaultsNick]]; 
		[[editor realField] setStringValue: [o objectForKey: IRCDefaultsRealName]]; 
		[[editor passwordField] setStringValue: [o objectForKey: IRCDefaultsPassword]]; 
		[[editor userField] setStringValue: [o objectForKey: IRCDefaultsUserName]]; 
		[[editor serverField] setStringValue: [o objectForKey: ServerListInfoServer]]; 
		[[editor portField] setStringValue: [o objectForKey: ServerListInfoPort]];
		[[editor commandsText] setString: [o objectForKey: ServerListInfoCommands]];
		if ([[o objectForKey: ServerListInfoAutoConnect] isEqualToString: @"YES"])
		{
			[[editor connectButton] setState: NSOnState];
		}
		else
		{
			[[editor connectButton] setState: NSOffState];
		}
		
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
		
		[_GS_ setDefaultsObject: prefs
		 forKey: GNUstepOutputServerList];
	
		[browser reloadColumn: 0];
	}
	else
	{
		id x;
		int first = [browser selectedRowInColumn: 0];
		row = [browser selectedRowInColumn: 1];
		
		if (first >= [prefs count]) return;
		
		x = [[prefs objectAtIndex: first] objectForKey: ServerListInfoEntries];
		
		if (row >= [x count]) return;
		
		[x removeObjectAtIndex: row];
		
		[_GS_ setDefaultsObject: prefs
		 forKey: GNUstepOutputServerList];
	
		[browser reloadColumn: 1];
	}		
}
- (void)connectHit: (NSButton *)sender
{
	id tmp = [_GS_ defaultsObjectForKey:
	  GNUstepOutputServerList];
	id win;
	
	int first, row;
	if ([browser selectedColumn] != 1) return;
	
	first = [browser selectedRowInColumn: 0];
	row = [browser selectedRowInColumn: 1];
	
	if (first >= [tmp count]) return;
	
	tmp = [[tmp objectAtIndex: first] objectForKey: ServerListInfoEntries];
	
	if (row >= [tmp count]) return;

	AUTORELEASE(win = [[ServerListConnectionController alloc]
	  initWithServerListDictionary: [tmp objectAtIndex: row]
	  inGroup: first atRow: row]);

	win = [[win contentController] window];
	
	[[editor window] close];
	[window close];

	[win makeKeyAndOrderFront: nil];	
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
		/* FIXME [browser setDelegate: nil]; */
		[browser setTarget: nil];
		DESTROY(window);
		[_GS_ removeServerList: self];
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
	id serverList = [_GS_ defaultsObjectForKey:
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
		
		group = [group objectForKey: ServerListInfoEntries];
		
		return [group count];
	}
		
	return 0;	
}
- (NSString *)browser: (NSBrowser *)sender titleOfColumn: (int)column
{
	if (column == 0)
	{
		return _l(@"Groups");
	}
	if (column == 1)
	{
		return _l(@"Servers");
	}
	
	return @"";
}
- (void)browser: (NSBrowser *)sender willDisplayCell: (id)cell
  atRow: (int)row column: (int)column
{
	id serverList = [_GS_ defaultsObjectForKey:
	  GNUstepOutputServerList];

	if (!serverList) return;
	
	if (column == 0)
	{
		id tmp;
		
		if (row >= [serverList count]) return;
		
		tmp = [serverList objectAtIndex: row];
		[cell setStringValue: [tmp objectForKey: ServerListInfoName]];
		[cell setLeaf: NO];
	}
	else if (column == 1)
	{
		id tmp;
		int first;
		
		first = [sender selectedRowInColumn: 0];
		
		if (first >= [serverList count]) return;
		
		tmp = [serverList objectAtIndex: first];
		tmp = [tmp objectForKey: ServerListInfoEntries];
		
		if (row >= [tmp count]) return;
		
		tmp = [tmp objectAtIndex: row];
		
		[cell setStringValue: [tmp objectForKey: ServerListInfoName]];
		[cell setLeaf: YES];
	}
	[cell setFont: [NSFont userFontOfSize: 0.0]];
}

@end
