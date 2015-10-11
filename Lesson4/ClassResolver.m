//
//  ClassResolver.m
//  Lesson4
//
//  Created by Azat Almeev on 11.10.15.
//  Copyright © 2015 Azat Almeev. All rights reserved.
//

#import "ClassResolver.h"
#import <objc/runtime.h>

@implementation ClassResolver

+ (void)load {
    NSString *definition = [NSString stringWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"StubClass" ofType:@"h"] encoding:NSUTF8StringEncoding error:nil];
    NSLog(@"%@", definition);
    //...
}

@end
