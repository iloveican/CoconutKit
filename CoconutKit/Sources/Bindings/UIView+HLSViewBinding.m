//
//  UIView+HLSViewBinding.m
//  CoconutKit
//
//  Created by Samuel Défago on 18.06.13.
//  Copyright (c) 2013 Hortis. All rights reserved.
//

#import "UIView+HLSViewBinding.h"

#import "HLSLogger.h"
#import "HLSRuntime.h"
#import "HLSViewBindingInformation.h"
#import "UIView+HLSExtensions.h"
#import "UIViewController+HLSViewBindingFriend.h"

// TODO:
//  - bound table view (use restricted interface proxy to restrict interface. Implement delegate
//    to which delegate forwards events; implement a runtime function to check whether a method
//    belongs to a protocol, and use it as a criterium to know whether the delegate must forward
//    unrecognized selectors to the bound table view delegate)
//  - demo with table view

// Keys for associated objects
static void *s_bindKeyPath = &s_bindKeyPath;
static void *s_bindFormatterKey = &s_bindFormatterKey;
static void *s_boundObjectKey = &s_boundObjectKey;
static void *s_bindingInformationKey = &s_bindingInformationKey;

// Original implementation of the methods we swizzle
static void (*s_UIView__didMoveToWindow_Imp)(id, SEL) = NULL;

// Swizzled method implementations
static void swizzled_UIView__didMoveToWindow_Imp(UIView *self, SEL _cmd);

@interface UIView (HLSViewBindingPrivate)

/**
 * Private properties which must be set via user-defined runtime attributes
 */
@property (nonatomic, strong) NSString *bindKeyPath;
@property (nonatomic, strong) NSString *bindFormatter;

@property (nonatomic, strong) id boundObject;
@property (nonatomic, strong) HLSViewBindingInformation *bindingInformation;

- (void)bindToObject:(id)object inViewController:(UIViewController *)viewController recursive:(BOOL)recursive;
- (void)refreshBindingsInViewController:(UIViewController *)viewController recursive:(BOOL)recursive forced:(BOOL)forced;
- (BOOL)bindsRecursively;

@end

@implementation UIView (HLSViewBinding)

#pragma mark Class methods

+ (void)load
{
    s_UIView__didMoveToWindow_Imp = (void (*)(id, SEL))HLSSwizzleSelector(self,
                                                                          @selector(didMoveToWindow),
                                                                          (IMP)swizzled_UIView__didMoveToWindow_Imp);
}

#pragma mark Bindings

- (void)bindToObject:(id)object
{
    [self bindToObject:object inViewController:[self nearestViewController] recursive:[self bindsRecursively]];
}

- (void)refreshBindingsForced:(BOOL)forced
{
    [self refreshBindingsInViewController:[self nearestViewController] recursive:[self bindsRecursively] forced:forced];
}

@end

@implementation UIView (HLSViewBindingPrivate)

#pragma mark Accessors and mutators

- (NSString *)bindKeyPath
{
    return objc_getAssociatedObject(self, s_bindKeyPath);
}

- (void)setBindKeyPath:(NSString *)bindKeyPath
{
    objc_setAssociatedObject(self, s_bindKeyPath, bindKeyPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)bindFormatter
{
    return objc_getAssociatedObject(self, s_bindFormatterKey);
}

- (void)setBindFormatter:(NSString *)bindFormatter
{
    objc_setAssociatedObject(self, s_bindFormatterKey, bindFormatter, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id)boundObject
{
    return objc_getAssociatedObject(self, s_boundObjectKey);
}

- (void)setBoundObject:(id)boundObject
{
    objc_setAssociatedObject(self, s_boundObjectKey, boundObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (HLSViewBindingInformation *)bindingInformation
{
    return objc_getAssociatedObject(self, s_bindingInformationKey);
}

- (void)setBindingInformation:(HLSViewBindingInformation *)bindingInformation
{
    objc_setAssociatedObject(self, s_bindingInformationKey, bindingInformation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark Bindings

// Bind to an object in the context of a view controller (might be nil). Stops at view controller boundaries. Correctly
// deals with viewController = nil as well
- (void)bindToObject:(id)object inViewController:(UIViewController *)viewController recursive:(BOOL)recursive
{   
    // Stop at view controller boundaries (correctly deals with viewController = nil)
    UIViewController *nearestViewController = self.nearestViewController;
    if (nearestViewController && nearestViewController != viewController) {
        return;
    }
    
    // Retains the object, so that view hierarchies can be bound to locally created objects assigned to them
    self.boundObject = object;
    
    if (self.bindKeyPath) {
        if ([self respondsToSelector:@selector(updateViewWithText:)]) {
            HLSLoggerDebug(@"Bind object %@ to view %@ with keyPath %@", object, self, self.bindKeyPath);
            
            self.bindingInformation = [[HLSViewBindingInformation alloc] initWithObject:object
                                                                                keyPath:self.bindKeyPath
                                                                          formatterName:self.bindFormatter
                                                                                   view:self];
            [self updateText];
        }
        else {
            HLSLoggerWarn(@"A binding path has been set for %@, but its class does not implement bindings", self);
        }
    }
    
    if (recursive) {
        for (UIView *subview in self.subviews) {
            [subview bindToObject:object inViewController:viewController recursive:recursive];
        }
    }
}

- (void)refreshBindingsInViewController:(UIViewController *)viewController recursive:(BOOL)recursive forced:(BOOL)forced
{
    // Stop at view controller boundaries. The following also correctly deals with viewController = nil
    UIViewController *nearestViewController = self.nearestViewController;
    if (nearestViewController && nearestViewController != viewController) {
        return;
    }
    
    if (forced) {
        // Not recursive here. Recursion is made below
        [self bindToObject:self.boundObject inViewController:viewController recursive:NO];
    }
    else {
        [self updateText];
    }
    
    if (recursive) {
        for (UIView *subview in self.subviews) {
            [subview refreshBindingsInViewController:viewController recursive:recursive forced:forced];
        }
    }
}

- (BOOL)bindsRecursively
{
    if ([self respondsToSelector:@selector(bindsSubviewsRecursively)]) {
        return [self performSelector:@selector(bindsSubviewsRecursively)];
    }
    else {
        return YES;
    }
}

- (void)updateText
{
    if (! self.bindingInformation) {
        return;
    }
    
    NSAssert([self respondsToSelector:@selector(updateViewWithText:)], @"Binding could only be made it -updateWithText: is implemented");
    
    NSString *text = [self.bindingInformation text];
    [self performSelector:@selector(updateViewWithText:) withObject:text];
}

@end

#pragma mark Swizzled method implementations

// By swizzling -didMoveToWindow, we know that the view has been added to its view hierarchy. The responder chain is therefore
// complete
static void swizzled_UIView__didMoveToWindow_Imp(UIView *self, SEL _cmd)
{
    (*s_UIView__didMoveToWindow_Imp)(self, _cmd);
    
    if (self.bindKeyPath && ! self.bindingInformation) {
        UIViewController *nearestViewController = self.nearestViewController;
        id boundObject = self.boundObject ?: nearestViewController.boundObject;
        [self bindToObject:boundObject inViewController:nearestViewController recursive:NO];
    }
}