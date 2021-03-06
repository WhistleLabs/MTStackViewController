//
//  MTStackViewController.m
//  Maple
//
//  Created by Andrew Carter on 10/19/12.
//  Copyright (c) 2013 WillowTree Apps. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "MTStackViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import "MTStackDefaultContainerView.h"
#import "SystemVersions.h"

const char *MTStackViewControllerKey = "MTStackViewControllerKey";

#pragma mark - UIViewController VPStackNavigationController Additions

@implementation UIViewController (MTStackViewController)

#pragma mark - Accessors

- (MTStackViewController *)stackViewController
{
    MTStackViewController *stackViewController = objc_getAssociatedObject(self, &MTStackViewControllerKey);
    
    if (!stackViewController && [self parentViewController] != nil)
    {
        stackViewController = [[self parentViewController] stackViewController];
    }
    
    return stackViewController;
}

- (void)setStackViewController:(MTStackViewController *)stackViewController
{
    objc_setAssociatedObject(self, &MTStackViewControllerKey, stackViewController, OBJC_ASSOCIATION_ASSIGN);
}

@end

@implementation MTStackContainerView

- (void)setContentView:(UIView *)contentView
{
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
    [self addSubview:contentView];
    contentView.frame = self.bounds;
    [contentView setNeedsLayout];
}

- (void)stackViewController:(MTStackViewController*)stackViewController
                       show:(BOOL)show side:(MTStackViewControllerPosition)side
                    toFrame:(CGRect)rect withDuration:(CGFloat)duration
{
    
}

- (void)stackViewController:(MTStackViewController *)stackViewController anmimateToFame:(CGRect)rect side:(MTStackViewControllerPosition)side withOffset:(CGFloat)offset
{
    
}

@end

#pragma mark - VPStackContentContainerView

@interface MTStackContentContainerView : UIView <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIView *separatorView;
@end

@implementation MTStackContentContainerView

#pragma mark - UIView Overrides

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
        [self setAutoresizesSubviews:YES];
    }
    return self;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:[self bounds]];
    [[self layer] setShadowPath:[shadowPath CGPath]];
}

@end

#pragma mark - VPStackNavigationController

@interface MTStackViewController ()
{
    CGPoint _initialPanGestureLocation;
    CGRect _initialContentControllerFrame;
    UITapGestureRecognizer *_tapGestureRecognizer;
}

@property (nonatomic, weak) UIViewController *childViewControllerForStatusBarHidden;

@end

@interface MTStackViewController () <UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIView *statusBarBackgroundView;
@end

@implementation MTStackViewController

#pragma mark - UIViewController Overrides

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	
	if (self)
	{
		[self setup];
	}
	
	return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self)
    {
		[self setup];
    }
    return self;
}

- (void)loadView
{
    CGRect frame = [[UIScreen mainScreen] bounds];
    
    if (WL_RUNNINGON_6) {
        CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
        frame.size.height -= MIN(statusBarFrame.size.width, statusBarFrame.size.height);
    }
    
    UIView *view = [[UIView alloc] initWithFrame:frame];
    [view setAutoresizesSubviews:YES];
    [view setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
    
    self.leftContainerView.frame = view.bounds;
    [view addSubview:self.leftContainerView];
    
    float frameWidth = CGRectGetWidth(view.frame);
    self.rightContainerView.frame = CGRectMake(frameWidth - self.slideOffset,
                                               0.0f, frameWidth,
                                               CGRectGetHeight(view.frame));
    [view addSubview:self.rightContainerView];
    
    [_contentContainerView setFrame:[view bounds]];
    [view addSubview:_contentContainerView];
    
    [self updateContainerViewFrameWidths];
    
    if (WL_RUNNINGON_7) {
        [view addSubview:self.statusBarBackgroundView];
    }
    
    [self setView:view];
}


- (UIView *)statusBar
{
    if (WL_RUNNINGON_6) {
        return nil;
    }
    
    NSString *key = [[NSString alloc] initWithData:[NSData dataWithBytes:(unsigned char[]) {
                                                    0x73, 0x74, 0x61, 0x74, 0x75, 0x73, 0x42, 0x61, 0x72
                                                    } length:9] encoding:NSASCIIStringEncoding];
    
    id object = [UIApplication sharedApplication];
    if ([object respondsToSelector:NSSelectorFromString(key)]) {
        return [object valueForKey:key];
    }
    
    return nil;
}

- (void)alignStatusBarToContentContainerFrame
{
    [[self statusBar] setTransform:CGAffineTransformMakeTranslation(_contentContainerView.frame.origin.x,
                                                                    _contentContainerView.frame.origin.y)];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (animated) {
        [UIView animateWithDuration:0.2f animations:^{
            [[self statusBar] setAlpha:0.0f];
            [[self statusBar] setTransform:CGAffineTransformMakeTranslation(0, -1 * [self statusBar].frame.size.height)];
        } completion:^(BOOL finished) {
            [self alignStatusBarToContentContainerFrame];
            
            [UIView animateWithDuration:0.2f animations:^{
                [[self statusBar] setAlpha:1.0f];
            }];
        }];
    } else {
        [self alignStatusBarToContentContainerFrame];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (animated) {
        [UIView animateWithDuration:0.2f animations:^{
            [[self statusBar] setAlpha:0.0f];
        } completion:^(BOOL finished) {
            [[self statusBar] setTransform:CGAffineTransformMakeTranslation(0, -1 * [self statusBar].frame.size.height)];
            
            [UIView animateWithDuration:0.2f animations:^{
                [[self statusBar] setAlpha:1.0f];
                [[self statusBar] setTransform:CGAffineTransformMakeTranslation(0, 0)];
            }];
        }];
    } else {
        [[self statusBar] setTransform:CGAffineTransformMakeTranslation(0, 0)];
    }
}

- (UIView *)statusBarBackgroundView
{
    if (! _statusBarBackgroundView) {
        _statusBarBackgroundView = [[UIView alloc] initWithFrame:[[UIApplication sharedApplication] statusBarFrame]];
    }
    return _statusBarBackgroundView;
}

- (UIViewController *)childViewControllerForStatusBarHidden
{
    return _childViewControllerForStatusBarHidden;
}

- (UIViewController *)childViewControllerForStatusBarStyle
{
    return [self childViewControllerForStatusBarHidden];
}

#pragma mark - Internal Setup

- (void)setup
{
    CGRect screenBounds = [self screenBounds];
    
    _swipeVelocity = 500.0f;
    
    _leftViewControllerEnabled = YES;
    _rightViewControllerEnabled = NO;
    _leftSnapThreshold = screenBounds.size.width / 2.0f;
    _rasterizesViewsDuringAnimation = YES;
    
    _leftContainerView = [[MTStackDefaultContainerView alloc] initWithFrame:screenBounds];
    _rightContainerView = [[MTStackDefaultContainerView alloc] initWithFrame:screenBounds];
    _contentContainerView = [[MTStackContentContainerView alloc] initWithFrame:screenBounds];

    [self setSlideOffset:roundf(screenBounds.size.width * 0.8f)];

    UIView *transitionView = [[UIView alloc] initWithFrame:screenBounds];
    [_contentContainerView addSubview:transitionView];
    
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognizerDidTap:)];
    
    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognizerDidPan:)];
    [_panGestureRecognizer setCancelsTouchesInView:YES];
    [_panGestureRecognizer setDelegate:self];
    [_contentContainerView addGestureRecognizer:_panGestureRecognizer];
    
    [self setSlideAnimationDuration:0.3f];
    [self setTrackingAnimationDuration:0.05f];
    [self setMinShadowRadius:3.0f];
    [self setMaxShadowRadius:10.0f];
    [self setMinShadowOpacity:0.5f];
    [self setMaxShadowOpacity:1.0f];
    [self setShadowOffset:CGSizeZero];
    [self setShadowColor:[UIColor blackColor]];
}

