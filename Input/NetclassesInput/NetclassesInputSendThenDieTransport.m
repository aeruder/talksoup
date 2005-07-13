/***************************************************************************
                      NetclassesInputSendThenDieTransport.m
                          -------------------
    begin                : Wed Jul 13 02:25:28 CDT 2005
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

#import "NetclassesInputSendThenDieTransport.h"

#import <Foundation/NSData.h>

@implementation NetclassesInputSendThenDieTransport
- initWithTransport: (id <NetTransport>)aTransport;
{
	if (!(self = [super init])) return self;

	ASSIGN(realTransport, aTransport);

	return self;
}
- (void)writeThenCloseForObject: (id <NetObject>)aObject
{
	ASSIGN(dieObject, aObject);
}
- (void)dealloc
{
	RELEASE(realTransport);

	[super dealloc];
}
- (id)localHost
{
	return [realTransport localHost];
}
- (id)remoteHost
{
	return [realTransport remoteHost];
}
- writeData: (NSData *)data
{
	id val;
	val = [realTransport writeData: data];
	if (dieObject && !data)
	{
		[[NetApplication sharedInstance] disconnectObject: dieObject];
		DESTROY(dieObject);
	}
	return val;
}
- (BOOL)isDoneWriting
{
	return [realTransport isDoneWriting];
}
- (NSData *)readData: (int)maxReadSize
{
	return [realTransport readData: maxReadSize];
}
- (int)desc
{
	return [realTransport desc];
}
- (void)close
{
	[realTransport close];
}
@end

