/***************************************************************************
                                ServerListController.m
                          -------------------
    begin                : Wed Apr 30 14:30:59 CDT 2003
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

#import "Controllers/ServerListController.h"
#import "Controllers/GroupEditorController.h"
#import "Controllers/ServerEditorController.h"
#import "Controllers/ServerListConnectionController.h"
#import "Controllers/ContentControllers/ContentController.h"
#import "GNUstepOutput.h"

#import <Foundation/NSNotification.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSPathUtilities.h>
#import <AppKit/NSButton.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSTableColumn.h>
#import <AppKit/NSScrollView.h>
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSTextField.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSBrowser.h>
#import <AppKit/NSBrowserCell.h>
#import <AppKit/NSTextView.h>

NSString *ServerListInfoEncoding = @"Encoding";
NSString *ServerListInfoWindowFrame = @"WindowFrame";
NSString *ServerListInfoCommands = @"Commands";
NSString *ServerListInfoServer = @"Server";
NSString *ServerListInfoPort = @"Port";
NSString *ServerListInfoName = @"Name";
NSString *ServerListInfoEntries = @"Entries";
NSString *ServerListInfoAutoConnect = @"AutoConnect";

static id mutable_object(id object)
{
	if ( [object isKindOfClass: [NSString class]] && 
	    ![object isKindOfClass: [NSMutableString class]])
	{
		return [NSMutableString stringWithString: object];
	} 
	else if ( [object isKindOfClass: [NSDictionary class]] )
	{
		id dict = [NSMutableDictionary dictionaryWithCapacity: [object count]];
		id iter;
		id iterobj;

		iter = [object keyEnumerator];
		while ((iterobj = [iter nextObject]))
		{
			[dict setObject: mutable_object([object objectForKey: iterobj])
			  forKey: iterobj];
		}

		return dict;
	}
	else if ( [ object isKindOfClass: [NSArray class]] )
	{
		id arr = [NSMutableArray arrayWithCapacity: [object count]];
		id iter;
		id iterobj;

		iter = [object objectEnumerator];
		while ((iterobj = [iter nextObject]))
		{
			[arr addObject: mutable_object(iterobj)];
		}

		return arr;
	}
	
	return object;
}

static int sort_server_dictionary(id first, id second, void *x)
{
	return [[first objectForKey: ServerListInfoName] caseInsensitiveCompare:
	  [second objectForKey: ServerListInfoName]];
}

@implementation ServerListController
+ (BOOL)saveServerListPreferences: (NSArray *)aPrefs
{
	NSArray *x;
	NSFileManager *fm;
	NSEnumerator *iter;
	id object;
	BOOL isDir;

	if (!aPrefs) return NO;

	x = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
	  NSUserDomainMask, YES);

	fm = [NSFileManager defaultManager];

	iter = [x objectEnumerator];

	while ((object = [iter nextObject]))
	{
		object = [object stringByAppendingString:
#ifdef GNUSTEP
		  @"/ApplicationSupport/"
#else
		  @"/Application Support/"
#endif
		  @"TalkSoup/Output/GNUstepOutput/Resources"
		];

		if ([fm fileExistsAtPath: object isDirectory: &isDir] && isDir)
		{
			id dict = AUTORELEASE([NSMutableDictionary new]);
			object = [object stringByAppendingString: @"ServerList.plist"];

			[dict setObject: aPrefs forKey: @"Servers"];
			
			if ([dict writeToFile: object atomically: YES])
			{
				return YES;
			}
		}
	}

	return NO;
}
+ (NSMutableArray *)serverListPreferences
{
	NSArray *x;
	NSFileManager *fm;
	NSEnumerator *iter;
	id object;
	BOOL isDir;

	x = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
	  NSAllDomainsMask, YES);

	fm = [NSFileManager defaultManager];

	iter = [x objectEnumerator];

	while ((object = [iter nextObject]))
	{
		object = [object stringByAppendingString:
#ifdef GNUSTEP
		  @"/ApplicationSupport/"
#else
		  @"/Application Support/"
#endif
		  @"TalkSoup/Output/GNUstepOutput/Resources/ServerList.plist"
		];

		if ([fm fileExistsAtPath: object isDirectory: &isDir] && !isDir)
		{
			id dict = [NSDictionary dictionaryWithContentsOfFile: object];
			id obj;
			
			if (dict && (obj = [dict objectForKey: @"Servers"])
			 && [obj isKindOfClass: [NSArray class]])
			{
				return mutable_object(obj);
			}
		}
	}

	return AUTORELEASE([NSMutableArray new]);
}
+ (BOOL)startAutoconnectServers
{
	id tmp = [ServerListController serverListPreferences];
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
				 initWithServerListDictionary: o2 inGroup: g atRow: r
				 withContentController: nil]);
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
	id tmp = [ServerListController serverListPreferences];
	
	if (group >= (int)[tmp count] || group < 0) return nil;
	
	tmp = [[tmp objectAtIndex: group] 
	  objectForKey: ServerListInfoEntries];
	
	if (row >= (int)[tmp count] || row < 0) return nil;
	
	return [tmp objectAtIndex: row];
}
+ (void)setServer: (NSDictionary *)x inGroup: (int)group row: (int)row
{
	id tmp = [ServerListController serverListPreferences]; 
	id array;
	
	if (group >= (int)[tmp count] || group < 0) return;
	
	array = [[tmp objectAtIndex: group]
	  objectForKey: ServerListInfoEntries];
	  
	if (row >= (int)[tmp count] || row < 0) return;
	
	[array replaceObjectAtIndex: row withObject: x];

	[ServerListController saveServerListPreferences: tmp];
}
+ (BOOL)serverFound: (NSDictionary *)x inGroup: (int *)group row: (int *)row
{
	id tmp = [ServerListController serverListPreferences];
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
	id tmp;
	
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
	
	tmp = [ServerListController serverListPreferences];
	[tmp sortUsingFunction: sort_server_dictionary context: 0]; 
	[ServerListController saveServerListPreferences: tmp];
	[browser reloadColumn: 0];
	
	[_GS_ addServerList: self];
	
	wasEditing = -1;
}
- (void)dealloc
{
	RELEASE(window);
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
	
	if ([editor isKindOfClass: [GroupEditorController class]])
	{
		NSMutableArray *x;
		id newOne;
		x = [ServerListController serverListPreferences];
		
		if (wasEditing != -1 && wasEditing < (int)[x count])
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
		[ServerListController saveServerListPreferences: x];
	
		[browser reloadColumn: 0]; 
		
		[[editor window] close];
		[window makeKeyAndOrderFront: nil];
	}
	else if ([editor isKindOfClass: [ServerEditorController class]])
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
		id prefs = [ServerListController serverListPreferences];
		
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
		
		if (first >= (int)[prefs count] || first < 0)
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
				
		if (wasEditing != -1 && wasEditing < (int)[array count])
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
		[ServerListController saveServerListPreferences: prefs];
	
		[browser reloadColumn: 1]; 
		
		[[editor window] close];
		[window makeKeyAndOrderFront: nil];
	}
}
- (void)addEntryHit: (NSButton *)sender
{
	if (editor)
	{
		if ([editor isKindOf: [ServerEditorController class]])
		{
			[[editor window] makeKeyAndOrderFront: nil];
			return;
		}
		else
		{
			[[editor window] close];
		}
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
		if ([editor isKindOf: [GroupEditorController class]])
		{
			[[editor window] makeKeyAndOrderFront: nil];
			return;
		}
		else
		{
			[[editor window] close];
		}
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
	id tmp = [ServerListController serverListPreferences]; 
	int row;
	id o;

	if ([browser selectedColumn] == 0)
	{
		row = [browser selectedRowInColumn: 0];
		
		if (row >= (int)[tmp count] || row < 0) return;
		
		[self addGroupHit: nil];
		
		o = [tmp objectAtIndex: row];
		[[editor entryField] setStringValue: [o objectForKey: ServerListInfoName]];
		
		wasEditing = row;
	}
	else
	{
		int first = [browser selectedRowInColumn: 0];
		row = [browser selectedRowInColumn: 1];
		
		if (first >= (int)[tmp count] || first < 0) return;
		
		o = [[tmp objectAtIndex: first] objectForKey: ServerListInfoEntries];
		
		if (row >= (int)[o count] || row < 0) return;
		
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
	id prefs = [ServerListController serverListPreferences];
	int row;
	
	if ([browser selectedColumn] == 0)
	{
		row = [browser selectedRowInColumn: 0];
		
		if (row >= (int)[prefs count]) return;
		
		[prefs removeObjectAtIndex: row];
		
		[ServerListController saveServerListPreferences: prefs];
	
		[browser reloadColumn: 0];
	}
	else
	{
		id x;
		int first = [browser selectedRowInColumn: 0];
		row = [browser selectedRowInColumn: 1];
		
		if (first >= (int)[prefs count]) return;
		
		x = [[prefs objectAtIndex: first] objectForKey: ServerListInfoEntries];
		
		if (row >= (int)[x count]) return;
		
		[x removeObjectAtIndex: row];
		
		[ServerListController saveServerListPreferences: prefs];
	
		[browser reloadColumn: 1];
	}		
}
- (void)connectHit: (NSButton *)sender
{
	id tmp = [ServerListController serverListPreferences];
	id win;
	id aContent = nil;
	
	int first, row;
	if ([browser selectedColumn] != 1) return;
	
	first = [browser selectedRowInColumn: 0];
	row = [browser selectedRowInColumn: 1];
	
	if (first >= (int)[tmp count]) return;
	
	tmp = [[tmp objectAtIndex: first] objectForKey: ServerListInfoEntries];
	
	if (row >= (int)[tmp count]) return;

	if ([forceButton state] == NSOffState)
	{
		id tmpArray;
		tmpArray = [_GS_ unconnectedConnectionControllers];
		if ([tmpArray count])
		{
			aContent = RETAIN([[tmpArray objectAtIndex: 0] contentController]);
			AUTORELEASE(aContent);
			[[aContent window] close]; // Cause the connection controller to
			                           // die
		}
	}	

	AUTORELEASE(win = [[ServerListConnectionController alloc]
	  initWithServerListDictionary: [tmp objectAtIndex: row]
	  inGroup: first atRow: row withContentController: aContent]);

	// FIXME win = [[win contentController] window];
	
	[[editor window] close];
	[window close];

	// [win makeKeyAndOrderFront: nil];	
}
- (void)forceHit: (NSButton *)sender
{
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
		AUTORELEASE(RETAIN(self));
		[_GS_ removeServerList: self];
	}
	else if ([aNotification object] == [editor window])
	{
		[[editor window] setDelegate: nil];
		[[editor okButton] setTarget: nil];
		AUTORELEASE(editor);
		editor = nil;
		wasEditing = -1;
	}
}	
@end

@interface ServerListController (BrowserDelegate)
@end

@implementation ServerListController (BrowserDelegate)
- (int)browser: (NSBrowser *)sender numberOfRowsInColumn: (int)column
{
	id serverList = [ServerListController serverListPreferences]; 
	
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
		
		if (col >= (int)[serverList count])
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
	id serverList = [ServerListController serverListPreferences]; 

	if (!serverList) return;
	
	if (column == 0)
	{
		id tmp;
		
		if (row >= (int)[serverList count]) return;
		
		tmp = [serverList objectAtIndex: row];
		[cell setStringValue: [tmp objectForKey: ServerListInfoName]];
		[cell setLeaf: NO];
	}
	else if (column == 1)
	{
		id tmp;
		int first;
		
		first = [sender selectedRowInColumn: 0];
		
		if (first >= (int)[serverList count]) return;
		
		tmp = [serverList objectAtIndex: first];
		tmp = [tmp objectForKey: ServerListInfoEntries];
		
		if (row >= (int)[tmp count]) return;
		
		tmp = [tmp objectAtIndex: row];
		
		[cell setStringValue: [tmp objectForKey: ServerListInfoName]];
		[cell setLeaf: YES];
	}
	[cell setFont: [NSFont userFontOfSize: 0.0]];
}

@end
