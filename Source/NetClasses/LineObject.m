/***************************************************************************
                                LineObject.m
                          -------------------
    begin                : Thu May 30 02:19:30 UTC 2002
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

#import "LineObject.h"
#import <Foundation/NSData.h>

static inline NSData *chomp_line(NSMutableData *data)
{
	char *memory = [data mutableBytes];
	char *memoryEnd = memory + [data length];
	char *lineEndWithControls;
	char *lineEnd;
	int tempLength;
	
	id lineData;
	
	lineEndWithControls = lineEnd = 
	  memchr(memory, '\n', memoryEnd - memory);
	
	if (!lineEnd)
	{
		return nil;
	}
	
	while (((*lineEnd == '\n') || (*lineEnd == '\r'))
	       && (lineEnd >= memory))
	{
		lineEnd--;
	}

	lineData = [NSData dataWithBytes: memory length: lineEnd - memory + 1];
	
	tempLength = memoryEnd - lineEndWithControls - 1;
	
	memmove(memory, lineEndWithControls + 1, 
	        tempLength);
	
	[data setLength: tempLength];
	
	return lineData;
}
	
@implementation LineObject
- (void)connectionLost
{
	[transport close];
	DESTROY(transport);
	RELEASE(data);
}
- connectionEstablished: aTransport
{
	transport = RETAIN(aTransport);
	[[NetApplication sharedInstance] connectObject: self];
	
	data = [NSMutableData new];

	return self;
}
- dataReceived: (NSData *)newData
{
	id newLine;
	
	[data appendData: newData];
	
	while ((newLine = chomp_line(data))) [self lineReceived: newLine];
	
	return self;
}
- transport
{
	return transport;
}
- lineReceived: (NSData *)line
{
	return self;
}
@end	