- (void)updateContainerViewFrameWidths
{
    CGRect frame = self.rightContainerView.frame;
    frame.size.width = self.slideOffset;
    self.rightContainerView.frame = frame;
    
    frame = self.leftContainerView.frame;
    frame.size.width = self.slideOffset;
    self.leftContainerView.frame = frame;
}

#pragma mark - Accessors

- (void)setSlideOffset:(CGFloat)slideOffset
{
    if (_slideOffset != slideOffset) {
        _slideOffset = slideOffset;
        [self updateContainerViewFrameWidths];
    }
}

- (void)setNoSimultaneousPanningViewClasses:(NSArray *)noSimultaneousPanningViewClasses
{
    _noSimultaneousPanningViewClasses = [noSimultaneousPanningViewClasses copy];
    
    for (id object in [self noSimultaneousPanningViewClasses])
    {
        NSAssert(class_isMetaClass(object_getClass(object)), @"Objects in this array must be of type 'Class'");
        NSAssert([(Class)object isSubclassOfClass:[UIView class]], @"Class objects in this array must be UIView subclasses");
    }
}

- (void)setShadowColor:(UIColor *)shadowColor
{
    _shadowColor = [shadowColor copy];
    [[_contentContainerView layer] setShadowColor:[[self shadowColor] CGColor]];
}

- (void)setShadowOffset:(CGSize)shadowOffset
{
    _shadowOffset = shadowOffset;
    [[_contentContainerView layer] setShadowOffset:[self shadowOffset]];
}

- (void)setMinShadowRadius:(CGFloat)minShadowRadius
{
    _minShadowRadius = minShadowRadius;
    if ([self isLeftViewControllerVisible])
    {
        [[_contentContainerView layer] setShadowRadius:[self minShadowRadius]];
    }
}

- (void)setMaxShadowRadius:(CGFloat)maxShadowRadius
{
    _maxShadowRadius = maxShadowRadius;
    if (![self isLeftViewControllerVisible])
    {
        [[_contentContainerView layer] setShadowRadius:[self maxShadowRadius]];
    }
}

- (void)setMinShadowOpacity:(CGFloat)minShadowOpacity
{
    _minShadowOpacity = minShadowOpacity;
    if ([self isLeftViewControllerVisible])
    {
        [[_contentContainerView layer] setShadowOpacity:[self minShadowOpacity]];
    }
}

- (void)setMaxShadowOpacity:(CGFloat)maxShadowOpacity
{
    _maxShadowOpacity = maxShadowOpacity;
    if (![self isLeftViewControllerVisible])
    {
        [[_contentContainerView layer] setShadowOpacity:[self maxShadowOpacity]];
    }
}

