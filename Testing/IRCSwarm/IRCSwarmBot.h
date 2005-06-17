/***************************************************************************
                                IRCSwarmBot.h
                          -------------------
    begin                : Wed Jun  5 03:28:59 UTC 2002
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

#import <netclasses/IRCObject.h>

@class ControlSwarm;

@interface IRCSwarmBot : IRCObject
	{
		ControlSwarm *control;
	}
- initWithNickname: (NSString *)aNickname withUserName: (NSString *)aUser
  withRealName: (NSString *)aReal withPassword: (NSString *)aPass
  withControl: (ControlSwarm *)aControl;
@end
