/***************************************************************************
                                ContentController.h
                          -------------------
    begin                : Mon Jan 19 12:09:57 CST 2004
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

#ifndef CONTENT_CONTROLLER_H
#define CONTENT_CONTROLLER_H

#import <Foundation/NSObject.h>

@protocol MasterController;
@protocol ContentController;
@protocol ContentControllerDelegate;

@class ConnectionController, NSView, NSString, NSAttributedString;
@class NSArray, NSTextView, NSTextField, NSWindow, Channel, NSText;

extern NSString *ContentControllerChannelType;
extern NSString *ContentControllerQueryType;

extern NSString *ContentConsoleName;

@protocol ContentControllerQueryController < NSObject >
+ (NSString *)standardNib;
- (NSTextView *)chatView;
- (NSView *)contentView;
@end

//@protocol ContentControllerChannelName < ContentControllerChannelName >
//- (NSString *)stringName;
//- (NSAttributedString *)presentationName;
//@end

@protocol ContentControllerChannelController 
              < ContentControllerQueryController, NSObject >
- (Channel *)channelSource;
- (void)attachChannelSource: (Channel *)aChannel;
- (void)detachChannelSource;
- (void)refreshFromChannelSource;
@end


@protocol MasterController <NSObject>
- (void)addViewController: (id <ContentControllerQueryController>)aController
   withLabel: (NSAttributedString *)aLabel
   forContentController: (id <ContentController>)aContentController;
- (void)addViewController: (id <ContentControllerQueryController>)aController
   withLabel: (NSAttributedString *)aLabel
   atIndex: (unsigned)aIndex 
   forContentController: (id <ContentController>)aContentController;

- (void)selectViewController: (id <ContentControllerQueryController>)aController;
- (void)selectViewControllerAtIndex: (unsigned)aIndex;
- (id <ContentControllerQueryController>)selectedViewController;

- (void)removeViewController: (id <ContentControllerQueryController>)aController;
- (void)removeViewControllerAtIndex: (unsigned)aIndex;

- (void)moveViewController: (id <ContentControllerQueryController>)aController
   toIndex: (unsigned)aIndex;
- (void)moveViewControllerAtIndex: (unsigned)aIndex 
   toIndex: (unsigned)aNewIndex;

- (unsigned)indexForViewController: (id <ContentControllerQueryController>)aController;
- (unsigned)count;

- (NSAttributedString *)labelForViewController: (id <ContentControllerQueryController>)aController;
- (void)setLabel: (NSAttributedString *)aLabel 
    forViewController: (id <ContentControllerQueryController>)aController;
	 
- (NSArray *)containedContentControllers;
- (NSArray *)viewControllerListForContentController: 
    (id <ContentController>)aContentController;
- (NSArray *)allViewControllers;

- (NSTextField *)typeView;
- (NSTextField *)nickView;

- (void)bringToFront;
- (NSWindow *)window;
@end

@protocol TypingController <NSObject>
- (void)losingFieldEditorForField: (NSTextField *)aField
   forMasterController: (id <MasterController>)aMaster;
- (NSText *)fieldEditorForField: (NSTextField *)aField
            forMasterController: (id <MasterController>)aMaster;
- (void)commandTyped: (NSString *)aCommand;
@end

@protocol ContentController <NSObject>
- (id <TypingController>)typingControllerForViewController: 
   (id <ContentControllerQueryController>)aController;

// Not retained
- (void)setConnectionController: (ConnectionController *)aController;
- (ConnectionController *)connectionController;

- (NSArray *)masterControllers;
- (id <MasterController>)primaryMasterController;
- (void)setPrimaryMasterController: (id <MasterController>)aController;

- (NSString *)nameForViewController: (id <ContentControllerQueryController>)aController;
- (id <MasterController>)masterControllerForName: (NSString *)aName;
- (NSTextView *)chatViewForName: (NSString *)aName;
- (id <ContentControllerQueryController>)viewControllerForName: (NSString *)aName;
- (NSString *)typeForName: (NSString *)aName;

- (NSArray *)allChatViews;
- (NSArray *)allControllers;
- (NSArray *)allNames;
- (NSArray *)allChatViewsOfType: (NSString *)aType;
- (NSArray *)allViewControllersOfType: (NSString *)aType;
- (NSArray *)allNamesOfType: (NSString *)aType;

- (void)putMessage: aMessage in: (id)aName;
- (void)putMessage: aMessage in: (id)aName 
    withEndLine: (BOOL)hasEnd;
- (void)putMessageInAll: aMessage;
- (void)putMessageInAll: aMessage
    withEndLine: (BOOL)hasEnd;
- (void)putMessageInAll: aMessage
    ofType: (NSString *)aType;
- (void)putMessageInAll: aMessage
    ofType: (NSString *)aType
    withEndLine: (BOOL)hasEnd;

- (id <ContentControllerQueryController>)addViewControllerOfType: (NSString *)aType 
   withName: (NSString *)aName 
   withLabel: (NSAttributedString *)aLabel 
   inMasterController: (id <MasterController>)aMaster;
- (void)removeViewControllerWithName: (NSString *)aName;
- (void)renameViewControllerWithName: (NSString *)aName to: (NSString *)newName;

- (NSString *)presentationalNameForName: (NSString *)aName;
- (void)setPresentationName: (NSString *)aPresentationName forName: (NSString *)aName;

- (NSAttributedString *)labelForName: (NSString *)aName;
- (void)setLabel: (NSAttributedString *)aLabel forName: (NSString *)aName;

- (NSString *)nickname;
- (void)setNickname: (NSString *)aNickname;

- (NSString *)titleForViewController: (id <ContentControllerQueryController>)aController;
- (void)setTitle: (NSString *)aTitle
    forViewController: (id <ContentControllerQueryController>)aController;

- (NSString * (*)(NSString *))lowercasingFunction;
- (void)setLowercasingFunction: (NSString * (*)(NSString *))aFunction;

- (void)bringNameToFront: (NSString *)aName;
@end

/*
	object:          The view controller.
	
	userinfo:
	@"Channel"       The Channel object.
	@"User"          The ChannelUser object.
	@"View"          The view controller.
*/
extern NSString *ChannelControllerUserOpenedNotification;

