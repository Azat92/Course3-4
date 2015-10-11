//
//  TestObject.m
//  Lesson4
//
//  Created by Azat Almeev on 11.10.15.
//  Copyright © 2015 Azat Almeev. All rights reserved.
//

#import "TestObject.h"

@interface TestObject ()
@property (nonatomic, strong) NSNumber *rnd;
@end

@implementation TestObject
- (instancetype)init {
    self = [super init];
    self.rnd = @(arc4random_uniform(100));
    return self;
}
- (void)simpleMethod {
    NSLog(@"Simple method: %@", self.rnd);
}
- (void)simpleMethodWithParam:(NSNumber *)param {
    NSLog(@"Simple method with param: %@", param);
}
- (NSNumber *)simpleMethodWithReturnalue:(NSNumber *)param {
    NSLog(@"Simple method with result: %@", param);
    return @([param integerValue] + 1);
}
- (void)dealloc {
    NSLog(@"Dealloc %@", NSStringFromClass(self.class));
}
@end
