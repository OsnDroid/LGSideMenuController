//
//  LGSideMenuController.m
//  LGSideMenuController
//
//
//  The MIT License (MIT)
//
//  Copyright © 2015 Grigory Lutkov <Friend.LGA@gmail.com>
//  (https://github.com/Friend-LGA/LGSideMenuController)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

#import <objc/runtime.h>

#import "LGSideMenuController.h"
#import "LGSideMenuView.h"
#import "LGSideMenuControllerGesturesHandler.h"
#import "LGSideMenuDrawer.h"
#import "LGSideMenuHelper.h"

#pragma mark - Constants

NSString * _Nonnull const LGSideMenuControllerWillShowLeftViewNotification = @"LGSideMenuControllerWillShowLeftViewNotification";
NSString * _Nonnull const LGSideMenuControllerDidShowLeftViewNotification  = @"LGSideMenuControllerDidShowLeftViewNotification";

NSString * _Nonnull const LGSideMenuControllerWillHideLeftViewNotification = @"LGSideMenuControllerWillHideLeftViewNotification";
NSString * _Nonnull const LGSideMenuControllerDidHideLeftViewNotification  = @"LGSideMenuControllerDidHideLeftViewNotification";

NSString * _Nonnull const LGSideMenuControllerWillShowRightViewNotification = @"LGSideMenuControllerWillShowRightViewNotification";
NSString * _Nonnull const LGSideMenuControllerDidShowRightViewNotification  = @"LGSideMenuControllerDidShowRightViewNotification";

NSString * _Nonnull const LGSideMenuControllerWillHideRightViewNotification = @"LGSideMenuControllerWillHideRightViewNotification";
NSString * _Nonnull const LGSideMenuControllerDidHideRightViewNotification  = @"LGSideMenuControllerDidHideRightViewNotification";

static CGFloat const LGSideMenuControllerRotationDuration = 0.25;

#pragma mark -

LGSideMenuSwipeGestureRange LGSideMenuSwipeGestureRangeMake(CGFloat left, CGFloat right) {
    LGSideMenuSwipeGestureRange range;
    range.left = left;
    range.right = right;
    return range;
}

#pragma mark -

@interface LGSideMenuController ()

@property (strong, nonatomic, readwrite) LGSideMenuView *rootViewContainer;
@property (strong, nonatomic, readwrite) LGSideMenuView *leftViewContainer;
@property (strong, nonatomic, readwrite) LGSideMenuView *rightViewContainer;

@property (assign, nonatomic, readwrite, getter=isLeftViewShowing)  BOOL leftViewShowing;
@property (assign, nonatomic, readwrite, getter=isRightViewShowing) BOOL rightViewShowing;

@property (assign, nonatomic, getter=isLeftViewGoingToShow) BOOL leftViewGoingToShow;
@property (assign, nonatomic, getter=isLeftViewGoingToHide) BOOL leftViewGoingToHide;

@property (assign, nonatomic, getter=isRightViewGoingToShow) BOOL rightViewGoingToShow;
@property (assign, nonatomic, getter=isRightViewGoingToHide) BOOL rightViewGoingToHide;

@property (assign, nonatomic) CGSize savedSize;

@property (strong, nonatomic) UIImageView        *rootViewStyleView;
@property (strong, nonatomic) UIVisualEffectView *rootViewCoverView;

@property (strong, nonatomic) UIView             *leftViewBackgroundColorView;
@property (strong, nonatomic) UIImageView        *leftViewBackgroundImageView;
@property (strong, nonatomic) UIVisualEffectView *leftViewStyleView;
@property (strong, nonatomic) UIImageView        *leftViewBorderAndShadowView;

@property (strong, nonatomic) UIView             *rightViewBackgroundColorView;
@property (strong, nonatomic) UIImageView        *rightViewBackgroundImageView;
@property (strong, nonatomic) UIVisualEffectView *rightViewStyleView;
@property (strong, nonatomic) UIImageView        *rightViewBorderAndShadowView;

@property (strong, nonatomic) UIVisualEffectView *sideViewsCoverView;

@property (strong, nonatomic) NSNumber *leftViewGestireStartX;
@property (strong, nonatomic) NSNumber *rightViewGestireStartX;

@property (assign, nonatomic, getter=isLeftViewShowingBeforeGesture)  BOOL leftViewShowingBeforeGesture;
@property (assign, nonatomic, getter=isRightViewShowingBeforeGesture) BOOL rightViewShowingBeforeGesture;

@property (strong, nonatomic) LGSideMenuControllerGesturesHandler *gesturesHandler;

@property (strong, nonatomic, readwrite) UITapGestureRecognizer *tapGesture;
@property (strong, nonatomic, readwrite) UIPanGestureRecognizer *panGesture;

@property (assign, nonatomic, getter=isNeedsUpdateLayoutsAndStyles) BOOL needsUpdateLayoutsAndStyles;

@property (assign, nonatomic, getter=isUserRootViewShouldAutorotate)             BOOL userRootViewShouldAutorotate;
@property (assign, nonatomic, getter=isUserRootViewStatusBarHidden)              BOOL userRootViewStatusBarHidden;
@property (assign, nonatomic, getter=isUserLeftViewStatusBarHidden)              BOOL userLeftViewStatusBarHidden;
@property (assign, nonatomic, getter=isUserRightViewStatusBarHidden)             BOOL userRightViewStatusBarHidden;
@property (assign, nonatomic, getter=isUserRootViewStatusBarStyle)               BOOL userRootViewStatusBarStyle;
@property (assign, nonatomic, getter=isUserLeftViewStatusBarStyle)               BOOL userLeftViewStatusBarStyle;
@property (assign, nonatomic, getter=isUserRightViewStatusBarStyle)              BOOL userRightViewStatusBarStyle;
@property (assign, nonatomic, getter=isUserRootViewStatusBarUpdateAnimation)     BOOL userRootViewStatusBarUpdateAnimation;
@property (assign, nonatomic, getter=isUserLeftViewStatusBarUpdateAnimation)     BOOL userLeftViewStatusBarUpdateAnimation;
@property (assign, nonatomic, getter=isUserRightViewStatusBarUpdateAnimation)    BOOL userRightViewStatusBarUpdateAnimation;
@property (assign, nonatomic, getter=isUserRootViewCoverColorForLeftView)        BOOL userRootViewCoverColorForLeftView;
@property (assign, nonatomic, getter=isUserRootViewCoverColorForRightView)       BOOL userRootViewCoverColorForRightView;
@property (assign, nonatomic, getter=isUserLeftViewCoverColor)                   BOOL userLeftViewCoverColor;
@property (assign, nonatomic, getter=isUserRightViewCoverColor)                  BOOL userRightViewCoverColor;
@property (assign, nonatomic, getter=isUserRootViewScaleForLeftView)             BOOL userRootViewScaleForLeftView;
@property (assign, nonatomic, getter=isUserRootViewScaleForRightView)            BOOL userRootViewScaleForRightView;
@property (assign, nonatomic, getter=isUserLeftViewInititialScale)               BOOL userLeftViewInititialScale;
@property (assign, nonatomic, getter=isUserRightViewInititialScale)              BOOL userRightViewInititialScale;
@property (assign, nonatomic, getter=isUserLeftViewInititialOffsetX)             BOOL userLeftViewInititialOffsetX;
@property (assign, nonatomic, getter=isUserRightViewInititialOffsetX)            BOOL userRightViewInititialOffsetX;
@property (assign, nonatomic, getter=isUserLeftViewBackgroundImageInitialScale)  BOOL userLeftViewBackgroundImageInitialScale;
@property (assign, nonatomic, getter=isUserRightViewBackgroundImageInitialScale) BOOL userRightViewBackgroundImageInitialScale;

@end

@implementation LGSideMenuController

@synthesize
rootViewController = _rootViewController,
leftViewBackgroundImage = _leftViewBackgroundImage,
rightViewBackgroundImage = _rightViewBackgroundImage,
leftViewBackgroundBlurEffect = _leftViewBackgroundBlurEffect,
rightViewBackgroundBlurEffect = _rightViewBackgroundBlurEffect,
leftViewBackgroundAlpha = _leftViewBackgroundAlpha,
rightViewBackgroundAlpha = _rightViewBackgroundAlpha,
rootViewLayerShadowColor = _rootViewLayerShadowColor,
leftViewLayerShadowColor = _leftViewLayerShadowColor,
rightViewLayerShadowColor = _rightViewLayerShadowColor,
rootViewLayerShadowRadius = _rootViewLayerShadowRadius,
leftViewLayerShadowRadius = _leftViewLayerShadowRadius,
rightViewLayerShadowRadius = _rightViewLayerShadowRadius,
leftViewCoverBlurEffect = _leftViewCoverBlurEffect,
rightViewCoverBlurEffect = _rightViewCoverBlurEffect,
leftViewCoverAlpha = _leftViewCoverAlpha,
rightViewCoverAlpha = _rightViewCoverAlpha,
rootViewShouldAutorotate = _rootViewShouldAutorotate,
rootViewStatusBarHidden = _rootViewStatusBarHidden,
leftViewStatusBarHidden = _leftViewStatusBarHidden,
rightViewStatusBarHidden = _rightViewStatusBarHidden,
rootViewStatusBarStyle = _rootViewStatusBarStyle,
leftViewStatusBarStyle = _leftViewStatusBarStyle,
rightViewStatusBarStyle = _rightViewStatusBarStyle,
rootViewStatusBarUpdateAnimation = _rootViewStatusBarUpdateAnimation,
leftViewStatusBarUpdateAnimation = _leftViewStatusBarUpdateAnimation,
rightViewStatusBarUpdateAnimation = _rightViewStatusBarUpdateAnimation,
rootViewCoverColorForLeftView = _rootViewCoverColorForLeftView,
rootViewCoverColorForRightView = _rootViewCoverColorForRightView,
leftViewCoverColor = _leftViewCoverColor,
rightViewCoverColor = _rightViewCoverColor,
rootViewScaleForLeftView = _rootViewScaleForLeftView,
rootViewScaleForRightView = _rootViewScaleForRightView,
leftViewInititialScale = _leftViewInititialScale,
rightViewInititialScale = _rightViewInititialScale,
leftViewInititialOffsetX = _leftViewInititialOffsetX,
rightViewInititialOffsetX = _rightViewInititialOffsetX,
leftViewBackgroundImageInitialScale = _leftViewBackgroundImageInitialScale,
rightViewBackgroundImageInitialScale = _rightViewBackgroundImageInitialScale;

- (nonnull instancetype)init {
    self = [super init];
    if (self) {
        [self setupDefaultProperties];
        [self setupDefaults];
    }
    return self;
}

- (nonnull instancetype)initWithRootViewController:(nullable UIViewController *)rootViewController {
    self = [super init];
    if (self) {
        [self setupDefaultProperties];
        [self setupDefaults];

        self.rootViewController = rootViewController;
    }
    return self;
}

+ (nonnull instancetype)sideMenuControllerWithRootViewController:(nullable UIViewController *)rootViewController {
    return [[self alloc] initWithRootViewController:rootViewController];
}

- (nonnull instancetype)initWithRootViewController:(nullable UIViewController *)rootViewController
                                leftViewController:(nullable UIViewController *)leftViewController
                               rightViewController:(nullable UIViewController *)rightViewController {
    self = [super init];
    if (self) {
        [self setupDefaultProperties];
        [self setupDefaults];

        self.rootViewController = rootViewController;
        self.leftViewController = leftViewController;
        self.rightViewController = rightViewController;
    }
    return self;
}

+ (nonnull instancetype)sideMenuControllerWithRootViewController:(nullable UIViewController *)rootViewController
                                              leftViewController:(nullable UIViewController *)leftViewController
                                             rightViewController:(nullable UIViewController *)rightViewController {
    return [[self alloc] initWithRootViewController:rootViewController
                                 leftViewController:leftViewController
                                rightViewController:rightViewController];
}

- (nonnull instancetype)initWithRootView:(nullable UIView *)rootView {
    self = [super init];
    if (self) {
        [self setupDefaultProperties];
        [self setupDefaults];

        self.rootView = rootView;
    }
    return self;
}

+ (nonnull instancetype)sideMenuControllerWithRootView:(nullable UIView *)rootView {
    return [[self alloc] initWithRootView:rootView];
}

- (nonnull instancetype)initWithRootView:(nullable UIView *)rootView
                                leftView:(nullable UIView *)leftView
                               rightView:(nullable UIView *)rightView {
    self = [super init];
    if (self) {
        [self setupDefaultProperties];
        [self setupDefaults];

        self.rootView = rootView;
        self.leftView = leftView;
        self.rightView = rightView;
    }
    return self;
}

+ (nonnull instancetype)sideMenuControllerWithRootView:(nullable UIView *)rootView
                                              leftView:(nullable UIView *)leftView
                                             rightView:(nullable UIView *)rightView {
    return [[self alloc] initWithRootView:rootView leftView:leftView rightView:rightView];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupDefaultProperties];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setupDefaults];
}

- (void)setupDefaults {
    self.view.clipsToBounds = YES;
    self.view.backgroundColor = nil;

    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture:)];
    self.tapGesture.delegate = self.gesturesHandler;
    self.tapGesture.numberOfTapsRequired = 1;
    self.tapGesture.numberOfTouchesRequired = 1;
    self.tapGesture.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:self.tapGesture];

    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
    self.panGesture.delegate = self.gesturesHandler;
    self.panGesture.minimumNumberOfTouches = 1;
    self.panGesture.maximumNumberOfTouches = 1;
    self.panGesture.cancelsTouchesInView = YES;
    [self.view addGestureRecognizer:self.panGesture];
}

#pragma mark - Static defaults

