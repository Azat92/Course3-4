//
//  StubClass.h
//  Lesson4
//
//  Created by Azat Almeev on 11.10.15.
//  Copyright © 2015 Azat Almeev. All rights reserved.
//

@interface StubClass : NSObject
@property (nonatomic, strong) NSNumber *n;
//@property (nonatomic) NSInteger c;
- (void)sayHello;
- (id)sayHelloToCaller:(NSString *)caller;
- (id)sayHelloToCaller:(NSString *)caller withParam:(NSNumber *)param;
+ (void)classMethod;
+ (id)classMethodReturn;
+ (NSString *)classMethodReturnWithParam:(NSNumber *)number;
@end