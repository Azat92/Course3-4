//
//  ClassResolver.m
//  Lesson4
//
//  Created by Azat Almeev on 11.10.15.
//  Copyright © 2015 Azat Almeev. All rights reserved.
//

#import "ClassResolver.h"
#import "StubClass.h"
#import <objc/runtime.h>

NSString * const InterfaceString = @"@interface";
NSString * const PropertyString = @"@property";

@implementation ClassResolver

+ (void)load {
    NSString *definition = [NSString stringWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"StubClass" ofType:@"h"] encoding:NSUTF8StringEncoding error:nil];
    NSLog(@"%@", definition);
    //...
    
    NSArray *allStrings = [definition componentsSeparatedByString:@"\n\n"];
    
    NSArray *classData = [allStrings[1] componentsSeparatedByString:@"\n"];
    
    Class superClass;
    Class myClass;
    
    for (NSString *string in classData) {
        if ([string containsString:@"//"]) {
            continue;
        }
        
        if ([string containsString:InterfaceString]) {
            NSString *substring = [string stringByReplacingOccurrencesOfString:InterfaceString withString:@""];
            NSString *stringWithoutSpaces = [substring stringByReplacingOccurrencesOfString:@" " withString:@""];
            NSArray *substrings = [stringWithoutSpaces componentsSeparatedByString:@":"];
            NSString *classString = substrings[0];
            NSString *superClassString = substrings[1];
            
            const char *className = [classString UTF8String];
            
            superClass = NSClassFromString(superClassString);
            myClass = objc_allocateClassPair(superClass, className, 0);

        } else if ([string containsString:PropertyString]) {
            NSString *substring = [string stringByReplacingOccurrencesOfString:PropertyString withString:@""];
            if ([substring containsString:@"("] && [substring containsString:@")"]) {
                NSArray *subArray = [substring componentsSeparatedByString:@")"];
                NSString *propertiesString = subArray[0];
                NSString *typeNamePropertyString = subArray[1];
                typeNamePropertyString = [typeNamePropertyString stringByReplacingOccurrencesOfString:@" " withString:@""];
                typeNamePropertyString = [typeNamePropertyString stringByReplacingOccurrencesOfString:@";" withString:@""];
                
                NSArray *propertyTypeNameArray = [typeNamePropertyString componentsSeparatedByString:@"*"];
                NSString *typePropertyString = propertyTypeNameArray[0];
                NSString *namePropertyString = propertyTypeNameArray[1];
                NSString *namePropertyStringSetter = [NSString stringWithFormat:@"set%@:", [namePropertyString capitalizedString]];
                
                
                int allAttrsCount = 7;
                objc_property_attribute_t attrs[allAttrsCount];
                
                const char *propName = [typePropertyString UTF8String];
                char *left = "@\"";
                char *right = "\"";
                
                char propertyTypeName[100];
                
                strcpy(propertyTypeName,left);
                strcat(propertyTypeName, propName);
                strcat(propertyTypeName,right);
                
                objc_property_attribute_t type = { "T", propertyTypeName };
                attrs[0] = type;
                
                const char *propertyName = [namePropertyString UTF8String];
                NSString *ivarPropertyName = [NSString stringWithFormat:@"_%@", namePropertyString];
                const char *ivarName = [ivarPropertyName UTF8String];
                
                objc_property_attribute_t ivar  = { "V", ivarName };
                attrs[1] = ivar;
                
                int size = 2;
                
                if ([propertiesString containsString:@"nonatomic"]) {
                    objc_property_attribute_t at = {"N", ""};
                    attrs[size] = at;
                    size++;
                    
                }
                if ([propertiesString containsString:@"strong"] || [propertiesString containsString:@"retain"]) {
                    objc_property_attribute_t at = {"&", ""};
                    attrs[size] = at;
                    size++;
                }
                if ([propertiesString containsString:@"weak"]) {
                    objc_property_attribute_t at = {"W", ""};
                    attrs[size] = at;
                    size++;
                }
                if ([propertiesString containsString:@"copy"]) {
                    objc_property_attribute_t at = {"C", ""};
                    attrs[size] = at;
                    size++;
                }
                if ([propertiesString containsString:@"readonly"]) {
                    objc_property_attribute_t at = {"R", ""};
                    attrs[size] = at;
                    size++;
                }
                
                objc_property_attribute_t attributes[size];
                for (int i = 0; i < size; i++) {
                    attributes[i] = attrs[i];
                }
                
                class_addIvar(myClass, ivarName, sizeof(NSObject*), log2(sizeof(NSObject*)), @encode(NSObject));
                class_addProperty(myClass, propertyName, attributes, size);
                class_addMethod(myClass, NSSelectorFromString(namePropertyString), (IMP)getter, "@@:");
                class_addMethod(myClass, NSSelectorFromString(namePropertyStringSetter), (IMP)setter, "v@:@");
            }
            
        } else if ([string containsString:@"-"] || [string containsString:@"+"]) {
            NSString *methodFullString = [string stringByReplacingOccurrencesOfString:@"-" withString:@""];
            methodFullString = [string stringByReplacingOccurrencesOfString:@"+" withString:@""];

            NSRange range = [methodFullString rangeOfString:@")"];
            if (range.location != NSNotFound) {
                methodFullString = [methodFullString substringFromIndex:range.location + 1];
                methodFullString = [methodFullString stringByReplacingOccurrencesOfString:@";" withString:@""];
                
                //if method with arguments
                NSMutableArray *result = [NSMutableArray new];
                NSString *methodString;
                if ([methodFullString containsString:@":"]) {
                    
                    NSArray *arguments = [[methodFullString componentsSeparatedByString:@":"] mutableCopy];
                    
                    [result addObject:arguments[0]];
                    for (int i = 1; i < arguments.count - 1; i++) {
                        NSString *str = arguments[i];
                        NSRange range = [str rangeOfString:@")"];
                        str = [str substringFromIndex:range.location + 1];
                        
                        range = [str rangeOfString:@" "];
                        str = [str substringFromIndex:range.location + 1];
                        [result addObject:str];
                    }
                    
                    methodString = [result componentsJoinedByString:@":"];
                    methodString = [NSString stringWithFormat:@"%@:", methodString];
                } else {
                    methodString = methodFullString;
                }
                if ([string containsString:@"-"]) {
                    class_addMethod(myClass, NSSelectorFromString(methodString), (IMP)simpleMethod, "@@:");
                } else if ([string containsString:@"+"]) {
                    class_addMethod(objc_getMetaClass([NSStringFromClass(superClass) UTF8String]), NSSelectorFromString(methodString), (IMP)simpleMethod, "@@:");
                }
                
//                NSLog(@"%@", methodString);
            }
        }
    }
    objc_registerClassPair(myClass);
}

