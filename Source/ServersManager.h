#include <Foundation/NSRunLoop.h>
#include <Foundation/NSUserDefaults.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <AppKit/NSWindowController.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSOutlineView.h>

@class GroupNode;

@interface ServersManager : NSWindowController
{
    NSMutableArray *groups;
    NSWindow *win;
}
- (id)init;
- (void)dealloc;
- (int)readDefaultServerList;
- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item;
- (id)outlineView:(NSOutlineView *)outlineView
            child:(int)index
           ofItem:(id)item;
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item;
- (id)outlineView:(NSOutlineView *)outlineView
    objectValueForTableColumn:(NSTableColumn *)tableColumn
                       byItem:(id)item;
-(void)showWindow;
-(id)getServersWindow;
@end