- (void)setupDefaultProperties {
    CGFloat minSide = MIN(CGRectGetWidth(UIScreen.mainScreen.bounds), CGRectGetHeight(UIScreen.mainScreen.bounds));
    CGFloat sideMenuWidth = minSide - 44.0;

    // Needed to be initialized before default properties
    self.gesturesHandler = [[LGSideMenuControllerGesturesHandler alloc] initWithSideMenuController:self];

    self.leftViewWidth = sideMenuWidth;
    self.rightViewWidth = sideMenuWidth;

    self.leftViewPresentationStyle = LGSideMenuPresentationStyleSlideAbove;
    self.rightViewPresentationStyle = LGSideMenuPresentationStyleSlideAbove;

    self.leftViewAlwaysVisibleOptions = LGSideMenuAlwaysVisibleOnNone;
    self.rightViewAlwaysVisibleOptions = LGSideMenuAlwaysVisibleOnNone;

    self.leftViewHidesOnTouch = YES;
    self.rightViewHidesOnTouch = YES;

    self.leftViewSwipeGestureEnabled = YES;
    self.rightViewSwipeGestureEnabled = YES;

    self.swipeGestureArea = LGSideMenuSwipeGestureAreaBorders;
    self.leftViewSwipeGestureRange = LGSideMenuSwipeGestureRangeMake(44.0, 44.0);
    self.rightViewSwipeGestureRange = LGSideMenuSwipeGestureRangeMake(44.0, 44.0);

    self.leftViewAnimationSpeed = 0.5;
    self.rightViewAnimationSpeed = 0.5;

    self.shouldHideLeftViewAnimated = YES;
    self.shouldHideRightViewAnimated = YES;

    self.leftViewEnabled = YES;
    self.rightViewEnabled = YES;

    self.leftViewBackgroundColor = nil;
    self.rightViewBackgroundColor = nil;

    self.leftViewBackgroundImage = nil;
    self.rightViewBackgroundImage = nil;

    self.leftViewBackgroundBlurEffect = nil;
    self.rightViewBackgroundBlurEffect = nil;

    self.leftViewBackgroundAlpha = 1.0;
    self.rightViewBackgroundAlpha = 1.0;

    self.rootViewLayerBorderColor = nil;
    self.leftViewLayerBorderColor = nil;
    self.rightViewLayerBorderColor = nil;

    self.rootViewLayerBorderWidth = 0.0;
    self.leftViewLayerBorderWidth = 0.0;
    self.rightViewLayerBorderWidth = 0.0;

    self.rootViewLayerShadowColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    self.leftViewLayerShadowColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    self.rightViewLayerShadowColor = [UIColor colorWithWhite:0.0 alpha:0.5];

    self.rootViewLayerShadowRadius = 5.0;
    self.leftViewLayerShadowRadius = 5.0;
    self.rightViewLayerShadowRadius = 5.0;

    self.rootViewCoverBlurEffectForLeftView = nil;
    self.rootViewCoverBlurEffectForRightView = nil;
    self.leftViewCoverBlurEffect = nil;
    self.rightViewCoverBlurEffect = nil;

    self.rootViewCoverAlphaForLeftView = 1.0;
    self.rootViewCoverAlphaForRightView = 1.0;
    self.leftViewCoverAlpha = 1.0;
    self.rightViewCoverAlpha = 1.0;

    self.needsUpdateLayoutsAndStyles = NO;
}

#pragma mark - Layouting

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    CGSize size = self.view.bounds.size;

    if (self.isNeedsUpdateLayoutsAndStyles || !CGSizeEqualToSize(self.savedSize, size)) {
        BOOL appeared = !CGSizeEqualToSize(self.savedSize, CGSizeZero);

        self.savedSize = size;
        self.needsUpdateLayoutsAndStyles = NO;

        // If side view is always visible and after rotating it should hide, we need to wait until rotation is finished
        [self updateLayoutsAndStylesWithDelay:(appeared ? LGSideMenuControllerRotationDuration : 0.0)];
    }
}

// inherit this method
- (void)rootViewWillLayoutSubviewsWithSize:(CGSize)size {
    if (self.rootViewController) {
        self.rootView.frame = CGRectMake(0.0, 0.0, size.width, size.height);
    }
}

// inherit this method
- (void)leftViewWillLayoutSubviewsWithSize:(CGSize)size {
    if (self.leftViewController) {
        self.leftView.frame = CGRectMake(0.0, 0.0, size.width, size.height);
    }
}

// inherit this method
- (void)rightViewWillLayoutSubviewsWithSize:(CGSize)size {
    if (self.rightViewController) {
        self.rightView.frame = CGRectMake(0.0, 0.0, size.width, size.height);
    }
}

#pragma mark - Rotation

- (BOOL)shouldAutorotate {
    if (self.rootView) {
        return self.rootViewShouldAutorotate;
    }

    return super.shouldAutorotate;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    if (self.isLeftViewGoingToShow) {
        [self showLeftViewDoneWithGesture:(self.leftViewGestireStartX != nil)];
    }
    else if (self.isLeftViewGoingToHide) {
        [self hideLeftViewDoneWithGesture:(self.leftViewGestireStartX != nil)];
    }

    if (self.isRightViewGoingToShow) {
        [self showRightViewDoneWithGesture:(self.rightViewGestireStartX != nil)];
    }
    else if (self.isRightViewGoingToHide) {
        [self hideRightViewDoneWithGesture:(self.rightViewGestireStartX != nil)];
    }
}

#pragma mark - Status bar

- (BOOL)prefersStatusBarHidden {
    if (self.leftView && (self.isLeftViewShowing || self.isLeftViewGoingToShow) && !self.isLeftViewGoingToHide && !self.isLeftViewAlwaysVisible) {
        return self.leftViewStatusBarHidden;
    }

    if (self.rightView && (self.isRightViewShowing || self.isRightViewGoingToShow) && !self.isRightViewGoingToHide && !self.isRightViewAlwaysVisible) {
        return self.rightViewStatusBarHidden;
    }

    if (self.rootView) {
        return self.rootViewStatusBarHidden;
    }

    return super.prefersStatusBarHidden;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    if (self.leftView && (self.isLeftViewShowing || self.isLeftViewGoingToShow) && !self.isLeftViewGoingToHide && !self.isLeftViewAlwaysVisible) {
        return self.leftViewStatusBarStyle;
    }

    if (self.rightView && (self.isRightViewShowing || self.isRightViewGoingToShow) && !self.isRightViewGoingToHide && !self.isRightViewAlwaysVisible) {
        return self.rightViewStatusBarStyle;
    }

    if (self.rootView) {
        return self.rootViewStatusBarStyle;
    }

    return super.preferredStatusBarStyle;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    if (self.leftView && (self.isLeftViewShowing || self.isLeftViewGoingToShow) && !self.isLeftViewGoingToHide && !self.isLeftViewAlwaysVisible) {
        return self.leftViewStatusBarUpdateAnimation;
    }

    if (self.rightView && (self.isRightViewShowing || self.isRightViewGoingToShow) && !self.isRightViewGoingToHide && !self.isRightViewAlwaysVisible) {
        return self.rightViewStatusBarUpdateAnimation;
    }

    if (self.rootView) {
        return self.rootViewStatusBarUpdateAnimation;
    }

    return super.preferredStatusBarUpdateAnimation;
}

#pragma mark - Update styles and layouts

- (void)setNeedsUpdateLayoutsAndStyles {
    self.needsUpdateLayoutsAndStyles = YES;

    if (self.isViewLoaded) {
        [self.view setNeedsLayout];
    }
}

- (void)updateLayoutsAndStyles {
    [self updateLayoutsAndStylesWithDelay:0.0];
}

- (void)updateLayoutsAndStylesWithDelay:(NSTimeInterval)delay {
    [self rootViewsValidate];
    [self leftViewsValidate];
    [self rightViewsValidate];

    [self viewsHierarchyValidate];

    [self rootViewsFramesValidate];
    [self leftViewsFramesValidate];
    [self rightViewsFramesValidate];

    [self stylesValidate];

    [self rootViewsTransformValidate];
    [self leftViewsTransformValidate];
    [self rightViewsTransformValidate];

    [self visibilityValidateWithDelay:delay];
}

#pragma mark - Static defaults getters

- (UIImage *)leftViewBackgroundImage {
    if (self.leftViewPresentationStyle == LGSideMenuPresentationStyleSlideAbove) {
        return nil;
    }

    return _leftViewBackgroundImage;
}

- (UIImage *)rightViewBackgroundImage {
    if (self.rightViewPresentationStyle == LGSideMenuPresentationStyleSlideAbove) {
        return nil;
    }

    return _rightViewBackgroundImage;
}

- (UIBlurEffect *)leftViewBackgroundBlurEffect {
    if (self.leftViewPresentationStyle != LGSideMenuPresentationStyleSlideAbove) {
        return nil;
    }

    return _leftViewBackgroundBlurEffect;
}

- (UIBlurEffect *)rightViewBackgroundBlurEffect {
    if (self.rightViewPresentationStyle != LGSideMenuPresentationStyleSlideAbove) {
        return nil;
    }

    return _rightViewBackgroundBlurEffect;
}

- (CGFloat)leftViewBackgroundAlpha {
    if (self.leftViewPresentationStyle != LGSideMenuPresentationStyleSlideAbove) {
        return 1.0;
    }

    return _leftViewBackgroundAlpha;
}

- (CGFloat)rightViewBackgroundAlpha {
    if (self.rightViewPresentationStyle != LGSideMenuPresentationStyleSlideAbove) {
        return 1.0;
    }

    return _rightViewBackgroundAlpha;
}

- (UIColor *)leftViewLayerShadowColor {
    if (self.leftViewPresentationStyle != LGSideMenuPresentationStyleSlideAbove) {
        return nil;
    }

    return _leftViewLayerShadowColor;
}

- (UIColor *)rightViewLayerShadowColor {
    if (self.rightViewPresentationStyle != LGSideMenuPresentationStyleSlideAbove) {
        return nil;
    }

    return _rightViewLayerShadowColor;
}

- (CGFloat)leftViewLayerShadowRadius {
    if (self.leftViewPresentationStyle != LGSideMenuPresentationStyleSlideAbove) {
        return 0.0;
    }

    return _leftViewLayerShadowRadius;
}

- (CGFloat)rightViewLayerShadowRadius {
    if (self.rightViewPresentationStyle != LGSideMenuPresentationStyleSlideAbove) {
        return 0.0;
    }

    return _rightViewLayerShadowRadius;
}

- (UIBlurEffect *)leftViewCoverBlurEffect {
    if (self.leftViewPresentationStyle == LGSideMenuPresentationStyleSlideAbove) {
        return nil;
    }

    return _leftViewCoverBlurEffect;
}

- (UIBlurEffect *)rightViewCoverBlurEffect {
    if (self.rightViewPresentationStyle == LGSideMenuPresentationStyleSlideAbove) {
        return nil;
    }

    return _rightViewCoverBlurEffect;
}

- (CGFloat)leftViewCoverAlpha {
    if (self.leftViewPresentationStyle == LGSideMenuPresentationStyleSlideAbove) {
        return 1.0;
    }

    return _leftViewCoverAlpha;
}

- (CGFloat)rightViewCoverAlpha {
    if (self.rightViewPresentationStyle == LGSideMenuPresentationStyleSlideAbove) {
        return 1.0;
    }

    return _rightViewCoverAlpha;
}

#pragma mark - Dynamic defaults setters and getters

- (void)setRootViewShouldAutorotate:(BOOL)rootViewShouldAutorotate {
    _rootViewShouldAutorotate = rootViewShouldAutorotate;
    self.userRootViewShouldAutorotate = YES;
}

- (BOOL)rootViewShouldAutorotate {
    if (self.isUserRootViewShouldAutorotate) {
        return _rootViewShouldAutorotate;
    }

    if (self.rootViewController) {
        return self.rootViewController.shouldAutorotate;
    }

    return super.shouldAutorotate;
}

- (void)setRootViewStatusBarHidden:(BOOL)rootViewStatusBarHidden {
    _rootViewStatusBarHidden = rootViewStatusBarHidden;
    self.userRootViewStatusBarHidden = YES;
}

- (BOOL)isRootViewStatusBarHidden {
    if (self.isUserRootViewStatusBarHidden) {
        return _rootViewStatusBarHidden;
    }

    if (!LGSideMenuHelper.isViewControllerBasedStatusBarAppearance) {
        return UIApplication.sharedApplication.statusBarHidden;
    }

    if (self.rootViewController) {
        return self.rootViewController.prefersStatusBarHidden;
    }

    return super.prefersStatusBarHidden;
}

- (void)setLeftViewStatusBarHidden:(BOOL)leftViewStatusBarHidden {
    _leftViewStatusBarHidden = leftViewStatusBarHidden;
    self.userLeftViewStatusBarHidden = YES;
}

- (BOOL)isLeftViewStatusBarHidden {
    if (self.isUserLeftViewStatusBarHidden) {
        return _leftViewStatusBarHidden;
    }

    if (!LGSideMenuHelper.isViewControllerBasedStatusBarAppearance) {
        return UIApplication.sharedApplication.statusBarHidden;
    }

    if (self.leftViewController) {
        return self.leftViewController.prefersStatusBarHidden;
    }

    if (self.rootViewController) {
        return self.rootViewController.prefersStatusBarHidden;
    }

    return super.prefersStatusBarHidden;
}

- (void)setRightViewStatusBarHidden:(BOOL)rightViewStatusBarHidden {
    _rightViewStatusBarHidden = rightViewStatusBarHidden;
    self.userRightViewStatusBarHidden = YES;
}

- (BOOL)isRightViewStatusBarHidden {
    if (self.isUserRightViewStatusBarHidden) {
        return _rightViewStatusBarHidden;
    }

    if (!LGSideMenuHelper.isViewControllerBasedStatusBarAppearance) {
        return UIApplication.sharedApplication.statusBarHidden;
    }

    if (self.rightViewController) {
        return self.rightViewController.prefersStatusBarHidden;
    }

    if (self.rootViewController) {
        return self.rootViewController.prefersStatusBarHidden;
    }

    return super.prefersStatusBarHidden;
}

- (void)setRootViewStatusBarStyle:(UIStatusBarStyle)rootViewStatusBarStyle {
    _rootViewStatusBarStyle = rootViewStatusBarStyle;
    self.userRootViewStatusBarStyle = YES;
}

- (UIStatusBarStyle)rootViewStatusBarStyle {
    if (self.isUserRootViewStatusBarStyle) {
        return _rootViewStatusBarStyle;
    }

    if (!LGSideMenuHelper.isViewControllerBasedStatusBarAppearance) {
        return UIApplication.sharedApplication.statusBarStyle;
    }

    if (self.rootViewController) {
        return self.rootViewController.preferredStatusBarStyle;
    }

    return super.preferredStatusBarStyle;
}

- (void)setLeftViewStatusBarStyle:(UIStatusBarStyle)leftViewStatusBarStyle {
    _leftViewStatusBarStyle = leftViewStatusBarStyle;
    self.userLeftViewStatusBarStyle = YES;
}

- (UIStatusBarStyle)leftViewStatusBarStyle {
    if (self.isUserLeftViewStatusBarStyle) {
        return _leftViewStatusBarStyle;
    }

    if (!LGSideMenuHelper.isViewControllerBasedStatusBarAppearance) {
        return UIApplication.sharedApplication.statusBarStyle;
    }

    if (self.leftViewController) {
        return self.leftViewController.preferredStatusBarStyle;
    }

    if (self.rootViewController) {
        return self.rootViewController.preferredStatusBarStyle;
    }

    return super.preferredStatusBarStyle;
}

- (void)setRightViewStatusBarStyle:(UIStatusBarStyle)rightViewStatusBarStyle {
    _rightViewStatusBarStyle = rightViewStatusBarStyle;
    self.userRightViewStatusBarStyle = YES;
}

- (UIStatusBarStyle)rightViewStatusBarStyle {
    if (self.isUserRightViewStatusBarStyle) {
        return _rightViewStatusBarStyle;
    }

    if (!LGSideMenuHelper.isViewControllerBasedStatusBarAppearance) {
        return UIApplication.sharedApplication.statusBarStyle;
    }

    if (self.rightViewController) {
        return self.rightViewController.preferredStatusBarStyle;
    }

    if (self.rootViewController) {
        return self.rootViewController.preferredStatusBarStyle;
    }

    return super.preferredStatusBarStyle;
}

- (void)setRootViewStatusBarUpdateAnimation:(UIStatusBarAnimation)rootViewStatusBarUpdateAnimation {
    _rootViewStatusBarUpdateAnimation = rootViewStatusBarUpdateAnimation;
    self.userRootViewStatusBarUpdateAnimation = YES;
}

