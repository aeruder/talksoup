#import <Foundation/NSObject.h>
#import "PrefBox.h"

@class GSVbox;
@class NSTextField;

@interface GeneralPrefs : NSObject <PrefBox>
{
    GSVbox *view;
    NSTextField *nickField;
    NSTextField *alternateNickField;
}
+(NSArray *) getDefaultNicks;
@end
