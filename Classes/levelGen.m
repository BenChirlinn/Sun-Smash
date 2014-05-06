//
//  levelGen.m
//  sunSmash
//
//  Created by Benjamin Chirlin on 6/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "levelGen.h"

static cpFloat gravityStrength = 5.0e6f;
static int levels;

static void
postStepRemove(cpSpace *space, cpShape *shape, void *unused)
{
    //NSLog(@"Removing");
    CCSprite *sprite = shape->data;
    
    [sprite stopAllActions];
    
    levelGen *layer = (levelGen*)[[sprite parent] parent];
    
    [layer removePlanetoid:sprite];
    
    [layer removeChild:[sprite parent] cleanup:NO];
    
    [layer resetBullet:sprite];
    
    // Note, chipmunk doesn't support destruction of bodies while it's iterating over the collisions
    
    cpSpaceRemoveBody(space, shape->body);
    cpSpaceRemoveShape(space, shape);
    cpBodyFree(shape->body);
    cpShapeFree(shape);
    
    shape->data = nil;
    shape->body = nil;
    shape = nil;
    sprite = nil;
    
    //NSLog(@"Removed");
    
    // If _planets is empty, game over
    if ( [layer win]) {
        [layer haltUpdate];
        [layer setScoring:YES];
        [[CCDirector sharedDirector] pause];
        
        // Bring up score
        [layer addScoreScreen:[layer compScore]];
    }
}

// Collision call back functions

static int
planetHit(cpArbiter *arb, cpSpace *space, void *unused)
{
    // Get the cpShapes involved in the collision
    // The order will be the same as you defined in the handler definition
    cpShape *a, *b; cpArbiterGetShapes(arb, &a, &b);
    
    // Alternatively you can use the CP_ARBITER_GET_SHAPES() macro
    // It defines and sets the variables for you.
    //CP_ARBITER_GET_SHAPES(arb, a, b);
    
    // Action
    //NSLog(@"planets Hit");
    cpSpaceAddPostStepCallback(space, (cpPostStepFunc)postStepRemove, b, NULL);
    
    // Damage planet
    a->life -= 20.0f;
    int lifish = a->life;
    // Change Sprite
    CCSprite* sp = a->data;
    CGRect frame = [sp textureRect];
    switch (lifish) {
        case 60:
            break;
        case 40:
            //[CCSprite spriteWithBatchNode:batch rect:CGRectMake(frame.size.width, 0, frame.size.width, frame.size.height)]
            [(CCSprite*)a->data setTextureRect: CGRectMake(frame.size.width, 0, frame.size.width, frame.size.height)];
            break;
        case 20:
            [(CCSprite*)a->data setTextureRect: CGRectMake(frame.size.width*2, 0, frame.size.width, frame.size.height)];
            break;
        case 0:
            break;
    }
    
    if (a->life <= 0.0f){
        cpSpaceAddPostStepCallback(space, (cpPostStepFunc)postStepRemove, a, NULL);
    }
    
    // The object is dead, don’t process the collision further, return 1 -> apply collision forces
    return 1;
}

static int
sunHit(cpArbiter *arb, cpSpace *space, void *unused)
{
    cpShape *a, *b; cpArbiterGetShapes(arb, &a, &b);
    
    // Action
    //NSLog(@"sun Hit");
    cpSpaceAddPostStepCallback(space, (cpPostStepFunc)postStepRemove, b, NULL);
    // The object is dead, don’t process the collision further
    // Return 0 -> bullet will pass through
    return 0;
}

static int
planetBurn(cpArbiter *arb, cpSpace *space, void *unused)
{
    cpShape *a, *b; cpArbiterGetShapes(arb, &a, &b);
    
    // Action
    //NSLog(@"planets Burned");
    cpSpaceAddPostStepCallback(space, (cpPostStepFunc)postStepRemove, b, NULL);
    // The object is dead, don’t process the collision further
    return 0;
}