- (UIStatusBarAnimation)rootViewStatusBarUpdateAnimation {
    if (self.isUserRootViewStatusBarUpdateAnimation) {
        return _rootViewStatusBarUpdateAnimation;
    }

    if (self.rootViewController) {
        return self.rootViewController.preferredStatusBarUpdateAnimation;
    }

    return super.preferredStatusBarUpdateAnimation;
}

- (void)setLeftViewStatusBarUpdateAnimation:(UIStatusBarAnimation)leftViewStatusBarUpdateAnimation {
    _leftViewStatusBarUpdateAnimation = leftViewStatusBarUpdateAnimation;
    self.userLeftViewStatusBarUpdateAnimation = YES;
}

- (UIStatusBarAnimation)leftViewStatusBarUpdateAnimation {
    if (self.isUserLeftViewStatusBarUpdateAnimation) {
        return _leftViewStatusBarUpdateAnimation;
    }

    if (self.leftViewController) {
        return self.leftViewController.preferredStatusBarUpdateAnimation;
    }

    if (self.rootViewController) {
        return self.rootViewController.preferredStatusBarUpdateAnimation;
    }

    return super.preferredStatusBarUpdateAnimation;
}

- (void)setRightViewStatusBarUpdateAnimation:(UIStatusBarAnimation)rightViewStatusBarUpdateAnimation {
    _rightViewStatusBarUpdateAnimation = rightViewStatusBarUpdateAnimation;
    self.userRightViewStatusBarUpdateAnimation = YES;
}

- (UIStatusBarAnimation)rightViewStatusBarUpdateAnimation {
    if (self.isUserRightViewStatusBarUpdateAnimation) {
        return _rightViewStatusBarUpdateAnimation;
    }

    if (self.rightViewController) {
        return self.rightViewController.preferredStatusBarUpdateAnimation;
    }

    if (self.rootViewController) {
        return self.rootViewController.preferredStatusBarUpdateAnimation;
    }

    return super.preferredStatusBarUpdateAnimation;
}

- (void)setRootViewCoverColorForLeftView:(UIColor *)rootViewCoverColorForLeftView {
    _rootViewCoverColorForLeftView = rootViewCoverColorForLeftView;
    self.userRootViewCoverColorForLeftView = YES;
}

- (UIColor *)rootViewCoverColorForLeftView {
    if (self.isUserRootViewCoverColorForLeftView) {
        return _rootViewCoverColorForLeftView;
    }

    if (self.leftViewPresentationStyle == LGSideMenuPresentationStyleSlideAbove) {
        return [UIColor colorWithWhite:0.0 alpha:0.5];
    }

    return nil;
}

- (void)setRootViewCoverColorForRightView:(UIColor *)rootViewCoverColorForRightView {
    _rootViewCoverColorForRightView = rootViewCoverColorForRightView;
    self.userRootViewCoverColorForRightView = YES;
}

- (UIColor *)rootViewCoverColorForRightView {
    if (self.isUserRootViewCoverColorForRightView) {
        return _rootViewCoverColorForRightView;
    }

    if (self.rightViewPresentationStyle == LGSideMenuPresentationStyleSlideAbove) {
        return [UIColor colorWithWhite:0.0 alpha:0.5];
    }

    return nil;
}

- (void)setLeftViewCoverColor:(UIColor *)leftViewCoverColor {
    _leftViewCoverColor = leftViewCoverColor;
    self.userLeftViewCoverColor = YES;
}

- (UIColor *)leftViewCoverColor {
    if (self.isUserLeftViewCoverColor) {
        return _leftViewCoverColor;
    }

    if (self.leftViewPresentationStyle != LGSideMenuPresentationStyleSlideAbove) {
        return [UIColor colorWithWhite:0.0 alpha:0.5];
    }

    return nil;
}

- (void)setRightViewCoverColor:(UIColor *)rightViewCoverColor {
    _rightViewCoverColor = rightViewCoverColor;
    self.userRightViewCoverColor = YES;
}

- (UIColor *)rightViewCoverColor {
    if (self.isUserRightViewCoverColor) {
        return _rightViewCoverColor;
    }

    if (self.rightViewPresentationStyle != LGSideMenuPresentationStyleSlideAbove) {
        return [UIColor colorWithWhite:0.0 alpha:0.5];
    }

    return nil;
}

- (void)setRootViewScaleForLeftView:(CGFloat)rootViewScaleForLeftView {
    _rootViewScaleForLeftView = rootViewScaleForLeftView;
    self.userRootViewScaleForLeftView = YES;
}

- (CGFloat)rootViewScaleForLeftView {
    if (self.isUserRootViewScaleForLeftView) {
        return _rootViewScaleForLeftView;
    }

    if (self.leftViewPresentationStyle == LGSideMenuPresentationStyleSlideAbove ||
        self.leftViewPresentationStyle == LGSideMenuPresentationStyleSlideBelow) {
        return 1.0;
    }

    return 0.8;
}

- (void)setRootViewScaleForRightView:(CGFloat)rootViewScaleForRightView {
    _rootViewScaleForRightView = rootViewScaleForRightView;
    self.userRootViewScaleForRightView = YES;
}

- (CGFloat)rootViewScaleForRightView {
    if (self.isUserRootViewScaleForRightView) {
        return _rootViewScaleForRightView;
    }

    if (self.rightViewPresentationStyle == LGSideMenuPresentationStyleSlideAbove ||
        self.rightViewPresentationStyle == LGSideMenuPresentationStyleSlideBelow) {
        return 1.0;
    }

    return 0.8;
}

- (void)setLeftViewInititialScale:(CGFloat)leftViewInititialScale {
    _leftViewInititialScale = leftViewInititialScale;
    self.userLeftViewInititialScale = YES;
}

- (CGFloat)leftViewInititialScale {
    if (self.isUserLeftViewInititialScale) {
        return _leftViewInititialScale;
    }

    if (self.leftViewPresentationStyle == LGSideMenuPresentationStyleScaleFromLittle) {
        return 0.8;
    }

    if (self.leftViewPresentationStyle == LGSideMenuPresentationStyleScaleFromBig) {
        return 1.2;
    }

    return 1.0;
}

- (void)setRightViewInititialScale:(CGFloat)rightViewInititialScale {
    _rightViewInititialScale = rightViewInititialScale;
    self.userRightViewInititialScale = YES;
}

- (CGFloat)rightViewInititialScale {
    if (self.isUserRightViewInititialScale) {
        return _rightViewInititialScale;
    }

    if (self.rightViewPresentationStyle == LGSideMenuPresentationStyleScaleFromLittle) {
        return 0.8;
    }

    if (self.rightViewPresentationStyle == LGSideMenuPresentationStyleScaleFromBig) {
        return 1.2;
    }

    return 1.0;
}

- (void)setLeftViewInititialOffsetX:(CGFloat)leftViewInititialOffsetX {
    _leftViewInititialOffsetX = leftViewInititialOffsetX;
    self.userLeftViewInititialOffsetX = YES;
}

- (CGFloat)leftViewInititialOffsetX {
    if (self.isUserLeftViewInititialOffsetX) {
        return _leftViewInititialOffsetX;
    }

    if (self.leftViewPresentationStyle == LGSideMenuPresentationStyleSlideBelow) {
        self.leftViewInititialOffsetX = -self.leftViewWidth/2;
    }

    return 0.0;
}

- (void)setRightViewInititialOffsetX:(CGFloat)rightViewInititialOffsetX {
    _rightViewInititialOffsetX = rightViewInititialOffsetX;
    self.userRightViewInititialOffsetX = YES;
}

- (CGFloat)rightViewInititialOffsetX {
    if (self.isUserRightViewInititialOffsetX) {
        return _rightViewInititialOffsetX;
    }

    if (self.rightViewPresentationStyle == LGSideMenuPresentationStyleSlideBelow) {
        self.rightViewInititialOffsetX = self.rightViewWidth/2;
    }

    return 0.0;
}

- (void)setLeftViewBackgroundImageInitialScale:(CGFloat)leftViewBackgroundImageInitialScale {
    _leftViewBackgroundImageInitialScale = leftViewBackgroundImageInitialScale;
    self.userLeftViewBackgroundImageInitialScale = YES;
}

- (CGFloat)leftViewBackgroundImageInitialScale {
    if (self.isUserLeftViewBackgroundImageInitialScale) {
        return _leftViewBackgroundImageInitialScale;
    }

    if (self.leftViewPresentationStyle == LGSideMenuPresentationStyleScaleFromLittle ||
        self.leftViewPresentationStyle == LGSideMenuPresentationStyleScaleFromBig) {
        return 1.4;
    }

    return 1.0;
}

- (void)setRightViewBackgroundImageInitialScale:(CGFloat)rightViewBackgroundImageInitialScale {
    _rightViewBackgroundImageInitialScale = rightViewBackgroundImageInitialScale;
    self.userRightViewBackgroundImageInitialScale = YES;
}

- (CGFloat)rightViewBackgroundImageInitialScale {
    if (self.isUserRightViewBackgroundImageInitialScale) {
        return _rightViewBackgroundImageInitialScale;
    }

    if (self.rightViewPresentationStyle == LGSideMenuPresentationStyleScaleFromLittle ||
        self.rightViewPresentationStyle == LGSideMenuPresentationStyleScaleFromBig) {
        return 1.4;
    }

    return 1.0;
}

#pragma mark -

- (void)setLeftViewPresentationStyle:(LGSideMenuPresentationStyle)leftViewPresentationStyle {
    if (_leftViewPresentationStyle == leftViewPresentationStyle) return;

    _leftViewPresentationStyle = leftViewPresentationStyle;

    [self setNeedsUpdateLayoutsAndStyles];
}

- (void)setRightViewPresentationStyle:(LGSideMenuPresentationStyle)rightViewPresentationStyle {
    if (_rightViewPresentationStyle == rightViewPresentationStyle) return;

    _rightViewPresentationStyle = rightViewPresentationStyle;

    [self setNeedsUpdateLayoutsAndStyles];
}

- (void)setLeftViewBackgroundColor:(UIColor *)leftViewBackgroundColor {
    if (_leftViewBackgroundColor == leftViewBackgroundColor) return;

    _leftViewBackgroundColor = leftViewBackgroundColor;

    [self setNeedsUpdateLayoutsAndStyles];
}

- (void)setRightViewBackgroundColor:(UIColor *)rightViewBackgroundColor {
    if (_rightViewBackgroundColor == rightViewBackgroundColor) return;

    _rightViewBackgroundColor = rightViewBackgroundColor;

    [self setNeedsUpdateLayoutsAndStyles];
}

- (void)setLeftViewBackgroundImage:(UIImage *)leftViewBackgroundImage {
    if (_leftViewBackgroundImage == leftViewBackgroundImage) return;

    _leftViewBackgroundImage = leftViewBackgroundImage;

    [self setNeedsUpdateLayoutsAndStyles];
}

- (void)setRightViewBackgroundImage:(UIImage *)rightViewBackgroundImage {
    if (_rightViewBackgroundImage == rightViewBackgroundImage) return;

    _rightViewBackgroundImage = rightViewBackgroundImage;

    [self setNeedsUpdateLayoutsAndStyles];
}

- (void)setLeftViewAlwaysVisibleOptions:(LGSideMenuAlwaysVisibleOptions)leftViewAlwaysVisibleOptions {
    if (_leftViewAlwaysVisibleOptions == leftViewAlwaysVisibleOptions) return;

    _leftViewAlwaysVisibleOptions = leftViewAlwaysVisibleOptions;

    [self setNeedsUpdateLayoutsAndStyles];
}

- (void)setRightViewAlwaysVisibleOptions:(LGSideMenuAlwaysVisibleOptions)rightViewAlwaysVisibleOptions {
    if (_rightViewAlwaysVisibleOptions == rightViewAlwaysVisibleOptions) return;

    _rightViewAlwaysVisibleOptions = rightViewAlwaysVisibleOptions;

    [self setNeedsUpdateLayoutsAndStyles];
}

- (void)setLeftViewWidth:(CGFloat)leftViewWidth {
    if (_leftViewWidth == leftViewWidth) return;

    _leftViewWidth = leftViewWidth;

    [self setNeedsUpdateLayoutsAndStyles];
}

- (void)setRightViewWidth:(CGFloat)rightViewWidth {
    if (_rightViewWidth == rightViewWidth) return;

    _rightViewWidth = rightViewWidth;

    [self setNeedsUpdateLayoutsAndStyles];
}

#pragma mark -

- (void)setRootViewContainer:(LGSideMenuView *)rootViewContainer {
    _rootViewContainer = rootViewContainer;
    self.gesturesHandler.rootViewContainer = rootViewContainer;
}

- (void)setLeftViewContainer:(LGSideMenuView *)leftViewContainer {
    _leftViewContainer = leftViewContainer;
    self.gesturesHandler.leftViewContainer = leftViewContainer;
}

- (void)setRightViewContainer:(LGSideMenuView *)rightViewContainer {
    _rightViewContainer = rightViewContainer;
    self.gesturesHandler.rightViewContainer = rightViewContainer;
}

- (void)setRootViewCoverView:(UIVisualEffectView *)rootViewCoverView {
    _rootViewCoverView = rootViewCoverView;
    self.gesturesHandler.rootViewCoverView = rootViewCoverView;
}

#pragma mark -

- (BOOL)isLeftViewVisible {
    return self.isLeftViewShowing || self.isLeftViewGoingToShow || self.isLeftViewGoingToHide;
}

- (BOOL)isRightViewVisible {
    return self.isRightViewShowing || self.isRightViewGoingToShow || self.isRightViewGoingToHide;
}

- (void)setLeftViewDisabled:(BOOL)leftViewDisabled {
    self.leftViewEnabled = !leftViewDisabled;
}

- (BOOL)isLeftViewDisabled {
    return !self.isLeftViewEnabled;
}

- (void)setRightViewDisabled:(BOOL)rightViewDisabled {
    self.rightViewEnabled = !rightViewDisabled;
}

- (BOOL)isRightViewDisabled {
    return !self.isRightViewEnabled;
}

- (void)setLeftViewHidden:(BOOL)leftViewHidden {
    self.leftViewShowing = !leftViewHidden;
}

- (BOOL)isLeftViewHidden {
    return !self.isLeftViewShowing;
}

- (void)setRightViewHidden:(BOOL)rightViewHidden {
    self.rightViewShowing = !rightViewHidden;
}

- (BOOL)isRightViewHidden {
    return !self.isRightViewShowing;
}

- (void)setLeftViewSwipeGestureDisabled:(BOOL)leftViewSwipeGestureDisabled {
    self.leftViewSwipeGestureEnabled = !leftViewSwipeGestureDisabled;
}

- (BOOL)isLeftViewSwipeGestureDisabled {
    return !self.isLeftViewSwipeGestureEnabled;
}

- (void)setRightViewSwipeGestureDisabled:(BOOL)rightViewSwipeGestureDisabled {
    self.rightViewSwipeGestureEnabled = !rightViewSwipeGestureDisabled;
}

- (BOOL)isRightViewSwipeGestureDisabled {
    return !self.isRightViewSwipeGestureEnabled;
}

- (BOOL)isLeftViewAlwaysVisibleForCurrentOrientation {
    return [self isLeftViewAlwaysVisibleForOrientation:UIApplication.sharedApplication.statusBarOrientation];
}

