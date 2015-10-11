//
//  ViewController.m
//  Lesson4
//
//  Created by Azat Almeev on 11.10.15.
//  Copyright © 2015 Azat Almeev. All rights reserved.
//

#import "ViewController.h"
#import <objc/runtime.h>
#import "TestObject2.h"

@interface ViewController ()
@property (nonatomic, strong) NSNumber *rnd;
@property (nonatomic, strong) TestObject *to;
@end

@implementation ViewController
@dynamic rnd;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.to = [TestObject new];
    SEL simpleSelector = NSSelectorFromString(@"simpleMethod");
    Method oldM = class_getInstanceMethod(TestObject.class, simpleSelector);
    Method newM = class_getInstanceMethod(self.class, simpleSelector);
    method_exchangeImplementations(oldM, newM);
    NSMutableArray *a = [@[ @1 ] mutableCopy];
    [a addObject:@2];
}

static char *key;
- (void)extractData {
    key = "userInfo";
    id res = objc_getAssociatedObject(self.to, key);
    NSLog(@"%@", res);
}

- (void)simpleMethod {
    NSLog(@"Exchanged method");
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    if ([self.to respondsToSelector:anInvocation.selector])
        [anInvocation invokeWithTarget:self.to];
    else
        [super forwardInvocation:anInvocation];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature *signature = [super methodSignatureForSelector:aSelector];
    if (!signature && aSelector == @selector(rnd))
        signature = [TestObject.class instanceMethodSignatureForSelector:aSelector];
    return signature;
}

@end