- (void)setSeparatorColor:(UIColor *)separatorColor
{
    _separatorColor = separatorColor;
    
    if (!_contentContainerView.separatorView)
    {
        CGRect frame = CGRectMake(-1,
                                  0,
                                  1,
                                  CGRectGetHeight(self.view.frame));

        UIView *separatorView = [[UIView alloc] initWithFrame:frame];
        [_contentContainerView addSubview:separatorView];
        _contentContainerView.separatorView = separatorView;
    }
    
    _contentContainerView.separatorView.backgroundColor = separatorColor;

}

- (void)setLeftViewController:(UIViewController *)leftViewController
{
    [self setViewController:leftViewController position:MTStackViewControllerPositionLeft];
}

- (void)setRightViewController:(UIViewController *)rightViewController
{
    [self setViewController:rightViewController position:MTStackViewControllerPositionRight];
}

- (CGRect)frameForViewController:(UIViewController *)viewController
                 inContainerView:(UIView *)containerView
{
    CGRect frame = containerView.bounds;
    CGFloat statusBarHeight = 0;
    UIRectEdge edgesForExtendedLayout = UIRectEdgeNone;

    if (WL_RUNNINGON_7) {
        statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;
        edgesForExtendedLayout = viewController.edgesForExtendedLayout;
    }
    
    if ([viewController respondsToSelector:@selector(prefersStatusBarHidden)]) {
        if (![viewController prefersStatusBarHidden]) {
            if (!(edgesForExtendedLayout & UIRectEdgeTop)) {
                frame.size.height -= statusBarHeight;
                frame.origin.y += statusBarHeight;
            }
        }
    } else {
        if (!(edgesForExtendedLayout & UIRectEdgeTop)) {
            frame.size.height -= statusBarHeight;
            frame.origin.y += statusBarHeight;
        }
    }
    return frame;
}

- (void)setViewController:(UIViewController *)newViewController position:(MTStackViewControllerPosition)position
{
    UIViewController* currentViewController;
    MTStackContainerView* containerView;
    
    switch (position) {
        case MTStackViewControllerPositionLeft:
            currentViewController = [self leftViewController];
            containerView = self.leftContainerView;
            _leftViewController = newViewController;
            break;
        case MTStackViewControllerPositionRight:
            currentViewController = [self rightViewController];
            containerView = self.rightContainerView;
            _rightViewController = newViewController;
            break;
    }
    
    if (newViewController)
    {
        [newViewController setStackViewController:self];
        newViewController.view.frame = [self frameForViewController:newViewController
                                                    inContainerView:containerView];
        [newViewController.view setNeedsLayout];
        [self addChildViewController:newViewController];
        [self.view bringSubviewToFront:self.statusBarBackgroundView];

        if (currentViewController)
        {
            [self transitionFromViewController:currentViewController toViewController:newViewController duration:0.0f options:0 animations:nil completion:^(BOOL finished) {
                [currentViewController removeFromParentViewController];
                [currentViewController setStackViewController:nil];
            }];
        }
        else
        {
            [containerView setContentView:[newViewController view]];
        }
    }
    else if (currentViewController)
    {
        [[currentViewController view] removeFromSuperview];
        [currentViewController removeFromParentViewController];
        [currentViewController setStackViewController:nil];
    }
}

- (void)setContentViewController:(UIViewController *)contentViewController
{
    [self setContentViewController:contentViewController snapToContentViewController:YES animated:YES];
}

- (BOOL)isLeftViewControllerVisible
{
    return CGRectGetMinX([_contentContainerView frame]) == [self slideOffset];
}

- (BOOL)isRightViewControllerVisible
{
    return CGRectGetMinX([_contentContainerView frame]) == -CGRectGetWidth([_contentContainerView bounds]) + (CGRectGetWidth([_contentContainerView bounds]) - [self slideOffset]);
}

#pragma mark - UIGestureRecognizerDelegate Methods

- (void)panGestureRecognizerDidPan:(UIPanGestureRecognizer *)panGestureRecognizer
{
    BOOL shouldPan = [self contentContainerView:_contentContainerView panGestureRecognizerShouldPan:panGestureRecognizer];
    
    if (shouldPan)
    {
        [self contentContainerView:_contentContainerView panGestureRecognizerDidPan:panGestureRecognizer];
    }
    
}

#pragma mark - UIGestureRecognizerDelegate Methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    BOOL shouldRecognize = YES;
    
    if ([[[otherGestureRecognizer view] superview] isKindOfClass:[UISwitch class]])
    {
        shouldRecognize = NO;
    }
    
    for (Class class in [self noSimultaneousPanningViewClasses])
    {
        if ([[otherGestureRecognizer view] isKindOfClass:class] || [[[otherGestureRecognizer view] superview] isKindOfClass:class])
        {
            shouldRecognize = NO;
        }
    }
    
    return shouldRecognize;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    MTStackViewControllerSwipeAllowed shouldBegin = self.swipePermissions;
    
    if (MTStackViewControllerSwipeAllowedNone == shouldBegin) {
        return NO;
    }
    
    if (self.leftViewControllerVisible) {
        shouldBegin &= MTStackViewControllerSwipeAllowedCloseLeft;
    } else if (self.rightViewControllerVisible) {
        shouldBegin &= MTStackViewControllerSwipeAllowedCloseRight;
    } else {
        shouldBegin &= (MTStackViewControllerSwipeAllowedOpenRight | MTStackViewControllerSwipeAllowedOpenLeft);
    }
    
    return ((BOOL)shouldBegin && [self contentContainerView:_contentContainerView panGestureRecognizerShouldPan:(UIPanGestureRecognizer *)gestureRecognizer]);
    
}

