/***************************************************************************
                                ContentController.h
                          -------------------
    begin                : Mon Jan 19 12:09:57 CST 2004
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

@protocol ContentControllerQueryView < NSObject >
+ (NSString *)standardNib;
- (NSTextView *)chatView;
- (NSView *)contentView;
@end

//@protocol ContentControllerChannelName < ContentControllerChannelName >
//- (NSString *)stringName;
//- (NSAttributedString *)presentationName;
//@end

@protocol ContentControllerChannelView < ContentControllerQueryView, NSObject >
- (Channel *)channelSource;
- (void)attachChannelSource: (Channel *)aChannel;
- (void)detachChannelSource;
- (void)refreshFromChannelSource;
@end


@protocol MasterController <NSObject>
- (void)addView: (id <ContentControllerQueryView>)aView withLabel: (NSAttributedString *)aLabel
   forContentController: (id <ContentController>)aContentController;
- (void)addView: (id <ContentControllerQueryView>)aView withLabel: (NSAttributedString *)aLabel
   atIndex: (unsigned)aIndex forContentController: (id <ContentController>)aContentController;

- (void)selectView: (id <ContentControllerQueryView>)aView;
- (void)selectViewAtIndex: (unsigned)aIndex;

- (void)removeView: (id <ContentControllerQueryView>)aView;
- (void)removeViewAtIndex: (unsigned)aIndex;

- (void)moveView: (id <ContentControllerQueryView>)aView toIndex: (unsigned)aIndex;
- (void)moveViewAtIndex: (unsigned)aIndex toIndex: (unsigned)aNewIndex;

- (unsigned)indexForView: (id <ContentControllerQueryView>)aView;
- (unsigned)count;

- (NSAttributedString *)labelForView: (id <ContentControllerQueryView>)aView;
- (void)setLabel: (NSAttributedString *)aLabel 
    forView: (id <ContentControllerQueryView>)aView;
	 
- (NSArray *)containedContentControllers;
- (NSArray *)viewListForContentController: 
    (id <ContentController>)aContentController;
- (NSArray *)allViews;

- (NSTextField *)typeView;
- (NSTextField *)nickView;

- (void)bringToFront;
- (NSWindow *)window;
@end

@protocol TypingController <NSObject>
- (NSText *)fieldEditor;
- (void)commandTyped: (NSString *)aCommand;
@end

@protocol ContentController <NSObject>
- (id <TypingController>)typingControllerForView: 
   (id <ContentControllerQueryView>)aView;

// Not retained
- (void)setConnectionController: (ConnectionController *)aController;
- (ConnectionController *)connectionController;

- (NSArray *)masterControllers;
- (id <MasterController>)primaryMasterController;
- (void)setPrimaryMasterController: (id <MasterController>)aController;

- (NSView *)viewForName: (NSString *)aName;
- (NSTextView *)chatViewForName: (NSString *)aName;
- (id)controllerForName: (NSString *)aName;
- (NSString *)typeForName: (NSString *)aName;
- (NSArray *)allChatViews;
- (NSArray *)allControllers;
- (NSArray *)allViews;
- (NSArray *)allNames;
- (NSArray *)allChatViewsOfType: (NSString *)aType;
- (NSArray *)allControllersOfType: (NSString *)aType;
- (NSArray *)allViewsOfType: (NSString *)aType;
- (NSArray *)allNamesOfType: (NSString *)aType;

- (void)putMessage: (NSAttributedString *)aMessage in: (id)aName;
- (void)putMessage: (NSAttributedString *)aMessage in: (id)aName 
    withEndLine: (BOOL)hasEnd;
- (void)putMessageInAll: (NSAttributedString *)aMessage;
- (void)putMessageInAll: (NSAttributedString *)aMessage
    withEndLine: (BOOL)hasEnd;
- (void)putMessageInAll: (NSAttributedString *)aMessage
    ofType: (NSString *)aType;
- (void)putMessageInAll: (NSAttributedString *)aMessage
    ofType: (NSString *)aType
    withEndLine: (BOOL)hasEnd;

- (void)addControllerOfType: (NSString *)aType withName: (NSString *)aName 
   withLabel: (NSAttributedString *)aLabel 
   inMasterController: (id <MasterController>)aMaster;
- (void)removeControllerWithName: (NSString *)aName;
- (void)renameControllerWithName: (NSString *)aName to: (NSString *)newName;

- (NSString *)presentationalNameForName: (NSString *)aName;
- (void)setPresentationName: (NSString *)aPresentationName forName: (NSString *)aName;

- (NSAttributedString *)labelForName: (NSString *)aName;
- (void)setLabel: (NSAttributedString *)aLabel forName: (NSString *)aName;

- (NSString *)nickname;
- (void)setNickname: (NSString *)aNickname;

- (NSString *)title;
- (void)setTitle: (NSString *)aTitle;

- (void)setLowercasingFunction: (NSString * (*)(NSString *))aFunction;

- (void)bringNameToFront: (NSString *)aName;
@end

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
