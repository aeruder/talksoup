/***************************************************************************
                                NetTCP.m
                          -------------------
    begin                : Fri Nov  2 01:19:16 UTC 2001
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
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <netdb.h>
#include <fcntl.h>

#include "NetTCP.h"
#include <Foundation/NSString.h>
#include <Foundation/NSData.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSTimer.h>
#include <Foundation/NSException.h>
#include <Foundation/NSHost.h>

#ifdef IDENT
	#undef IDENT
#endif

#define IDENT

static TCPSystem *default_system = nil;

@interface TCPConnecting (InternalTCPConnecting)
- initWithNetObject: (id)netObject withTimeout: (int)aTimeout;
- connectingFailed: (NSString *)error;
- connectingSucceeded;
- timeoutReceived: (NSTimer *)aTimer;
@end
	
@interface TCPConnectingTransport : NSObject < NetTransport >
	{
		BOOL connected;
		int desc;
		NSHost *address;
		NSMutableData *writeBuffer;
		TCPConnecting *owner;	
	}
- (NSMutableData *)writeBuffer;

- initWithDesc: (int)aDesc atAddress: (NSHost *)theAddress
     withOwner: (TCPConnecting *)anObject;
	 
- (void)close;

- (NSData *)readData: (int)maxDataSize;
- (BOOL)isDoneWriting;
- writeData: (NSData *)data;

- (NSHost *)address;
- (int)desc;
@end

@implementation TCPConnectingTransport
- (NSMutableData *)writeBuffer
{
	return writeBuffer;
}
- initWithDesc: (int)aDesc atAddress: (NSHost *)theAddress 
     withOwner: (TCPConnecting *)anObject
{
	if (!(self = [super init])) return nil;
	
	desc = aDesc;

	writeBuffer = [NSMutableData new];
	address = RETAIN(theAddress);
		
	owner = anObject;
	connected = YES;
	
	[[NetApplication sharedInstance] transportNeedsToWrite: self];

	return self;
}
- (void)dealloc
{
	RELEASE(writeBuffer);
	RELEASE(address);

	[super dealloc];
}
- (NSData *)readData: (int)maxDataSize
{
	return nil;
}
- (BOOL)isDoneWriting
{
	return YES;
}

#undef IDENT
#define IDENT(_x) @"[TCPConnectingTransport writeData: %@] " _x, data

- writeData: (NSData *)data
{
	char buffer[1];
	if (data)
	{
		[writeBuffer appendData: data];
		return self;
	}
	
	if (recv(desc, buffer, sizeof(buffer), MSG_PEEK) == -1)
	{
		if (errno != EAGAIN)
		{
			[owner connectingFailed: [NSString stringWithFormat:
			 IDENT(@"recv() failed: %s"), strerror(errno)]];
			return self;
		}
	}
	
	[owner connectingSucceeded];
	return self;
}
- (NSHost *)address
{
	return address;
}
- (int)desc
{
	return desc;
}
- (void)close
{
	if (connected)
	{
		close(desc);
		connected = NO;
	}
}
@end

@implementation TCPConnecting (InternalTCPConnecting)
- initWithNetObject: (id)aNetObject withTimeout: (int)aTimeout
{
	if (!(self = [super init])) return nil;
	
	netObject = RETAIN(aNetObject);
	if (aTimeout > 0)
	{
		timeout = RETAIN([NSTimer scheduledTimerWithTimeInterval:
		    (NSTimeInterval)aTimeout
		  target: self selector: @selector(timeoutReceived:)
		  userInfo: nil repeats: NO]);
	}
		
	return self;
}
- connectingFailed: (NSString *)error
{
	if ([netObject conformsTo: @protocol(TCPConnecting)])
	{
		[netObject connectingFailed: error];
	}
	[timeout invalidate];
	[transport close];
	[[NetApplication sharedInstance] disconnectObject: self];

	return self;
}
- connectingSucceeded
{
	id newTrans = AUTORELEASE([[TCPTransport alloc] initWithDesc:
	    [transport desc]
	  atAddress: [transport address]]);
	id buffer = RETAIN([transport writeBuffer]);
	
	[timeout invalidate];
	
	[[NetApplication sharedInstance] disconnectObject: self];
	[netObject connectionEstablished: newTrans];

	[newTrans writeData: buffer];
	RELEASE(buffer);

	return self;
}
- timeoutReceived: (NSTimer *)aTimer
{	
	if (aTimer != timeout)
	{
		[aTimer invalidate];
	}
	[self connectingFailed: @"Timeout reached"];
	
	return self;
}
@end

@implementation TCPConnecting
- (void)dealloc
{
	RELEASE(netObject);
	RELEASE(timeout);
	
	[super dealloc];
}
- (id)netObject
{
	return netObject;
}
- (void)abortConnection
{
	[self connectingFailed: @"Aborted Connection"];
}
- (void)connectionLost
{
	DESTROY(transport);
}
- connectionEstablished: aTransport
{
	transport = RETAIN(aTransport);	
	[[NetApplication sharedInstance] connectObject: self];
	if ([netObject conformsTo: @protocol(TCPConnecting)])
	{
		[netObject connectingStarted: self];
	}
	return self;
}
- dataReceived: (NSData *)data
{
	return self;
}
- (id)transport
{
	return transport;
}
@end

@interface TCPSystem (InternalTCPSystem)
- (int)openPort: (int)portNumber;
- (int)openPort: (int)portNumber onHost: (NSHost *)aHost;
- (int)openPort: (int)portNumber onHost: (NSHost *)aHost
    withInfo: (struct sockaddr_in *)info;

- (int)connectToHost: (NSHost *)aHost onPort: (int)portNumber
         withTimeout: (int)timeout;

- (int)connectToHostInBackground: (NSHost *)aHost onPort: (int)portNumber;

- setErrorString: (NSString *)anError;
@end

@implementation TCPSystem (InternalTCPSystem)
- (int)openPort: (int)portNumber
{
	return [self openPort: portNumber onHost: nil withInfo: 0];
}
- (int)openPort: (int)portNumber onHost: (NSHost *)aHost
{
	return [self openPort: portNumber onHost: aHost withInfo: 0];
}

#undef IDENT
#define IDENT(_x) @"[TCPSystem openPort: %d onHost: %@] " _x, portNumber, aHost

- (int)openPort: (int)portNumber onHost: (NSHost *)aHost
    withInfo: (struct sockaddr_in *)info
{
	struct sockaddr_in sin;
	int temp;
	int myDesc;
	
	if (portNumber < 0)
	{
		[self setErrorString: 
		 [NSString stringWithFormat: 
		 IDENT(@"%d is not a valid port number"), portNumber]];
		return -1;
	} 
	memset(&sin, 0, sizeof(struct sockaddr_in));
	
	if (!aHost)
	{
		sin.sin_addr.s_addr = htonl(INADDR_ANY);
	}
	else
	{
		if (inet_aton([[aHost address] cString], &(sin.sin_addr)) == 0)
		{
			[self setErrorString:
			  [NSString stringWithFormat:
				IDENT(@"Invalid address")]]; 
		}	      
	}
	
	sin.sin_port = htons(portNumber);
	sin.sin_family = AF_INET;
	
	if ((myDesc = socket(AF_INET, SOCK_STREAM, 0)) == -1)
	{
		[self setErrorString: [NSString stringWithFormat:
		 IDENT(@"socket(): %s"), strerror(errno)]];
		return -1;
	}
	if (bind(myDesc, (struct sockaddr *) &sin, sizeof(struct sockaddr)) < 0)
	{
		close(myDesc);
		[self setErrorString: [NSString stringWithFormat:
		 IDENT(@"bind(): %s"), strerror(errno)]];
		return -1;
	}
	temp = 1;
	if (setsockopt(myDesc, SOL_SOCKET, SO_KEEPALIVE, 
	               &temp, sizeof(temp)) == -1)
	{
		close(myDesc);
		[self setErrorString: [NSString stringWithFormat:
		 IDENT(@"setsockopt(KEEPALIVE): %s"), strerror(errno)]];
		return -1;
	}
	temp = 1;
	if (setsockopt(myDesc, SOL_SOCKET, SO_REUSEADDR, 
	               &temp, sizeof(temp)) == -1)
	{
		close(myDesc);
		[self setErrorString: [NSString stringWithFormat:
		 IDENT(@"setsockopt(REUSEADDR): %s"), strerror(errno)]];
		return -1;
	}
	if (listen(myDesc, 5) == -1)
	{
		close(myDesc);
		[self setErrorString: [NSString stringWithFormat:
		 IDENT(@"listen(): %s"), strerror(errno)]];
		return -1;
	}
	
	if (info)
	{
		socklen_t len = sizeof(struct sockaddr_in);
		memcpy(info, &sin, sizeof(struct sockaddr_in));
		getsockname(myDesc, (struct sockaddr *)info, &len);
	}

	return myDesc;
}

#undef IDENT
#define IDENT(_x) @"[TCPSystem connectToHost: %@ onPort: %@ " \
                  @"withTimeout: %d ]" _x,  host, portNumber, timeout

- (int)connectToHost: (NSHost *)host onPort: (int)portNumber 
       withTimeout: (int)timeout
{
	int myDesc;
	struct sockaddr_in destAddr;

	if (!host)
	{
		[self setErrorString: [NSString stringWithFormat: 
		 IDENT(@"Host cannot be nil")]];
		return -1;
	}
	
	if ((myDesc = socket(AF_INET, SOCK_STREAM, 0)) == -1)
	{
		[self setErrorString: [NSString stringWithFormat:
		 IDENT(@"socket(): %s"), strerror(errno)]];
		return -1;
	}

	destAddr.sin_family = AF_INET;
	destAddr.sin_port = htons(portNumber);
	if (!(inet_aton([[host address] cString], &destAddr.sin_addr)))
	{
		[self setErrorString: [NSString stringWithFormat:
		 IDENT(@"Invalid address")]];
		close(myDesc);
		return -1;
	}
	memset(&(destAddr.sin_zero), 0, sizeof(destAddr.sin_zero));

	if (timeout > 0)
	{
		if (fcntl(myDesc, F_SETFL, O_NONBLOCK) == -1)
		{
			[self setErrorString: [NSString stringWithFormat:
			 IDENT(@"fcntl(O_NONBLOCK): %s"), strerror(errno)]];
			close(myDesc);
			return -1;
		}
	}
	if (connect(myDesc, (struct sockaddr *)&destAddr, sizeof(destAddr)) == -1)
	{
		if (errno == EINPROGRESS) // Need to work with timeout now.
		{
			fd_set fdset;
			struct timeval selectTime;
			int selectReturn;

			FD_ZERO(&fdset);
			FD_SET(myDesc, &fdset);

			selectTime.tv_sec = timeout;
			selectTime.tv_usec = 0;

			selectReturn = select(myDesc + 1, 0, &fdset, 0, &selectTime);

			if (selectReturn == -1)
			{
				[self setErrorString: [NSString stringWithFormat:
				 IDENT(@"select(): %s"), strerror(errno)]];
				close(myDesc);
				return -1;
			}
			if (selectReturn > 0)
			{
				char buffer[1];
				if (recv(myDesc, buffer, sizeof(buffer), MSG_PEEK) == -1)
				{
					if (errno != EAGAIN)
					{
						[self setErrorString: [NSString stringWithFormat:
						 IDENT(@"recv(): %s"), strerror(errno)]];
						close(myDesc);
						return -1;
					}
				}
			}
			else
			{
				[self setErrorString: [NSString stringWithFormat:
				 IDENT(@"Connection timeout")]];
				close(myDesc);
				return -1;
			}
		}
		else // connect failed with something other than EINPROGRESS
		{
			[self setErrorString: [NSString stringWithFormat:
			 IDENT(@"connect(): %s"), strerror(errno)]];
			close(myDesc);
			return -1;
		}
	}
	return myDesc;
}

#undef IDENT
#define IDENT(_x) @"[TCPSystem connectToHostInBackground: %@ " \
                  @"onPort: %d] " _x, host, portNumber
                  
- (int)connectToHostInBackground: (NSHost *)host onPort: (int)portNumber
{
	int myDesc;
	struct sockaddr_in destAddr;

	if (!host)
	{
		[self setErrorString: [NSString stringWithFormat: 
		 IDENT(@"Host cannot be nil")]];
		return -1;
	}
	
	if ((myDesc = socket(AF_INET, SOCK_STREAM, 0)) == -1)
	{
		[self setErrorString: [NSString stringWithFormat:
		 IDENT(@"socket(): %s"), strerror(errno)]];
		return -1;
	}

	destAddr.sin_family = AF_INET;
	destAddr.sin_port = htons(portNumber);
	if (!(inet_aton([[host address] cString], &destAddr.sin_addr)))
	{
		[self setErrorString: [NSString stringWithFormat:
		 IDENT(@"Invalid address")]];
		close(myDesc);
		return -1;
	}
	memset(&(destAddr.sin_zero), 0, sizeof(destAddr.sin_zero));

	if (fcntl(myDesc, F_SETFL, O_NONBLOCK) == -1)
	{
		[self setErrorString: [NSString stringWithFormat:
		 IDENT(@"fcntl(O_NONBLOCK): %s"), strerror(errno)]];
		close(myDesc);
		return -1;
	}
	
	if (connect(myDesc, (struct sockaddr *)&destAddr, sizeof(destAddr)) == -1)
	{
		if (errno == EINPROGRESS)
		{
			return myDesc;
		}
		else // connect failed with something other than EINPROGRESS
		{
			[self setErrorString: [NSString stringWithFormat:
			 IDENT(@"connect(): %s"), strerror(errno)]];
			close(myDesc);
			return -1;
		}
	}
	
	return myDesc;
}
- setErrorString: (NSString *)anError
{
	if (anError == errorString) return self;

	RELEASE(errorString);
	errorString = RETAIN(anError);

	return self;
}
@end		
	
@implementation TCPSystem
+ sharedInstance
{
	return (default_system) ? default_system : [[self alloc] init];
}
- init
{
	if (!(self = [super init])) return nil;
	
	if (default_system)
	{
		[self dealloc];
		return nil;
	}
	default_system = RETAIN(self);
	
	return self;
}
- (NSString *)errorString
{
	return errorString;
}
- (id)connectNetObject: (id)netObject toHost: (NSHost *)host
                onPort: (int)aPort withTimeout: (int)timeout
{
	int desc;
	id transport;

	host = [NSHost hostWithAddress: [host address]];
	
	desc = [self connectToHost: host onPort: aPort withTimeout: timeout];
	if (desc < 0)
	{
		return nil;
	}
	transport = AUTORELEASE([[TCPTransport alloc] initWithDesc: desc 
	              atAddress: host]);
	
	if (!(transport))
	{
		return nil;
	}

	[netObject connectionEstablished: transport];
	
	return netObject;
}
- (TCPConnecting *)connectNetObjectInBackground: (id)netObject 
    toHost: (NSHost *)host onPort: (int)aPort withTimeout: (int)timeout
{
	int desc;
	id transport;
	id object;

	host = [NSHost hostWithAddress: [host address]];

	desc = [self connectToHostInBackground: host onPort: aPort];
	if (desc < 0)
	{
		return nil;
	}
	
	object = AUTORELEASE([[TCPConnecting alloc] initWithNetObject: netObject
	   withTimeout: timeout]);
	transport = AUTORELEASE([[TCPConnectingTransport alloc] initWithDesc: desc 
	              atAddress: host withOwner: object]);
	
	if (!transport)
	{
		return nil;
	}
	
	[object connectionEstablished: transport];
	
	return object;
}
- (NSHost *)hostFromInt: (unsigned long int)ip
{
	struct in_addr addr;
	char *temp;
	
	addr.s_addr = ip;

	temp = inet_ntoa(addr);
	if (temp)
	{
		return [NSHost hostWithAddress: [NSString stringWithCString: temp]];
	}

	return nil;
}

#undef IDENT
#define IDENT(_x) @"[TCPSystem localIpForTransport: %@] "

- (NSHost *)hostForTransport: (TCPTransport *)aTransport
{
	struct sockaddr_in x;
	socklen_t address_length = sizeof(x);
	
	if (
	 getsockname([aTransport desc], (struct sockaddr *)&x, &address_length) 
	  != 0)
	{
		[self setErrorString: [NSString stringWithFormat: 
		 IDENT(@"getsockname() failed: %s"), strerror(errno)]];
		return nil;
	}

	return [NSString stringWithCString: inet_ntoa(x.sin_addr)];
}	
@end


@implementation TCPPort
- initOnHost: (NSHost *)aHost onPort: (int)aPort
{
	if (!(self = [super init])) return nil;
	
	desc = [[TCPSystem sharedInstance] openPort: aPort onHost: aHost
	  withInfo: &socketInfo];

	if (desc < 0)
	{
		[self dealloc];
		return nil;
	}

	[[NetApplication sharedInstance] connectObject: self];
	return self;
}
- initOnPort: (int)aPort
{
	return [self initOnHost: nil onPort: aPort];
}

#undef IDENT
#define IDENT(_x) @"[TCPPort setNetObject: (Class)%@] " _x, \
                  NSStringFromClass(aClass)

- setNetObject: (Class)aClass
{
	if (![aClass conformsToProtocol: @protocol(NetObject)])
	{
		[NSException raise: FatalNetException
		  format: IDENT(@"%@ does not conform to < NetObject >"),
		    NSStringFromClass(aClass)];
	}
	
	netObjectClass = aClass;
	return self;
}
- (int)desc
{
	return desc;
}
- (void)connectionLost
{
	close(desc);
}

#undef IDENT
#define IDENT(_x) @"[TCPPort newConnection] " _x

- newConnection
{
	int newDesc;
	struct sockaddr_in sin;
	int temp;
	TCPTransport *transport;
	NSHost *newAddress;
	
	temp = sizeof(struct sockaddr_in);
	
	if ((newDesc = accept(desc, (struct sockaddr *)&sin, 
	    &temp)) == -1)
	{
		[NSException raise: FatalNetException
		  format: IDENT(@"accept(): %s"), strerror(errno)];
	}
	
	newAddress = [[TCPSystem sharedInstance] hostFromInt: sin.sin_addr.s_addr];	

	transport = AUTORELEASE([[TCPTransport alloc] 
	  initWithDesc: newDesc
	     atAddress: [[TCPSystem sharedInstance] hostFromInt: 
	       sin.sin_addr.s_addr]]);
	
	if (!transport)
		return self;
	
	[AUTORELEASE([netObjectClass new]) connectionEstablished: transport];
	
	return self;
}
- (struct sockaddr_in *)socketInfo
{
	return &socketInfo;
}
@end

static NetApplication *net_app = nil; 

@implementation TCPTransport
+ (void)initialize
{
	net_app = RETAIN([NetApplication sharedInstance]);
}
- initWithDesc: (int)aDesc atAddress:(NSHost *)theAddress
{
	if (!(self = [super init])) return nil;
	
	desc = aDesc;
	
	writeBuffer = RETAIN([NSMutableData dataWithCapacity: 2000]);
	address = RETAIN(theAddress);
	
	connected = YES;
	
	return self;
}
- (void)dealloc
{
	RELEASE(writeBuffer);
	RELEASE(address);

	[super dealloc];
}

#undef IDENT
#define IDENT(_x) @"[TCPTransport readData: %d] " _x, maxDataSize

- (NSData *)readData: (int)maxDataSize
{
	char *buffer;
	int readReturn;
	NSData *data;
	
	if (!connected)
	{
		[NSException raise: FatalNetException
		  format: IDENT(@"Not connected")];
	}
	
	if (maxDataSize == 0)
	{
		return nil;
	}
	
	if (maxDataSize < 0)
	{
		[NSException raise: FatalNetException
		 format: IDENT(@"invalid number of bytes specified")];
	}
	
	buffer = malloc(maxDataSize + 1);
	readReturn = read(desc, buffer, maxDataSize);
	
	if (readReturn == 0)
	{
		free(buffer);
		[NSException raise: NetException
		 format: IDENT(@"socket closed")];
	}
	
	if (readReturn == -1)
	{
		free(buffer);
		[NSException raise: FatalNetException
		 format: IDENT(@"read(): %s"), strerror(errno)];
	}
	
	data = [NSData dataWithBytes: buffer length: readReturn];
	free(buffer);
	
	return data;
}

#undef IDENT
#define IDENT(_x) @"[TCPTransport isDoneWriting] " _x

- (BOOL)isDoneWriting
{
	if (!connected)
	{
		[NSException raise: FatalNetException
		  format: IDENT(@"Not connected")];
	}
	return ([writeBuffer length]) ? NO : YES;
}

#undef IDENT
#define IDENT(_x) @"[TCPTransport writeData:] " _x

- writeData: (NSData *)data
{
	int writeReturn;
	char *bytes;
	int length;
	
	if (data)
	{
		if ([writeBuffer length] == 0)
		{
			[net_app transportNeedsToWrite: self];
		}
		[writeBuffer appendData: data];
		return self;
	}
	if (!connected)
	{
		[NSException raise: FatalNetException
		  format: IDENT(@"Not connected")];
	}
	
	if ([writeBuffer length] == 0)
	{
		return self;
	}
	
	writeReturn = 
	  write(desc, [writeBuffer mutableBytes], [writeBuffer length]);

	if (writeReturn == -1)
	{
		[NSException raise: FatalNetException
		  format: IDENT(@"write(): %s"), strerror(errno)];
	}
	if (writeReturn == 0)
	{
		return self;
	}
	
	bytes = (char *)[writeBuffer mutableBytes];
	length = [writeBuffer length] - writeReturn;
	
	memmove(bytes, bytes + writeReturn, length);
	[writeBuffer setLength: length];
	
	return self;
}
- (NSHost *)address
{
	return address;	
}
- (int)desc
{
	return desc;
}
- (void)close
{
	if (!connected)
	{
		return;
	}
	connected = NO;
	close(desc);
}
@end	

#undef IDENT