#pragma mark - Instance Methods

- (void)tapGestureRecognizerDidTap:(UITapGestureRecognizer *)tapGestureRecognizer
{
    [self hideLeftViewController];
}

- (void)setContentViewController:(UIViewController *)contentViewController hideLeftViewController:(BOOL)hideLeftViewController animated:(BOOL)animated
{
    [self setContentViewController:contentViewController snapToContentViewController:hideLeftViewController animated:animated];
}

- (void)setContentViewController:(UIViewController *)contentViewController snapToContentViewController:(BOOL)snapToContentViewController animated:(BOOL)animated
{
    UIViewController *currentContentViewController = [self contentViewController];
    
    _contentViewController = contentViewController;
    
    if ([self contentViewController])
    {
        [[self contentViewController] setStackViewController:self];
        [self addChildViewController:[self contentViewController]];
        self.contentViewController.view.frame = _contentContainerView.bounds;
        
        if (currentContentViewController)
        {
            [self transitionFromViewController:currentContentViewController toViewController:[self contentViewController] duration:[self contentViewControllerAnimationDuration] options:[self contentViewControllerAnimationOption] animations:nil completion:^(BOOL finished) {
                
                [currentContentViewController removeFromParentViewController];
                [currentContentViewController setStackViewController:nil];
                if (snapToContentViewController)
                {
                    if ([self isLeftViewControllerVisible])
                    {
                        [self hideLeftViewControllerAnimated:animated];
                    }
                    else if ([self isRightViewControllerVisible])
                    {
                        [self hideRightViewControllerAnimated:animated];
                    }
                    else
                    {
                        [self setContentViewUserInteractionEnabled:YES];
                    }
                }
            }];
        }
        else
        {
            [_contentContainerView addSubview:[[self contentViewController] view]];
            if (snapToContentViewController)
            {
                if ([self isLeftViewControllerVisible])
                {
                    [self hideLeftViewControllerAnimated:animated];
                }
                else if ([self isRightViewControllerVisible])
                {
                    [self hideRightViewControllerAnimated:animated];
                }
                else
                {
                    [self setContentViewUserInteractionEnabled:YES];
                }
            }
            
            [self didRevealContentViewController];
        }
    }
    else if (currentContentViewController)
    {
        [[currentContentViewController view] removeFromSuperview];
        [currentContentViewController removeFromParentViewController];
        [currentContentViewController setStackViewController:nil];
        if (snapToContentViewController)
        {
            if ([self isLeftViewControllerVisible])
            {
                [self hideLeftViewControllerAnimated:animated];
            }
            else if ([self isRightViewControllerVisible])
            {
                [self hideRightViewControllerAnimated:animated];
            }
            else
            {
                [self setContentViewUserInteractionEnabled:YES];
            }
        }
    }
}

- (void)panWithPanGestureRecognizer:(UIPanGestureRecognizer *)panGestureRecognizer
{
    CGPoint location = [panGestureRecognizer locationInView:[self view]];
    
    if (CGRectGetMinX([_contentContainerView frame]) > 0.0f)
    {
        [_rightContainerView setHidden:YES];
        [_leftContainerView setHidden:NO];
    }
    else if (CGRectGetMinX([_contentContainerView frame]) < 0.0f)
    {
        [_rightContainerView setHidden:NO];
        [_leftContainerView setHidden:YES];
    }
    else
    {
        [_rightContainerView setHidden:YES];
        [_leftContainerView setHidden:YES];
    }
    
    MTStackViewControllerPosition side = CGRectGetMinX([_contentContainerView frame]) >= 0.0f ?MTStackViewControllerPositionLeft : MTStackViewControllerPositionRight;
    MTStackContainerView *containerView;
    CGRect containerFrame;
    switch(side)
    {
        case MTStackViewControllerPositionLeft:
            containerView = _leftContainerView;
            containerFrame = CGRectMake(0.0f,
                                        CGRectGetMinY([_leftContainerView frame]),
                                        CGRectGetWidth([_leftContainerView frame]),
                                        CGRectGetHeight([_leftContainerView frame]));
            break;
        case MTStackViewControllerPositionRight:
            containerView = _rightContainerView;
            containerFrame = CGRectMake(CGRectGetWidth([_contentContainerView bounds]) - [self slideOffset],
                                        CGRectGetMinY([_rightContainerView frame]),
                                        CGRectGetWidth([_rightContainerView frame]),
                                        CGRectGetHeight([_rightContainerView frame]));
            break;
    }
    
    CGFloat contentViewFrameX = CGRectGetMinX(_initialContentControllerFrame) - (_initialPanGestureLocation.x - location.x);
    if (contentViewFrameX < -CGRectGetWidth([_contentContainerView bounds]) + (CGRectGetWidth([_contentContainerView bounds]) - [self slideOffset]))
    {
        contentViewFrameX = -CGRectGetWidth([_contentContainerView bounds]) + (CGRectGetWidth([_contentContainerView bounds]) - [self slideOffset]);
    }
    if (contentViewFrameX > [self slideOffset])
    {
        contentViewFrameX = [self slideOffset];
    }
    
    if (
        ([self isLeftViewControllerEnabled] && contentViewFrameX > 0.0f) ||
        ([self isRightViewControllerEnabled] && contentViewFrameX < 0.0f)
        )
    {
        CGFloat percentRevealed = (fabsf(contentViewFrameX) / [self slideOffset]);
        
        [containerView stackViewController:self anmimateToFame:containerFrame side:side withOffset:percentRevealed];

        [UIView animateWithDuration:[self trackingAnimationDuration]
                              delay:0.0f
                            options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             
                             [_contentContainerView setFrame:CGRectMake(contentViewFrameX,
                                                                        CGRectGetMinY([_contentContainerView frame]),
                                                                        CGRectGetWidth([_contentContainerView frame]),
                                                                        CGRectGetHeight([_contentContainerView frame]))];
                             [self alignStatusBarToContentContainerFrame];

                             [[_contentContainerView layer] setShadowRadius:[self maxShadowRadius] - (([self maxShadowRadius] - [self minShadowRadius]) * percentRevealed)];
                             [[_contentContainerView layer] setShadowOpacity:1.0f - (0.5 * percentRevealed)];
                             
                         } completion:^(BOOL finished) {
                             
                             id <MTStackChildViewController> childViewController = [self stackChildViewControllerForViewController:[self contentViewController]];
                             if ([childViewController respondsToSelector:@selector(stackViewController:didPanToOffset:)])
                             {
                                 [childViewController stackViewController:self didPanToOffset:CGRectGetMinX([_contentContainerView frame])];
                             }
                             
                         }];
    }
}

