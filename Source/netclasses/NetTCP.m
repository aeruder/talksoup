/***************************************************************************
                                NetTCP.m
                          -------------------
    begin                : Fri Nov  2 01:19:16 UTC 2001
    copyright            : (C) 2002 by Andy Ruder
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

#import "NetTCP.h"
#import <Foundation/NSString.h>
#import <Foundation/NSData.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSTimer.h>
#import <Foundation/NSException.h>

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
		NSString *address;
		NSMutableData *writeBuffer;
		TCPConnecting *owner;	
	}
- (NSMutableData *)writeBuffer;

- initWithDesc: (int)aDesc atAddress: (NSString *)theAddress
     withOwner: (TCPConnecting *)anObject;
	 
- (void)close;

- (NSData *)readData: (int)maxDataSize;
- (BOOL)isDoneWriting;
- writeData: (NSData *)data;

- (NSString *)address;
- (int)desc;
@end

@implementation TCPConnectingTransport
- (NSMutableData *)writeBuffer
{
	return writeBuffer;
}
- initWithDesc: (int)aDesc atAddress: (NSString *)theAddress 
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
- writeData: (NSData *)data
{
	char buffer[2];
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
			 @"[TCPConnectingTransport writeData: (nil)] recv() failed: %s",
			  strerror(errno)]];
			return self;
		}
	}
	
	[owner connectingSucceeded];
	return self;
}
- (NSString *)address
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
	if ([netObject conformsTo: @protocol(TCPConnecting)])
	{
		[netObject connectingFailed: @"Timeout reached"];
	}
	if (aTimer != timeout)
	{
		[aTimer invalidate];
	}
	
	[timeout invalidate];
	[transport close];
	[[NetApplication sharedInstance] disconnectObject: self];
	
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
	[timeout invalidate];
	[transport close];
	[[NetApplication sharedInstance] disconnectObject: self];
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
- (int)openPort: (int)portNumber onHost: (NSString *)aHost;
- (int)openPort: (int)portNumber onHost: (NSString *)aHost
    withInfo: (struct sockaddr_in *)info;

- (int)connectToIp: (NSString *)ip onPort: (int)portNumber 
       withTimeout: (int)timeout;
- (int)connectToHost: (NSString *)aHost onPort: (int)portNumber
         withTimeout: (int)timeout;

- (int)connectToIpInBackground: (NSString *)ip onPort: (int)portNumber;
- (int)connectToHostInBackground: (NSString *)aHost onPort: (int)portNumber;

- setErrorString: (NSString *)anError;
@end

static const char *my_hstrerror(int aError)
{
	struct MyErrorStruct
	{
		int errorNumber;
		const char *str;
	};

	const struct MyErrorStruct errorList[] =
	{
		{HOST_NOT_FOUND, "HOST_NOT_FOUND"},
		{NO_ADDRESS, "NO_ADDRESS"},
		{NO_RECOVERY, "NO_RECOVERY"},
		{TRY_AGAIN, "TRY_AGAIN"},
		{0, 0}
	};

	const struct MyErrorStruct *structPtr;

	for (structPtr = errorList; structPtr->str; structPtr++)
	{
		if (structPtr->errorNumber == aError)
		{
			return structPtr->str;
		}
	}
	
	return "Error Code not Found!";
}
			
@implementation TCPSystem (InternalTCPSystem)
- (int)openPort: (int)portNumber
{
	return [self openPort: portNumber onHost: nil withInfo: 0];
}
- (int)openPort: (int)portNumber onHost: (NSString *)aHost
{
	return [self openPort: portNumber onHost: aHost withInfo: 0];
}
- (int)openPort: (int)portNumber onHost: (NSString *)aHost
    withInfo: (struct sockaddr_in *)info
{
	struct sockaddr_in sin;
	int temp;
	int myDesc;
	
	if (portNumber < 0)
	{
		[self setErrorString: 
		 [NSString stringWithFormat: 
		 @"[TCPSystem openPort: %d onHost: %@] %d is not a valid port number.", 
		 portNumber, aHost, portNumber]];
		return -1;
	} 
	memset(&sin, 0, sizeof(struct sockaddr_in));
	
	if (!aHost)
	{
		sin.sin_addr.s_addr = htonl(INADDR_ANY);
	}
	else
	{
		struct hostent *host;
		host = gethostbyname([aHost cString]);
		if (!host)
		{
			[self setErrorString:
			 [NSString stringWithFormat: 
			 @"[TCPSystem openPort: %d onHost: %@] gethostbyname(): %s", 
			 portNumber, aHost, my_hstrerror(h_errno)]];
			return -1;
		}		
		memcpy(&(sin.sin_addr), host->h_addr, sizeof(struct in_addr));
	}
	
	sin.sin_port = htons(portNumber);
	sin.sin_family = AF_INET;
	
	if ((myDesc = socket(AF_INET, SOCK_STREAM, 0)) == -1)
	{
		[self setErrorString: [NSString stringWithFormat:
		 @"[TCPSystem openPort: %d onHost: %@] socket(): %s", 
		 portNumber, aHost, strerror(errno)]];
		return -1;
	}
	if (bind(myDesc, (struct sockaddr *) &sin, sizeof(struct sockaddr)) < 0)
	{
		close(myDesc);
		[self setErrorString: [NSString stringWithFormat:
		 @"[TCPSystem openPort: %d onHost: %@] bind(): %s", 
		 portNumber, aHost, strerror(errno)]];
		return -1;
	}
	temp = 1;
	if (setsockopt(myDesc, SOL_SOCKET, SO_KEEPALIVE, 
	               &temp, sizeof(temp)) == -1)
	{
		close(myDesc);
		[self setErrorString: [NSString stringWithFormat:
		 @"[TCPSystem openPort: %d onHost: %@] setsockopt(KEEPALIVE): %s",
		 portNumber, aHost, strerror(errno)]];
		return -1;
	}
	temp = 1;
	if (setsockopt(myDesc, SOL_SOCKET, SO_REUSEADDR, 
	               &temp, sizeof(temp)) == -1)
	{
		close(myDesc);
		[self setErrorString: [NSString stringWithFormat:
		 @"[TCPSystem openPort: %d onHost: %@] setsockopt(REUSEADDR): %s",
		 portNumber, aHost, strerror(errno)]];
		return -1;
	}
	if (listen(myDesc, 5) == -1)
	{
		close(myDesc);
		[self setErrorString: [NSString stringWithFormat:
		 @"[TCPSystem openPort: %d onHost: %@] listen(): %s",
		 portNumber, aHost, strerror(errno)]];
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
- (int)connectToIp: (NSString *)ip onPort: (int)portNumber 
       withTimeout: (int)timeout
{
	int myDesc;
	struct sockaddr_in destAddr;

	if (!ip)
	{
		[self setErrorString: [NSString stringWithFormat: 
		 @"[TCPSystem connectToIp: (nil) onPort: %d] Ip cannot be nil",
		 portNumber]];
		return -1;
	}
	
	if ((myDesc = socket(AF_INET, SOCK_STREAM, 0)) == -1)
	{
		[self setErrorString: [NSString stringWithFormat:
		 @"[TCPSystem connectToIp: %@ onPort: %d] socket(): %s",
		 ip, portNumber, strerror(errno)]];
		return -1;
	}

	destAddr.sin_family = AF_INET;
	destAddr.sin_port = htons(portNumber);
	if (!(inet_aton([ip cString], &destAddr.sin_addr)))
	{
		[self setErrorString: [NSString stringWithFormat:
		 @"[TCPSystem connectToIp: %@ onPort: %d] inet_aton(): Invalid IP",
		 ip, portNumber]];
		close(myDesc);
		return -1;
	}
	memset(&(destAddr.sin_zero), 0, sizeof(destAddr.sin_zero));

	if (timeout > 0)
	{
		if (fcntl(myDesc, F_SETFL, O_NONBLOCK) == -1)
		{
			[self setErrorString: [NSString stringWithFormat:
			 @"[TCPSystem connectToIp: %@ onPort: %d] fcntl(O_NONBLOCK): %s",
			 ip, portNumber, strerror(errno)]];
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
				 @"[TCPSystem connectToIp: %@ onPort: %d] select(): %s",
				 ip, portNumber, strerror(errno)]];
				close(myDesc);
				return -1;
			}
			if (selectReturn > 0)
			{
				char buffer[2];
				if (recv(myDesc, buffer, sizeof(buffer), MSG_PEEK) == -1)
				{
					if (errno != EAGAIN)
					{
						[self setErrorString: [NSString stringWithFormat:
						 @"[TCPSystem connectToIp: %@ onPort: %d] recv() test failed: %s",
						 ip, portNumber, strerror(errno)]];
						close(myDesc);
						return -1;
					}
				}
			}
			else
			{
				[self setErrorString: [NSString stringWithFormat:
				 @"[TCPSystem connectToIp: %@ onPort: %d] connection timeout",
				 ip, portNumber]];
				close(myDesc);
				return -1;
			}
		}
		else // connect failed with something other than EINPROGRESS
		{
			[self setErrorString: [NSString stringWithFormat:
			 @"[TCPSystem connectToIp: %@ onPort: %d] connect(): %s",
			 ip, portNumber, strerror(errno)]];
			close(myDesc);
			return -1;
		}
	}
	return myDesc;
}
- (int)connectToHost: (NSString *)aHost onPort: (int)portNumber
         withTimeout: (int)timeout
{
	id ip = [self ipFromHost: aHost];
	if (ip)
	{
		return [self connectToIp: ip onPort: portNumber
		             withTimeout: timeout];
	}
	return -1;
}
- (int)connectToIpInBackground: (NSString *)ip onPort: (int)portNumber
{
	int myDesc;
	struct sockaddr_in destAddr;

	if (!ip)
	{
		[self setErrorString: [NSString stringWithFormat: 
		 @"[TCPSystem connectToIpInBackground: (nil) onPort: %d] Ip cannot be nil",
		 portNumber]];
		return -1;
	}
	
	if ((myDesc = socket(AF_INET, SOCK_STREAM, 0)) == -1)
	{
		[self setErrorString: [NSString stringWithFormat:
		 @"[TCPSystem connectToIpInBackground: %@ onPort: %d] socket(): %s",
		 ip, portNumber, strerror(errno)]];
		return -1;
	}

	destAddr.sin_family = AF_INET;
	destAddr.sin_port = htons(portNumber);
	if (!(inet_aton([ip cString], &destAddr.sin_addr)))
	{
		[self setErrorString: [NSString stringWithFormat:
		 @"[TCPSystem connectToIpInBackground: %@ onPort: %d] inet_aton(): Invalid IP",
		 ip, portNumber]];
		close(myDesc);
		return -1;
	}
	memset(&(destAddr.sin_zero), 0, sizeof(destAddr.sin_zero));

	if (fcntl(myDesc, F_SETFL, O_NONBLOCK) == -1)
	{
		[self setErrorString: [NSString stringWithFormat:
		 @"[TCPSystem connectToIpInBackground: %@ onPort: %d] fcntl(O_NONBLOCK): %s",
		 ip, portNumber, strerror(errno)]];
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
			 @"[TCPSystem connectToIpInBackground: %@ onPort: %d] connect(): %s",
			 ip, portNumber, strerror(errno)]];
			close(myDesc);
			return -1;
		}
	}
	
	return myDesc;
}
- (int)connectToHostInBackground: (NSString *)aHost onPort: (int)portNumber
{
	id ip = [self ipFromHost: aHost];
	if (ip)
	{
		return [self connectToIpInBackground: ip onPort: portNumber];
	}
	return -1;
}
- setErrorString: (NSString *)anError
{
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
- (id)connectNetObject: (id)netObject toIp: (NSString *)ip onPort: (int)aPort
           withTimeout: (int)timeout
{
	int desc;
	id transport;

	desc = [self connectToIp: ip onPort: aPort withTimeout: timeout];
	if (desc < 0)
	{
		return nil;
	}
	transport = AUTORELEASE([[TCPTransport alloc] initWithDesc: desc 
	              atAddress: ip]);
	
	if (!(transport))
	{
		return nil;
	}
	
	[netObject connectionEstablished: transport];
	
	return netObject;
}
- (id)connectNetObject: (id)netObject toHost: (NSString *)host
                onPort: (int)aPort withTimeout: (int)timeout
{
	int desc;
	id transport;

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
    toIp: (NSString *)ip onPort: (int)aPort withTimeout: (int)timeout 
{
	int desc;
	id transport;
	id object;

	desc = [self connectToIpInBackground: ip onPort: aPort];
	if (desc < 0)
	{
		return nil;
	}
	
	object = AUTORELEASE([[TCPConnecting alloc] initWithNetObject: netObject
	  withTimeout: timeout]);
	transport = AUTORELEASE([[TCPConnectingTransport alloc] initWithDesc: desc 
	              atAddress: ip withOwner: object]);
	
	if (!transport)
	{
		return nil;
	}
	
	[object connectionEstablished: transport];
	
	return object;
}
- (TCPConnecting *)connectNetObjectInBackground: (id)netObject 
    toHost: (NSString *)host onPort: (int)aPort withTimeout: (int)timeout
{
	int desc;
	id transport;
	id object;

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

- (NSString *)hostFromIp: (NSString *)ip
{
	struct in_addr address;
	struct hostent *host;
	
	if (!ip)
	{	
		[self setErrorString: @"[TCPSystem hostFromIp: (nil)] Ip can't be nil"];
		return nil;
	}
	
	if (inet_aton([ip cString], &address))
	{
		host = gethostbyaddr(&address, sizeof(address), AF_INET);
		if (!host)
		{
			[self setErrorString: [NSString stringWithFormat:
			 @"[TCPSystem hostFromIp: %@] gethostbyaddr() failed: %s", 
			 ip, my_hstrerror(h_errno)]];
			return nil;
		}
		return [NSString stringWithCString: host->h_name];
	}
	return nil;
}
- (NSString *)ipFromHost: (NSString *)aHost
{
	struct hostent *host;
	
	if (!aHost)
	{
		[self setErrorString: 
		  @"[TCPSystem ipFromHost: (nil)] Host can't be nil"];
	}
	host = gethostbyname([aHost cString]);
	if (!host)
	{
			[self setErrorString: [NSString stringWithFormat:
			 @"[TCPSystem ipFromHost: %@] gethostbyaddr() failed: %s", 
			 aHost, my_hstrerror(h_errno)]];
			return nil;
		
	}
	
	return [NSString stringWithCString: 
	  inet_ntoa(*((struct in_addr *)host->h_addr))];
}
- (NSString *)ipFromInt: (unsigned long int)ip
{
	struct in_addr addr;
	char *temp;
	
	addr.s_addr = ip;

	temp = inet_ntoa(addr);
	if (temp)
	{
		return [NSString stringWithCString: temp];
	}

	return nil;
}
- (NSString *)localIpForTransport: (TCPTransport *)aTransport
{
	struct sockaddr_in x;
	socklen_t address_length = sizeof(x);
	
	if (
	 getsockname([aTransport desc], (struct sockaddr *)&x, &address_length) 
	  != 0)
	{
		[self setErrorString: [NSString stringWithFormat: 
		 @"[TCPSystem localIpForTransport: %@] getsockname() failed: %s",
		  [aTransport address], strerror(errno)]];
		return nil;
	}

	return [NSString stringWithCString: inet_ntoa(x.sin_addr)];
}
	
@end


@implementation TCPPort
- initOnHost: (NSString *)aHost onPort: (int)aPort
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
- setNetObject: (Class)aClass
{
	if (![aClass conformsToProtocol: @protocol(NetObject)])
	{
		[NSException raise: FatalNetException
		  format:@"[TCPPort setNetObject] %@ does not conform to < NetObject >",
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
- newConnection
{
	int newDesc;
	struct sockaddr_in sin;
	int temp;
	char *test;
	TCPTransport *transport;
	NSString *newAddress;
	struct hostent *host;
	
	temp = sizeof(struct sockaddr_in);
	
	if ((newDesc = accept(desc, (struct sockaddr *)&sin, 
	    &temp)) == -1)
	{
		[NSException raise: FatalNetException
		  format: @"[TCPPort newConnection] accept(): %s", strerror(errno)];
	}
	
	test = inet_ntoa(sin.sin_addr);
	if (!test)
	{
		return self;
	}

	host = gethostbyaddr((char *)&sin.sin_addr, sizeof(sin.sin_addr), AF_INET);

	newAddress = [NSString stringWithCString: host ? host->h_name: test];

	transport = AUTORELEASE([[TCPTransport alloc] 
	  initWithDesc: newDesc
	     atAddress: newAddress]);
	
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
- initWithDesc: (int)aDesc atAddress:(NSString *)theAddress
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
- (NSData *)readData: (int)maxDataSize
{
	char *buffer;
	int readReturn;
	NSData *data;
	
	if (!connected)
	{
		[NSException raise: FatalNetException
		  format: @"[TCPTransport readData: %d] Not connected", maxDataSize];
	}
	
	if (maxDataSize == 0)
	{
		return nil;
	}
	
	if (maxDataSize < 0)
	{
		[NSException raise: FatalNetException
		 format: 
		 @"[TCPTransport readData: %d] invalid number of bytes specified",
		   maxDataSize];
	}
	
	buffer = malloc(maxDataSize + 1);
	readReturn = read(desc, buffer, maxDataSize);
	
	if (readReturn == 0)
	{
		free(buffer);
		[NSException raise: NetException
		 format:@"[TCPTransport readData:] socket closed"];
	}
	
	if (readReturn == -1)
	{
		free(buffer);
		[NSException raise: FatalNetException
		 format:@"[TCPTransport readData:] read(): %s", strerror(errno)];
	}
	
	data = [NSData dataWithBytes: buffer length: readReturn];
	free(buffer);
	
	return data;
}
- (BOOL)isDoneWriting
{
	if (!connected)
	{
		[NSException raise: FatalNetException
		  format: @"[TCPTransport isDoneWriting] Not connected"];
	}
	return ([writeBuffer length]) ? NO : YES;
}
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
		  format: @"[TCPTransport writeData:] Not connected"];
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
		  format: @"[TCPTransport writeData:] write(): %s", strerror(errno)];
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
- (NSString *)address
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


