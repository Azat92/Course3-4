//
//  TestObject.h
//  Lesson4
//
//  Created by Azat Almeev on 11.10.15.
//  Copyright © 2015 Azat Almeev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TestObject : NSObject
- (void)simpleMethod;
- (void)simpleMethodWithParam:(NSNumber *)param;
- (NSNumber *)simpleMethodWithReturnalue:(NSNumber *)param;
@end