- (void)endPanning
{
    [self snapContentViewController];
}

- (void)snapContentViewController
{
    if (CGRectGetMinX([_contentContainerView frame]) <= _leftSnapThreshold && CGRectGetMinX([_contentContainerView frame]) >= 0.0f)
    {
        [self hideLeftViewControllerAnimated:YES];
    }
    else if (CGRectGetMinX([_contentContainerView frame]) > 0.0f)
    {
        [self revealLeftViewControllerAnimated:YES];
    }
    else if (CGRectGetMaxX([_contentContainerView frame]) <= CGRectGetWidth([_contentContainerView frame]) / 2.0f)
    {
        [self revealRightViewControllerAnimated:YES];
    }
    else
    {
        [self hideRightViewController];
    }
}

- (void)revealLeftViewController
{
    [self revealLeftViewControllerAnimated:YES];
}

- (void)revealLeftViewControllerAnimated:(BOOL)animated
{
    if ([self isLeftViewControllerEnabled])
    {
        [_rightContainerView setHidden:YES];
        [_leftContainerView setHidden:NO];
        
        [self setShadowOffset:CGSizeMake(-1.0f, 0.0f)];
        
        if ([self rasterizesViewsDuringAnimation])
        {
            [[_contentContainerView layer] setShouldRasterize:YES];
            [[_leftContainerView layer] setShouldRasterize:YES];
            [[_rightContainerView layer] setShouldRasterize:YES];
        }
        
        NSTimeInterval animationDuration = 0.0f;
        
        if (animated)
        {
            if ([self animationDurationProportionalToPosition])
            {
                animationDuration = [self slideAnimationDuration] * ([self slideOffset] - [_contentContainerView frame].origin.x) / [self slideOffset];
                animationDuration = fmax(animationDuration, 0.15f);
            }
            else
                animationDuration = [self slideAnimationDuration];
        }
        
        
        CGRect containerFrame = CGRectMake(0.0f,
                                           CGRectGetMinY([_leftContainerView frame]),
                                           CGRectGetWidth([_leftContainerView frame]),
                                           CGRectGetHeight([_leftContainerView frame]));
        [self.leftContainerView stackViewController:self show:YES
                                               side:MTStackViewControllerPositionRight
                                            toFrame:containerFrame
                                       withDuration:animationDuration];

        [self willRevealViewController:[self leftViewController]];

        [UIView animateWithDuration:animationDuration
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             
                             [_contentContainerView setFrame:CGRectMake([self slideOffset],
                                                                        CGRectGetMinY([_contentContainerView frame]),
                                                                        CGRectGetWidth([_contentContainerView frame]),
                                                                        CGRectGetHeight([_contentContainerView frame]))];
                             [self alignStatusBarToContentContainerFrame];
                             
                             [[_contentContainerView layer] setShadowRadius:[self minShadowRadius]];
                             [[_contentContainerView layer] setShadowOpacity:[self minShadowOpacity]];
                             self.visibleViewController = _leftViewController;
                         } completion:^(BOOL finished) {
                             
                             if ([self rasterizesViewsDuringAnimation])
                             {
                                 [[_contentContainerView layer] setShouldRasterize:NO];
                                 [[_leftContainerView layer] setShouldRasterize:NO];
                                 [[_rightContainerView layer] setShouldRasterize:NO];
                             }
                             
                             [self setContentViewUserInteractionEnabled:NO];
                             [_contentContainerView addGestureRecognizer:_tapGestureRecognizer];
                             
                             [self didRevealLeftViewController];
                             
                         }];
    }
}

- (void)revealRightViewController
{
    [self revealRightViewControllerAnimated:YES];
}