static int
planetCrash(cpArbiter *arb, cpSpace *space, void *unused)
{
    cpShape *a, *b; cpArbiterGetShapes(arb, &a, &b);

    // Action
    //NSLog(@"planets Crashed");

    // Damage planets
    a->life -= 20.0f;
    b->life -= 20.0f;
    
    // Change Sprite of A
    int lifish = a->life;
    CCSprite* sp = a->data;
    CGRect frame = [sp textureRect];
    switch (lifish) {
        case 60:
            break;
        case 40:
            [(CCSprite*)a->data setTextureRect: CGRectMake(frame.size.width, 0, frame.size.width, frame.size.height)];
            break;
        case 20:
            [(CCSprite*)a->data setTextureRect: CGRectMake(frame.size.width*2, 0, frame.size.width, frame.size.height)];
            break;
        case 0:
            break;
    }
    
    // Change Sprite of B
    lifish = b->life;
    sp = b->data;
    frame = [sp textureRect];
    switch (lifish) {
        case 60:
            break;
        case 40:
            [(CCSprite*)b->data setTextureRect: CGRectMake(frame.size.width, 0, frame.size.width, frame.size.height)];
            break;
        case 20:
            [(CCSprite*)b->data setTextureRect: CGRectMake(frame.size.width*2, 0, frame.size.width, frame.size.height)];
            break;
        case 0:
            break;
    }
    
    // If life is 0, destroy planet
    if (a->life <= 0.0f){
        cpSpaceAddPostStepCallback(space, (cpPostStepFunc)postStepRemove, a, NULL);
    }
    
    if (b->life <= 0.0f){
        cpSpaceAddPostStepCallback(space, (cpPostStepFunc)postStepRemove, b, NULL);
    }
    
    // The object is dead, don’t process the collision further
    return 1;
}

// Sprite/Body Update function
static void
eachShape(void *ptr, void* unused)
{
	cpShape *shape = (cpShape*) ptr;
	CCSprite *sprite = shape->data;
	if( sprite ) {
		cpBody *body = shape->body;
		
		// TIP: cocos2d and chipmunk uses the same struct to store it's position
		// chipmunk uses: cpVect, and cocos2d uses CGPoint but in reality the are the same
		// since v0.7.1 you can mix them if you want.		
		[sprite setPosition: body->p];
		
		//[sprite setRotation: (float) CC_RADIANS_TO_DEGREES( -body->a )];
        

	}
}

// levelGen implementation
@implementation levelGen

@synthesize level;
@synthesize planets;
@synthesize scoring;
@synthesize win;

+(id) scene:(int)num
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	levelGen *layer = [[levelGen node] initLevel:num];
    //[layer setLevel:num];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init] )) {
        
        // Initialize Variables
        _bullets = [[NSMutableArray alloc] init];
        _planets = [[NSMutableArray alloc] init];
        pathed = [[NSMutableArray alloc] init];
        
        bullets = 0;
        scoring = 0;
        fired = NO;
        firing = NO;
        win = NO;
		
        cpResetShapeIdCounter();
		
		//Setup Chipmunk Physics Space
		
		cpInitChipmunk();
		
		[self genSpace];

        // Create Planets
        [self genPlanets];
        
        // Initialize our targeting reticle
        reticle = [CCSprite spriteWithFile:@"reticle.png"];
        reticle.visible = NO;
        [self addChild:reticle];
        
		// schedule a repeating callback on every frame
		[self schedule:@selector(updateFrame:)];
        
        // Set up score screen array for later
        [self setupScoreScreen];
		
		self.isTouchEnabled = YES;
	}
	return self;
}

-(id) initLevel: (int) n {
    // always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init] )) {
		level = n;
        
        // Initialize Variables
        _bullets = [[NSMutableArray alloc] init];
        _planets = [[NSMutableArray alloc] init];
        pathed = [[NSMutableArray alloc] init];
        
        bullets = 0;
        scoring = 0;
        fired = NO;
        firing = NO;
        win = NO;
		
        cpResetShapeIdCounter();
		
		//Setup Chipmunk Physics Space
		cpInitChipmunk();
		
		[self genSpace];
        
        // Create Sun
        [self genPlanets];
        
        // Initialize our targeting reticle
        reticle = [CCSprite spriteWithFile:@"reticle.png"];
        reticle.visible = NO;
        [self addChild:reticle];
        
		// schedule a repeating callback on every frame
		[self schedule:@selector(updateFrame:)];
		
        // Set up score screen array for later
        [self setupScoreScreen];
        
		self.isTouchEnabled = YES;
	}
	return self;
}


-(void) draw
{	
	if (!scoring) {	 
		
		// Draw dotted line of last bullet        
		CGPoint points[50];
        
        for (int i = 0; i < [pathed count]; i++) {
            CGPoint pos = [[pathed objectAtIndex:i] CGPointValue];
			points[i] = ccp( pos.x, pos.y );			
		}
        glColor4ub(78,76,73,50);
        ccDrawPoly(points, [pathed count], NO, NO);
		glPointSize(4);
		glColor4ub(0,0,255,255);
		//ccDrawPoints( points, [pathed count]);
        /*	
        // Draw last touch if not origin and not on score screen
        if ( !CGPointEqualToPoint(fireV, CGPointZero)) {
            glLineWidth(5);
            glColor4ub(0, 255, 0, 255);
            ccDrawCircle( ccp(fireV.x, fireV.y), 22, 0, 30, NO);
        }
        */
    }
	
	// restore original values
	glLineWidth(1);
	glColor4ub(255,255,255,255);
	glPointSize(1);
    glDisable(GL_LINE_SMOOTH);
}

