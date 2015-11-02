//
//  StubClass.h
//  Lesson4
//
//  Created by Azat Almeev on 11.10.15.
//  Copyright © 2015 Azat Almeev. All rights reserved.
//

@interface StubClass  :  NSObject
@property (nonatomic, copy) NSNumber *n;
@property (readonly) NSInteger c;
+ (void)sayHello;
- (id)sayHelloToCaller:(NSString *)caller;
- (id)sayHelloToCaller:(NSString *)caller withParam:(NSNumber *)param;
@end