#import <AppKit/NSView.h>
#import <AppKit/NSTableView.h>
#import <AppKit/NSTabViewItem.h>
#import <AppKit/NSTextField.h>
#import <AppKit/GSVbox.h>
#import <AppKit/GSHbox.h>

#import "TerminalView/TerminalView.h"

@interface ChannelView : NSTabViewItem
{
  GSVbox *vbox;
  NSTableView *users;
  TerminalView *terminal;
  NSString *channel;
  NSTableView *usersTableView;
}
-(id)initWithLabel:(NSString *)label;
-(void)setChannelName:(NSString *)channelName;
-(NSString *)getChannelName;
-(void)writeMessage:(NSString*)message from:(NSString*)from;
-(id)getTerminalView;
@end
