//
//  LoggingArray.m
//  Lesson4
//
//  Created by Azat Almeev on 11.10.15.
//  Copyright © 2015 Azat Almeev. All rights reserved.
//

#import "LoggingArray.h"
#import <objc/runtime.h>

@implementation NSMutableArray (Logging)

+ (void)load {
    Class mClass = NSClassFromString(@"__NSArrayM");
    Method addObject = class_getInstanceMethod(mClass, @selector(addObject:));
    Method logAddObject = class_getInstanceMethod(mClass, @selector(logAddObject:));
    method_exchangeImplementations(addObject, logAddObject);
}

- (void)logAddObject:(id)obj {
    [self logAddObject:obj];
    NSLog(@"Add object: %@", obj);
}

@end