- (void) updateFrame:(int)ticks {
    
	int steps = 1;
	cpFloat dt = 1.0f/80.0f/(cpFloat)steps;
	
	cpSpaceStep(space, dt);
    
	//cpBodyUpdatePosition(sunBody, dt);
	
	cpSpaceHashEach(space->activeShapes, &eachShape, nil); 
}

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    reticle.visible = NO;
	return YES;
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event {
    // New shot -> clear path
    [pathed removeAllObjects];
    firing = YES;
    
	CGPoint location = [touch locationInView: [touch view]];
	CGPoint convertedLocation = [[CCDirector sharedDirector] convertToGL:location];
    // Full screen
	CGRect touchAreaC = CGRectMake(0, 0, 480, 320);
	
	fireU = cpv(0, 160);
	fireV = convertedLocation;
    
    // Set reticle to this last position if not scoring
    if (!scoring) {
        reticle.position = fireV;
        reticle.visible = YES;
    }
	
	// Log end point of touch if within central screen area
	if(CGRectContainsPoint(touchAreaC, convertedLocation)) {		
                
        // Compute firing vector for length i.e. velocity of bullet
        cpVect firePath = cpv(fireV.x-fireU.x, fireV.y-fireU.y);
        //NSLog(@"Fire Vector: (%f, %f)", firePath.x, firePath.y);
        
        Planetoid *bullet = [[Planetoid alloc] init];
        [bullet setSpace:space];
        
        bullet.myid = bullets;
        bullets++;
        
        CCSprite *bulletSprite = [bullet addToSpace: @"bullet.png" : self : _bullets source:fireU velocity:firePath radius:8.0f dim: 0 mass:25.0f type: 3];
        bulletSprite.tag = 2;
        
        // store bullet path
        id action1 = [CCDelayTime actionWithDuration:0.07];
        id action2 = [CCCallFuncN actionWithTarget:self selector:@selector(logBullet:)];
        id action3 = [CCRepeat actionWithAction:[CCSequence actions:action1, action2, nil] times:50];
        [action3 setTag:1];
        
        if (!fired) {
            prevSprite = bulletSprite;
            fired = YES;
        } 
        else {
            if (firing && prevSprite != nil) {
                [prevSprite stopActionByTag:1];
            }
            prevSprite = bulletSprite;
        }
    
        [bulletSprite runAction: action3];

        // timeout bullets
        action1 = [CCDelayTime actionWithDuration:6];
        action2 = [CCCallFuncND actionWithTarget:self selector:@selector(destroyBullet:data:) data:[bullet shape]];
        
        [bulletSprite runAction: [CCSequence actions:action1, action2, nil]];
	}
}

-(void) destroyBullet : (id)sender data:(void*) data {
    cpSpaceAddPostStepCallback(space, (cpPostStepFunc)postStepRemove, data, NULL);
    cpShape *shape = (cpShape*)data;
    // If no new bullet has been fired, set firing to NO
    if (prevSprite == shape->data ) {
        firing = NO;
        prevSprite = nil;
        //[pathed removeAllObjects];
       // NSLog(@"Reset bullet");
    }
	//NSLog(@"Destroying Bullet");
}

-(void) logBullet:(id)sender {
	CCSprite *sprite = (CCSprite *)sender;
    NSValue *pos = [NSValue valueWithCGPoint:sprite.position];
    [pathed addObject:pos];
}

-(void) resetBullet:(CCSprite*)check {
    if(check == prevSprite) {
        prevSprite = nil;
    }
}

-(BOOL) removePlanetoid:(CCSprite*) target {
    if( [_planets containsObject:target] ) {
        [_planets removeObject:[target retain]];
        
        if( [_planets count] <= 1 ) {win = YES;}
        
        return YES;
    }
    
    return NO;
}

