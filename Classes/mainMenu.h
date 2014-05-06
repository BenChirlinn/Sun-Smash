//
//  mainMenu.h
//  sunSmash
//
//  Created by Benjamin Chirlin on 6/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"
#import "levelGen.h"

// HelloWorld Layer
@interface mainMenu : CCLayer
{
	// Class variables
    CCLabelTTF *scoreLabel;
}

// returns a Scene that contains the HelloWorld as the only child
+(id) scene;

-(void) setUpMenus;
-(id) init;
- (void) dealloc;
/*
- (void) startGame(CCMenuItem  *menuItem);
- (void) levelSelect(CCMenuItem  *menuItem);
- (void) optionMenu(CCMenuItem  *menuItem);
- (void) highScores(CCMenuItem  *menuItem);*/

@end