- (BOOL)isRightViewAlwaysVisibleForCurrentOrientation {
    return [self isRightViewAlwaysVisibleForOrientation:UIApplication.sharedApplication.statusBarOrientation];
}

- (BOOL)isLeftViewAlwaysVisibleForOrientation:(UIInterfaceOrientation)orientation {
    return ((self.leftViewAlwaysVisibleOptions & LGSideMenuAlwaysVisibleOnAll) ||
            (UIInterfaceOrientationIsPortrait(orientation) && self.leftViewAlwaysVisibleOptions & LGSideMenuAlwaysVisibleOnPortrait) ||
            (UIInterfaceOrientationIsLandscape(orientation) && self.leftViewAlwaysVisibleOptions & LGSideMenuAlwaysVisibleOnLandscape) ||
            (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone &&
             ((self.leftViewAlwaysVisibleOptions & LGSideMenuAlwaysVisibleOnPhone) ||
              (UIInterfaceOrientationIsPortrait(orientation) && self.leftViewAlwaysVisibleOptions & LGSideMenuAlwaysVisibleOnPhonePortrait) ||
              (UIInterfaceOrientationIsLandscape(orientation) && self.leftViewAlwaysVisibleOptions & LGSideMenuAlwaysVisibleOnPhoneLandscape))) ||
            (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad &&
             ((self.leftViewAlwaysVisibleOptions & LGSideMenuAlwaysVisibleOnPad) ||
              (UIInterfaceOrientationIsPortrait(orientation) && self.leftViewAlwaysVisibleOptions & LGSideMenuAlwaysVisibleOnPadPortrait) ||
              (UIInterfaceOrientationIsLandscape(orientation) && self.leftViewAlwaysVisibleOptions & LGSideMenuAlwaysVisibleOnPadLandscape))));
}

- (BOOL)isRightViewAlwaysVisibleForOrientation:(UIInterfaceOrientation)orientation {
    return ((self.rightViewAlwaysVisibleOptions & LGSideMenuAlwaysVisibleOnAll) ||
            (UIInterfaceOrientationIsPortrait(orientation) && self.rightViewAlwaysVisibleOptions & LGSideMenuAlwaysVisibleOnPortrait) ||
            (UIInterfaceOrientationIsLandscape(orientation) && self.rightViewAlwaysVisibleOptions & LGSideMenuAlwaysVisibleOnLandscape) ||
            (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone &&
             ((self.rightViewAlwaysVisibleOptions & LGSideMenuAlwaysVisibleOnPhone) ||
              (UIInterfaceOrientationIsPortrait(orientation) && self.rightViewAlwaysVisibleOptions & LGSideMenuAlwaysVisibleOnPhonePortrait) ||
              (UIInterfaceOrientationIsLandscape(orientation) && self.rightViewAlwaysVisibleOptions & LGSideMenuAlwaysVisibleOnPhoneLandscape))) ||
            (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad &&
             ((self.rightViewAlwaysVisibleOptions & LGSideMenuAlwaysVisibleOnPad) ||
              (UIInterfaceOrientationIsPortrait(orientation) && self.rightViewAlwaysVisibleOptions & LGSideMenuAlwaysVisibleOnPadPortrait) ||
              (UIInterfaceOrientationIsLandscape(orientation) && self.rightViewAlwaysVisibleOptions & LGSideMenuAlwaysVisibleOnPadLandscape))));
}

#pragma mark - ViewControllers

- (void)setRootViewController:(UIViewController *)rootViewController {
    [self removeRootViews];

    if (!rootViewController) return;

    _rootViewController = rootViewController;
    _rootView = rootViewController.view;

    // Needed because when any of side menus is showing, rootViewController is removed from it's parentViewController
    objc_setAssociatedObject(rootViewController, @"sideMenuController", self, OBJC_ASSOCIATION_ASSIGN);

    [self setNeedsUpdateLayoutsAndStyles];
}

- (void)setLeftViewController:(UIViewController *)leftViewController {
    [self removeLeftViews];

    if (!leftViewController) return;

    _leftViewController = leftViewController;
    _leftView = leftViewController.view;

    [self setNeedsUpdateLayoutsAndStyles];
}

- (void)setRightViewController:(UIViewController *)rightViewController {
    [self removeRightViews];

    if (!rightViewController) return;

    _rightViewController = rightViewController;
    _rightView = rightViewController.view;

    [self setNeedsUpdateLayoutsAndStyles];
}

#pragma mark - Views

- (void)setRootView:(UIView *)rootView {
    [self removeRootViews];

    if (!rootView) return;

    _rootView = rootView;

    [self setNeedsUpdateLayoutsAndStyles];
}

- (void)setLeftView:(LGSideMenuView *)leftView {
    [self removeLeftViews];

    if (!leftView) return;

    _leftView = leftView;

    [self setNeedsUpdateLayoutsAndStyles];
}

- (void)setRightView:(LGSideMenuView *)rightView {
    [self removeRightViews];

    if (!rightView) return;

    _rightView = rightView;

    [self setNeedsUpdateLayoutsAndStyles];
}

#pragma mark - Remove views

- (void)removeRootViews {
    if (self.rootViewController) {
        [self.rootViewController.view removeFromSuperview];
        [self.rootViewController removeFromParentViewController];
        _rootViewController = nil;

        objc_setAssociatedObject(_rootViewController, @"sideMenuController", nil, OBJC_ASSOCIATION_ASSIGN);
    }

    if (self.rootView) {
        [self.rootView removeFromSuperview];
        _rootView = nil;
    }

    if (self.rootViewContainer) {
        [self.rootViewContainer removeFromSuperview];
        _rootViewContainer = nil;
    }

    if (self.rootViewStyleView) {
        [self.rootViewStyleView removeFromSuperview];
        _rootViewStyleView = nil;
    }

    if (self.rootViewCoverView) {
        [self.rootViewCoverView removeFromSuperview];
        _rootViewCoverView = nil;
    }
}

- (void)removeLeftViews {
    if (self.leftViewController) {
        [self.leftViewController.view removeFromSuperview];
        [self.leftViewController removeFromParentViewController];
        _leftViewController = nil;
    }

    if (self.leftView) {
        [self.leftView removeFromSuperview];
        _leftView = nil;
    }

    if (self.leftViewContainer) {
        [self.leftViewContainer removeFromSuperview];
        _leftViewContainer = nil;
    }

    if (self.leftViewBorderAndShadowView) {
        [self.leftViewBorderAndShadowView removeFromSuperview];
        _leftViewBorderAndShadowView = nil;
    }

    if (self.leftViewStyleView) {
        [self.leftViewStyleView removeFromSuperview];
        _leftViewStyleView = nil;
    }

    if (self.sideViewsCoverView && !self.rightView) {
        [self.sideViewsCoverView removeFromSuperview];
        _sideViewsCoverView = nil;
    }

    if (self.leftViewBackgroundColorView) {
        [self.leftViewBackgroundColorView removeFromSuperview];
        _leftViewBackgroundColorView = nil;
    }

    if (self.leftViewBackgroundImageView) {
        [self.leftViewBackgroundImageView removeFromSuperview];
        _leftViewBackgroundImageView = nil;
    }
}

- (void)removeRightViews {
    if (self.rightViewController) {
        [self.rightViewController.view removeFromSuperview];
        [self.rightViewController removeFromParentViewController];
        _rightViewController = nil;
    }

    if (self.rightView) {
        [self.rightView removeFromSuperview];
        _rightView = nil;
    }

    if (self.rightViewContainer) {
        [self.rightViewContainer removeFromSuperview];
        _rightViewContainer = nil;
    }

    if (self.rightViewBorderAndShadowView) {
        [self.rightViewBorderAndShadowView removeFromSuperview];
        _rightViewBorderAndShadowView = nil;
    }

    if (self.rightViewStyleView) {
        [self.rightViewStyleView removeFromSuperview];
        _rightViewStyleView = nil;
    }

    if (self.sideViewsCoverView && !self.leftView) {
        [self.sideViewsCoverView removeFromSuperview];
        _sideViewsCoverView = nil;
    }

    if (self.rightViewBackgroundColorView) {
        [self.rightViewBackgroundColorView removeFromSuperview];
        _rightViewBackgroundColorView = nil;
    }

    if (self.rightViewBackgroundImageView) {
        [self.rightViewBackgroundImageView removeFromSuperview];
        _rightViewBackgroundImageView = nil;
    }
}

#pragma mark - Validators

- (void)rootViewsValidate {
    if (!self.rootView) return;

    // -----

    if (self.rootViewController && !self.isLeftViewGoingToShow && !self.isRightViewGoingToShow) {
        [self addChildViewController:self.rootViewController];
    }

    // -----

    if ((self.leftView && self.leftViewPresentationStyle != LGSideMenuPresentationStyleSlideAbove) ||
        (self.rightView && self.rightViewPresentationStyle != LGSideMenuPresentationStyleSlideAbove)) {
        if (!self.rootViewStyleView) {
            self.rootViewStyleView = [UIImageView new];
            self.rootViewStyleView.contentMode = UIViewContentModeScaleToFill;
            self.rootViewStyleView.clipsToBounds = YES;
            self.rootViewStyleView.userInteractionEnabled = NO;
        }
    }
    else {
        self.rootViewStyleView = nil;
    }

    // -----

    if (!self.rootViewContainer) {
        __weak typeof(self) wself = self;

        self.rootViewContainer = [[LGSideMenuView alloc] initWithLayoutSubviewsHandler:^(void) {
            if (!wself) return;

            __strong typeof(wself) sself = wself;

            [sself rootViewWillLayoutSubviewsWithSize:sself.rootViewContainer.bounds.size];
        }];
        self.rootViewContainer.clipsToBounds = YES;
        [self.rootViewContainer addSubview:self.rootView];
    }

    // -----

    if (!self.rootViewCoverView) {
        self.rootViewCoverView = [UIVisualEffectView new];
        self.rootViewCoverView.clipsToBounds = YES;
    }
}

- (void)leftViewsValidate {
    if (!self.leftView) return;

    // -----

    if (self.leftViewController) {
        [self addChildViewController:self.leftViewController];
    }

    // -----

    if (self.leftViewBackgroundColor && self.leftViewPresentationStyle != LGSideMenuPresentationStyleSlideAbove) {
        if (!self.leftViewBackgroundColorView) {
            self.leftViewBackgroundColorView = [UIView new];
            self.leftViewBackgroundColorView.userInteractionEnabled = NO;
        }
    }
    else {
        self.leftViewBackgroundColorView = nil;
    }

    // -----

    if (self.leftViewBackgroundImage && self.leftViewPresentationStyle != LGSideMenuPresentationStyleSlideAbove) {
        if (!self.leftViewBackgroundImageView) {
            self.leftViewBackgroundImageView = [[UIImageView alloc] initWithImage:self.leftViewBackgroundImage];
            self.leftViewBackgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
            self.leftViewBackgroundImageView.clipsToBounds = YES;
            self.leftViewBackgroundImageView.userInteractionEnabled = NO;
        }
    }
    else {
        self.leftViewBackgroundImageView = nil;
    }

    // -----

    if (!self.leftViewStyleView) {
        self.leftViewStyleView = [UIVisualEffectView new];
        self.leftViewStyleView.userInteractionEnabled = NO;
        self.leftViewStyleView.contentView.clipsToBounds = NO;
        self.leftViewStyleView.layer.anchorPoint = CGPointMake(0.0, 0.5);

        self.leftViewBorderAndShadowView = [UIImageView new];
        self.leftViewBorderAndShadowView.contentMode = UIViewContentModeScaleToFill;
        self.leftViewBorderAndShadowView.clipsToBounds = YES;
        self.leftViewBorderAndShadowView.userInteractionEnabled = NO;
        [self.leftViewStyleView.contentView addSubview:self.leftViewBorderAndShadowView];
    }

    // -----

    if (!self.leftViewContainer) {
        __weak typeof(self) wself = self;

        self.leftViewContainer = [[LGSideMenuView alloc] initWithLayoutSubviewsHandler:^(void) {
            if (!wself) return;

            __strong typeof(wself) sself = wself;

            [sself leftViewWillLayoutSubviewsWithSize:sself.leftViewContainer.bounds.size];
        }];
        self.leftViewContainer.layer.anchorPoint = CGPointMake(0.0, 0.5);

        [self.leftViewContainer addSubview:self.leftView];
    }

    // -----

    if (self.leftViewPresentationStyle != LGSideMenuPresentationStyleSlideAbove) {
        if (!self.sideViewsCoverView) {
            self.sideViewsCoverView = [UIVisualEffectView new];
            self.sideViewsCoverView.userInteractionEnabled = NO;
        }
    }
    else if (self.rightViewPresentationStyle == LGSideMenuPresentationStyleSlideAbove) {
        self.sideViewsCoverView = nil;
    }
}

- (void)rightViewsValidate {
    if (!self.rightView) return;

    // -----

    if (self.rightViewController) {
        [self addChildViewController:self.rightViewController];
    }

    // -----

    if (self.rightViewBackgroundColor && self.rightViewPresentationStyle != LGSideMenuPresentationStyleSlideAbove) {
        if (!self.rightViewBackgroundColorView) {
            self.rightViewBackgroundColorView = [UIView new];
            self.rightViewBackgroundColorView.userInteractionEnabled = NO;
        }
    }
    else {
        self.rightViewBackgroundColorView = nil;
    }

    // -----

    if (self.rightViewBackgroundImage && self.rightViewPresentationStyle != LGSideMenuPresentationStyleSlideAbove) {
        if (!self.rightViewBackgroundImageView) {
            self.rightViewBackgroundImageView = [[UIImageView alloc] initWithImage:self.rightViewBackgroundImage];
            self.rightViewBackgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
            self.rightViewBackgroundImageView.clipsToBounds = YES;
            self.rightViewBackgroundImageView.userInteractionEnabled = NO;
        }
    }
    else {
        self.rightViewBackgroundImageView = nil;
    }

    // -----

    if (!self.rightViewStyleView) {
        self.rightViewStyleView = [UIVisualEffectView new];
        self.rightViewStyleView.userInteractionEnabled = NO;
        self.rightViewStyleView.contentView.clipsToBounds = NO;
        self.rightViewStyleView.layer.anchorPoint = CGPointMake(1.0, 0.5);

        if (!self.rightViewBorderAndShadowView) {
            self.rightViewBorderAndShadowView = [UIImageView new];
            self.rightViewBorderAndShadowView.contentMode = UIViewContentModeScaleToFill;
            self.rightViewBorderAndShadowView.clipsToBounds = YES;
            self.rightViewBorderAndShadowView.userInteractionEnabled = NO;
            [self.rightViewStyleView.contentView addSubview:self.rightViewBorderAndShadowView];
        }
    }

    // -----

    if (!self.rightViewContainer) {
        __weak typeof(self) wself = self;

        self.rightViewContainer = [[LGSideMenuView alloc] initWithLayoutSubviewsHandler:^(void) {
            if (!wself) return;

            __strong typeof(wself) sself = wself;

            [sself rightViewWillLayoutSubviewsWithSize:sself.rightViewContainer.bounds.size];
        }];
        self.rightViewContainer.layer.anchorPoint = CGPointMake(1.0, 0.5);

        [self.rightViewContainer addSubview:self.rightView];
    }

    // -----

    if (self.rightViewPresentationStyle != LGSideMenuPresentationStyleSlideAbove) {
        if (!self.sideViewsCoverView) {
            self.sideViewsCoverView = [UIVisualEffectView new];
            self.sideViewsCoverView.userInteractionEnabled = NO;
        }
    }
    else if (self.leftViewPresentationStyle == LGSideMenuPresentationStyleSlideAbove) {
        self.sideViewsCoverView = nil;
    }
}

