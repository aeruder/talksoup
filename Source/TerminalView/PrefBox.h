/*
copyright 2002 Alexander Malmberg <alexander@malmberg.org>
*/

#ifndef PrefBox_h
#define PrefBox_h

@class NSView,NSButton,NSString;

@protocol PrefBox

-(void) setupButton: (NSButton *)b;
/* Called when the PrefBox is added to a preferences panel. It should
add a label or an image or something to the button. */

-(void) willHide;
/* Called just before another PrefBox will be displayed if this one
is currently displayed.*/

-(NSView *) willShow;
/* Called before this PrefBox will be displayed. Should return the
top-level NSView that should be displayed. (This view should probably
be cached, but creating it on demand is nice.) */

-(void) save;
-(void) revert;
/* Called on all PrefBox:s when the user clicks the save or revert
button. */

-(NSString *) name;
/* Return the name that is displayed in the header of the NSBox when
this PrefBox is displayed. */

@end

#endif

