/***************************************************************************
                                main.h
                          -------------------
    begin                : Thu Jun 16 22:05:36 CDT 2005
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

#import <Foundation/NSObject.h>

@class NSString, NSMutableArray, NSTimer, NSHost;
@class IRCSwarmBot;

@interface ControlSwarm : NSObject
	{
		NSString *channel;
		NSMutableArray *play;
		int curIndex;
		NSHost *host;
		int repeat;
	}
- initWithChannel: (NSString *)aChan withPlay: (NSString *)aPlay
  withHost: (NSHost *)aHost;
- getBotForName: (NSString *)aName;
- (void)timerFired: (NSTimer *)aTimer;
- (void)botDied: (IRCSwarmBot *)aBot;
- (void)botRegistered: (IRCSwarmBot *)aBot;
@end