NSObject *simpleMethod(id self, SEL _cmd) {
    return @"simple method";
}

NSObject *getter(id self, SEL _cmd) {
    NSString *name = NSStringFromSelector(_cmd);
    NSString *ivarName = [NSString stringWithFormat:@"_%@", name];
    
    Ivar ivar = class_getInstanceVariable([self class], [ivarName UTF8String]);
    return object_getIvar(self, ivar);
}

void setter(id self, SEL _cmd, NSObject *newObj) {
    NSString *name = NSStringFromSelector(_cmd);
    
    NSString *propertyName = [name stringByReplacingOccurrencesOfString:@"set" withString:@""]; //N
    propertyName = [propertyName stringByReplacingOccurrencesOfString:@":" withString:@""];
    NSString *first = [propertyName substringToIndex:1];
    NSString *second = [propertyName substringFromIndex:1];
    first = [first lowercaseString];
    propertyName = [NSString stringWithFormat:@"%@%@", first, second];
    NSString *ivarString = [NSString stringWithFormat:@"_%@", propertyName];
    
    Ivar ivar = class_getInstanceVariable([self class], [ivarString UTF8String]);
    id oldObj = object_getIvar(self, ivar);
    if (![oldObj isEqual: newObj]) {
        object_setIvar(self, ivar, newObj);
    }
}

@end
