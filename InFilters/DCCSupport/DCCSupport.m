/***************************************************************************
                              DCCSupport.m
                          -------------------
    begin                : Wed Jul 2 18:58:30 CDT 2003
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

#import <TalkSoupBundles/TalkSoup.h>
#import <netclasses/NetTCP.h>
#import "DCCObject.h"
#import "DCCSupport.h"
#import "DCCSupportPreferencesController.h"
#import "DCCSender.h"
#import "DCCGetter.h"

#import <Foundation/NSAttributedString.h>
#import <Foundation/NSInvocation.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSFileHandle.h>
#import <Foundation/NSTimer.h>
#import <Foundation/NSHost.h>
#import <Foundation/NSString.h>
#import <Foundation/NSData.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSBundle.h>

#include <string.h>
#include <stdlib.h>

NSString *DCCDownloadDirectory = @"DCCSupportDownloadedDirectory";
NSString *DCCCompletedDirectory = @"DCCSupportCompletedDirectory";
NSString *DCCPortRange = @"DCCSupportPortRange";
NSString *DCCGetTimeout = @"DCCSupportGetTimeout";
NSString *DCCSendTimeout = @"DCCSupportSendTimeout";
NSString *DCCBlockSize = @"DCCSupportBlockSize";
NSString *DCCDefault = @"DCCSupport";

static NSInvocation *invoc = nil;
static NSDictionary *default_dict = nil;

#define get_default(_x) [DCCSupport defaultsObjectForKey: _x]
#define set_default(_x, _y) \
{	[DCCSupport setDefaultsObject: _y forKey: _x];\
	[controller reloadData];}

#define GET_DEFAULT_INT(_x) [get_default(_x) intValue]
#define SET_DEFAULT_INT(_x, _y) set_default(_x, ([NSString stringWithFormat: @"%d", _y]))

static NSString *fix_file_name(NSString *name)
{
	NSMutableString *newName;
	NSRange aRange;
	
	newName = [NSMutableString stringWithString: name];
	aRange = NSMakeRange(0, [newName length]);
	
	[newName replaceOccurrencesOfString: @"/" withString: @"_" options: 0
	  range: aRange];
	[newName replaceOccurrencesOfString: @":" withString: @"_" options: 0
	  range: aRange];
	
	return newName;
}

static NSString *unique_path(NSString *path)
{
	int x;
	id temp;
	id dfm;
	
	dfm = [NSFileManager defaultManager];
	
	if (![dfm fileExistsAtPath: path]) return path;

	for (x = 0; x < 10000000; x++)
	{
		temp = 
		  [path stringByAppendingString: [NSString stringWithFormat: @".%d", x]];
		if (![dfm fileExistsAtPath: temp])
		{
			return temp;
		}
	}
	
	return nil;
}

@implementation DCCSupport (PrivateSupport)
+ (NSDictionary *)defaultSettings
{
	return default_dict;
}	
+ (void)setDefaultsObject: aObject forKey: aKey
{
	id object = [NSUserDefaults standardUserDefaults];
	
	if ([aKey hasPrefix: DCCDefault] && ![aKey isEqualToString: DCCDefault])
	{
		NSMutableDictionary *y;
		id tmp;
		
		aKey = [aKey substringFromIndex: [DCCDefault length]];
		tmp = [object objectForKey: DCCDefault];
		
		if (!tmp)
		{
			y = AUTORELEASE([NSMutableDictionary new]);
		}
		else
		{
			y = [NSMutableDictionary dictionaryWithDictionary: tmp];
		}
		
		if (aObject)
		{
			[y setObject: aObject forKey: aKey];
		}
		else
		{
			[y removeObjectForKey: aKey];
		}
		
		[object setObject: y forKey: DCCDefault];
	}
}
+ (id)defaultsObjectForKey: aKey
{
	id object = [NSUserDefaults standardUserDefaults];
	
	if ([aKey hasPrefix: DCCDefault] && ![aKey isEqualToString: DCCDefault])
	{
		aKey = [aKey substringFromIndex: [DCCDefault length]];
		object = [object objectForKey: DCCDefault];
		if (!(object))
		{
			[[NSUserDefaults standardUserDefaults] setObject:
			  object = default_dict forKey: DCCDefault];
		}
		return (object = [object objectForKey: aKey]) ? object : 
		  [default_dict objectForKey: aKey];
	}
	
	return [object objectForKey: aKey];
}
+ (id)defaultDefaultsForKey: aKey
{
	return [default_dict objectForKey: aKey];
}
- (void)startedSend: (id)dcc onConnection: aConnection
{
	id path = [dcc path];
	id nick = [dcc receiver];
	
	[[_TS_ pluginForOutput] showMessage:
	  BuildAttributedFormat(_l(@"Transfer of %@ to %@ initiated."), path, nick)
	  onConnection: aConnection];
}	
- (void)finishedSend: (id)dcc onConnection: aConnection
{
	id status = [dcc status];
	id cps = [NSString stringWithFormat: @"%d", [dcc cps]];
	id path = [dcc path];
	id nick = [dcc receiver];
	id connections = [self getConnectionTable: aConnection];
	
	if ([status isEqualToString: DCCStatusDone])
	{
		[[_TS_ pluginForOutput] showMessage:
		  BuildAttributedFormat(_l(@"Transfer of %@ to %@ completed successfully! (%@ cps)"),
		  path, nick, cps) onConnection: aConnection];
	}
	else if ([status isEqualToString: DCCStatusTimeout])
	{
		[[_TS_ pluginForOutput] showMessage:
		  BuildAttributedFormat(_l(@"Transfer of %@ to %@ timed out."),
		  path, nick) onConnection: aConnection];
	}
	else if ([status isEqualToString: DCCStatusAborted])
	{
		[[_TS_ pluginForOutput] showMessage:
		  BuildAttributedFormat(_l(@"Transfer of %@ to %@ aborted."),
		  path, nick) onConnection: aConnection];
	}
	else if ([status isEqualToString: DCCStatusError])
	{
		[[_TS_ pluginForOutput] showMessage: 
		  BuildAttributedFormat(_l(@"There was an error sending %@ to %@."), 
		  path, nick) onConnection: aConnection];
	}

	[connections removeObjectIdenticalTo: dcc];
}
- (void)startedReceive: (id)dcc onConnection: aConnection
{
	id info = [dcc info];
	id nick = [info objectForKey: DCCInfoNick];
	id filename = [info objectForKey: DCCInfoFileName];
	
	[[_TS_ pluginForOutput] showMessage: 
	  BuildAttributedFormat(_l(@"Transfer of %@ from %@ initiated."),
	  filename, nick) onConnection: aConnection];
}
- (void)finishedReceive: (id)dcc onConnection: aConnection
{
	id status = [dcc status];
	id info = [dcc info];
	id cps = [NSString stringWithFormat: @"%d", [dcc cps]];
	id path = [dcc path];
	id filename = [info objectForKey: DCCInfoFileName];
	id nick = [info objectForKey: DCCInfoNick];
	id connections = [self getConnectionTable: aConnection];
	
	if ([status isEqualToString: DCCStatusDone])
	{
		id completed = get_default(DCCCompletedDirectory);
		id filename = [path lastPathComponent];
		id fm, newpath;
		
		completed = [completed stringByStandardizingPath];
		
		[[_TS_ pluginForOutput] showMessage:
		  BuildAttributedFormat(_l(@"Transfer of %@ to %@ from %@ completed successfully! (%@ cps)"),
		  filename, path, nick, cps) onConnection: aConnection];
		fm = [NSFileManager defaultManager];
		
		newpath = [NSString stringWithFormat: @"%@/%@", completed, filename];
		newpath = unique_path(newpath);
		if (!newpath)
		{
			[[_TS_ pluginForOutput] showMessage:
			  BuildAttributedFormat(_l(@"Could not move %@ into %@"),
			  filename, completed) onConnection: aConnection];
			return;
		}
		
		if (![fm movePath: path toPath: newpath handler: nil])
		{
			[[_TS_ pluginForOutput] showMessage:
			  BuildAttributedFormat(_l(@"Could not move %@ to %@"),
			  filename, newpath) onConnection: aConnection];
			return;
		}
		
		[[_TS_ pluginForOutput] showMessage:
		  BuildAttributedFormat(_l(@"%@ moved to %@"), 
		  filename, newpath) onConnection: aConnection];
	}
	else if ([status isEqualToString: DCCStatusTimeout])
	{
		[[_TS_ pluginForOutput] showMessage:
		  BuildAttributedFormat(_l(@"Transfer of %@ from %@ timed out."),
		  filename, nick) onConnection: aConnection];
	}
	else if ([status isEqualToString: DCCStatusAborted])
	{
		[[_TS_ pluginForOutput] showMessage:
		  BuildAttributedFormat(_l(@"Transfer of %@ from %@ aborted."),
		  filename, nick) onConnection: aConnection];
	}
	else if ([status isEqualToString: DCCStatusError])
	{
		[[_TS_ pluginForOutput] showMessage: 
		  BuildAttributedFormat(_l(@"There was an error receiving %@ from %@."), 
		  filename, nick) onConnection: aConnection];
	}

	[connections removeObjectIdenticalTo: dcc];
}
- (NSMutableArray *)getConnectionTable: aConnection
{
	id table = NSMapGet(connectionMap, aConnection);
	
	if (table) return table;
	
	NSMapInsert(connectionMap, aConnection, table = AUTORELEASE([NSMutableArray new]));
	
	return table;
}
@end


@implementation DCCSupport
+ (void)initialize
{
	invoc = RETAIN([NSInvocation invocationWithMethodSignature: 
	  [self instanceMethodSignatureForSelector: @selector(commandDCC:connection:)]]);
	[invoc retainArguments];
	[invoc setSelector: @selector(commandDCC:connection:)];

	default_dict = [[NSDictionary alloc] initWithContentsOfFile:
	  [[NSBundle bundleForClass: [DCCSupport class]]
	  pathForResource: @"Defaults" ofType: @"plist"]];
}
- (NSAttributedString *)commandDCCABORT: (NSString *)command connection: (id)connection
{
	id x, connections;
	int val = -1;
	
	connections = [self getConnectionTable: connection];
	
	x = [command separateIntoNumberOfArguments: 2];
	
	if ([x count])
	{
		val = [[x objectAtIndex: 0] intValue];
		if (val < 0) val = 0 - val;
	}
	
	val--;
	
	if (val < 0 || val >= (int)[connections count])
	{
		return S2AS(_l(@"Usage: /dcc abort <#>" @"\n"
		  @"Aborts the connection in slot <#>.  See /dcc list."));
	}
	
	x = [connections objectAtIndex: val];
	
	if ([x isKindOfClass: [DCCSender class]] || [x isKindOfClass: [DCCGetter class]])
	{
		[x abortConnection];
	}
	else if ([x isKindOfClass: [NSDictionary class]])
	{
		x = [NSDictionary dictionaryWithDictionary: x];
		[connections removeObjectAtIndex: val];
		return BuildAttributedFormat(_l(@"Offer of the file %@ from %@ removed."),
		  [x objectForKey: DCCInfoFileName], [x objectForKey: DCCInfoNick]);
	}
	
	return nil;
}		  
- (NSAttributedString *)commandDCCPORTRANGE: (NSString *)command connection: (id)connection
{
	id x;

	x = [command separateIntoNumberOfArguments: 1];
	if ([x count] == 0)
	{
		return BuildAttributedString(_l(@"Usage: /dcc portrange <low>-<high>" @"\n"
		  @"Sets the range of allowable ports for sending files.  If <low> and "
		  @"<high> are the same sending will only use that port.  Use "
		  @"/dcc portrange - to allow use of any port.  This option should "
		  @"only be needed if you are behind a firewall." @"\n"
		  @"Current portrange: "), get_default(DCCPortRange));
	}
	
	x = [NSMutableArray arrayWithArray: 
	  [[x objectAtIndex: 0] componentsSeparatedByString: @"-"]];
	[x removeObject: @""];

	if ([x count] == 0)
	{
		set_default(DCCPortRange, @"");
	}
	else if ([x count] == 1)
	{
		int x1;
		id tmp;
		
		x1 = [[x objectAtIndex: 0] intValue];
		if (x1 < 0)
		{
			set_default(DCCPortRange, @"");
		}
		else
		{
			if (x1 > 65535) x1 = 65535;
			
			tmp = [NSString stringWithFormat: @"%d-%d", x1, x1];

			set_default(DCCPortRange, tmp);
		}
	}
	else if ([x count] >= 2)
	{
		int x1, x2;
		id tmp;

		x1 = [[x objectAtIndex: 0] intValue];
		x2 = [[x objectAtIndex: 1] intValue];

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
				int temp;
				temp = x2;
				x2 = x1;
				x1 = temp;
			}

			tmp = [NSString stringWithFormat: @"%d-%d", x1, x2];

			set_default(DCCPortRange, tmp);
		}	
	}

	return S2AS(_l(@"Ok."));
}
- (NSAttributedString *)commandDCCBLOCKSIZE: (NSString *)command connection: (id)connection
{
	id x;
	int val;
	
	x = [command separateIntoNumberOfArguments: 2];

	if ([x count] == 0)
	{
		return BuildAttributedString(_l(@"Usage: /dcc blocksize <bytes>" @"\n"
		  @"Sets the block size of files being sent.  The default should be "
		  @"fine most of the time." @"\n"
		  @"Current block size: "), get_default(DCCBlockSize), nil);
	}
	
	val = [[x objectAtIndex: 0] intValue];

	if (val < 0) val = 0 - val;
	
	SET_DEFAULT_INT(DCCBlockSize, val);

	return S2AS(_l(@"Ok."));
}
- (NSAttributedString *)commandDCCGETTIMEOUT: (NSString *)command connection: (id)connection
{
	id x;
	int val;
	
	x = [command separateIntoNumberOfArguments: 2];
	
	if ([x count] == 0)
	{
		return BuildAttributedString(_l(@"Usage: /dcc gettimeout <seconds>" @"\n"
		  @"Sets the timeout in seconds on receiving files." @"\n"
		  @"Current timeout: "), get_default(DCCGetTimeout), nil);
	}
	
	val = [[x objectAtIndex: 0] intValue];
	
	if (val < 0) val = 0 - val;
	
	SET_DEFAULT_INT(DCCGetTimeout, val);
	
	return S2AS(_l(@"Ok."));
}
- (NSAttributedString *)commandDCCSENDTIMEOUT: (NSString *)command connection: (id)connection
{
	id x;
	int val;
	
	x = [command separateIntoNumberOfArguments: 2];
	
	if ([x count] == 0)
	{
		return BuildAttributedString(_l(@"Usage: /dcc sendtimeout <seconds>" @"\n"
		  @"Sets the timeout in seconds on sending files." @"\n"
		  @"Current timeout: "), get_default(DCCSendTimeout), nil);
	}
	
	val = [[x objectAtIndex: 0] intValue];
	
	if (val < 0) val = 0 - val;
	
	SET_DEFAULT_INT(DCCSendTimeout, val);
	
	return S2AS(_l(@"Ok."));
}
- (NSAttributedString *)commandDCCSEND: (NSString *)command connection: (id)connection
{
	id x;
	id user;
	id path;
	id dfm;
	BOOL isDir;
	id sender;
	id connections;
	
	x = [command separateIntoNumberOfArguments: 2];
	dfm = [NSFileManager defaultManager];
	
	if ([x count] < 2)
	{
		return S2AS(
		 _l(@"Usage: /dcc send <user> <file>" @"\n"
		 @"Requests <user> to receive file named <file>"));
	}
	
	user = [x objectAtIndex: 0];
	path = [x objectAtIndex: 1];
	
	path = [path stringByStandardizingPath];
	
	if (![dfm fileExistsAtPath: path isDirectory: &isDir] || isDir)
	{
		return S2AS(_l(@"That file does not exist."));
	}
	
	connections = [self getConnectionTable: connection];
	
	sender = AUTORELEASE([[DCCSender alloc] initWithFilename: path
	  withConnection: connection to: user withDelegate: self]);
	
	if (sender)
	{
		[connections addObject: sender];
		return BuildAttributedFormat(_l(@"Offering %@ to %@."), path, user);
	}
	
	return S2AS(_l(@"Had problems initializing the port."));
}
- (NSAttributedString *)commandDCCLIST: (NSString *)command connection: (id)connection
{
	int max, index;
	id object;
	NSMutableAttributedString *attr;
	NSMutableArray *connections;
	
	connections = [self getConnectionTable: connection];
	
	attr = AUTORELEASE([NSMutableAttributedString new]);
	
	max = [connections count];
	for (index = 0; index < max; index++)
	{
		object = [connections objectAtIndex: index];
		if ([object isKindOfClass: [NSDictionary class]])
		{
			[attr appendAttributedString: 
			  BuildAttributedFormat(_l(@"%@. %@ %@ has requested to send %@ (%@ bytes)"),
			  [NSString stringWithFormat: @"%d", index + 1],
			  BuildAttributedString([NSNull null], IRCBold, IRCBoldValue, _l(@"REQUEST"), nil), 
			  [object objectForKey: DCCInfoNick],
			  [object objectForKey: DCCInfoFileName],  
			  [NSString stringWithFormat: @"%d", [[object objectForKey: DCCInfoFileSize] intValue]])];
		}
		if ([object isKindOfClass: [DCCGetter class]])
		{
			[attr appendAttributedString: 
			  BuildAttributedFormat(_l(@"%@. %@ %@ is sending %@ (%@ of %@ bytes @ %@ cps)"),
			  [NSString stringWithFormat: @"%d", index + 1],
			  BuildAttributedString([NSNull null], IRCBold, IRCBoldValue, _l(@"RECEIVING"), nil),
			  [[object info] objectForKey: DCCInfoNick],  
			  [[object info] objectForKey: DCCInfoFileName], 
			  [object percentDone],
			  [NSString stringWithFormat: @"%d", 
			    [[[object info] objectForKey: DCCInfoFileSize] intValue]],
			  [NSString stringWithFormat: @"%d", [object cps]])];
		}
		if ([object isKindOfClass: [DCCSender class]])
		{
			if ([[object status] isEqualToString: DCCStatusConnecting])
			{
			[attr appendAttributedString: 
			  BuildAttributedFormat(_l(@"%@. %@ You have offered to send %@ to %@"),
			  [NSString stringWithFormat: @"%d", index + 1],
			  BuildAttributedString([NSNull null], IRCBold, IRCBoldValue, _l(@"OFFERED"), nil),
			  [object path],  
			  [object receiver])];
			}
			else
			{
			[attr appendAttributedString: 
			  BuildAttributedFormat(_l(@"%@. %@ You are sending %@ to %@ (%@ of %@ bytes @ %@ cps)"),
			  [NSString stringWithFormat: @"%d", index + 1],
			  BuildAttributedString([NSNull null], IRCBold, IRCBoldValue, _l(@"SENDING"), nil),
			  [object path],  
			  [object receiver], 
			  [object percentDone],
			  [NSString stringWithFormat: @"%d", 
			    [[[object info] objectForKey: DCCInfoFileSize] intValue]],
			  [NSString stringWithFormat: @"%d", [object cps]])];
			}
		}
		[attr appendAttributedString: S2AS(@"\n")];
	}
	
	if ([attr length] == 0)
	{
		[attr appendAttributedString: 
		  S2AS(_l(@"End of list (See /dcc help for more information)."))];
	}
	else
	{
		[attr appendAttributedString: S2AS(_l(@"End of list."))];
	}

	return attr;
}
- (NSAttributedString *)commandDCCGET: (NSString *)command connection: (id)connection
{
	id x;
	id path;
	id dict;
	int number;
	BOOL isDir;
	id dfm;
	id getter;
	NSMutableArray *connections;
	
	connections = [self getConnectionTable: connection];
	
	x = [command separateIntoNumberOfArguments: 2];
	
	if ([x count] == 0)
	{
		return S2AS(_l(@"Usage: /dcc get <#> [filename]" @"\n"
		  @"Receives the file at <#> position (see /dcc list)."
		  @"If [filename] isn't specified, it will be put into the default"
		  @" directory (see /dcc setdir) with the filename specified by the sender."));
	}

	number = [[x objectAtIndex: 0] intValue] - 1;
	
	if (number >= (int)[connections count] || 
	    !([(dict = [connections objectAtIndex: number]) isKindOfClass: [NSDictionary class]]))
	{
		return S2AS(_l(@"The specified index is invalid. Please see /dcc list."));
	}
	
	path = @"";
	
	if ([x count] == 2)
	{
		path = [x objectAtIndex: 1];
	}
	
	dfm = [NSFileManager defaultManager];
	if ([path length] == 0)
	{
		path = [dict objectForKey: DCCInfoFileName];
		x = get_default(DCCDownloadDirectory);
		if (![dfm fileExistsAtPath: x isDirectory: &isDir] || !isDir)
		{
			return S2AS(_l(@"Invalid download directory, see /dcc setdir."));
		}
		path = [NSString stringWithFormat: @"%@/%@", x, fix_file_name(path)];
	}
	
	path = [path stringByStandardizingPath];

	path = unique_path(path);
	if (!path)
	{
		return S2AS(_l(@"Could not find a unique file name."));
	}
	
	getter = AUTORELEASE([[DCCGetter alloc] initWithInfo: dict withFileName: path
	  withConnection: connection withDelegate: self]);
	
	[connections replaceObjectAtIndex: number withObject: getter]; 
	
	return nil;
}
- (NSAttributedString *)commandDCCSETDIR: (NSString *)command connection: (id)connection
{
	id x;
	id dir;
	BOOL force = NO;
	NSEnumerator *iter;
	id object;
	BOOL isDir;
	id current;
	id dfm;
	BOOL couldCreate = YES;
	
	x = [command separateIntoNumberOfArguments: 1];
	
	dir = [x count] ? [x objectAtIndex: 0] : @"";
	
	if ([dir hasPrefix: @"-f"])
	{
		x = [dir separateIntoNumberOfArguments: 2];
		if ([x count] != 2)
		{
			dir = @"";
		}
		else
		{
			dir = [x objectAtIndex: 1];
			force = YES;
		}
	}
	
	if ([dir length] == 0)
	{
		return BuildAttributedString(_l(@"Usage: /dcc setdir [-f] <directory>" @"\n"
		  @"Sets the default download directory to <directory>, if -f is specified "
		  @"the directory will be created if it doesn't already exist." @"\n"
		  @"Currently: "), [get_default(DCCDownloadDirectory) stringByExpandingTildeInPath], nil);
	}
	
	dfm = [NSFileManager defaultManager];	
	dir = [dir stringByExpandingTildeInPath];
	dir = [dir stringByStandardizingPath];
	
	if (![dir hasPrefix: @"/"])
	{
		dir = [[@"~/" stringByExpandingTildeInPath] stringByAppendingString: dir];
	}
	
	if ([dfm fileExistsAtPath: dir isDirectory: &isDir])
	{
		if (!isDir)
		{
			return S2AS(_l(@"File exists at path."));
		}
	}
	else if (force)
	{
		x = [dir pathComponents];
		
		iter = [x objectEnumerator];
		current = @"";
		while ((object = [iter nextObject]))
		{
			current = [current stringByAppendingString: object];
			if ([dfm fileExistsAtPath: current isDirectory: &isDir])
			{
				if (!isDir)
				{
					break;
				}
			}
			else
			{
				if (![dfm createDirectoryAtPath: current attributes: nil])
				{
					break;
				}
			}
			current = [current stringByAppendingString: @"/"];
		}
		
		if (object)
		{
			return S2AS(_l(@"Could not create directory."));
		}
	}
	else
	{
		couldCreate = NO;
	}
	
	if (couldCreate)
	{
		set_default(DCCDownloadDirectory, dir);
		return S2AS(_l(@"Ok."));
	}

	return S2AS(_l(@"Directory does not exist. Try the -f flag."));
}
- (NSAttributedString *)commandDCCHELP: (NSString *)command connection: (id)connection
{
	return S2AS(_l(@"Usage:" @"\n" 
	  @"/dcc (lists current connections and requests)" @"\n"
	  @"/dcc get (receives a file)" @"\n"
	  @"/dcc setdir (sets default download directory)" @"\n"
	  @"/dcc send (sends a file)" @"\n"
	  @"/dcc gettimeout (sets timeout on receiving files)" @"\n"
	  @"/dcc sendtimeout (sets timeout on sending files)" @"\n"
	  @"/dcc abort (aborts a connection)" @"\n"
	  @"/dcc blocksize (sets the block size on sending files)" @"\n"
	  @"/dcc portrange (sets allowable ports for sending files)" @"\n"
	  @"/dcc help (this help)"));
}	
- (NSAttributedString *)commandDCC: (NSString *)command connection: (id)connection
{
	id x = [command separateIntoNumberOfArguments: 2];
	id arg = @"";
	int count;
	SEL sel;
	
	if ((count = [x count]) > 0)
	{
		command = [x objectAtIndex: 0];
		arg = (count > 1) ? [x objectAtIndex: 1] : @"";
		command = [command uppercaseString];
		sel = NSSelectorFromString([NSString stringWithFormat: @"commandDCC%@:connection:", command]);
		if (sel && [self respondsToSelector: sel])
		{
			return [self performSelector: sel withObject: arg withObject: connection];
		}
		else
		{
			return [self commandDCCHELP: arg connection: connection];
		}
	}
	
	return [self commandDCCLIST: arg connection: connection];
}	
- init
{
	if (!(self = [super init])) return nil;
	
	connectionMap = NSCreateMapTable(NSObjectMapKeyCallBacks, NSObjectMapValueCallBacks, 5);

	return self;
}
- (void)dealloc
{
	NSFreeMapTable(connectionMap);
	[super dealloc];
}	
- pluginActivated
{
	controller = [DCCSupportPreferencesController new];

#ifdef USE_APPKIT
	[_TS_ controlObject: [NSDictionary dictionaryWithObjectsAndKeys:
	  @"AddBundlePreferencesController", @"Process",
	  @"DCCSupport", @"Name",
	  controller, @"Controller",
	  nil] onConnection: nil withNickname: nil sender: self];
#endif

	[invoc setTarget: self];
	[_TS_ addCommand: @"dcc" withInvocation: invoc];
	return self;
}
- pluginDeactivated
{
#ifdef USE_APPKIT
	[controller shouldHide];
	[_TS_ controlObject: [NSDictionary dictionaryWithObjectsAndKeys:
	  @"RemoveBundlePreferencesController", @"Process",
	  @"DCCSupport", @"Name", nil]
	  onConnection: nil withNickname: nil sender: [_TS_ pluginForInput]];
#endif
	DESTROY(controller);

	[invoc setTarget: nil];
	[_TS_ removeCommand: @"dcc"];
	return self;
}
- (NSAttributedString *)pluginDescription
{
	return BuildAttributedString([NSNull null], IRCBold, IRCBoldValue,
	 _l(@"Author: "), @"Andrew Ruder\n\n",
	 [NSNull null], IRCBold, IRCBoldValue,
	 _l(@"Description: "), _l(@"Provides a interface to DCC file transfer "
	 @"through the /dcc command.  Type /dcc when this bundle is loaded "
	 @"for more information."), @"\n\n",
	 _l(@"Copyright (C) 2005 by Andrew Ruder"), nil);
}
- DCCSendRequestReceived: (NSDictionary *)aInfo onConnection: aConnection
{
	id connections;
	
	connections = [self getConnectionTable: aConnection];
	
	[connections addObject: aInfo];
	
	[[_TS_ pluginForOutput] showMessage: BuildAttributedFormat(
	  _l(@"%@ (%@:%@) has requested to send %@ (%@ bytes)"),
	  [aInfo objectForKey: DCCInfoNick],
	  [[aInfo objectForKey: DCCInfoHost] address],
	  [NSString stringWithFormat: @"%hu", 
	    [[aInfo objectForKey: DCCInfoPort] unsignedShortValue]],
	  [aInfo objectForKey: DCCInfoFileName],
	  [NSString stringWithFormat: @"%lu", 
	    [[aInfo objectForKey: DCCInfoFileSize] unsignedLongValue]])
	  onConnection: aConnection];
	
	return self;
}
- CTCPRequestReceived: (NSAttributedString *)aCTCP 
   withArgument: (NSAttributedString *)argument 
   to: (NSAttributedString *)receiver
   from: (NSAttributedString *)aPerson onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{	
	NSArray *list;
	
	if (![[[aCTCP string] uppercaseString] isEqualToString: @"DCC"])
	{
		[_TS_ CTCPRequestReceived: aCTCP withArgument: argument to: receiver
		  from: aPerson onConnection: connection withNickname: aNick
		  sender: self];
		return self;
	}
	
	list = [[argument string] componentsSeparatedByString: @" "];
	if ([list count] < 4)
	{
		return self;
	}
	
	if ([[[list objectAtIndex: 0] uppercaseString] isEqualToString: @"SEND"])
	{
		id fileName;
		id fileSize;
		id port;
		id address;
		
		if ([list count] >= 5)
		{
			fileSize = [NSNumber numberWithUnsignedLong: 
			 strtoul([[list objectAtIndex: 4] cString], 0, 10)];
		}
		else
		{
			fileSize = [NSNumber numberWithInt: -1];
		}

		port = [NSNumber numberWithUnsignedShort: 
		 strtoul([[list objectAtIndex: 3] cString], 0, 10)];

		address = [(TCPSystem *)[TCPSystem sharedInstance] hostFromHostOrderInteger:
		 strtoul([[list objectAtIndex: 2] cString], 0, 10)];
		
		fileName = [list objectAtIndex: 1];
		
		[self DCCSendRequestReceived: 
		 [NSDictionary dictionaryWithObjectsAndKeys:
		  fileName, DCCInfoFileName,
		  fileSize, DCCInfoFileSize,
		  port, DCCInfoPort,
		  address, DCCInfoHost,
		  [[IRCUserComponents(aPerson) objectAtIndex: 0] string], DCCInfoNick,
		  nil] onConnection: connection];
	}
	
	return self;
}
@end

