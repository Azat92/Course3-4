//
//  ClassResolver.m
//  Lesson4
//
//  Created by Azat Almeev on 11.10.15.
//  Copyright © 2015 Azat Almeev. All rights reserved.
//
typedef id (*IMP)(id, SEL, ...);

#import "ClassResolver.h"
#import "StubClass.h"
#import "NSString+SubstringFromRight.h"
#import <RegExCategories/RegExCategories.h>
#import <objc/runtime.h>


@interface ClassResolver()

@end

@implementation ClassResolver

+ (void)load {
    
    NSString *definition = [NSString stringWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"StubClass" ofType:@"h"] encoding:NSUTF8StringEncoding error:nil];
    NSLog(@"%@", definition);
    [self parseString:definition];
}

+(NSRange)searchedRangeFromString:(NSString*)str{
    return NSMakeRange(0, [str length]);
}

+(void)parseString:(NSString*)str{
    
    NSString *inheritancePatter = @": \w+";
    
    NSError  *error = nil;
    NSString *commentLess = str;
    NSArray *comments = [self parseCommentsFromString:str];
    for (int i=0; i<[comments count]; i++) {
        commentLess = [commentLess stringByReplacingOccurrencesOfString:comments[i] withString:@""];
    }
    NSLog(@"NO COMMNET:%@",commentLess);
    NSDictionary *classAndSuperClassName=[self parseClassAndSuperclassNameFromString:str];
    NSString *className = [classAndSuperClassName objectForKey:@"className"];
    NSString *superClassName = [classAndSuperClassName objectForKey:@"superClassName"];
    NSLog(@"CLASS NAME: %@",className);
    
    Class theStubClass = NSClassFromString(className);
    Class superClass = NSClassFromString(superClassName);
    Class stubClass = objc_allocateClassPair(superClass, [className cStringUsingEncoding:NSUTF8StringEncoding], 0);


    unsigned int propertyCount;
    for (NSDictionary* prop in [self parsePropertiesFromString:str]) {
        NSLog(@"PROP: %@",prop);
        NSString *type = [prop objectForKey:@"type"];
//        char tEncoder;
//        CFStringRef ts = CFStringCreateWithCString(kCFAllocatorDefault, [type cStringUsingEncoding:NSUTF8StringEncoding], kCFStringEncodingUTF8);
//        Class myClass = NSClassFromString(typeName);
//        const char myObject = *[[[theStubClass alloc] init] objCType];
//        @encode(myObject);
//        if ([type isEqual:@"char"]) {
//            tEncoder = 'c';
//        } else if ([type isEqual:@"int"]){
//            NSLog(@"YEEES");
//            tEncoder = 'i';
//        } else if ([type isEqual:@"short"]){
//            tEncoder = 's';
//        } else if ([type isEqual:@"long"]){
//            tEncoder = 'l';
//        } else if ([type isEqual:@"float"]){
//            tEncoder = 'f';
//        } else if ([type isEqual:@"double"]){
//            tEncoder = 's';
//        } else if ([type isEqual:@"void"]){
//            tEncoder = 'v';
//        } else if (NSClassFromString(type)){
//            tEncoder = '@';
//        }
//        NSLog(@"ENCODER: %c",tEncoder);

        
//        objc_property_attribute_t type = { "T", "@\"NSString\"" };
//        objc_property_attribute_t ownership = { "C", "" }; // C = copy
//        objc_property_attribute_t backingivar  = { "V", "privateName" };
//        objc_property_attribute_t attrs[] = { type, ownership, backingivar };
//        class_addProperty(stubClass, <#const char *name#>, <#const objc_property_attribute_t *attributes#>, <#unsigned int attributeCount#>)
    }
    for (NSString* method in [self parseMethodsFromString:str]) {
//        SEL mySelector = sel_registerName("myMethod");
        SEL aSelector =(SEL) NSSelectorFromString(method);
//        class_addMethod(<#__unsafe_unretained Class cls#>, <#SEL name#>, <#IMP imp#>, <#const char *types#>)
        NSLog(@"METHOD :%@",method);
    }
    
    id myObject = [[theStubClass alloc] init];
    
    objc_registerClassPair(stubClass);
     id myInstance = [[stubClass alloc] init];
}



+(NSArray*)parseCommentsFromString:(NSString*)str{
    Rx* rx = [Rx rx:@"(\\/\\/.*\n)+" ignoreCase:YES];
    NSArray* comments = [str matches:rx];
    return comments;
}

+(NSDictionary*)parseClassAndSuperclassNameFromString:(NSString*)str{
    Rx* rx = RX(@"@interface (\\D+):\\s*(\\w+)");
    RxMatch* match = [str firstMatchWithDetails:rx];
    NSString *className = [[match.groups objectAtIndex:1] value];
    NSString *superClassName = [[match.groups objectAtIndex:2] value];
    
    NSDictionary *results = [NSDictionary dictionaryWithObjectsAndKeys:className,@"className",superClassName,@"superClassName", nil];

    return results;
}

+(NSArray*)parsePropertiesFromString:(NSString*)str{
    Rx* rx = RX(@"@property\\s*(\\([\\w, ]+\\))?\\s*(\\w*)\\s+\\*?(\\S*)\\s*;");
    NSLog(@"isMATCH?:%i",[str isMatch:rx]);
    NSArray *matches = [str matchesWithDetails:rx];
    NSMutableArray *results = [NSMutableArray new];
    for (RxMatch *match in matches) {
        NSLog(@"PROP:%@",match.value);
        NSString *modificators = [[match.groups[1] value]stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"()"]];
        NSDictionary *attributes = @{
                                     [match.groups[3] value] : @"name",
                                     [match.groups[2] value] : @"type",
                                     modificators?modificators:@"" : @"modificators"
                                     };
        [results addObject:attributes];
    }
    return [results copy];
}

+(NSArray*)parseMethodsFromString:(NSString*)str{
    Rx* rx = RX(@"(-|\\+)\\s\(([\\w|\\*|\\s]*)\)(?:(?:(?:(\\w*)(?:\\:\([\\w|\\s|\\*]*)\)(\\w*)\\s*){1,}))?(\\w*)");
    NSLog(@"METHODSisMATCH?:%i",[str isMatch:rx]);
    NSArray *matches = [str matchesWithDetails:rx];
    NSMutableArray *results = [NSMutableArray new];
    for (int i=0; i<[matches count]; i++) {
        RxMatch *thisMethod = [matches objectAtIndex:i];
        NSString *methodWithTrash = [str substringFromIndex:thisMethod.range.location];
//        NSLog(@"SUBstringed from left:%@",methodWithTrash);
        NSString *justMethod = [[methodWithTrash componentsSeparatedByCharactersInSet:
                               [NSCharacterSet newlineCharacterSet]] objectAtIndex:0];
        [results addObject:justMethod];
      
    }
    return results;
}

@end