- (void)viewsHierarchyValidate {
    [self.rootViewStyleView removeFromSuperview];
    [self.rootViewContainer removeFromSuperview];
    [self.rootViewCoverView removeFromSuperview];

    [self.leftViewBackgroundColorView removeFromSuperview];
    [self.leftViewBackgroundImageView removeFromSuperview];
    [self.leftViewStyleView removeFromSuperview];
    [self.leftViewContainer removeFromSuperview];

    [self.rightViewBackgroundColorView removeFromSuperview];
    [self.rightViewBackgroundImageView removeFromSuperview];
    [self.rightViewStyleView removeFromSuperview];
    [self.rightViewContainer removeFromSuperview];

    [self.sideViewsCoverView removeFromSuperview];

    // -----

    BOOL isSideViewAdded = false;

    if (self.leftViewPresentationStyle != LGSideMenuPresentationStyleSlideAbove) {
        if (self.leftViewBackgroundColorView) {
            [self.view addSubview:self.leftViewBackgroundColorView];
        }

        if (self.leftViewBackgroundImageView) {
            [self.view addSubview:self.leftViewBackgroundImageView];
        }

        if (self.leftViewStyleView) {
            [self.view addSubview:self.leftViewStyleView];
        }

        if (self.leftViewContainer) {
            [self.view addSubview:self.leftViewContainer];
        }

        isSideViewAdded = YES;
    }

    if (self.rightViewPresentationStyle != LGSideMenuPresentationStyleSlideAbove) {
        if (self.rightViewBackgroundColorView) {
            [self.view addSubview:self.rightViewBackgroundColorView];
        }

        if (self.rightViewBackgroundImageView) {
            [self.view addSubview:self.rightViewBackgroundImageView];
        }

        if (self.rightViewStyleView) {
            [self.view addSubview:self.rightViewStyleView];
        }

        if (self.rightViewContainer) {
            [self.view addSubview:self.rightViewContainer];
        }

        isSideViewAdded = YES;
    }

    if (isSideViewAdded) {
        if (self.sideViewsCoverView) {
            [self.view addSubview:self.sideViewsCoverView];
        }
    }

    if (self.rootViewStyleView) {
        [self.view addSubview:self.rootViewStyleView];
    }

    if (self.rootViewContainer) {
        [self.view addSubview:self.rootViewContainer];
    }

    if (self.rootViewCoverView) {
        [self.view addSubview:self.rootViewCoverView];
    }

    if (self.leftViewPresentationStyle == LGSideMenuPresentationStyleSlideAbove) {
        if (self.leftViewStyleView) {
            [self.view addSubview:self.leftViewStyleView];
        }

        if (self.leftViewContainer) {
            [self.view addSubview:self.leftViewContainer];
        }
    }

    if (self.rightViewPresentationStyle == LGSideMenuPresentationStyleSlideAbove) {
        if (self.rightViewStyleView) {
            [self.view addSubview:self.rightViewStyleView];
        }

        if (self.rightViewContainer) {
            [self.view addSubview:self.rightViewContainer];
        }
    }
}

- (void)rootViewsFramesValidate {
    if (!self.rootView) return;

    // -----

    CGFloat frameWidth = CGRectGetWidth(self.view.bounds);
    CGFloat frameHeight = CGRectGetHeight(self.view.bounds);

    CGRect rootViewFrame = CGRectMake(0.0, 0.0, frameWidth, frameHeight);

    CGFloat offset = self.rootViewLayerBorderWidth + self.rootViewLayerShadowRadius;
    CGRect rootViewStyleViewFrame = CGRectMake(-offset, -offset, frameWidth + (offset * 2.0), frameHeight + (offset * 2.0));

    if (self.leftView && self.isLeftViewAlwaysVisibleForCurrentOrientation) {
        rootViewFrame.origin.x += self.leftViewWidth;
        rootViewFrame.size.width -= self.leftViewWidth;

        rootViewStyleViewFrame.origin.x += self.leftViewWidth;
        rootViewStyleViewFrame.size.width -= self.leftViewWidth;
    }

    if (self.rightView && self.isRightViewAlwaysVisibleForCurrentOrientation) {
        rootViewFrame.size.width -= self.rightViewWidth;

        rootViewStyleViewFrame.size.width -= self.rightViewWidth;
    }

    if (LGSideMenuHelper.isRetina) {
        rootViewFrame = CGRectIntegral(rootViewFrame);
        rootViewStyleViewFrame = CGRectIntegral(rootViewStyleViewFrame);
    }

    // -----

    self.rootViewStyleView.transform = CGAffineTransformIdentity;
    self.rootViewStyleView.frame = rootViewStyleViewFrame;

    self.rootViewContainer.transform = CGAffineTransformIdentity;
    self.rootViewContainer.frame = rootViewFrame;

    self.rootViewCoverView.transform = CGAffineTransformIdentity;
    self.rootViewCoverView.frame = rootViewFrame;
}

- (void)rootViewsTransformValidate {
    [self rootViewsTransformValidateWithPercentage:(self.isLeftViewShowing || self.isRightViewShowing ? 1.0 : 0.0)];
}

- (void)rootViewsTransformValidateWithPercentage:(CGFloat)percentage {
    if (!self.rootView) return;

    // -----

    if (self.leftView && self.isLeftViewVisible) {
        self.rootViewCoverView.alpha = self.rootViewCoverAlphaForLeftView * percentage;
    }
    else if (self.rightView && self.isRightViewVisible) {
        self.rootViewCoverView.alpha = self.rootViewCoverAlphaForRightView * percentage;
    }
    else {
        self.rootViewCoverView.alpha = percentage;
    }

    // -----

    if ((self.leftView && self.isLeftViewAlwaysVisibleForCurrentOrientation) ||
        (self.rightView && self.isRightViewAlwaysVisibleForCurrentOrientation)) {
        return;
    }

    // -----

    CGFloat frameX = 0.0;
    CGFloat frameWidth = CGRectGetWidth(self.view.bounds);
    CGFloat rootViewScale = 1.0;

    // -----

    if (self.leftView && self.isLeftViewVisible && self.leftViewPresentationStyle != LGSideMenuPresentationStyleSlideAbove) {
        rootViewScale = 1.0 + (self.rootViewScaleForLeftView - 1.0) * percentage;
        CGFloat shift = frameWidth * (1.0 - rootViewScale) / 2.0;
        frameX = (self.leftViewWidth - shift) * percentage;
    }
    else if (self.rightView && self.isRightViewVisible && self.rightViewPresentationStyle != LGSideMenuPresentationStyleSlideAbove) {
        rootViewScale = 1.0 + (self.rootViewScaleForRightView - 1.0) * percentage;
        CGFloat shift = frameWidth * (1.0 - rootViewScale) / 2.0;
        frameX = -(self.rightViewWidth - shift) * percentage;
    }

    CGAffineTransform transform = CGAffineTransformConcat(CGAffineTransformMakeScale(rootViewScale, rootViewScale),
                                                          CGAffineTransformMakeTranslation(frameX, 0.0));

    // -----

    self.rootViewContainer.transform = transform;
    self.rootViewStyleView.transform = transform;
    self.rootViewCoverView.transform = transform;
}

- (void)leftViewsFramesValidate {
    if (!self.leftView) return;

    CGFloat frameWidth = CGRectGetWidth(self.view.bounds);
    CGFloat frameHeight = CGRectGetHeight(self.view.bounds);

    // -----

    CGRect leftViewFrame = CGRectMake(0.0, 0.0, self.leftViewWidth, frameHeight);

    if (LGSideMenuHelper.isRetina) {
        leftViewFrame = CGRectIntegral(leftViewFrame);
    }

    self.leftViewContainer.transform = CGAffineTransformIdentity;
    self.leftViewContainer.frame = leftViewFrame;

    // -----

    if (self.sideViewsCoverView) {
        CGRect sideViewsCoverViewFrame = CGRectMake(0.0, 0.0, frameWidth, frameHeight);

        if (LGSideMenuHelper.isRetina) {
            sideViewsCoverViewFrame = CGRectIntegral(sideViewsCoverViewFrame);
        }

        self.sideViewsCoverView.transform = CGAffineTransformIdentity;
        self.sideViewsCoverView.frame = sideViewsCoverViewFrame;
    }

    // -----

    if (self.leftViewPresentationStyle != LGSideMenuPresentationStyleSlideAbove) {
        CGRect backgroundViewFrame = CGRectMake(0.0, 0.0, frameWidth, frameHeight);

        if (self.isLeftViewAlwaysVisibleForCurrentOrientation && self.isRightViewAlwaysVisibleForCurrentOrientation) {
            CGFloat multiplier = self.rightViewWidth / self.leftViewWidth;
            backgroundViewFrame.size.width = frameWidth / (multiplier + 1.0);
        }

        if (LGSideMenuHelper.isRetina) {
            backgroundViewFrame = CGRectIntegral(backgroundViewFrame);
        }

        self.leftViewBackgroundColorView.transform = CGAffineTransformIdentity;
        self.leftViewBackgroundColorView.frame = backgroundViewFrame;

        self.leftViewBackgroundImageView.transform = CGAffineTransformIdentity;
        self.leftViewBackgroundImageView.frame = backgroundViewFrame;
    }
    else {
        self.leftViewStyleView.transform = CGAffineTransformIdentity;
        self.leftViewStyleView.frame = leftViewFrame;

        CGFloat offset = self.leftViewLayerBorderWidth + self.leftViewLayerShadowRadius;
        CGRect leftViewBorderAndShadowViewFrame = CGRectMake(-offset,
                                                             -offset,
                                                             CGRectGetWidth(leftViewFrame) + (offset * 2.0),
                                                             CGRectGetHeight(leftViewFrame) + (offset * 2.0));

        if (LGSideMenuHelper.isRetina) {
            leftViewBorderAndShadowViewFrame = CGRectIntegral(leftViewBorderAndShadowViewFrame);
        }

        self.leftViewBorderAndShadowView.transform = CGAffineTransformIdentity;
        self.leftViewBorderAndShadowView.frame = leftViewBorderAndShadowViewFrame;
    }
}

- (void)leftViewsTransformValidate {
    [self leftViewsTransformValidateWithPercentage:(self.isLeftViewShowing ? 1.0 : 0.0)];
}

- (void)leftViewsTransformValidateWithPercentage:(CGFloat)percentage {
    if (!self.leftView) return;

    // -----

    if (self.sideViewsCoverView) {
        if (self.isLeftViewVisible && !self.isLeftViewAlwaysVisibleForCurrentOrientation && !self.isRightViewAlwaysVisibleForCurrentOrientation) {
            self.sideViewsCoverView.alpha = self.leftViewCoverAlpha - (self.leftViewCoverAlpha * percentage);
        }
    }

    // -----

    CGFloat frameX = 0.0;
    CGAffineTransform leftViewScaleTransform = CGAffineTransformIdentity;
    CGAffineTransform backgroundViewTransform = CGAffineTransformIdentity;

    // -----

    if (!self.isLeftViewAlwaysVisibleForCurrentOrientation) {
        if (self.leftViewPresentationStyle == LGSideMenuPresentationStyleSlideAbove) {
            frameX = -(self.leftViewWidth + self.leftViewLayerBorderWidth + self.leftViewLayerShadowRadius) * (1.0 - percentage);
        }
        else {
            CGFloat leftViewScale = 1.0 + (self.leftViewInititialScale - 1.0) * (1.0 - percentage);
            CGFloat backgroundViewScale = 1.0 + (self.leftViewBackgroundImageInitialScale - 1.0) * (1.0 - percentage);

            leftViewScaleTransform = CGAffineTransformMakeScale(leftViewScale, leftViewScale);
            backgroundViewTransform = CGAffineTransformMakeScale(backgroundViewScale, backgroundViewScale);

            frameX = self.leftViewInititialOffsetX * (1.0 - percentage);
        }
    }

    CGAffineTransform leftViewTransform = CGAffineTransformConcat(leftViewScaleTransform,
                                                                  CGAffineTransformMakeTranslation(frameX, 0.0));

    // -----

    self.leftViewContainer.transform = leftViewTransform;

    if (self.leftViewPresentationStyle != LGSideMenuPresentationStyleSlideAbove) {
        self.leftViewBackgroundImageView.transform = backgroundViewTransform;
    }
    else {
        self.leftViewStyleView.transform = leftViewTransform;
    }
}

- (void)rightViewsFramesValidate {
    if (!self.rightView) return;

    CGFloat frameWidth = CGRectGetWidth(self.view.bounds);
    CGFloat frameHeight = CGRectGetHeight(self.view.bounds);

    // -----

    CGRect rightViewFrame = CGRectMake(frameWidth - self.rightViewWidth, 0.0, self.rightViewWidth, frameHeight);

    if (LGSideMenuHelper.isRetina) {
        rightViewFrame = CGRectIntegral(rightViewFrame);
    }

    self.rightViewContainer.transform = CGAffineTransformIdentity;
    self.rightViewContainer.frame = rightViewFrame;

    // -----

    if (self.sideViewsCoverView) {
        CGRect sideViewsCoverViewFrame = CGRectMake(0.0, 0.0, frameWidth, frameHeight);

        if (LGSideMenuHelper.isRetina) {
            sideViewsCoverViewFrame = CGRectIntegral(sideViewsCoverViewFrame);
        }

        self.sideViewsCoverView.transform = CGAffineTransformIdentity;
        self.sideViewsCoverView.frame = sideViewsCoverViewFrame;
    }

    // -----

    if (self.rightViewPresentationStyle != LGSideMenuPresentationStyleSlideAbove) {
        CGRect backgroundViewFrame = CGRectMake(0.0, 0.0, frameWidth, frameHeight);

        if (self.isLeftViewAlwaysVisibleForCurrentOrientation && self.isRightViewAlwaysVisibleForCurrentOrientation) {
            CGFloat multiplier = self.leftViewWidth / self.rightViewWidth;
            backgroundViewFrame.size.width = frameWidth / (multiplier + 1.0);
            backgroundViewFrame.origin.x = frameWidth - CGRectGetWidth(backgroundViewFrame);
        }

        if (LGSideMenuHelper.isRetina) {
            backgroundViewFrame = CGRectIntegral(backgroundViewFrame);
        }

        self.rightViewBackgroundColorView.transform = CGAffineTransformIdentity;
        self.rightViewBackgroundColorView.frame = backgroundViewFrame;

        self.rightViewBackgroundImageView.transform = CGAffineTransformIdentity;
        self.rightViewBackgroundImageView.frame = backgroundViewFrame;
    }
    else {
        self.rightViewStyleView.transform = CGAffineTransformIdentity;
        self.rightViewStyleView.frame = rightViewFrame;

        CGFloat offset = self.rightViewLayerBorderWidth + self.rightViewLayerShadowRadius;
        CGRect rightViewBorderAndShadowViewFrame = CGRectMake(-offset,
                                                              -offset,
                                                              CGRectGetWidth(rightViewFrame) + (offset * 2.0),
                                                              CGRectGetHeight(rightViewFrame) + (offset * 2.0));

        if (LGSideMenuHelper.isRetina) {
            rightViewBorderAndShadowViewFrame = CGRectIntegral(rightViewBorderAndShadowViewFrame);
        }

        self.rightViewBorderAndShadowView.transform = CGAffineTransformIdentity;
        self.rightViewBorderAndShadowView.frame = rightViewBorderAndShadowViewFrame;
    }
}

