/***************************************************************************
                                InputController.h
                          -------------------
    begin                : Thu Mar 13 13:18:48 CST 2003
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

@class InputController;

#ifndef INPUT_CONTROLLER_H
#define INPUT_CONTROLLER_H

#include <Foundation/NSObject.h>

@class ConnectionController;

@interface InputController : NSObject
	{
		ConnectionController *controller;
	}

- initWithConnectionController: (ConnectionController *)aController;

- (void)enterPressed: (id)sender;
@end

#endif
