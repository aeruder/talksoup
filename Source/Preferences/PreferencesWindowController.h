/*
copyright 2002 Alexander Malmberg <alexander@malmberg.org>
*/

#ifndef PreferencesWindowController_h
#define PreferencesWindowController_h

#import <AppKit/NSWindowController.h>

#import "PrefBox.h"

@class GSHbox,NSBox;

@interface PreferencesWindowController : NSWindowController
{
	GSHbox *button_box;
	NSBox *pref_box;

	NSObject<PrefBox> *current;

	NSMutableArray *pref_boxes;
	NSMutableArray *pref_buttons;
}

-(void) addPrefBox: (NSObject<PrefBox> *)pb;

@end

#endif

