/***************************************************************************
                                DCCGetter.m
                          -------------------
    begin                : Wed Jan  7 21:08:21 CST 2004
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

#import "DCCGetter.h"

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
		if (![dfm createFileAtPath: aPath contents: AUTORELEASE([NSData new]) attributes: nil])
		{
			RELEASE(self);
			return nil;
		}
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
	  withDelegate: self withTimeout: GET_DEFAULT_INT(DCCGetTimeout) 
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
