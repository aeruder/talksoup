/***************************************************************************
                              DCCSupport.m
                          -------------------
    begin                : Wed Jul 2 18:58:30 CDT 2003
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

#include "DCCSupport.h"
#include "TalkSoupBundles/TalkSoup.h"
#include "netclasses/NetTCP.h"
#include "netclasses/DCCObject.h"

#import <Foundation/NSAttributedString.h>
#import <Foundation/NSInvocation.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSFileHandle.h>
#import <Foundation/NSTimer.h>
#import <Foundation/NSHost.h>

static NSString *dcc_default = @"DCCSupport";
static NSString *dcc_dir = @"DCCSupportDirectory";
static NSString *dcc_gettimeout = @"DCCSupportGetTimeout";
static NSString *dcc_sendtimeout = @"DCCSupportSendTimeout";

static id get_default_default(NSString *key)
{
	static NSDictionary *dict = nil;
	
	if (!dict)
	{
		dict = [[NSDictionary alloc] initWithObjectsAndKeys: 
		  @"~/", dcc_dir,
		  @"30", dcc_gettimeout,
		  @"300", dcc_sendtimeout,
		  nil];
	}
	
	return [dict objectForKey: key];
}

static void set_default(NSString *key, id value)
{
	if ([key hasPrefix: dcc_default] && ![key isEqualToString: dcc_default]) 
	{
		id dict;
		key = [key substringFromIndex: [dcc_default length]];
		
		dict = [[NSUserDefaults standardUserDefaults] objectForKey: dcc_default];
		if (dict && [dict isKindOf: [NSDictionary class]])
		{
			dict = [NSMutableDictionary dictionaryWithDictionary: dict];
		}
		else
		{
			dict = AUTORELEASE([NSMutableDictionary new]);
		}
		
		if (!value)
		{
			[dict removeObjectForKey: key];
		}
		else
		{
			[dict setObject: value forKey: key];
		}
		
		[[NSUserDefaults standardUserDefaults] setObject: dict forKey: dcc_default];
		return;
	}
	
	if (!value)
	{
		[[NSUserDefaults standardUserDefaults] removeObjectForKey: key];
	}
	else
	{
		[[NSUserDefaults standardUserDefaults] setObject: value forKey: key];
	}	
}

static id get_default(NSString *key)
{
	if ([key hasPrefix: dcc_default] && ![key isEqualToString: dcc_default]) 
	{
		id dict;
		id sub;
		sub = [key substringFromIndex: [dcc_default length]];
		
		dict = [[NSUserDefaults standardUserDefaults] objectForKey: dcc_default];
		if (!dict || ![dict isKindOf: [NSDictionary class]])
		{
			[[NSUserDefaults standardUserDefaults] setObject: 
			  dict = AUTORELEASE([NSDictionary new]) forKey: dcc_default];
		}
		
		if (!(sub = [dict objectForKey: sub]))
		{
			set_default(key, sub = get_default_default(key));
		}
		
		return sub;
	}
	
	return [[NSUserDefaults standardUserDefaults] objectForKey: key];
}

#define GET_DEFAULT_INT(_x) [get_default(_x) intValue]
#define SET_DEFAULT_INT(_x, _y) set_default(_x, [NSString stringWithFormat: @"%d", _y])

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

static NSInvocation *invoc = nil;

@interface DCCSupport (PrivateSupport)
- (void)startedReceive: dcc onConnection: aConnection;
- (void)finishedReceive: dcc onConnection: aConnection;
- (void)startedSend: dcc onConnection: aConnection;
- (void)finishedSend: dcc onConnection: aConnection;
- (NSMutableArray *)getConnectionTable: aConnection;
@end






@interface DCCGetter : NSObject
	{
		NSFileHandle *file;
		NSString *path;
		DCCObject *getter;
		NSString *status;
		id connection;
		id delegate;
		NSTimer *cpsTimer;
		int cps;
		uint32_t oldTransferredBytes;
	}
- initWithInfo: (NSDictionary *)aDict withFileName: (NSString *)aPath 
    withConnection: aConnection withDelegate: aDel;

- (NSString *)status;

- (NSDictionary *)info;

- (NSHost *)localHost;
- (NSHost *)remoteHost;

- (NSString *)percentDone;

- (int)cps;
- cpsTimer: (NSTimer *)aTimer;

- (NSString *)path;

- (void)abortConnection;
@end





@interface DCCSender : NSObject
	{
		NSFileHandle *file;
		NSString *path;
		DCCSendObject *sender;
		NSString *status;
		NSString *receiver;
		id connection;
		id delegate;
		NSTimer *cpsTimer;
		int cps;
		uint32_t oldTransferredBytes;
	}
- initWithFilename: (NSString *)path 
    withConnection: aConnection to: (NSString *)receiver withDelegate: aDel;

- (NSString *)status;

- (NSDictionary *)info;

- (NSHost *)localHost;
- (NSHost *)remoteHost;

- (NSString *)percentDone;

- (int)cps;
- cpsTimer: (NSTimer *)aTimer;

- (NSString *)path;
- (NSString *)receiver;

- (void)abortConnection;
@end





@implementation DCCGetter
- initWithInfo: (NSDictionary *)aDict withFileName: (NSString *)aPath
   withConnection: aConnection withDelegate: aDel
{
	id dfm;
	BOOL isDir;
	
	if (!(self = [super init])) return nil;
	
	dfm = [NSFileManager defaultManager];
	
	if (![dfm fileExistsAtPath: aPath isDirectory: &isDir])
	{
		[dfm createFileAtPath: aPath contents: AUTORELEASE([NSData new]) attributes: nil];
	}
	else if (isDir)
	{
		RELEASE(self);
		return nil;
	}
	
	connection = RETAIN(aConnection);
	
	file = RETAIN([NSFileHandle fileHandleForWritingAtPath: aPath]);
	
	path = RETAIN(aPath);
	getter = [[DCCReceiveObject alloc] initWithReceiveOfFile: aDict 
	  withDelegate: self withTimeout: GET_DEFAULT_INT(dcc_gettimeout) 
	  withUserInfo: nil];
	
	delegate = aDel;
	
	return self;
}
- (void)dealloc
{
	[cpsTimer invalidate];
	DESTROY(cpsTimer);
	RELEASE(getter);
	RELEASE(path);
	RELEASE(file);
	RELEASE(connection);
	RELEASE(status);
	
	[super dealloc];
}
- cpsTimer: (NSTimer *)aTimer
{
	cps = ([getter transferredBytes] - oldTransferredBytes) / 5;
	oldTransferredBytes = [getter transferredBytes];
	return self;
}
- DCCInitiated: aConnection
{
	return self;
}
- DCCStatusChanged: (NSString *)aStatus forObject: aConnection
{
	if (status == aStatus) return self;
	
	if ([aStatus isEqualToString: DCCStatusTransferring])
	{
		[cpsTimer invalidate];
		RELEASE(cpsTimer);
		oldTransferredBytes = 0;
		cpsTimer = RETAIN([NSTimer scheduledTimerWithTimeInterval: 5.0 target: self
		  selector: @selector(cpsTimer:) userInfo: nil repeats: YES]);
		[delegate startedReceive: self onConnection: connection];
	}
		
	RELEASE(status);
	status = RETAIN(aStatus);
	
	return self;
}
- DCCReceivedData: (NSData *)data forObject: aConnection
{
	[file writeData: data];
	
	return self;
}
- DCCDone: aConnection
{
	[cpsTimer invalidate];
	DESTROY(cpsTimer);
	
	[delegate finishedReceive: self onConnection: connection];
	
	return self;
}
- (NSString *)status
{
	return status;
}
- (NSDictionary *)info
{
	return [getter info];
}
- (NSHost *)localHost
{
	return [connection localHost];
}
- (NSHost *)remoteHost
{
	return [connection remoteHost];
}
- (NSString *)percentDone
{
	id dict = [getter info];
	int length;
	
	length = [[dict objectForKey: DCCInfoFileSize] intValue];
	
	if (length < 0)
	{
		return @"??%";
	}
	
	return [NSString stringWithFormat: @"%d%%", 
	  ([getter transferredBytes] * 100) / length];
}
- (int)cps
{
	return cps;
}
- (NSString *)path
{
	return path;
}
- (void)abortConnection
{
	[getter abortConnection];
}
@end





@implementation DCCSender
- initWithFilename: (NSString *)aPath 
    withConnection: aConnection to: (NSString *)aReceiver withDelegate: aDel;
{
	id dfm;
	NSNumber *fileSize;
	id dict;
	
	dfm = [NSFileManager defaultManager];
	
	if (!(dict = [dfm fileAttributesAtPath: aPath traverseLink: YES]))
	{
		return nil;
	}
	
	fileSize = [dict objectForKey: NSFileSize];
	
	if (!(self = [super init])) return nil;
	
	file = RETAIN([NSFileHandle fileHandleForReadingAtPath: aPath]);
	
	if (!file) 
	{
		[self dealloc];
		return nil;
	}
	
	path = RETAIN(aPath);

	receiver = RETAIN(aReceiver);
	
	connection = RETAIN(aConnection);
	
	sender = [[DCCSendObject alloc] initWithSendOfFile: [path lastPathComponent]  
	  withSize: fileSize
	  withDelegate: self withTimeout: GET_DEFAULT_INT(dcc_sendtimeout) 
	  withBlockSize: 2000 withUserInfo: nil];
	
	[_TS_ sendCTCPRequest: S2AS(@"DCC") 
	  withArgument: S2AS(BuildDCCSendRequest([sender info]))
	  to: S2AS(aReceiver) onConnection: aConnection withNickname: S2AS([aConnection nick])
	  sender: [_TS_ pluginForOutput]];
	
	delegate = aDel;
	
	return self;
}
- (void)dealloc
{
	[cpsTimer invalidate];
	DESTROY(cpsTimer);
	RELEASE(sender);
	RELEASE(path);
	RELEASE(file);
	RELEASE(connection);
	RELEASE(status);
	RELEASE(receiver);
	
	[super dealloc];
}
- cpsTimer: (NSTimer *)aTimer
{
	cps = ([sender transferredBytes] - oldTransferredBytes) / 5;
	oldTransferredBytes = [sender transferredBytes];
	return self;
}
- DCCInitiated: aConnection
{
	return self;
}
- DCCStatusChanged: (NSString *)aStatus forObject: aConnection
{
	if (status == aStatus) return self;
	
	if ([aStatus isEqualToString: DCCStatusTransferring])
	{
		[cpsTimer invalidate];
		RELEASE(cpsTimer);
		oldTransferredBytes = 0;
		cpsTimer = RETAIN([NSTimer scheduledTimerWithTimeInterval: 5.0 target: self
		  selector: @selector(cpsTimer:) userInfo: nil repeats: YES]);
		[delegate startedSend: self onConnection: connection];
	}		
		
	RELEASE(status);
	status = RETAIN(aStatus);
	
	return self;
}
- DCCNeedsMoreData: aConnection
{
	NSData *data;
	
	data = [file readDataOfLength: [sender blockSize]];
	
	[sender writeData: ([data length]) ? data : nil];
	
	return self;
}
- DCCDone: aConnection
{
	[cpsTimer invalidate];
	DESTROY(cpsTimer);
	
	[delegate finishedSend: self onConnection: connection];
	
	return self;
}
- (NSString *)status
{
	return status;
}
- (NSDictionary *)info
{
	return [sender info];
}
- (NSHost *)localHost
{
	return [connection localHost];
}
- (NSHost *)remoteHost
{
	return [connection remoteHost];
}
- (NSString *)percentDone
{
	id dict = [sender info];
	int length;
	
	length = [[dict objectForKey: DCCInfoFileSize] intValue];
	
	if (length < 0)
	{
		return @"??%";
	}
	
	return [NSString stringWithFormat: @"%d%%", 
	  ([sender transferredBytes] * 100) / length];
}
- (int)cps
{
	return cps;
}
- (NSString *)path
{
	return path;
}
- (NSString *)receiver
{
	return receiver;
}
- (void)abortConnection
{
	[sender abortConnection];
}
@end




@implementation DCCSupport (PrivateSupport)
- (void)startedSend: (id)dcc onConnection: aConnection
{
	id path = [dcc path];
	id nick = [dcc receiver];
	
	[[_TS_ pluginForOutput] showMessage:
	  BuildAttributedFormat(@"Transfer of %@ to %@ initiated.", path, nick)
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
		  BuildAttributedFormat(@"Transfer of %@ to %@ completed successfully! (%@ cps)",
		  path, nick, cps) onConnection: aConnection];
	}
	else if ([status isEqualToString: DCCStatusTimeout])
	{
		[[_TS_ pluginForOutput] showMessage:
		  BuildAttributedFormat(@"Transfer of %@ to %@ timed out.",
		  path, nick) onConnection: aConnection];
	}
	else if ([status isEqualToString: DCCStatusAborted])
	{
		[[_TS_ pluginForOutput] showMessage:
		  BuildAttributedFormat(@"Transfer of %@ to %@ aborted.",
		  path, nick) onConnection: aConnection];
	}
	else if ([status isEqualToString: DCCStatusError])
	{
		[[_TS_ pluginForOutput] showMessage: 
		  BuildAttributedFormat(@"There was an error sending %@ to %@.", 
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
	  BuildAttributedFormat(@"Transfer of %@ from %@ initiated.",
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
		[[_TS_ pluginForOutput] showMessage:
		  BuildAttributedFormat(@"Transfer of %@ to %@ from %@ completed successfully! (%@ cps)",
		  filename, path, nick, cps) onConnection: aConnection];
	}
	else if ([status isEqualToString: DCCStatusTimeout])
	{
		[[_TS_ pluginForOutput] showMessage:
		  BuildAttributedFormat(@"Transfer of %@ from %@ timed out.",
		  filename, nick) onConnection: aConnection];
	}
	else if ([status isEqualToString: DCCStatusAborted])
	{
		[[_TS_ pluginForOutput] showMessage:
		  BuildAttributedFormat(@"Transfer of %@ from %@ aborted.",
		  filename, nick) onConnection: aConnection];
	}
	else if ([status isEqualToString: DCCStatusError])
	{
		[[_TS_ pluginForOutput] showMessage: 
		  BuildAttributedFormat(@"There was an error receiving %@ from %@.", 
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
	
	if (val < 0 || val >= [connections count])
	{
		return BuildAttributedString(@"Usage: /dcc abort <#>", @"\n",
		  @"Aborts the connection in slot <#>.  See /dcc list.", nil);
	}
	
	x = [connections objectAtIndex: val];
	
	if ([x isKindOf: [DCCSender class]] || [x isKindOf: [DCCGetter class]])
	{
		[x abortConnection];
	}
	else if ([x isKindOf: [NSDictionary class]])
	{
		x = [NSDictionary dictionaryWithDictionary: x];
		[connections removeObjectAtIndex: val];
		return BuildAttributedFormat(@"Offer of the file %@ from %@ removed.",
		  [x objectForKey: DCCInfoFileName], [x objectForKey: DCCInfoNick]);
	}
	
	return nil;
}		  
- (NSAttributedString *)commandDCCGETTIMEOUT: (NSString *)command connection: (id)connection
{
	id x;
	int val;
	
	x = [command separateIntoNumberOfArguments: 2];
	
	if ([x count] == 0)
	{
		return BuildAttributedString(@"Usage: /dcc gettimeout <seconds>", @"\n",
		  @"Sets the timeout in seconds on receiving files.", @"\n",
		  @"Current timeout: ", get_default(dcc_gettimeout), nil);
	}
	
	val = [[x objectAtIndex: 0] intValue];
	
	if (val < 0) val = 0 - val;
	
	SET_DEFAULT_INT(dcc_gettimeout, val);
	
	return S2AS(@"Ok.");
}
- (NSAttributedString *)commandDCCSENDTIMEOUT: (NSString *)command connection: (id)connection
{
	id x;
	int val;
	
	x = [command separateIntoNumberOfArguments: 2];
	
	if ([x count] == 0)
	{
		return BuildAttributedString(@"Usage: /dcc sendtimeout <seconds>", @"\n",
		  @"Sets the timeout in seconds on sending files.", @"\n",
		  @"Current timeout: ", get_default(dcc_sendtimeout), nil);
	}
	
	val = [[x objectAtIndex: 0] intValue];
	
	if (val < 0) val = 0 - val;
	
	SET_DEFAULT_INT(dcc_sendtimeout, val);
	
	return S2AS(@"Ok.");
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
		return BuildAttributedString(
		 @"Usage: /dcc send <user> <file>", @"\n",
		 @"Requests <user> to receive file named <file>", nil);
	}
	
	user = [x objectAtIndex: 0];
	path = [x objectAtIndex: 1];
	
	path = [path stringByStandardizingPath];
	
	if (![dfm fileExistsAtPath: path isDirectory: &isDir] || isDir)
	{
		return S2AS(@"That file does not exist.");
	}
	
	connections = [self getConnectionTable: connection];
	
	sender = AUTORELEASE([[DCCSender alloc] initWithFilename: path
	  withConnection: connection to: user withDelegate: self]);
	
	if (sender)
	{
		[connections addObject: sender];
	}

	return BuildAttributedFormat(@"Offering %@ to %@.", path, user);
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
		if ([object isKindOf: [NSDictionary class]])
		{
			[attr appendAttributedString: 
			  BuildAttributedFormat(@"%@. %@ %@ has requested to send %@ (%@ bytes)",
			  [NSString stringWithFormat: @"%d", index + 1],
			  BuildAttributedString([NSNull null], IRCBold, IRCBoldValue, @"REQUEST", nil), 
			  [object objectForKey: DCCInfoNick],
			  [object objectForKey: DCCInfoFileName],  
			  [NSString stringWithFormat: @"%d", [[object objectForKey: DCCInfoFileSize] intValue]])];
		}
		if ([object isKindOf: [DCCGetter class]])
		{
			[attr appendAttributedString: 
			  BuildAttributedFormat(@"%@. %@ %@ is sending %@ (%@ of %@ bytes @ %@ cps)",
			  [NSString stringWithFormat: @"%d", index + 1],
			  BuildAttributedString([NSNull null], IRCBold, IRCBoldValue, @"RECEIVING", nil),
			  [[object info] objectForKey: DCCInfoNick],  
			  [[object info] objectForKey: DCCInfoFileName], 
			  [object percentDone],
			  [NSString stringWithFormat: @"%d", 
			    [[[object info] objectForKey: DCCInfoFileSize] intValue]],
			  [NSString stringWithFormat: @"%d", [object cps]])];
		}
		if ([object isKindOf: [DCCSender class]])
		{
			if ([[object status] isEqualToString: DCCStatusConnecting])
			{
			[attr appendAttributedString: 
			  BuildAttributedFormat(@"%@. %@ You have offered to send %@ to %@",
			  [NSString stringWithFormat: @"%d", index + 1],
			  BuildAttributedString([NSNull null], IRCBold, IRCBoldValue, @"OFFERED", nil),
			  [object path],  
			  [object receiver])];
			}
			else
			{
			[attr appendAttributedString: 
			  BuildAttributedFormat(@"%@. %@ You are sending %@ to %@ (%@ of %@ bytes @ %@ cps)",
			  [NSString stringWithFormat: @"%d", index + 1],
			  BuildAttributedString([NSNull null], IRCBold, IRCBoldValue, @"SENDING", nil),
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
	
	[attr appendAttributedString: 
	  S2AS(@"End of list.")];

	return attr;
}
- (NSAttributedString *)commandDCCGET: (NSString *)command connection: (id)connection
{
	id x;
	id path;
	id dict;
	int number;
	BOOL tryContinue = NO, isDir;
	id dfm;
	id getter;
	NSMutableArray *connections;
	
	connections = [self getConnectionTable: connection];
	
	x = [command separateIntoNumberOfArguments: 2];
	
	if ([x count] == 0)
	{
		return BuildAttributedString(@"Usage: /dcc get <#> [-c] [filename]", @"\n",
		  @"Receives the file at <#> position (see /dcc list)."
		  @"If [filename] isn't specified, it will be put into the default",
		  @" directory (see /dcc setdir) with the filename specified by the sender.",
		  nil);
	}

	number = [[x objectAtIndex: 0] intValue] - 1;
	
	if (number >= [connections count] || 
	    !([(dict = [connections objectAtIndex: number]) isKindOf: [NSDictionary class]]))
	{
		return BuildAttributedString(@"The specified index is invalid. Please see /dcc list.", nil);
	}
	
	path = @"";
	
	if ([x count] == 2)
	{
		path = [x objectAtIndex: 1];
		if ([path hasPrefix: @"-c"])
		{
			x = [path separateIntoNumberOfArguments: 2];
			tryContinue = YES;
			
			if ([x count] <= 1)
			{
				path = @"";
			}
			else
			{
				path = [x objectAtIndex: 1];
			}
		}
	}
	
	if ([path length] == 0)
	{
		path = [dict objectForKey: DCCInfoFileName];
		path = fix_file_name(path);
		path = [NSString stringWithFormat: @"%@/%@", get_default(dcc_dir), path];
	}
	
	path = [path stringByExpandingTildeInPath];
	path = [path stringByStandardizingPath];

	dfm = [NSFileManager defaultManager];
	if ([dfm fileExistsAtPath: path isDirectory: &isDir])
	{
		if (isDir || !tryContinue)
		{
			if ((path = unique_path(path)) == nil)
			{
				return S2AS(@"Could not find a unique file name.");
			}
		}
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
		return BuildAttributedString(@"Usage: /dcc setdir [-f] <directory>", @"\n",
		  @"Sets the default download directory to <directory>, if -f is specified ",
		  @"the directory will be created if it doesn't already exist.", @"\n",
		  @"Currently: ", [get_default(dcc_dir) stringByExpandingTildeInPath], nil);
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
			return S2AS(@"File exists at path.");
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
			return S2AS(@"Could not create directory.");
		}
	}
	else
	{
		couldCreate = NO;
	}
	
	if (couldCreate)
	{
		set_default(dcc_dir, dir);
		return S2AS(@"Ok.");
	}

	return S2AS(@"Directory does not exist. Try the -f flag.");
}
- (NSAttributedString *)commandDCC: (NSString *)command connection: (id)connection
{
	id x = [command separateIntoNumberOfArguments: 2];
	id arg;
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
	}
	
	return BuildAttributedString(@"Usage:", @"\n", 
	  @"/dcc list (lists current connections and requests)", @"\n",
	  @"/dcc get (receives a file)", @"\n",
	  @"/dcc setdir (sets default download directory)", @"\n",
	  @"/dcc send (sends a file)", @"\n",
	  @"/dcc gettimeout (sets timeout on receiving files)", @"\n",
	  @"/dcc sendtimeout (sets timeout on sending files)", @"\n",
	  @"/dcc abort (aborts a connection)",
	  nil);
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
	[invoc setTarget: self];
	[_TS_ addCommand: @"dcc" withInvocation: invoc];
	return self;
}
- pluginDeactivated
{
	[invoc setTarget: nil];
	[_TS_ removeCommand: @"dcc"];
	return self;
}
- (NSAttributedString *)pluginDescription
{
	return BuildAttributedString([NSNull null], IRCBold, IRCBoldValue,
	 @"Author: ", @"Andrew Ruder\n\n",
	 [NSNull null], IRCBold, IRCBoldValue,
	 @"Description: ", @"Provides a interface to DCC file transfer "
	 @"through the /dcc command.  Type /dcc when this bundle is loaded "
	 @"for more information.\n\n"
	 @"Copyright (C) 2003 by Andrew Ruder", nil);
}
- DCCSendRequestReceived: (NSDictionary *)aInfo onConnection: aConnection
{
	id connections;
	
	connections = [self getConnectionTable: aConnection];
	
	[connections addObject: aInfo];
	
	[[_TS_ pluginForOutput] showMessage: BuildAttributedFormat(
	  @"%@ (%@:%@) has requested to send %@ (%@ bytes)",
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