/*
	object:          The content controller.
	
	userinfo:
	@"OldIndex"      Old index
	@"Index"         The new index
	@"Master"        The master controller
	@"View"          The view controller.
	@"Content"       The content controller
*/
extern NSString *ContentControllerMovedInMasterControllerNotification;

/*
	object:          The content controller
	
	userinfo:
	@"Master":       The master controller.
	@"View":         The view controller.
	@"Index":        The index
	@"Content":      The content controller
*/
extern NSString *ContentControllerAddedToMasterControllerNotification;

/*
	object:          The content controller
	
	userinfo:
	@"Master":       The master controller.
	@"View":         The view controller.
	@"Content":      The content controller.
*/
extern NSString *ContentControllerRemovedFromMasterControllerNotification;

/* 
	object:          The content controller
	
	userinfo:
	@"OldNickname": Old nickname
	@"Nickname":    New nickname
	@"Content":     The content controller
*/
extern NSString *ContentControllerChangedNicknameNotification;

/* 
	object:          The view controller
	
	userinfo:
	@"Title":       New title 
	@"View":        The view controller
	@"Content":     The content controller
*/
extern NSString *ContentControllerChangedTitleNotification;

/* 
	object:       The content controller

	userinfo:
	@"View":     The view controller
	@"Content":  The content controller
	@"Master":   The master controller
*/
extern NSString *ContentControllerSelectedNameNotification;

/* 
	object:       The content controller
	
	userinfo:
	@"OldLabel": The old label
	@"Label":    The new label
	@"View":     The view controller
	@"Content":  The content controller
	@"Master":   The master controller
*/
extern NSString *ContentControllerChangedLabelNotification;

	
#endif
