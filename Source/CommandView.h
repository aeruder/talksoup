#import <AppKit/NSTextField.h>

@class HistoryCommands;

@interface CommandView : NSTextField
{
    HistoryCommands *historyManager;
}
-init;
-(void)setNewChannel:(NSString *)aChannel;
-(void)removeChannel:(NSString *)aChannel;
-(void) keyDown: (NSEvent *) theEvent;
@end