- (void)revealRightViewControllerAnimated:(BOOL)animated
{
    if ([self isRightViewControllerEnabled])
    {
        [_rightContainerView setHidden:NO];
        [_leftContainerView setHidden:YES];
        
        [self setShadowOffset:CGSizeMake(1.0f, 0.0f)];
        
        if ([self rasterizesViewsDuringAnimation])
        {
            [[_contentContainerView layer] setShouldRasterize:YES];
            [[_leftContainerView layer] setShouldRasterize:YES];
            [[_rightContainerView layer] setShouldRasterize:YES];
        }
        
        CGRect containerFrame = CGRectMake(CGRectGetWidth([_contentContainerView bounds]) - [self slideOffset],
                                           CGRectGetMinY([_rightContainerView frame]),
                                           CGRectGetWidth([_rightContainerView frame]),
                                           CGRectGetHeight([_rightContainerView frame]));
        
        [self.rightContainerView stackViewController:self show:YES
                                                side:MTStackViewControllerPositionRight
                                             toFrame:containerFrame
                                        withDuration:self.slideAnimationDuration];
        
        [self willRevealViewController:[self rightViewController]];

        [UIView animateWithDuration:animated ? [self slideAnimationDuration] : 0.0f
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             [_contentContainerView setFrame:CGRectMake(-CGRectGetWidth([_contentContainerView bounds]) + (CGRectGetWidth([_contentContainerView bounds]) - [self slideOffset]),
                                    CGRectGetMinY([_contentContainerView frame]),
                                    CGRectGetWidth([_contentContainerView frame]),
                                    CGRectGetHeight([_contentContainerView frame]))];
                             [self alignStatusBarToContentContainerFrame];
                             
                             [[_contentContainerView layer] setShadowRadius:[self minShadowRadius]];
                             [[_contentContainerView layer] setShadowOpacity:[self minShadowOpacity]];
                             self.visibleViewController = _rightViewController;
                         } completion:^(BOOL finished) {
                             
                             if ([self rasterizesViewsDuringAnimation])
                             {
                                 [[_contentContainerView layer] setShouldRasterize:NO];
                                 [[_leftContainerView layer] setShouldRasterize:NO];
                                 [[_rightContainerView layer] setShouldRasterize:NO];
                             }
                             [self setContentViewUserInteractionEnabled:NO];
                             [_contentContainerView addGestureRecognizer:_tapGestureRecognizer];
                             
                             [self didRevealRightViewController];
                         }];
    }
}

- (void)hideLeftViewController
{
    [self hideLeftViewControllerAnimated:YES];
}

- (void)hideLeftViewControllerAnimated:(BOOL)animated
{
    [self hideLeftOrRightViewControllerAnimated:animated];
}

- (void)hideRightViewController
{
    [self hideRightViewControllerAnimated:YES];
}

- (void)hideRightViewControllerAnimated:(BOOL)animated
{
    [self hideLeftOrRightViewControllerAnimated:animated];
}

- (void)hideLeftOrRightViewControllerAnimated:(BOOL)animated
{
    if ([self rasterizesViewsDuringAnimation])
    {
        [[_contentContainerView layer] setShouldRasterize:YES];
        [[_leftContainerView layer] setShouldRasterize:YES];
        [[_rightContainerView layer] setShouldRasterize:YES];
    }
    
    NSTimeInterval animationDuration = 0.0f;
    
    if (animated)
    {
        if ([self animationDurationProportionalToPosition])
        {
            if (CGRectGetMinX([_contentContainerView frame]) > 0.0f)
            {
                animationDuration = [self slideAnimationDuration] * (CGRectGetMinX([_contentContainerView frame]) / [self slideOffset]);
            } 
            else
            {
                animationDuration = [self slideAnimationDuration] * ((CGRectGetWidth([_contentContainerView bounds]) - CGRectGetMaxX([_contentContainerView frame])) / [self slideOffset]);
            }
            animationDuration = fmax(0.15f, animationDuration);
        }
        else
        {
            animationDuration = [self slideAnimationDuration];
        }
    }

    CGRect leftFrame = CGRectMake(0.0f, CGRectGetMinY([_leftContainerView frame]),
        CGRectGetWidth([_leftContainerView frame]), CGRectGetHeight([_leftContainerView frame]));
    
    CGRect rightFrame = CGRectMake(CGRectGetWidth(_contentContainerView.frame) - self.slideOffset,
                                   CGRectGetMinY([_rightContainerView frame]),
                                   CGRectGetWidth([_rightContainerView frame]), CGRectGetHeight([_rightContainerView frame]));
    
    CGRect contentFrame = CGRectMake(0.0f,
                                     CGRectGetMinY([_contentContainerView frame]),
                                     CGRectGetWidth([_contentContainerView frame]),
                                     CGRectGetHeight([_contentContainerView frame]));
    
    [self.leftContainerView stackViewController:self show:NO
                                           side:MTStackViewControllerPositionLeft
                                        toFrame:leftFrame
                                   withDuration:animationDuration];
    
    [self.rightContainerView stackViewController:self show:NO
                                            side:MTStackViewControllerPositionRight
                                         toFrame:rightFrame
                                    withDuration:animationDuration];

    [self willRevealViewController:[self contentViewController]];
    
    [UIView animateWithDuration:animationDuration
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseOut |UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [_contentContainerView setFrame:contentFrame];
                         [self alignStatusBarToContentContainerFrame];
                         [[_contentContainerView layer] setShadowRadius:[self maxShadowRadius]];
                         [[_contentContainerView layer] setShadowOpacity:[self maxShadowOpacity]];
                         self.visibleViewController = _contentViewController;
                     } completion:^(BOOL finished) {
                         if ([self rasterizesViewsDuringAnimation])
                         {
                             [[_contentContainerView layer] setShouldRasterize:NO];
                             [[_leftContainerView layer] setShouldRasterize:NO];
                             [[_rightContainerView layer] setShouldRasterize:NO];
                         }
                         
                         [self setContentViewUserInteractionEnabled:YES];
                         [_contentContainerView removeGestureRecognizer:_tapGestureRecognizer];
                         
                         [self didRevealContentViewController];
                     }];
}