- (void)rightViewsTransformValidate {
    [self rightViewsTransformValidateWithPercentage:(self.isRightViewShowing ? 1.0 : 0.0)];
}

- (void)rightViewsTransformValidateWithPercentage:(CGFloat)percentage {
    if (!self.rightView) return;

    // -----

    if (self.sideViewsCoverView) {
        if (self.isRightViewVisible && !self.isRightViewAlwaysVisibleForCurrentOrientation && !self.isLeftViewAlwaysVisibleForCurrentOrientation) {
            self.sideViewsCoverView.alpha = self.rightViewCoverAlpha - (self.rightViewCoverAlpha * percentage);
        }
    }

    // -----

    CGFloat frameX = 0.0;
    CGAffineTransform rightViewScaleTransform = CGAffineTransformIdentity;
    CGAffineTransform backgroundViewTransform = CGAffineTransformIdentity;

    // -----

    if (!self.isRightViewAlwaysVisibleForCurrentOrientation) {
        if (self.rightViewPresentationStyle == LGSideMenuPresentationStyleSlideAbove) {
            frameX = (self.rightViewWidth + self.rightViewLayerBorderWidth + self.rightViewLayerShadowRadius) * (1.0 - percentage);
        }
        else {
            CGFloat rightViewScale = 1.0 + (self.rightViewInititialScale - 1.0) * (1.0 - percentage);
            CGFloat backgroundViewScale = 1.0 + (self.rightViewBackgroundImageInitialScale - 1.0) * (1.0 - percentage);

            rightViewScaleTransform = CGAffineTransformMakeScale(rightViewScale, rightViewScale);
            backgroundViewTransform = CGAffineTransformMakeScale(backgroundViewScale, backgroundViewScale);

            frameX = self.rightViewInititialOffsetX * (1.0 - percentage);
        }
    }

    CGAffineTransform rightViewTransform = CGAffineTransformConcat(rightViewScaleTransform,
                                                                   CGAffineTransformMakeTranslation(frameX, 0.0));

    // -----

    self.rightViewContainer.transform = rightViewTransform;

    if (self.rightViewPresentationStyle != LGSideMenuPresentationStyleSlideAbove) {
        self.rightViewBackgroundImageView.transform = backgroundViewTransform;
    }
    else {
        self.rightViewStyleView.transform = rightViewTransform;
    }
}

- (void)stylesValidate {
    if (self.rootViewStyleView) {
        [LGSideMenuHelper imageView:self.rootViewStyleView
                       setImageSafe:[LGSideMenuDrawer drawRectangleWithViewSize:self.rootViewContainer.bounds.size
                                                                 roundedCorners:0.0
                                                                   cornerRadius:0.0
                                                                    strokeColor:self.rootViewLayerBorderColor
                                                                    strokeWidth:self.rootViewLayerBorderWidth
                                                                    shadowColor:self.rootViewLayerShadowColor
                                                                     shadowBlur:self.rootViewLayerShadowRadius]];
    }

    if (self.isLeftViewAlwaysVisibleForCurrentOrientation || self.isLeftViewVisible) {
        if (!self.isLeftViewAlwaysVisibleForCurrentOrientation) {
            self.rootViewCoverView.backgroundColor = self.rootViewCoverColorForLeftView;
            self.rootViewCoverView.effect = self.rootViewCoverBlurEffectForLeftView;

            if (self.sideViewsCoverView) {
                self.sideViewsCoverView.backgroundColor = self.leftViewCoverColor;
                self.sideViewsCoverView.effect = self.leftViewCoverBlurEffect;
            }
        }

        if (self.leftViewStyleView) {
            self.leftViewStyleView.backgroundColor = self.isLeftViewAlwaysVisibleForCurrentOrientation ? [self.leftViewBackgroundColor colorWithAlphaComponent:1.0] : self.leftViewBackgroundColor;
            self.leftViewStyleView.alpha = self.leftViewBackgroundAlpha;
            self.leftViewStyleView.effect = self.leftViewBackgroundBlurEffect;

            [LGSideMenuHelper imageView:self.leftViewBorderAndShadowView
                           setImageSafe:[LGSideMenuDrawer drawRectangleWithViewSize:self.leftViewContainer.bounds.size
                                                                     roundedCorners:0.0
                                                                       cornerRadius:0.0
                                                                        strokeColor:self.leftViewLayerBorderColor
                                                                        strokeWidth:self.leftViewLayerBorderWidth
                                                                        shadowColor:self.leftViewLayerShadowColor
                                                                         shadowBlur:self.leftViewLayerShadowRadius]];
        }

        if (self.leftViewBackgroundColorView) {
            self.leftViewBackgroundColorView.backgroundColor = self.leftViewBackgroundColor;
        }

        if (self.leftViewBackgroundImageView) {
            [LGSideMenuHelper imageView:self.leftViewBackgroundImageView setImageSafe:self.leftViewBackgroundImage];
        }
    }

    if (self.isRightViewAlwaysVisibleForCurrentOrientation || self.isRightViewVisible) {
        if (!self.isRightViewAlwaysVisibleForCurrentOrientation) {
            self.rootViewCoverView.backgroundColor = self.rootViewCoverColorForRightView;
            self.rootViewCoverView.effect = self.rootViewCoverBlurEffectForRightView;

            if (self.sideViewsCoverView) {
                self.sideViewsCoverView.backgroundColor = self.rightViewCoverColor;
                self.sideViewsCoverView.effect = self.rightViewCoverBlurEffect;
            }
        }

        if (self.rightViewStyleView) {
            self.rightViewStyleView.backgroundColor = self.isRightViewAlwaysVisibleForCurrentOrientation ? [self.rightViewBackgroundColor colorWithAlphaComponent:1.0] : self.rightViewBackgroundColor;
            self.rightViewStyleView.alpha = self.rightViewBackgroundAlpha;
            self.rightViewStyleView.effect = self.rightViewBackgroundBlurEffect;

            [LGSideMenuHelper imageView:self.rightViewBorderAndShadowView
                           setImageSafe:[LGSideMenuDrawer drawRectangleWithViewSize:self.rightViewContainer.bounds.size
                                                                     roundedCorners:0.0
                                                                       cornerRadius:0.0
                                                                        strokeColor:self.rightViewLayerBorderColor
                                                                        strokeWidth:self.rightViewLayerBorderWidth
                                                                        shadowColor:self.rightViewLayerShadowColor
                                                                         shadowBlur:self.rightViewLayerShadowRadius]];
        }

        if (self.rightViewBackgroundColorView) {
            self.rightViewBackgroundColorView.backgroundColor = self.rightViewBackgroundColor;
        }

        if (self.rightViewBackgroundImageView) {
            [LGSideMenuHelper imageView:self.rightViewBackgroundImageView setImageSafe:self.rightViewBackgroundImage];
        }
    }
}

- (void)visibilityValidate {
    [self visibilityValidateWithDelay:0.0];
}

- (void)visibilityValidateWithDelay:(NSTimeInterval)delay {
    BOOL rootViewStyleViewHiddenForLeftView = YES;
    BOOL rootViewCoverViewHiddenForLeftView = YES;
    BOOL sideViewsCoverViewHiddenForLeftView = YES;

    if (self.leftView) {
        if (self.isLeftViewAlwaysVisibleForCurrentOrientation) {
            self.leftViewBackgroundColorView.hidden = NO;
            self.leftViewBackgroundImageView.hidden = NO;
            self.leftViewStyleView.hidden = NO;
            self.leftViewContainer.hidden = NO;

            sideViewsCoverViewHiddenForLeftView = YES;
            rootViewStyleViewHiddenForLeftView = NO;
            rootViewCoverViewHiddenForLeftView = YES;
        }
        else if (self.isLeftViewVisible) {
            self.leftViewBackgroundColorView.hidden = NO;
            self.leftViewBackgroundImageView.hidden = NO;
            self.leftViewStyleView.hidden = NO;
            self.leftViewContainer.hidden = NO;

            sideViewsCoverViewHiddenForLeftView = NO;
            rootViewStyleViewHiddenForLeftView = NO;
            rootViewCoverViewHiddenForLeftView = NO;
        }
        else if (self.isLeftViewHidden) {
            if (delay) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void) {
                    self.leftViewBackgroundColorView.hidden = YES;
                    self.leftViewBackgroundImageView.hidden = YES;
                    self.leftViewStyleView.hidden = YES;
                    self.leftViewContainer.hidden = YES;
                });
            }
            else {
                self.leftViewBackgroundColorView.hidden = YES;
                self.leftViewBackgroundImageView.hidden = YES;
                self.leftViewStyleView.hidden = YES;
                self.leftViewContainer.hidden = YES;
            }

            sideViewsCoverViewHiddenForLeftView = YES;
            rootViewStyleViewHiddenForLeftView = YES;
            rootViewCoverViewHiddenForLeftView = YES;
        }
    }

    // -----

    BOOL rootViewStyleViewHiddenForRightView = YES;
    BOOL rootViewCoverViewHiddenForRightView = YES;
    BOOL sideViewsCoverViewHiddenForRightView = YES;

    if (self.rightView) {
        if (self.isRightViewAlwaysVisibleForCurrentOrientation) {
            self.rightViewBackgroundColorView.hidden = NO;
            self.rightViewBackgroundImageView.hidden = NO;
            self.rightViewStyleView.hidden = NO;
            self.rightViewContainer.hidden = NO;

            sideViewsCoverViewHiddenForRightView = YES;
            rootViewStyleViewHiddenForRightView = NO;
            rootViewCoverViewHiddenForRightView = YES;
        }
        else if (self.isRightViewVisible) {
            self.rightViewBackgroundColorView.hidden = NO;
            self.rightViewBackgroundImageView.hidden = NO;
            self.rightViewStyleView.hidden = NO;
            self.rightViewContainer.hidden = NO;

            sideViewsCoverViewHiddenForRightView = NO;
            rootViewStyleViewHiddenForRightView = NO;
            rootViewCoverViewHiddenForRightView = NO;
        }
        else if (self.isRightViewHidden) {
            if (delay) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void) {
                    self.rightViewBackgroundColorView.hidden = YES;
                    self.rightViewBackgroundImageView.hidden = YES;
                    self.rightViewStyleView.hidden = YES;
                    self.rightViewContainer.hidden = YES;
                });
            }
            else {
                self.rightViewBackgroundColorView.hidden = YES;
                self.rightViewBackgroundImageView.hidden = YES;
                self.rightViewStyleView.hidden = YES;
                self.rightViewContainer.hidden = YES;
            }

            sideViewsCoverViewHiddenForRightView = YES;
            rootViewStyleViewHiddenForRightView = YES;
            rootViewCoverViewHiddenForRightView = YES;
        }
    }

    // -----

    if (rootViewStyleViewHiddenForLeftView && rootViewStyleViewHiddenForRightView) {
        if (delay) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void) {
                self.rootViewStyleView.hidden = YES;
            });
        }
        else {
            self.rootViewStyleView.hidden = YES;
        }
    }
    else {
        self.rootViewStyleView.hidden = NO;
    }

    // -----

    if (rootViewCoverViewHiddenForLeftView && rootViewCoverViewHiddenForRightView) {
        if (delay) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void) {
                self.rootViewCoverView.hidden = YES;
            });
        }
        else {
            self.rootViewCoverView.hidden = YES;
        }
    }
    else {
        self.rootViewCoverView.hidden = NO;
    }

    // -----

    if ((sideViewsCoverViewHiddenForLeftView && sideViewsCoverViewHiddenForRightView) ||
        self.isLeftViewAlwaysVisibleForCurrentOrientation || self.isRightViewAlwaysVisibleForCurrentOrientation) {
        if (delay) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void) {
                self.sideViewsCoverView.hidden = YES;
            });
        }
        else {
            self.sideViewsCoverView.hidden = YES;
        }
    }
    else {
        self.sideViewsCoverView.hidden = NO;
    }
}

#pragma mark - Left view actions

- (IBAction)showLeftView:(nullable id)sender {
    [self showLeftViewAnimated:NO completionHandler:nil];
}

- (IBAction)hideLeftView:(nullable id)sender {
    [self hideLeftViewAnimated:NO completionHandler:nil];
}

- (IBAction)toggleLeftView:(nullable id)sender {
    [self toggleLeftViewAnimated:NO completionHandler:nil];
}

#pragma mark -

- (IBAction)showLeftViewAnimated:(nullable id)sender {
    [self showLeftViewAnimated:YES completionHandler:nil];
}

- (IBAction)hideLeftViewAnimated:(nullable id)sender {
    [self hideLeftViewAnimated:YES completionHandler:nil];
}

- (IBAction)toggleLeftViewAnimated:(nullable id)sender {
    [self toggleLeftViewAnimated:YES completionHandler:nil];
}

#pragma mark -

- (void)showLeftViewAnimated:(BOOL)animated completionHandler:(LGSideMenuControllerCompletionHandler)completionHandler {
    if (!self.leftView ||
        self.isLeftViewDisabled ||
        self.isLeftViewShowing ||
        self.isLeftViewAlwaysVisibleForCurrentOrientation ||
        (self.isRightViewAlwaysVisibleForCurrentOrientation && self.leftViewPresentationStyle != LGSideMenuPresentationStyleSlideAbove)) {
        return;
    }

    [self showLeftViewPrepareWithGesture:NO];
    [self showLeftViewAnimatedActions:animated completionHandler:completionHandler];
}

- (void)hideLeftViewAnimated:(BOOL)animated completionHandler:(LGSideMenuControllerCompletionHandler)completionHandler {
    if (!self.leftView ||
        self.isLeftViewDisabled ||
        self.isLeftViewHidden ||
        self.isLeftViewAlwaysVisibleForCurrentOrientation ||
        (self.isRightViewAlwaysVisibleForCurrentOrientation && self.leftViewPresentationStyle != LGSideMenuPresentationStyleSlideAbove)) {
        return;
    }

    [self hideLeftViewPrepareWithGesture:NO];
    [self hideLeftViewAnimatedActions:animated completionHandler:completionHandler];
}

- (void)toggleLeftViewAnimated:(BOOL)animated completionHandler:(LGSideMenuControllerCompletionHandler)completionHandler {
    if (self.isLeftViewShowing) {
        [self hideLeftViewAnimated:animated completionHandler:completionHandler];
    }
    else {
        [self showLeftViewAnimated:animated completionHandler:completionHandler];
    }
}

#pragma mark -

- (void)showLeftViewAnimated:(BOOL)animated delay:(NSTimeInterval)delay completionHandler:(LGSideMenuControllerCompletionHandler)completionHandler {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self showLeftViewAnimated:animated completionHandler:completionHandler];
    });
}

