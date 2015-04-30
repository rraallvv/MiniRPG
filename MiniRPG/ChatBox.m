#import "ChatBox.h"

@interface ChatBox ()<CCTargetedTouchDelegate>
@property(nonatomic, strong) NSString *npc;
@property(nonatomic, strong) NSMutableArray *textArray;
@property(nonatomic, strong) CCLabelTTF *label;
@end

@implementation ChatBox

- (id) initWithNPC:(NSString *)npc text:(NSString *)text
{
    if (self = [super init])
    {
        self.npc = npc;
        // 1
        self.textArray = [[text componentsSeparatedByString:@""] mutableCopy];
        // 2
        CCSprite *backroundSprite = [CCSprite spriteWithFile:@"chat-box.png"];
        [backroundSprite.texture setAliasTexParameters];
        backroundSprite.scale = 8;
        backroundSprite.position = ccp(0,240);
        backroundSprite.anchorPoint = ccp(0,0);
        [self addChild:backroundSprite z:0];
        // 3
        self.label = [CCLabelTTF labelWithString:@"" dimensions:CGSizeMake(460, 60) hAlignment:UITextAlignmentLeft lineBreakMode:UILineBreakModeWordWrap fontName:@"Helvetica" fontSize:24];
        self.label.color = ccWHITE;
        self.label.anchorPoint = ccp(0, 0);
        self.label.position = ccp(10,250);

        [self addChild:self.label z:1];
    }

    return self;
}

- (void) advanceTextOrHide
{
    // 1
    if(self.textArray.count == 0)
    {
        [self setVisible:NO];
        [self.parent removeChild:self cleanup:YES];
        return;
    }

    // 2
    NSString *text = self.textArray[0];
    [self.textArray removeObjectAtIndex:0];

    // 3
    NSString *message = [NSString stringWithFormat:@"%@: %@",[self.npc uppercaseString], text];
    [self.label setString:message];
}

@end
