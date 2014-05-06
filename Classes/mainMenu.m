//
//  mainMenu.m
//  sunSmash
//
//  Created by Benjamin Chirlin on 6/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "mainMenu.h"

@implementation mainMenu

+(id) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	mainMenu *layer = [mainMenu node];
	
	// add layer as a child to scene
	[scene addChild: layer];
    
    CCSprite *bg = [CCSprite spriteWithFile:@"BGmain.png"];
    bg.position = ccp(240, 160);
	[layer addChild:bg z:-1];
    
	// return the scene
	return scene;
}

// set up the Menus
-(void) setUpMenus
{
	
	// Create some menu items
	CCMenuItemImage * menuItem1 = [CCMenuItemImage itemFromNormalImage:@"mainStartUp.png"
														 selectedImage: @"mainStartDown.png"
																target:self
															  selector:@selector(playGame:)];
	
	CCMenuItemImage * menuItem2 = [CCMenuItemImage itemFromNormalImage:@"mainNaviUp.png"
														 selectedImage: @"mainNaviDown.png"
																target:self
															  selector:@selector(doSomethingTwo:)];
	
	
	CCMenuItemImage * menuItem3 = [CCMenuItemImage itemFromNormalImage:@"mainConfigUp.png"
														 selectedImage: @"mainConfigDown.png"
																target:self
															  selector:@selector(doSomethingThree:)]; 
	
	
	// Create a menu and add your menu items to it
	CCMenu * myMenu = [CCMenu menuWithItems:menuItem1, menuItem2, menuItem3, nil];
	
	// Arrange the menu items vertically
	[myMenu alignItemsVerticallyWithPadding:15.5];
    myMenu.position =ccp(240, 130);
	
	// add the menu to your scene
	[self addChild:myMenu];
}

-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init] )) {
		
		// Initiate menu
		[self setUpMenus];
		
		self.isTouchEnabled = YES;
		
		// register to receive targeted touch events
        [[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self
														 priority:0
												  swallowsTouches:YES];
	}
	return self;
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	
	// don't forget to call "super dealloc"
	[super dealloc];
}

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    return YES;
}

- (void) playGame: (CCMenuItem  *) menuItem 
{
	//NSLog(@"The first menu was called");
    // Start game with first scene
	[[CCDirector sharedDirector] replaceScene: [CCTransitionMoveInR transitionWithDuration:1.0f scene:[levelGen scene:0]]];
}
- (void) doSomethingTwo: (CCMenuItem  *) menuItem 
{
	//NSLog(@"The second menu was called");
}
- (void) doSomethingThree: (CCMenuItem  *) menuItem 
{
	//NSLog(@"The third menu was called");
}

@end