- (void)setVisibleViewController:(UIViewController *)visibleViewController
{
    if (_visibleViewController != visibleViewController) {
        _visibleViewController = visibleViewController;
        [self visibleViewControllerDidChange];
    }
}

- (void)visibleViewControllerDidChange
{
    if ([_visibleViewController respondsToSelector:@selector(preferredStatusBarBackgroundColor)]) {
        self.statusBarBackgroundView.backgroundColor =
            (UIColor *) [_visibleViewController performSelector:@selector(preferredStatusBarBackgroundColor)];
    } else {
        self.statusBarBackgroundView.backgroundColor = [UIColor clearColor];
    }
    
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        [self setNeedsStatusBarAppearanceUpdate];
    }
    
}

- (void)willRevealViewController:(UIViewController *)controller
{
    self.childViewControllerForStatusBarHidden = controller;
}

- (void)didRevealLeftViewController
{
    if ([[self delegate] respondsToSelector:@selector(stackViewController:didRevealLeftViewController:)])
    {
        [[self delegate] stackViewController:self didRevealLeftViewController:[self leftViewController]];
    }
}

- (void)didRevealRightViewController
{
    if ([[self delegate] respondsToSelector:@selector(stackViewController:didRevealLeftViewController:)])
    {
        [[self delegate] stackViewController:self didRevealRightViewController:[self leftViewController]];
    }
}

- (void)didRevealContentViewController
{
    if ([[self delegate] respondsToSelector:@selector(stackViewController:didRevealContentViewController:)])
    {
        [[self delegate] stackViewController:self didRevealContentViewController:[self contentViewController]];
    }
}

- (void)toggleLeftViewController
{
    [self toggleLeftViewControllerAnimated:YES];
}

- (void)toggleLeftViewControllerAnimated:(BOOL)animated
{
    if ([self isLeftViewControllerVisible])
    {
        [self hideLeftViewControllerAnimated:animated];
    }
    else
    {
        [self revealLeftViewControllerAnimated:animated];
    }
}

- (void)toggleLeftViewController:(id)sender event:(UIEvent *)event
{
    [self toggleLeftViewController];
}

- (void)toggleRightViewController
{
    [self toggleRightViewControllerAnimated:YES];
}

- (void)toggleRightViewControllerAnimated:(BOOL)animated
{
    if ([self isRightViewControllerVisible])
    {
        [self hideRightViewControllerAnimated:animated];
    }
    else
    {
        [self revealRightViewControllerAnimated:animated];
    }
}

- (void)toggleRightViewController:(id)sender event:(UIEvent *)event
{
    [self toggleRightViewController];
}

- (void)setContentViewUserInteractionEnabled:(BOOL)userInteractionEnabled
{
    UIViewController *contentViewController = [self contentViewController];
    if ([contentViewController isKindOfClass:[UINavigationController class]])
    {
        UINavigationController *navigationController = (UINavigationController *)contentViewController;
        
        if ([[navigationController viewControllers] count] > 1 && [self disableNavigationBarUserInterationWhenDrilledDown])
        {
            [[navigationController view] setUserInteractionEnabled:userInteractionEnabled];
        }
        else if ([[navigationController viewControllers] count])
        {
            UIViewController *currentViewController = [[navigationController viewControllers] lastObject];
            [[currentViewController view] setUserInteractionEnabled:userInteractionEnabled];
        }
    }
    else
    {
        [[[self contentViewController] view] setUserInteractionEnabled:userInteractionEnabled];
    }
}

#pragma mark - VPStackContentContainerView Methods

- (id <MTStackChildViewController>)stackChildViewControllerForViewController:(UIViewController *)childViewController
{
    id <MTStackChildViewController> navigationChild = nil;
    
    if ([childViewController isKindOfClass:[UINavigationController class]])
    {
        UINavigationController *navigationController = (UINavigationController *)childViewController;
        if ([navigationController conformsToProtocol:@protocol(MTStackChildViewController)])
        {
            navigationChild = (id <MTStackChildViewController>)navigationController;
        }
        else if ([[navigationController viewControllers] count])
        {
            UIViewController *viewController = [[navigationController viewControllers] lastObject];
            if ([viewController conformsToProtocol:@protocol(MTStackChildViewController)])
            {
                navigationChild = (id <MTStackChildViewController>)viewController;
            }
        }
    }
    else if ([childViewController isKindOfClass:[UIViewController class]])
    {
        if ([childViewController conformsToProtocol:@protocol(MTStackChildViewController)])
        {
            navigationChild = (id <MTStackChildViewController>)childViewController;
        }
    }
    
    return navigationChild;
}