- (void)hideLeftViewAnimated:(BOOL)animated delay:(NSTimeInterval)delay completionHandler:(LGSideMenuControllerCompletionHandler)completionHandler {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self hideLeftViewAnimated:animated completionHandler:completionHandler];
    });
}

- (void)toggleLeftViewAnimated:(BOOL)animated delay:(NSTimeInterval)delay completionHandler:(LGSideMenuControllerCompletionHandler)completionHandler {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self toggleLeftViewAnimated:animated completionHandler:completionHandler];
    });
}

#pragma mark - Show left view

- (void)showLeftViewPrepareWithGesture:(BOOL)withGesture {
    self.leftViewGoingToShow = YES;

    [self.view endEditing:YES];

    [self stylesValidate];
    [self visibilityValidate];

    [self.rootViewController removeFromParentViewController];

    if (withGesture) {
        [LGSideMenuHelper statusBarAppearanceUpdateAnimated:YES
                                             viewController:self
                                                   duration:self.leftViewAnimationSpeed
                                                     hidden:self.leftViewStatusBarHidden
                                                      style:self.leftViewStatusBarStyle
                                                  animation:self.leftViewStatusBarUpdateAnimation];
    }
    else {
        [self rootViewsTransformValidateWithPercentage:0.0];
        [self leftViewsTransformValidateWithPercentage:0.0];
    }
}

- (void)showLeftViewAnimatedActions:(BOOL)animated completionHandler:(LGSideMenuControllerCompletionHandler)completionHandler {
    if (self.leftViewGoingToShow) {
        [self willShowLeftViewCallbacks];
    }

    // -----

    [LGSideMenuHelper statusBarAppearanceUpdateAnimated:animated
                                         viewController:self
                                               duration:self.leftViewAnimationSpeed
                                                 hidden:self.leftViewStatusBarHidden
                                                  style:self.leftViewStatusBarStyle
                                              animation:self.leftViewStatusBarUpdateAnimation];

    // -----

    if (animated) {
        self.gesturesHandler.animating = YES;

        [LGSideMenuHelper
         animateStandardWithDuration:self.leftViewAnimationSpeed
         animations:^(void) {
             [self rootViewsTransformValidateWithPercentage:1.0];
             [self leftViewsTransformValidateWithPercentage:1.0];

             // -----

             if (self.showLeftViewAnimationsBlock) {
                 self.showLeftViewAnimationsBlock(self, self.leftView, self.leftViewAnimationSpeed);
             }

             if (self.delegate && [self.delegate respondsToSelector:@selector(showAnimationsBlockForLeftView:sideMenuController:duration:)]) {
                 [self.delegate showAnimationsBlockForLeftView:self.leftView sideMenuController:self duration:self.leftViewAnimationSpeed];
             }
         }
         completion:^(BOOL finished) {
             [self showLeftViewDoneWithGesture:NO];

             self.gesturesHandler.animating = NO;

             if (completionHandler) {
                 completionHandler();
             }
         }];
    }
    else {
        [self showLeftViewDoneWithGesture:NO];

        if (completionHandler) {
            completionHandler();
        }
    }
}

- (void)showLeftViewDoneWithGesture:(BOOL)withGesture {
    if (withGesture) {
        self.leftViewGestireStartX = nil;
    }
    else {
        [self rootViewsTransformValidateWithPercentage:1.0];
        [self leftViewsTransformValidateWithPercentage:1.0];
    }

    self.leftViewShowing = YES;

    if (self.isLeftViewGoingToShow) {
        self.leftViewGoingToShow = NO;

        if (self.rootViewController) {
            [self addChildViewController:self.rootViewController];
        }

        [self didShowLeftViewCallbacks];
    }
}

#pragma mark - Hide left view

- (void)hideLeftViewPrepareWithGesture:(BOOL)withGesture {
    self.leftViewGoingToHide = YES;

    [self.view endEditing:YES];

    if (self.rootViewController) {
        [self addChildViewController:self.rootViewController];
    }
}

- (void)hideLeftViewAnimatedActions:(BOOL)animated completionHandler:(LGSideMenuControllerCompletionHandler)completionHandler {
    if (self.isLeftViewGoingToHide) {
        [self willHideLeftViewCallbacks];
    }

    // -----

    [LGSideMenuHelper statusBarAppearanceUpdateAnimated:animated
                                         viewController:self
                                               duration:self.leftViewAnimationSpeed
                                                 hidden:self.leftViewStatusBarHidden
                                                  style:self.leftViewStatusBarStyle
                                              animation:self.leftViewStatusBarUpdateAnimation];

    // -----

    if (animated) {
        self.gesturesHandler.animating = YES;

        [LGSideMenuHelper
         animateStandardWithDuration:self.leftViewAnimationSpeed
         animations:^(void) {
             [self rootViewsTransformValidateWithPercentage:0.0];
             [self leftViewsTransformValidateWithPercentage:0.0];

             // -----

             if (self.hideLeftViewAnimationsBlock) {
                 self.hideLeftViewAnimationsBlock(self, self.leftView, self.leftViewAnimationSpeed);
             }

             if (self.delegate && [self.delegate respondsToSelector:@selector(hideAnimationsBlockForLeftView:sideMenuController:duration:)]) {
                 [self.delegate hideAnimationsBlockForLeftView:self.leftView sideMenuController:self duration:self.leftViewAnimationSpeed];
             }
         }
         completion:^(BOOL finished) {
             [self hideLeftViewDoneWithGesture:NO];

             self.gesturesHandler.animating = NO;

             if (completionHandler) {
                 completionHandler();
             }
         }];
    }
    else {
        [self hideLeftViewDoneWithGesture:NO];

        if (completionHandler) {
            completionHandler();
        }
    }
}

- (void)hideLeftViewDoneWithGesture:(BOOL)withGesture {
    if (withGesture) {
        [LGSideMenuHelper statusBarAppearanceUpdateAnimated:YES
                                             viewController:self
                                                   duration:self.leftViewAnimationSpeed
                                                     hidden:self.leftViewStatusBarHidden
                                                      style:self.leftViewStatusBarStyle
                                                  animation:self.leftViewStatusBarUpdateAnimation];

        self.leftViewGestireStartX = nil;
    }
    else {
        [self rootViewsTransformValidateWithPercentage:0.0];
        [self leftViewsTransformValidateWithPercentage:0.0];
    }

    self.leftViewShowing = NO;

    if (self.isLeftViewGoingToHide) {
        self.leftViewGoingToHide = NO;

        [self visibilityValidate];

        [self didHideLeftViewCallbacks];
    }
    else {
        [self visibilityValidate];
    }
}

#pragma mark - Right view actions

- (IBAction)showRightView:(nullable id)sender {
    [self showRightViewAnimated:NO completionHandler:nil];
}

- (IBAction)hideRightView:(nullable id)sender {
    [self hideRightViewAnimated:NO completionHandler:nil];
}

- (IBAction)toggleRightView:(nullable id)sender {
    [self toggleRightViewAnimated:NO completionHandler:nil];
}

#pragma mark -

- (IBAction)showRightViewAnimated:(nullable id)sender {
    [self showRightViewAnimated:YES completionHandler:nil];
}

- (IBAction)hideRightViewAnimated:(nullable id)sender {
    [self hideRightViewAnimated:YES completionHandler:nil];
}

- (IBAction)toggleRightViewAnimated:(nullable id)sender {
    [self toggleRightViewAnimated:YES completionHandler:nil];
}

#pragma mark -

- (void)showRightViewAnimated:(BOOL)animated completionHandler:(LGSideMenuControllerCompletionHandler)completionHandler {
    if (!self.rightView ||
        self.isRightViewDisabled ||
        self.isRightViewShowing ||
        self.isRightViewAlwaysVisibleForCurrentOrientation ||
        (self.isLeftViewAlwaysVisibleForCurrentOrientation && self.rightViewPresentationStyle != LGSideMenuPresentationStyleSlideAbove)) {
        return;
    }

    [self showRightViewPrepareWithGesture:NO];
    [self showRightViewAnimatedActions:animated completionHandler:completionHandler];
}

- (void)hideRightViewAnimated:(BOOL)animated completionHandler:(LGSideMenuControllerCompletionHandler)completionHandler {
    if (!self.rightView ||
        self.isRightViewDisabled ||
        self.isRightViewHidden ||
        self.isRightViewAlwaysVisibleForCurrentOrientation ||
        (self.isLeftViewAlwaysVisibleForCurrentOrientation && self.rightViewPresentationStyle != LGSideMenuPresentationStyleSlideAbove)) {
        return;
    }

    [self hideRightViewPrepareWithGesture:NO];
    [self hideRightViewAnimatedActions:animated completionHandler:completionHandler];
}

- (void)toggleRightViewAnimated:(BOOL)animated completionHandler:(LGSideMenuControllerCompletionHandler)completionHandler {
    if (self.isRightViewShowing) {
        [self hideRightViewAnimated:animated completionHandler:completionHandler];
    }
    else {
        [self showRightViewAnimated:animated completionHandler:completionHandler];
    }
}

#pragma mark -

- (void)showRightViewAnimated:(BOOL)animated delay:(NSTimeInterval)delay completionHandler:(LGSideMenuControllerCompletionHandler)completionHandler {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self showRightViewAnimated:animated completionHandler:completionHandler];
    });
}

- (void)hideRightViewAnimated:(BOOL)animated delay:(NSTimeInterval)delay completionHandler:(LGSideMenuControllerCompletionHandler)completionHandler {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self hideRightViewAnimated:animated completionHandler:completionHandler];
    });
}

- (void)toggleRightViewAnimated:(BOOL)animated delay:(NSTimeInterval)delay completionHandler:(LGSideMenuControllerCompletionHandler)completionHandler {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self toggleRightViewAnimated:animated completionHandler:completionHandler];
    });
}

#pragma mark - Show right view

- (void)showRightViewPrepareWithGesture:(BOOL)withGesture {
    self.rightViewGoingToShow = YES;

    [self.view endEditing:YES];

    [self stylesValidate];
    [self visibilityValidate];

    [self.rootViewController removeFromParentViewController];

    if (withGesture) {
        [LGSideMenuHelper statusBarAppearanceUpdateAnimated:YES
                                             viewController:self
                                                   duration:self.rightViewAnimationSpeed
                                                     hidden:self.rightViewStatusBarHidden
                                                      style:self.rightViewStatusBarStyle
                                                  animation:self.rightViewStatusBarUpdateAnimation];
    }
    else {
        [self rootViewsTransformValidateWithPercentage:0.0];
        [self rightViewsTransformValidateWithPercentage:0.0];
    }
}

- (void)showRightViewAnimatedActions:(BOOL)animated completionHandler:(LGSideMenuControllerCompletionHandler)completionHandler {
    if (self.rightViewGoingToShow) {
        [self willShowRightViewCallbacks];
    }

    // -----

    [LGSideMenuHelper statusBarAppearanceUpdateAnimated:animated
                                         viewController:self
                                               duration:self.rightViewAnimationSpeed
                                                 hidden:self.rightViewStatusBarHidden
                                                  style:self.rightViewStatusBarStyle
                                              animation:self.rightViewStatusBarUpdateAnimation];

    // -----

    if (animated) {
        self.gesturesHandler.animating = YES;

        [LGSideMenuHelper
         animateStandardWithDuration:self.rightViewAnimationSpeed
         animations:^(void) {
             [self rootViewsTransformValidateWithPercentage:1.0];
             [self rightViewsTransformValidateWithPercentage:1.0];

             // -----

             if (self.showRightViewAnimationsBlock) {
                 self.showRightViewAnimationsBlock(self, self.rightView, self.rightViewAnimationSpeed);
             }

             if (self.delegate && [self.delegate respondsToSelector:@selector(showAnimationsBlockForRightView:sideMenuController:duration:)]) {
                 [self.delegate showAnimationsBlockForRightView:self.rightView sideMenuController:self duration:self.rightViewAnimationSpeed];
             }
         }
         completion:^(BOOL finished) {
             [self showRightViewDoneWithGesture:NO];

             self.gesturesHandler.animating = NO;

             if (completionHandler) {
                 completionHandler();
             }
         }];
    }
    else {
        [self showRightViewDoneWithGesture:NO];

        if (completionHandler) {
            completionHandler();
        }
    }
}

- (void)showRightViewDoneWithGesture:(BOOL)withGesture {
    if (withGesture) {
        self.rightViewGestireStartX = nil;
    }
    else {
        [self rootViewsTransformValidateWithPercentage:1.0];
        [self rightViewsTransformValidateWithPercentage:1.0];
    }

    self.rightViewShowing = YES;

    if (self.isRightViewGoingToShow) {
        self.rightViewGoingToShow = NO;

        if (self.rootViewController) {
            [self addChildViewController:self.rootViewController];
        }

        [self didShowRightViewCallbacks];
    }
}

#pragma mark - Hide right view

- (void)hideRightViewPrepareWithGesture:(BOOL)withGesture {
    self.rightViewGoingToHide = YES;

    [self.view endEditing:YES];

    if (self.rootViewController) {
        [self addChildViewController:self.rootViewController];
    }
}

- (void)hideRightViewAnimatedActions:(BOOL)animated completionHandler:(LGSideMenuControllerCompletionHandler)completionHandler {
    if (self.isRightViewGoingToHide) {
        [self willHideRightViewCallbacks];
    }

    // -----

    [LGSideMenuHelper statusBarAppearanceUpdateAnimated:animated
                                         viewController:self
                                               duration:self.rightViewAnimationSpeed
                                                 hidden:self.rightViewStatusBarHidden
                                                  style:self.rightViewStatusBarStyle
                                              animation:self.rightViewStatusBarUpdateAnimation];

    // -----

    if (animated) {
        self.gesturesHandler.animating = YES;

        [LGSideMenuHelper
         animateStandardWithDuration:self.rightViewAnimationSpeed
         animations:^(void) {
             [self rootViewsTransformValidateWithPercentage:0.0];
             [self rightViewsTransformValidateWithPercentage:0.0];

             // -----

             if (self.hideRightViewAnimationsBlock) {
                 self.hideRightViewAnimationsBlock(self, self.rightView, self.rightViewAnimationSpeed);
             }

             if (self.delegate && [self.delegate respondsToSelector:@selector(hideAnimationsBlockForRightView:sideMenuController:duration:)]) {
                 [self.delegate hideAnimationsBlockForRightView:self.rightView sideMenuController:self duration:self.rightViewAnimationSpeed];
             }
         }
         completion:^(BOOL finished) {
             [self hideRightViewDoneWithGesture:NO];

             self.gesturesHandler.animating = NO;

             if (completionHandler) {
                 completionHandler();
             }
         }];
    }
    else {
        [self hideRightViewDoneWithGesture:NO];

        if (completionHandler) {
            completionHandler();
        }
    }
}