-(void) genPlanets {
    // Fetch planet array from gameData.plist, first entry is always sun
    
    // create a pointer to a dictionary
    NSDictionary *dictionary;
    // read "foo.plist" from application bundle
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSString *finalPath = [path stringByAppendingPathComponent:@"gameData.plist"];
    
    dictionary = [NSDictionary dictionaryWithContentsOfFile:finalPath];
    
    NSArray *levelDat = [[dictionary valueForKey:@"Levels"] objectAtIndex:level];
    
    // generate sun from first planet entry
    NSString *img = [[levelDat objectAtIndex:0]objectAtIndex:0];
    float sunxLoc = [[[levelDat objectAtIndex:0]objectAtIndex:1]floatValue];
    float sunyLoc = [[[levelDat objectAtIndex:0]objectAtIndex:2]floatValue];
    float rad = [[[levelDat objectAtIndex:0]objectAtIndex:3]floatValue];
    [self genSun:img loc:cpv(sunxLoc, sunyLoc) radius:rad];
    
    // store number of levels
    levels = [[dictionary valueForKey:@"Levels"] count];
    
    // grab and generate background
    img = [[levelDat objectAtIndex:0]objectAtIndex:4];
    CCSprite *bg = [CCSprite spriteWithFile:img];
    bg.position = ccp(240, 160);
	[self addChild:bg z:-2];
    
    float mass;
    int dim;
    float xLoc;
    float yLoc;
    cpVect sunPos = cpv(sunxLoc, sunyLoc);
    
    for (int i = 1; i < [levelDat count]; i++) {
        // fetch planet vars
        img = [[levelDat objectAtIndex:i]objectAtIndex:0];
        xLoc = [[[levelDat objectAtIndex:i]objectAtIndex:1]floatValue];
        yLoc = [[[levelDat objectAtIndex:i]objectAtIndex:2]floatValue];
        rad = [[[levelDat objectAtIndex:i]objectAtIndex:3]floatValue];
        dim = [[[levelDat objectAtIndex:i]objectAtIndex:4]floatValue];
        mass = [[[levelDat objectAtIndex:i]objectAtIndex:5]floatValue];
        
        // create planet
        Planetoid *planet = [[Planetoid alloc] initSun:sunPos];
        [planet setSpace:space];
        
        cpVect loc = cpv(xLoc, yLoc);
        
        cpVect diff = cpvsub(loc, sun.sprite.position);
        cpFloat r = cpvlength(diff);
        cpFloat v = cpfsqrt(gravityStrength / r) / r;
        cpVect vel = cpvmult(cpvperp(diff), v);
        
        [planet addToSpace: img : self : _planets source:loc velocity:vel radius:rad dim:dim mass:mass type: 2];
    }
    
    // Set total number of planets
    planets = [_planets count] - 1;
}

-(void) genSun: (NSString*) img loc: (cpVect) s radius: (float) r {
    sun = [[Planetoid alloc] initSun:s];
    [sun setSpace:space];
    [sun genSun: img : self  : _planets source:s radius:r];
}

-(int) compScore {
    // Optimally, player uses one bullet per planet plus two to spare, at worst player hits each planet three times
    float best = planets + 1;
    float worst = 4*planets+1;
    float mid = 2.5*planets+1;
    // Check where # of shots falls in scale from 1 to 4
    if ( bullets >= worst) {return 1;}
    else if ( bullets <= best) {return 4;}
    else if ( bullets <= mid ) {return 3;}
    else if ( bullets >= mid ) {return 2;}
    // Should never return 0
    return 0;
}

-(void) replay: (CCNode*)menu {
    scoring = 0;
    [self removeScoreScreen];
    [self reboot];
    win = 0;
    
    // Regenerate level
    [[CCDirector sharedDirector] resume];
    [[CCDirector sharedDirector] replaceScene:[CCTransitionMoveInR transitionWithDuration:1.0f scene:[levelGen scene:level]]];
}

-(void) nextLevel: (CCNode*)menu {
    scoring = 0;
    [self removeScoreScreen];
    [self reboot];
    win = 0;
    
    // Generate and transition to next level
    [[CCDirector sharedDirector] resume];
    int levelNum = level+1;
    
    // Check if level exists
    NSLog(@"Level: %d",levelNum);
    if ( levelNum >= levels ) {
        // If beyond last level, go to main menu
        [[CCDirector sharedDirector] replaceScene:[CCTransitionMoveInR transitionWithDuration:1.0f scene:[mainMenu scene]]];
        return;
    }
    
    [[CCDirector sharedDirector] replaceScene:[CCTransitionMoveInR transitionWithDuration:1.0f scene:[levelGen scene:levelNum]]];
}

-(void) backMenu: (CCNode*)menu {
    scoring = 0;
    [self removeScoreScreen];
    [self reboot];
    win = 0;
    
    // Generate menu
    [[CCDirector sharedDirector] resume];
    [[CCDirector sharedDirector] replaceScene:[CCTransitionMoveInL transitionWithDuration:1.0f scene:[mainMenu scene]]];
}