- (BOOL)contentContainerView:(MTStackContentContainerView *)view panGestureRecognizerShouldPan:(UIPanGestureRecognizer *)panGestureRecognizer
{
    BOOL shouldPan = YES;
    
    if ([self disableSwipeWhenContentNavigationControllerDrilledDown] &&
        [_contentViewController isKindOfClass:[UINavigationController class]] &&
        [[(UINavigationController *)_contentViewController viewControllers] count] > 1)
    {
        shouldPan = NO;
    }
    else
    {
        id <MTStackChildViewController> navigationChild = [self stackChildViewControllerForViewController:[self contentViewController]];
        
        if (navigationChild)
        {
            shouldPan = [navigationChild shouldAllowPanning];
        }
    }
    
    return shouldPan;
}

- (CGRect)screenBounds
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    if (UIInterfaceOrientationIsLandscape([self interfaceOrientation]))
        screenBounds.size = CGSizeMake(screenBounds.size.height, screenBounds.size.width);
    
    return screenBounds;
}

- (void)contentContainerView:(MTStackContentContainerView *)view panGestureRecognizerDidPan:(UIPanGestureRecognizer *)panGestureRecognizer
{
    switch ([panGestureRecognizer state])
    {
        case UIGestureRecognizerStateEnded:
        {
            if (![self handleSwipe:panGestureRecognizer])
            {
                [self endPanning];
            }
            id <MTStackChildViewController> controller = [self stackChildViewControllerForViewController:[self contentViewController]];
            if ([controller respondsToSelector:@selector(stackViewControllerDidEndPanning:)])
            {
                [controller stackViewControllerDidEndPanning:self];
            }
        }
            break;
        case UIGestureRecognizerStateBegan:
        {
            if ([self rasterizesViewsDuringAnimation])
            {
                [[_contentContainerView layer] setShouldRasterize:YES];
                [[_leftContainerView layer] setShouldRasterize:YES];
                [[_rightContainerView layer] setShouldRasterize:YES];
            }
            _initialPanGestureLocation = [panGestureRecognizer locationInView:[self view]];
            _initialContentControllerFrame = [_contentContainerView frame];
            id <MTStackChildViewController> controller = [self stackChildViewControllerForViewController:[self contentViewController]];
            if ([controller respondsToSelector:@selector(stackViewControllerWillBeginPanning:)])
            {
                [controller stackViewControllerWillBeginPanning:self];
            }
        }
        case UIGestureRecognizerStateChanged:
            [self panWithPanGestureRecognizer:panGestureRecognizer];
            break;
        default:
            break;
    }
}

-(void)setLeftContainerView:(MTStackContainerView *)leftContainerView
{
    NSAssert(leftContainerView, @"New view can not be nil");
    // Force the view to load if it hasn't
    CGRect frame = self.view.frame;
    _leftContainerView.frame = frame;
    [self.leftContainerView removeFromSuperview];

    
    _leftContainerView = leftContainerView;
    if(self.leftViewController)
    {
        [self.leftViewController.view removeFromSuperview];
        [self.leftContainerView setContentView:self.leftViewController.view];
    }
    [self.view addSubview:_leftContainerView];
    [self.view bringSubviewToFront:self.contentContainerView];
}

-(void)setRightContainerView:(MTStackContainerView *)rightContainerView
{
    NSAssert(rightContainerView, @"New view can not be nil");
    // Force the view to load if it hasn't
    CGRect frame = self.view.frame;
    _rightContainerView.frame = frame;

    [self.rightContainerView removeFromSuperview];
    
    _rightContainerView = rightContainerView;
    if(self.rightViewController)
    {
        [self.rightViewController.view removeFromSuperview];
        [self.rightContainerView setContentView:self.rightViewController.view];
    }
    [self.view addSubview:_rightContainerView];
    [self.view bringSubviewToFront:self.contentContainerView];
}

- (BOOL)handleSwipe:(UIPanGestureRecognizer *)panGestureRecognizer
{
    BOOL didSwipe = NO;
    CGFloat velocity = [panGestureRecognizer velocityInView:[self view]].x;
    if (velocity >= [self swipeVelocity])
    {
        if (CGRectGetMinX([_contentContainerView frame]) > 0.0f)
        {
            if (self.swipePermissions & MTStackViewControllerSwipeAllowedOpenLeft) {
                [self revealLeftViewController];
            } else {
                [self hideLeftOrRightViewControllerAnimated:NO];
            }
        }
        else
        {
            if (self.swipePermissions & MTStackViewControllerSwipeAllowedCloseRight) {
                [self hideRightViewController];
            }
        }
        didSwipe = YES;
    }
    else if (velocity <= [self swipeVelocity] * -1.0f)
    {
        if (CGRectGetMinX([_contentContainerView frame]) < 0.0f)
        {
            if (self.swipePermissions & MTStackViewControllerSwipeAllowedOpenRight) {
                [self revealRightViewController];
            } else {
                [self hideLeftOrRightViewControllerAnimated:NO];
            }
        }
        else
        {
            if (self.swipePermissions & MTStackViewControllerSwipeAllowedCloseLeft) {
                [self hideLeftViewController];
            }
        }
        didSwipe = YES;
    }
    
    return didSwipe;
}

// Defaults to portrait only, subclass and override these methods, if you want to support landscape
// Also make sure your content view controller overrides these methods to support registration, so it resizes correctly
// for UINavigationController, the autoresizing mask needs to be flexible width and height (may need to be set in viewWillAppear:)

#pragma mark - Support Rotation

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

- (BOOL)shouldAutorotate
{
    return NO;
}

@end