- (void)hideRightViewDoneWithGesture:(BOOL)withGesture {
    if (withGesture) {
        [LGSideMenuHelper statusBarAppearanceUpdateAnimated:YES
                                             viewController:self
                                                   duration:self.rightViewAnimationSpeed
                                                     hidden:self.rightViewStatusBarHidden
                                                      style:self.rightViewStatusBarStyle
                                                  animation:self.rightViewStatusBarUpdateAnimation];

        self.rightViewGestireStartX = nil;
    }
    else {
        [self rootViewsTransformValidateWithPercentage:0.0];
        [self rightViewsTransformValidateWithPercentage:0.0];
    }

    self.rightViewShowing = NO;

    if (self.isRightViewGoingToHide) {
        self.rightViewGoingToHide = NO;

        [self visibilityValidate];

        [self didHideRightViewCallbacks];
    }
    else {
        [self visibilityValidate];
    }
}

#pragma mark - Callbacks

- (void)willShowLeftViewCallbacks {
    [[NSNotificationCenter defaultCenter] postNotificationName:LGSideMenuControllerWillShowLeftViewNotification object:self userInfo:nil];

    if (self.willShowLeftView) {
        self.willShowLeftView(self, self.leftView);
    }

    if (self.delegate && [self.delegate respondsToSelector:@selector(willShowLeftView:sideMenuController:)]) {
        [self.delegate willShowLeftView:self.leftView sideMenuController:self];
    }
}

- (void)didShowLeftViewCallbacks {
    [[NSNotificationCenter defaultCenter] postNotificationName:LGSideMenuControllerDidShowLeftViewNotification object:self userInfo:nil];

    if (self.didShowLeftView) {
        self.didShowLeftView(self, self.leftView);
    }

    if (self.delegate && [self.delegate respondsToSelector:@selector(didShowLeftView:sideMenuController:)]) {
        [self.delegate didShowLeftView:self.leftView sideMenuController:self];
    }
}

- (void)willHideLeftViewCallbacks {
    [[NSNotificationCenter defaultCenter] postNotificationName:LGSideMenuControllerWillHideLeftViewNotification object:self userInfo:nil];

    if (self.willHideLeftView) {
        self.willHideLeftView(self, self.leftView);
    }

    if (self.delegate && [self.delegate respondsToSelector:@selector(willHideLeftView:sideMenuController:)]) {
        [self.delegate willHideLeftView:self.leftView sideMenuController:self];
    }
}

- (void)didHideLeftViewCallbacks {
    [[NSNotificationCenter defaultCenter] postNotificationName:LGSideMenuControllerDidHideLeftViewNotification object:self userInfo:nil];

    if (self.didHideLeftView) {
        self.didHideLeftView(self, self.leftView);
    }

    if (self.delegate && [self.delegate respondsToSelector:@selector(didHideLeftView:sideMenuController:)]) {
        [self.delegate didHideLeftView:self.leftView sideMenuController:self];
    }
}

- (void)willShowRightViewCallbacks {
    [[NSNotificationCenter defaultCenter] postNotificationName:LGSideMenuControllerWillShowRightViewNotification object:self userInfo:nil];

    if (self.willShowRightView) {
        self.willShowRightView(self, self.rightView);
    }

    if (self.delegate && [self.delegate respondsToSelector:@selector(willShowRightView:sideMenuController:)]) {
        [self.delegate willShowRightView:self.leftView sideMenuController:self];
    }
}

- (void)didShowRightViewCallbacks {
    [[NSNotificationCenter defaultCenter] postNotificationName:LGSideMenuControllerDidShowRightViewNotification object:self userInfo:nil];

    if (self.didShowRightView) {
        self.didShowRightView(self, self.rightView);
    }

    if (self.delegate && [self.delegate respondsToSelector:@selector(didShowRightView:sideMenuController:)]) {
        [self.delegate didShowRightView:self.leftView sideMenuController:self];
    }
}

- (void)willHideRightViewCallbacks {
    [[NSNotificationCenter defaultCenter] postNotificationName:LGSideMenuControllerWillHideRightViewNotification object:self userInfo:nil];

    if (self.willHideRightView) {
        self.willHideRightView(self, self.rightView);
    }

    if (self.delegate && [self.delegate respondsToSelector:@selector(willHideRightView:sideMenuController:)]) {
        [self.delegate willHideRightView:self.leftView sideMenuController:self];
    }
}

- (void)didHideRightViewCallbacks {
    [[NSNotificationCenter defaultCenter] postNotificationName:LGSideMenuControllerDidHideRightViewNotification object:self userInfo:nil];

    if (self.didHideRightView) {
        self.didHideRightView(self, self.rightView);
    }

    if (self.delegate && [self.delegate respondsToSelector:@selector(didHideRightView:sideMenuController:)]) {
        [self.delegate didHideRightView:self.leftView sideMenuController:self];
    }
}

#pragma mark - UIGestureRecognizers

- (void)tapGesture:(UITapGestureRecognizer *)gesture {
    [self hideLeftViewAnimated:self.shouldHideLeftViewAnimated completionHandler:nil];
    [self hideRightViewAnimated:self.shouldHideRightViewAnimated completionHandler:nil];
}

- (void)panGesture:(UIPanGestureRecognizer *)gestureRecognizer {
    CGPoint location = [gestureRecognizer locationInView:self.view];
    CGPoint velocity = [gestureRecognizer velocityInView:self.view];

    // -----

    CGFloat frameWidth = CGRectGetWidth(self.view.bounds);

    // -----

    if (self.leftView && self.isLeftViewSwipeGestureEnabled && !self.isLeftViewAlwaysVisibleForCurrentOrientation && !self.rightViewGestireStartX && self.isRightViewHidden && self.isLeftViewEnabled) {
        if (!self.leftViewGestireStartX && (gestureRecognizer.state == UIGestureRecognizerStateBegan || gestureRecognizer.state == UIGestureRecognizerStateChanged)) {
            BOOL velocityReady = self.isLeftViewShowing ? velocity.x < 0.0 : velocity.x > 0.0;

            if (velocityReady && (self.isLeftViewShowing || self.swipeGestureArea == LGSideMenuSwipeGestureAreaFull || location.x < frameWidth / 2.0)) {
                self.leftViewGestireStartX = [NSNumber numberWithFloat:location.x];
                self.leftViewShowingBeforeGesture = self.leftViewShowing;

                if (self.isLeftViewShowing) {
                    [self hideLeftViewPrepareWithGesture:YES];
                }
                else {
                    [self showLeftViewPrepareWithGesture:YES];
                }
            }
        }
        else if (self.leftViewGestireStartX) {
            CGFloat firstVar = 0.0;

            if (self.isLeftViewShowingBeforeGesture) {
                firstVar = location.x+(self.leftViewWidth-self.leftViewGestireStartX.floatValue);
            }
            else {
                firstVar = location.x-self.leftViewGestireStartX.floatValue;
            }

            CGFloat percentage = firstVar/self.leftViewWidth;

            if (percentage < 0.0) {
                percentage = 0.0;
            }
            else if (percentage > 1.0) {
                percentage = 1.0;
            }

            if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
                [self rootViewsTransformValidateWithPercentage:percentage];
                [self leftViewsTransformValidateWithPercentage:percentage];
            }
            else if (gestureRecognizer.state == UIGestureRecognizerStateEnded && self.leftViewGestireStartX) {
                if ((percentage < 1.0 && velocity.x > 0.0) || (velocity.x == 0.0 && percentage >= 0.5)) {
                    self.leftViewGoingToShow = YES;
                    self.leftViewGoingToHide = NO;
                    [self showLeftViewAnimatedActions:YES completionHandler:nil];
                }
                else if ((percentage > 0.0 && velocity.x < 0.0) || (velocity.x == 0.0 && percentage < 0.5)) {
                    self.leftViewGoingToHide = YES;
                    self.leftViewGoingToShow = NO;
                    [self hideLeftViewAnimatedActions:YES completionHandler:nil];
                }
                else if (percentage == 1.0) {
                    self.leftViewGoingToShow = YES;
                    self.leftViewGoingToHide = NO;
                    [self showLeftViewDoneWithGesture:YES];
                }
                else if (percentage == 0.0) {
                    self.leftViewGoingToHide = YES;
                    self.leftViewGoingToShow = NO;
                    [self hideLeftViewDoneWithGesture:YES];
                }

                self.leftViewGestireStartX = nil;
            }
        }
    }

    // -----

    if (self.rightView && self.isRightViewSwipeGestureEnabled && !self.isRightViewAlwaysVisibleForCurrentOrientation && !self.leftViewGestireStartX && self.isLeftViewHidden && self.isRightViewEnabled) {
        if (!self.rightViewGestireStartX && (gestureRecognizer.state == UIGestureRecognizerStateBegan || gestureRecognizer.state == UIGestureRecognizerStateChanged)) {
            BOOL velocityReady = self.isRightViewShowing ? velocity.x > 0.0 : velocity.x < 0.0;

            if (velocityReady && (self.isRightViewShowing || self.swipeGestureArea == LGSideMenuSwipeGestureAreaFull || location.x > frameWidth / 2.0)) {
                self.rightViewGestireStartX = [NSNumber numberWithFloat:location.x];
                self.rightViewShowingBeforeGesture = self.rightViewShowing;

                if (self.isRightViewShowing) {
                    [self hideRightViewPrepareWithGesture:YES];
                }
                else {
                    [self showRightViewPrepareWithGesture:YES];
                }
            }
        }
        else if (self.rightViewGestireStartX) {
            CGFloat firstVar = 0.0;

            if (self.isRightViewShowingBeforeGesture) {
                firstVar = (location.x-(frameWidth-self.rightViewWidth))-(self.rightViewWidth-(frameWidth-self.rightViewGestireStartX.floatValue));
            }
            else {
                firstVar = (location.x-(frameWidth-self.rightViewWidth))+(frameWidth-self.rightViewGestireStartX.floatValue);
            }

            CGFloat percentage = 1.0-firstVar/self.rightViewWidth;

            if (percentage < 0.0) {
                percentage = 0.0;
            }
            else if (percentage > 1.0) {
                percentage = 1.0;
            }

            if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
                [self rootViewsTransformValidateWithPercentage:percentage];
                [self rightViewsTransformValidateWithPercentage:percentage];
            }
            else if (gestureRecognizer.state == UIGestureRecognizerStateEnded && self.rightViewGestireStartX) {
                if ((percentage < 1.0 && velocity.x < 0.0) || (velocity.x == 0.0 && percentage >= 0.5)) {
                    self.rightViewGoingToShow = YES;
                    self.rightViewGoingToHide = NO;
                    [self showRightViewAnimatedActions:YES completionHandler:nil];
                }
                else if ((percentage > 0.0 && velocity.x > 0.0) || (velocity.x == 0.0 && percentage < 0.5)) {
                    self.rightViewGoingToHide = YES;
                    self.rightViewGoingToShow = NO;
                    [self hideRightViewAnimatedActions:YES completionHandler:nil];
                }
                else if (percentage == 1.0) {
                    self.rightViewGoingToShow = YES;
                    self.rightViewGoingToHide = NO;
                    [self showRightViewDoneWithGesture:YES];
                }
                else if (percentage == 0.0) {
                    self.rightViewGoingToHide = YES;
                    self.rightViewGoingToShow = NO;
                    [self hideRightViewDoneWithGesture:YES];
                }

                self.rightViewGestireStartX = nil;
            }
        }
    }
}

@end

#pragma mark - Deprecated

NSString * _Nonnull const LGSideMenuControllerWillDismissLeftViewNotification  = @"LGSideMenuControllerWillHideLeftViewNotification";
NSString * _Nonnull const LGSideMenuControllerDidDismissLeftViewNotification   = @"LGSideMenuControllerDidHideLeftViewNotification";
NSString * _Nonnull const LGSideMenuControllerWillDismissRightViewNotification = @"LGSideMenuControllerWillHideRightViewNotification";
NSString * _Nonnull const LGSideMenuControllerDidDismissRightViewNotification  = @"LGSideMenuControllerDidHideRightViewNotification";

NSString * _Nonnull const kLGSideMenuControllerWillShowLeftViewNotification = @"LGSideMenuControllerWillShowLeftViewNotification";
NSString * _Nonnull const kLGSideMenuControllerWillHideLeftViewNotification = @"LGSideMenuControllerWillHideLeftViewNotification";
NSString * _Nonnull const kLGSideMenuControllerDidShowLeftViewNotification  = @"LGSideMenuControllerDidShowLeftViewNotification";
NSString * _Nonnull const kLGSideMenuControllerDidHideLeftViewNotification  = @"LGSideMenuControllerDidHideLeftViewNotification";

NSString * _Nonnull const kLGSideMenuControllerWillShowRightViewNotification = @"LGSideMenuControllerWillShowRightViewNotification";
NSString * _Nonnull const kLGSideMenuControllerWillHideRightViewNotification = @"LGSideMenuControllerWillHideRightViewNotification";
NSString * _Nonnull const kLGSideMenuControllerDidShowRightViewNotification  = @"LGSideMenuControllerDidShowRightViewNotification";
NSString * _Nonnull const kLGSideMenuControllerDidHideRightViewNotification  = @"LGSideMenuControllerDidHideRightViewNotification";

@implementation LGSideMenuController (Deprecated)

- (void)setShouldShowLeftView:(BOOL)shouldShowLeftView {
    self.leftViewEnabled = shouldShowLeftView;
}

- (BOOL)isShouldShowLeftView {
    return self.isLeftViewEnabled;
}

- (void)setShouldShowRightView:(BOOL)shouldShowRightView {
    self.rightViewEnabled = shouldShowRightView;
}

- (BOOL)isShouldShowRightView {
    return self.isRightViewEnabled;
}

- (BOOL)isLeftViewAlwaysVisible {
    return self.isLeftViewAlwaysVisibleForCurrentOrientation;
}

- (BOOL)isRightViewAlwaysVisible {
    return self.isRightViewAlwaysVisibleForCurrentOrientation;
}

#pragma mark -

- (BOOL)isLeftViewAlwaysVisibleForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [self isLeftViewAlwaysVisibleForOrientation:interfaceOrientation];
}

- (BOOL)isRightViewAlwaysVisibleForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [self isRightViewAlwaysVisibleForInterfaceOrientation:interfaceOrientation];
}

- (void)showHideLeftViewAnimated:(BOOL)animated completionHandler:(LGSideMenuControllerCompletionHandler)completionHandler {
    [self toggleLeftViewAnimated:animated completionHandler:completionHandler];
}

- (void)showHideRightViewAnimated:(BOOL)animated completionHandler:(LGSideMenuControllerCompletionHandler)completionHandler {
    [self toggleRightViewAnimated:animated completionHandler:completionHandler];
}

- (void)setLeftViewEnabledWithWidth:(CGFloat)width
                  presentationStyle:(LGSideMenuPresentationStyle)presentationStyle
               alwaysVisibleOptions:(LGSideMenuAlwaysVisibleOptions)alwaysVisibleOptions {
    self.leftViewWidth = width;
    self.leftViewPresentationStyle = presentationStyle;
    self.leftViewAlwaysVisibleOptions = alwaysVisibleOptions;
}

- (void)setRightViewEnabledWithWidth:(CGFloat)width
                   presentationStyle:(LGSideMenuPresentationStyle)presentationStyle
                alwaysVisibleOptions:(LGSideMenuAlwaysVisibleOptions)alwaysVisibleOptions {
    self.rightViewWidth = width;
    self.rightViewPresentationStyle = presentationStyle;
    self.rightViewAlwaysVisibleOptions = alwaysVisibleOptions;
}

@end
