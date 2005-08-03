/***************************************************************************
                                InputController.h
                          -------------------
    begin                : Thu Mar 13 13:18:48 CST 2003
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

@class InputController;

#ifndef INPUT_CONTROLLER_H
#define INPUT_CONTROLLER_H

#import <Foundation/NSObject.h>

#import "ContentControllers/ContentController.h"

@class ConnectionController, NSMutableArray, NSText, KeyTextView, NSTextField;
@class NSConnection, HelperExecutor;

extern NSString *TaskExecutionOutputNotification;

@interface InputController : NSObject <TypingController>
	{
		id <ContentController> content;
		id <ContentControllerQueryController> view;
		id <MasterController> lastMaster;
		ConnectionController *controller;
		unsigned historyIndex;
		NSMutableArray *history;
		NSMutableArray *modHistory;
		KeyTextView *fieldEditor;
		NSMutableArray *tabCompletion;
		unsigned tabCompletionIndex;
		HelperExecutor *helper;
		NSRange savedRange;
	}
- initWithViewController: (id <ContentControllerQueryController>)aController
    contentController: (id <ContentController>)aContentController;

- (void)setConnectionController: (ConnectionController *)aController;

- (void)commandTyped: (NSString *)aCommand;
- (void)loseTextField: (KeyTextView *)aField
   forMasterController: (id <MasterController>)aMaster;
- (void)handleTextField: (KeyTextView *)aField
   forMasterController: (id <MasterController>)aMaster;
- (void)processSingleCommand: (NSString *)aCommand;
@end

#endif
