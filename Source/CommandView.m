#import "CommandView.h"

#import "HistoryCommands.h"

@implementation CommandView 
/*{
    HistoryCommands *historyManager;
}*/
-init
{
    if([super init]!=nil)
    {
        historyManager=[[HistoryCommands alloc] init];
    }

    return self;
};
-(void)dealloc
{
    if(historyManager)
    {
        [historyManager release];
    };
};
-(void)setNewChannel:(NSString *)aChannel
{
    [historyManager addNewChannel:aChannel];
};
-(void)removeChannel:(NSString *)aChannel
{
    [historyManager removeChannel:aChannel];
};
- (void) keyDown: (NSEvent *) theEvent
{
    NSLog(@"Weeeee!!!!!");
    [super keyDown: theEvent];
};
@end
