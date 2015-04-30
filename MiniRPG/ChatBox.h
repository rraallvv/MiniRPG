//
//  ChatBox.h
//  MiniRPG
//

#import "cocos2d.h"

@interface ChatBox : CCNode

- (id) initWithNPC:(NSString *) npc text:(NSString *) text;
- (void) advanceTextOrHide;

@end