-(void) setupScoreScreen {
    // Generate menu bg
    CCSprite *scoreBack = [CCSprite spriteWithFile:@"levelMenu.png"];
    scoreBack.position = ccp(240, 145);
    
    // Generate score stars
    CCSprite *star1 = [CCSprite spriteWithFile:@"star.png"];
    star1.position = ccp(151, 193);
    star1.visible = false;
    CCSprite *star2 = [CCSprite spriteWithFile:@"star.png"];
    star2.position = ccp(210, 193);
    star2.visible = false;
    CCSprite *star3 = [CCSprite spriteWithFile:@"star.png"];
    star3.position = ccp(267, 193);
    star3.visible = false;
    CCSprite *star4 = [CCSprite spriteWithFile:@"star.png"];
    star4.position = ccp(324, 193);
    star4.visible = false;
    
    // Create post game menu
    CCMenuItemImage * menuItem1 = [CCMenuItemImage itemFromNormalImage:@"levelNextUp.png"
                                                         selectedImage: @"levelNextDown.png"
                                                                target:self
                                                              selector:@selector(nextLevel:)];
    
    CCMenuItemImage * menuItem2 = [CCMenuItemImage itemFromNormalImage:@"levelMenuUp.png"
                                                         selectedImage: @"levelMenuDown.png"
                                                                target:self
                                                              selector:@selector(backMenu:)];
    
    
    CCMenuItemImage * menuItem3 = [CCMenuItemImage itemFromNormalImage:@"levelRedoUp.png"
                                                         selectedImage: @"levelRedoDown.png"
                                                                target:self
                                                              selector:@selector(replay:)];
    menuItem1.position = ccp(0, -103);
    menuItem2.position = ccp(79, -40);
    menuItem3.position = ccp(-79, -40);
    
    // Create a menu and add your menu items to it
    CCMenu * scoreMenu = [CCMenu menuWithItems:menuItem1, menuItem2, menuItem3, nil];
    
    scoreScreen = [NSArray arrayWithObjects:scoreBack, scoreMenu, star1, star2, star3, star4, nil];
    [scoreScreen retain];
}

-(void) addScoreScreen: (int) score {
    [self addChild:[scoreScreen objectAtIndex:0] z:2];
    [self addChild:[scoreScreen objectAtIndex:1] z:3];
    [self addChild:[scoreScreen objectAtIndex:2] z:3];
    [self addChild:[scoreScreen objectAtIndex:3] z:3];
    [self addChild:[scoreScreen objectAtIndex:4] z:3];
    [self addChild:[scoreScreen objectAtIndex:5] z:3];
    // Add appropriate number of stars
    for (int i = 2; i < score+2; i++){
        ((CCSprite*)[scoreScreen objectAtIndex:i]).visible = YES;
    }
}

-(void) removeScoreScreen {
    for(id obj in scoreScreen) {
        [self removeChild:obj cleanup:YES];
    }
}

-(void) reboot {    
    // Reset all variables except sun and level which remain constant
    [_planets release];
	_planets = nil;
	
	[_bullets release];
	_bullets = nil;
    /*
    [pathed release];
    pathed = nil;
    */
    bullets = 0;
    fired = NO;
    firing = NO;
    scoring = NO;
    
    fireU = cpv(0,0);
    fireV = cpv(0,0);
    
    prevSprite = nil;
}

-(void) registerWithTouchDispatcher
{
	[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
}
         
-(void) genSpace {
    space = cpSpaceNew();
    cpSpaceResizeActiveHash(space, 30.0f, 10000);

    // Add collision handlers
    cpSpaceAddCollisionHandler(space, 2, 3, planetHit, NULL, NULL, NULL, NULL);
    cpSpaceAddCollisionHandler(space, 1, 3, sunHit, NULL, NULL, NULL, NULL);
    cpSpaceAddCollisionHandler(space, 1, 2, planetBurn, NULL, NULL, NULL, NULL);
    cpSpaceAddCollisionHandler(space, 2, 2, planetCrash, NULL, NULL, NULL, NULL);
}

-(void) haltUpdate {
    [self pauseSchedulerAndActions];
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	
	[_planets release];
	_planets = nil;
	
	[_bullets release];
	_bullets = nil;
    
    [pathed release];
    pathed = nil;

    [prevSprite release];
    prevSprite = nil;
    
    [scoreScreen release];
	scoreScreen = nil;
    
    [sun release];
    sun = nil;
    
    cpSpaceFreeChildren(space);
    cpSpaceFree(space);
    space = nil;
    
	// don't forget to call "super dealloc"
	[super dealloc];
}

@end


