/***************************************************************************
                                DCCSender.m
                          -------------------
    begin                : Wed Jan  7 21:13:07 CST 2004
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

#import "DCCSender.h"

#import "DCCObject.h"
#import "DCCSupport.h"
#import <TalkSoupBundles/TalkSoup.h>

#import <Foundation/NSFileHandle.h>
#import <Foundation/NSString.h>
#import <Foundation/NSTimer.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSHost.h>
#import <Foundation/NSFileManager.h> 

#define get_default(_x) [DCCSupport defaultsObjectForKey: _x]
#define set_default(_x, _y) \
{	[DCCSupport setDefaultsObject: _y forKey: _x];\
	[controller reloadData];}

#define GET_DEFAULT_INT(_x) [get_default(_x) intValue]
#define SET_DEFAULT_INT(_x, _y) set_default(_x, ([NSString stringWithFormat: @"%d", _y]))

@implementation DCCSender
- initWithFilename: (NSString *)aPath 
    withConnection: aConnection to: (NSString *)aReceiver withDelegate: aDel;
{
	id dfm;
	NSNumber *fileSize;
	id dict;
	id range;
	int low, high;
	
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
	
	range = get_default(DCCPortRange);

	range = [NSMutableArray arrayWithArray: [range 
	   componentsSeparatedByString: @"-"]];
	[range removeObject: @""];

	if ([range count] < 2)
	{
		low = -1;
		high = -1;
	}
	else
	{
		low = [[range objectAtIndex: 0] intValue];
		high = [[range objectAtIndex: 1] intValue];
	}

	sender = [[DCCSendObject alloc] initWithSendOfFile: [path lastPathComponent]  
	  withSize: fileSize
	  withDelegate: self withTimeout: GET_DEFAULT_INT(DCCSendTimeout) 
	  withBlockSize: GET_DEFAULT_INT(DCCBlockSize) withUserInfo: nil
	  withPort: low to: high];
	
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
