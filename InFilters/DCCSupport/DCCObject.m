/***************************************************************************
                                DCCObject.m
                          -------------------
    begin                : Wed Jul  2 15:23:24 CDT 2003
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

#import "DCCObject.h"

#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSHost.h>
#import <Foundation/NSTimer.h>
#import <Foundation/NSData.h>

#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <string.h>

NSString *DCCStatusTransferring = @"DCCStatusTransferring";
NSString *DCCStatusError = @"DCCStatusError";
NSString *DCCStatusDone = @"DCCStatusDone";
NSString *DCCStatusConnecting = @"DCCStatusConnecting";
NSString *DCCStatusAborted = @"DCCStatusAborted";
NSString *DCCStatusTimeout = @"DCCStatusTimeout";

NSString *DCCInfoFileName = @"DCCInfoFileName";
NSString *DCCInfoFileSize = @"DCCInfoFileSize";
NSString *DCCInfoPort = @"DCCInfoPort";
NSString *DCCInfoHost = @"DCCInfoHost";
NSString *DCCInfoNick = @"DCCInfoNick";

NSString *BuildDCCSendRequest(NSDictionary *info)
{
	struct in_addr inp;
	NSMutableString *file = [NSMutableString stringWithString: 
	       [info objectForKey: DCCInfoFileName]];
	NSNumber *size = [info objectForKey: DCCInfoFileSize];
	NSNumber *port = [info objectForKey: DCCInfoPort];
	NSHost *address = [info objectForKey: DCCInfoHost];
	
	if (!address) return nil;
	
	[file replaceOccurrencesOfString: @" " withString: @"_" options: 0
	  range: NSMakeRange(0, [file length])];
	
	inet_aton([[address address] cString], &inp);
	
	return [NSString stringWithFormat: @"SEND %@ %lu %hu %lu",
	  file, ntohl(inp.s_addr), [port unsignedShortValue],
	  [size unsignedLongValue]];
}

@implementation DCCObject
- initWithDelegate: aDelegate withInfo: (NSDictionary *)aInfo
    withUserInfo: (NSDictionary *)aUserInfo
{
	if (!(self = [super init])) return nil;
	
	delegate = aDelegate;
	info = RETAIN(aInfo);
	userInfo = RETAIN(aUserInfo);

	[delegate DCCInitiated: self];
	
	status = RETAIN(DCCStatusConnecting);
	[delegate DCCStatusChanged: status forObject: self];

	return self;
}
- (void)dealloc
{
	DESTROY(status);
	DESTROY(info);
	DESTROY(userInfo);
	delegate = nil;
	[super dealloc];
}
- (uint32_t)transferredBytes
{
	return transferredBytes;
}
- (void)abortConnection
{	
	RELEASE(status);
	status = RETAIN(DCCStatusAborted);
	[delegate DCCStatusChanged: status forObject: self];

	if (transport)
	{
		[[NetApplication sharedInstance] disconnectObject: self];
	}
}
- connectionEstablished: aTransport
{
	transport = RETAIN(aTransport);
	[[NetApplication sharedInstance] connectObject: self];
	
	RELEASE(status);
	status = RETAIN(DCCStatusTransferring);
	[delegate DCCStatusChanged: status forObject: self];
	
	return self;
}
- (void)connectionLost
{
	[transport close];
	DESTROY(transport);
	[delegate DCCDone: self];
}
- dataReceived: (NSData *)data
{
	return self;
}
- transport
{
	return transport;
}
- (NSDictionary *)info
{
	return info;
}
- (NSString *)status
{
	return status;
}
- (NSDictionary *)userInfo
{
	return userInfo;
}
@end

@implementation DCCReceiveObject
- initWithReceiveOfFile: (NSDictionary *)aInfo 
           withDelegate: aDelegate
		   withTimeout: (int)seconds
		   withUserInfo: (NSDictionary *)aUserInfo
{
	if (!(self = [super initWithDelegate: aDelegate 
	  withInfo: aInfo withUserInfo: aUserInfo])) return nil;
	
	connection = RETAIN([[TCPSystem sharedInstance] 
	  connectNetObjectInBackground: self
	  toHost: [aInfo objectForKey: DCCInfoHost]
	  onPort: [[aInfo objectForKey: DCCInfoPort] unsignedShortValue]
	  withTimeout: seconds]);
	
	return self;
}
- (void)abortConnection
{
	[super abortConnection];
	if (connection)
	{
		DESTROY(connection);
		[self connectionLost];
	}
}	
- dataReceived: (NSData *)data
{
	uint32_t len;
	
	transferredBytes += [data length];

	len = htonl(transferredBytes);	
	
	[transport writeData: [NSData dataWithBytes: &len length: sizeof(len)]];

	[delegate DCCReceivedData: (NSData *)data forObject: self];

	return self;
}
- connectionEstablished: aTransport
{
	DESTROY(connection);
	[super connectionEstablished: aTransport];
	
	return self;
}
- (void)connectionLost
{
	if ([status isEqualToString: DCCStatusTransferring])
	{
		if ((int)transferredBytes < [[info objectForKey: DCCInfoFileSize] intValue])
		{
			RELEASE(status);
			status = RETAIN(DCCStatusError);
		}
		else
		{
			RELEASE(status);
			status = RETAIN(DCCStatusDone);
		}
		[delegate DCCStatusChanged: status forObject: self];
	}
	
	[super connectionLost];
}
- connectingFailed: (NSString *)anError
{
	if ([anError isEqualToString: NetclassesErrorTimeout])
	{
		RELEASE(status);
		status = RETAIN(DCCStatusTimeout);
	}
	else
	{
		RELEASE(status);
		status = RETAIN(DCCStatusError);
	}
	
	[delegate DCCStatusChanged: status forObject: self];
	
	DESTROY(connection);
	[self connectionLost];
	
	return self;
}
- connectingStarted: (TCPConnecting *)aConnection
{
	return self;
}
@end

static id connection_holder = nil;

@interface DCCConnectionHolder : NSObject < NetObject >
- (void)connectionLost;
- connectionEstablished: aTransport;
- dataReceived: (NSData *)data;
- transport;
@end

@implementation DCCConnectionHolder
- (void)connectionLost
{
}
- connectionEstablished: aTransport
{
	connection_holder = RETAIN(aTransport);
	return self;
}
- dataReceived: (NSData *)data
{
	return self;
}
- transport
{
	return nil;
}
@end

@interface DCCSendObject (InternalSendObject)
- portTimeout;
- checkAndWrite;
@end

@interface DCCSendObjectPort : TCPPort
	{
		id delegate;
	}
- initOnPort: (int)aPort withDelegate: aDelegate;
@end

@implementation DCCSendObjectPort
- initOnPort: (int)aPort withDelegate: aDelegate
{
	if (!(self = [super initOnPort: aPort])) return nil;
	delegate = aDelegate;
	return self;
}
- newConnection
{
	[super newConnection];
	[delegate connectionEstablished: connection_holder];
	DESTROY(connection_holder);
	return self;
}
- timeoutReceived: (NSTimer *)aTimer
{
	[delegate portTimeout];
	return self;
}
@end

@implementation DCCSendObject (InternalSendObject)
- portTimeout
{
	if (port)
	{
		[[NetApplication sharedInstance] disconnectObject: port];
		[timeout invalidate];
		DESTROY(timeout);
		DESTROY(port);
		RELEASE(status);
		status = RETAIN(DCCStatusTimeout);
		[delegate DCCStatusChanged: status forObject: self];
		[self connectionLost];
	}
	return self;
}
- checkAndWrite
{
	int length = [dataToWrite length];
	
	if (confirmedBytes != transferredBytes) // They must acknowledge everything
	{
		return self;
	}

	if (length > (int)blockSize)
	{
		char *buffer = [dataToWrite mutableBytes];

		[transport writeData: [NSData dataWithBytes: buffer length: blockSize]];
		transferredBytes += blockSize;
		memmove(buffer, buffer + blockSize, length - blockSize);
		[dataToWrite setLength: length - blockSize];
	}
	else if (length == (int)blockSize)
	{
		[transport writeData: dataToWrite];
		[dataToWrite setLength: 0];
		transferredBytes += blockSize;
	}
	else 
	{
		if (noMoreData)
		{
			if (length == 0) // No data to send and no more is coming
			{
				[[NetApplication sharedInstance] disconnectObject: self];
				return self;
			}
			[transport writeData: dataToWrite];
			[dataToWrite setLength: 0];
			transferredBytes += length;
		}
		else
		{
			[delegate DCCNeedsMoreData: self];
		}
	}
	return self;
}
@end
	
@implementation DCCSendObject
- initWithSendOfFile: (NSString *)name
    withSize: (NSNumber *)size
    withDelegate: aDelegate
    withTimeout: (int)seconds withBlockSize: (uint32_t)numBytes
    withUserInfo: (NSDictionary *)aUserInfo
{
	id address;
	id portNum;

	if (!(self = [super initWithDelegate: aDelegate
	  withInfo: AUTORELEASE([NSDictionary new]) 
	  withUserInfo: aUserInfo])) return nil;
	
	if (seconds < 0)
	{
		[self dealloc];
		return nil;
	}
	
	if ([name length] == 0)
	{
		[self dealloc];
		return nil;
	}

	if ([size unsignedLongValue] == 0)
	{
		[self dealloc];
		return nil;
	}
	
	port = [[[DCCSendObjectPort alloc] initOnPort: 0 withDelegate: self]
	 setNetObject: [DCCConnectionHolder class]];

	if (!port)
	{
		[self dealloc];
		return nil;
	}

	if (numBytes <= 0)
	{
		[self dealloc];
		return nil;
	}
	
	if (seconds > 0)
	{
		timeout = RETAIN([NSTimer scheduledTimerWithTimeInterval:
		 (NSTimeInterval)seconds target: port 
		 selector: @selector(timeoutReceived:)
		 userInfo: nil repeats: NO]);
	}
	
	blockSize = numBytes;
	
	receivedData = [[NSMutableData alloc] initWithCapacity: 12];

	dataToWrite = [[NSMutableData alloc] initWithCapacity: blockSize * 2];

	address = [aDelegate localHost]; 
	
	portNum = [NSNumber numberWithUnsignedShort: [port port]];
	
	RELEASE(info);
	info = [[NSDictionary alloc] initWithObjectsAndKeys: 
	  name, DCCInfoFileName,
	  size, DCCInfoFileSize,
	  portNum, DCCInfoPort,
	  address, DCCInfoHost,
	  nil];
	
	return self;
}
- (void)dealloc
{
	if (port)
	{
		[[NetApplication sharedInstance] disconnectObject: port];
		DESTROY(port);
		[timeout invalidate];
		DESTROY(timeout);
	}
	DESTROY(receivedData);
	DESTROY(dataToWrite);
	[super dealloc];
}
- (void)abortConnection
{
	[super abortConnection];
	if (port)
	{
		[[NetApplication sharedInstance] disconnectObject: port];
		DESTROY(port);
		if (timeout)
		{
			[timeout invalidate];
			DESTROY(timeout);
		}
		[self connectionLost];
	}
}		
- connectionEstablished: aTransport
{
	[super connectionEstablished: aTransport];
	
	[[NetApplication sharedInstance] disconnectObject: port];
	DESTROY(port);
	
	if (timeout)
	{
		[timeout invalidate];
		DESTROY(timeout);
	}
	
	[self checkAndWrite];

	return self;
}
- dataReceived: (NSData *)data
{
	char *buffer;
	char *index;
	char *bufferEnd;
	
	[receivedData appendData: data];

	index = buffer = [receivedData mutableBytes];
	
	bufferEnd = buffer + [receivedData length];

	while((index + 3) < bufferEnd)
	{
		confirmedBytes = ntohl(*((unsigned long int *)index));
				
		index += 4;
	}

	memmove(buffer, index, bufferEnd - index);
	
	[receivedData setLength: bufferEnd - index];
	
	if (confirmedBytes > transferredBytes)
	{
		[[NetApplication sharedInstance] disconnectObject: self];
	}
	
	[self checkAndWrite];
	
	return self;
}
- (void)connectionLost
{
	if ([status isEqualToString: DCCStatusTransferring])
	{
		if ((int)confirmedBytes != [[info objectForKey: DCCInfoFileSize] intValue])
		{
			RELEASE(status);
			status = RETAIN(DCCStatusError);
		}
		else
		{
			RELEASE(status);
			status = RETAIN(DCCStatusDone);
		}
		[delegate DCCStatusChanged: status forObject: self];
	}
	
	[super connectionLost];
}
- writeData: (NSData *)someData
{
	if (noMoreData)
	{
		[self checkAndWrite];
		return self;
	}
	if (!someData)
	{
		noMoreData = YES;
	}
	else
	{
		[dataToWrite appendData: someData];
	}
	[self checkAndWrite];
	return self;
}
- (uint32_t)blockSize
{
	return blockSize;
}
@end

