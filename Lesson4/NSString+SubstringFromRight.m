//
//  NSString+SubstringFromRight.m
//  Lesson4
//
//  Created by Артур Сагидулин on 19.10.15.
//  Copyright © 2015 Azat Almeev. All rights reserved.
//

#import "NSString+SubstringFromRight.h"

@implementation NSString (SubstringFromRight)
-(NSString *)substringFromRight:(NSUInteger)from{
    if (self.length<from) {
        return nil;
    }
    return [self substringFromIndex:self.length-from];
}

@end
