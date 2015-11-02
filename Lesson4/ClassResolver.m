//
//  ClassResolver.m
//  Lesson4
//
//  Created by Azat Almeev on 11.10.15.
//  Copyright © 2015 Azat Almeev. All rights reserved.
//

#import "ClassResolver.h"
#import "NSString+SubstringFromRight.h"
#import <RegExCategories/RegExCategories.h>
#import <objc/runtime.h>

@interface ClassResolver()
@property (nonatomic,readonly, copy) NSNumber *nf;
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
    
    NSString *commentLess = str;
    NSArray *comments = [self parseCommentsFromString:str];
    for (int i=0; i<[comments count]; i++) {
        commentLess = [commentLess stringByReplacingOccurrencesOfString:comments[i] withString:@""];
    }
    NSLog(@"NO COMMNET:%@",commentLess);
    NSDictionary *classAndSuperClassName=[self parseClassAndSuperclassNameFromString:str];
    NSString *className = [classAndSuperClassName objectForKey:@"className"];
    NSString *superClassName = [classAndSuperClassName objectForKey:@"superClassName"];
    NSLog(@"CLASS NAME:%@END",className);
    
    Class superClass = NSClassFromString(superClassName);
    Class stubClass = objc_allocateClassPair(superClass, [className UTF8String], 0);
    

    [self addProperties:[self parsePropertyStringFromString:str] ToClass:stubClass];
    [self addMethods:[self parseMethodsFromString:str] ToClass:stubClass withSClass:superClassName];
    
    objc_registerClassPair(stubClass);
    id obj = [[stubClass alloc] init];
    
//    [obj sayHelloToCaller:@"" withParam:@(1)];
//    [[obj class] sayHello];
//    [obj setN:@(1)];
    [[obj class] performSelector:@selector(sayHello)];
    [obj performSelector:@selector(sayHelloToCaller:) withObject:@""];
    [obj performSelector:@selector(setN:) withObject:@(5)];
    NSLog(@"N:%@",[obj performSelector:@selector(n)]);
}

+(void)addMethods:(NSArray*)methods ToClass:(Class)class withSClass:(NSString*)superClassName{

    for (int i=0; i<methods.count; i++) {
        NSDictionary *currentMethod = [methods objectAtIndex:i];
        NSString *selectorStr = [currentMethod objectForKey:@"selector"];
        const char *methodName = [selectorStr UTF8String];
        SEL mySelector = sel_registerName(methodName);
//        char *typeEncodings;
//        asprintf(&typeEncodings, "%s%s%s%s",
//                 @encode(NSObject),     // return
//                 @encode(id),       // self
//                 @encode(SEL),      // _cmd
//                 @encode(NSObject));     // repetitions
        NSObject *(^block)(id) = ^(id self){
            NSLog(@"INVOKED!");
            return [NSObject new];
        };
        IMP blockIMP = imp_implementationWithBlock(block);
        NSString *mType = [[currentMethod objectForKey:@"type"] value];
        if (![mType isEqualToString:@"-"]) {
            Class meta_cls = objc_getMetaClass([superClassName UTF8String]);
            NSLog(@"METHOD ADDED?:%i",class_addMethod(meta_cls, mySelector, blockIMP, "@@:"));
        } else NSLog(@"METHOD ADDED?:%i",class_addMethod(class, mySelector, blockIMP, "@@:"));
        
    }
}

NSObject *getter(id self, SEL _cmd){
    NSString* name = NSStringFromSelector(_cmd);
    NSString* ivarName = ivarNameFor(name);
    Ivar ivar = class_getInstanceVariable([self class], [ivarName UTF8String]);
    return object_getIvar(self, ivar);
}

void setter(id self, SEL _cmd, NSObject *newObj){
    NSString* name = propNameFromSetterName(NSStringFromSelector(_cmd));
    NSString* ivarName = ivarNameFor(name);
    Ivar ivar = class_getInstanceVariable([self class], [ivarName UTF8String]);
    id oldObj = object_getIvar(self, ivar);
    if (![oldObj isEqual: newObj]) {
        if(oldObj != nil) oldObj = nil;
        object_setIvar(self, ivar, newObj);
    }
}

+(void)addProperties:(NSArray*)props ToClass:(Class)class{
    unsigned int propertyCount=0;
    for (NSDictionary* prop in props) {
        NSLog(@"PROP: %@",prop);
        propertyCount++;
        
        NSString *propName = [prop objectForKey:@"name"];
        NSString *ivarName = [NSString stringWithFormat:@"_%@",propName];
        NSString *type = [prop objectForKey:@"type"];
        NSString *typeString = [NSString stringWithFormat:@"@\"%@\"",type];
        
        const char *cPropName =  [propName UTF8String];
        const char *cIvarName = [ivarName UTF8String];
        const char *typeCString = [typeString UTF8String];
        NSString *ownershipString = [prop objectForKey:@"modificators"];
        
        NSMutableArray *ownModificators = [NSMutableArray new];
        if ([ownershipString isMatch:RX(@"readonly")]) [ownModificators addObject:@"R"];
        if ([ownershipString isMatch:RX(@"copy")])  [ownModificators addObject:@"C"];
        else if ([ownershipString isMatch:RX(@"weak")]) [ownModificators addObject:@"W"];
        else if ([ownershipString isMatch:RX(@"retain")])
            [ownModificators addObject:@"&"];
        if ([ownershipString isMatch:RX(@"nonatomic")])  [ownModificators addObject:@"N"];
        objc_property_attribute_t ownAttributes[ownModificators.count];
        for (int i=0; i<ownModificators.count; i++) {
            const char *cMod = [[ownModificators objectAtIndex:i] UTF8String];
            *(ownAttributes + i) = (objc_property_attribute_t){ cMod, "" };
            objc_property_attribute_t temp;
            temp = *(ownAttributes + i);
            NSLog(@"");
        }
        
        
        objc_property_attribute_t typeAttr = { "T", typeCString };
        objc_property_attribute_t backingivar  = { "V", cIvarName };
        
        objc_property_attribute_t attrs[ownModificators.count + 2];
        
        attrs[0] = typeAttr;
        for (int i=0; i<ownModificators.count; i++) {
            objc_property_attribute_t ownership = ownAttributes[i];
            attrs[1 + i] = ownership;
        }
        attrs[1 + ownModificators.count] = backingivar;
        
        NSLog(@"IVAR ADDED?:%i",class_addIvar(class,cIvarName, sizeof(NSObject*), log2(sizeof(NSObject*)), @encode(NSObject*)));
        NSLog(@"PROPERTY ADDED?:%i",class_addProperty(class, cPropName, attrs, (unsigned int)ownModificators.count+2));
        NSLog(@"GETTER ADDED?:%i", class_addMethod(class,NSSelectorFromString(propName), (IMP)getter, "v@:@"));
        NSString *setterName = [self setterName:propName];
        NSLog(@"SETTER NAME:%@",setterName);
        NSLog(@"SETTER ADDED?:%i", class_addMethod(class, NSSelectorFromString(setterName), (IMP)setter, "v@:@"));
    }

}

+(void)showPropertiesOfClass:(Class)class{
    id obj = [[class alloc] init];
    unsigned int outCount, i, attrCount;
    objc_property_t *newProps = class_copyPropertyList([obj class], &outCount);
    for (i = 0; i < outCount; i++) {
        objc_property_t prop = newProps[i];
        objc_property_attribute_t *attrArr = property_copyAttributeList(prop, &attrCount);
        NSLog(@"NEW PROPERTY: %s Attr:%s",property_getName(prop), property_getAttributes(prop));
        
        for (int k=0; k<attrCount; k++) {
            objc_property_attribute_t tempA = attrArr[k];
            NSLog(@"tempA: %s",tempA);
        }
        
    }
}

+(void)showThisProperties{
    unsigned int outCount, i, attrCount;
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        
        NSLog(@"PROPERTY: %s Attr: %s",property_getName(property), property_getAttributes(property));
        objc_property_attribute_t *attrArr = property_copyAttributeList(property, &attrCount);
        for (int k=0; k<attrCount; k++) {
            objc_property_attribute_t tempA = attrArr[k];
            NSLog(@"tempA: %s",tempA);
        }
    }
}

NSString* propName(NSString* name) {
    name = [name stringByReplacingOccurrencesOfString:@":" withString:@""];
    
    NSRange r;
    r.length = name.length -1 ;
    r.location = 1;
    
    NSString* firstChar = [name stringByReplacingCharactersInRange:r withString:@""];
    
    if([firstChar isEqualToString:[firstChar lowercaseString]])
    {
        return name;
    }
    
    r.length = 1;
    r.location = 0;
    
    NSString* theRest = [name stringByReplacingCharactersInRange:r withString:@""];
    
    return [NSString stringWithFormat:@"%@%@", [firstChar lowercaseString] , theRest];
    
}

NSString* ivarNameFor(NSString* name){
    NSRange r;
    r.length = name.length -1 ;
    r.location = 1;
    
    NSString* firstChar = [name stringByReplacingCharactersInRange:r withString:@""].lowercaseString;
    
    if([firstChar isEqualToString:@"_"])
        return name;
    
    r.length = 1;
    r.location = 0;
    
    NSString* theRest = [name stringByReplacingCharactersInRange:r withString:@""];
    
    return [NSString stringWithFormat:@"_%@%@",firstChar, theRest];
}

+(NSString*)setterName:(NSString*)name
{
    name = propName(name);
    
    NSRange r;
    r.length = name.length -1 ;
    r.location = 1;
    
    NSString* firstChar = [name stringByReplacingCharactersInRange:r withString:@""];
    
    r.length = 1;
    r.location = 0;
    
    NSString* theRest = [name stringByReplacingCharactersInRange:r withString:@""];
    
    return [NSString stringWithFormat:@"set%@%@:", [firstChar uppercaseString] , theRest];
}

NSString* propNameFromSetterName(NSString* name) {
    NSRange r;
    r.length = 3 ;
    r.location = 0;
    
    NSString* tempPropName = [name stringByReplacingCharactersInRange:r withString:@""];
    NSString *result = propName(tempPropName);
    return result;
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
    className = [className stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *superClassName = [[match.groups objectAtIndex:2] value];
    
    NSDictionary *results = [NSDictionary dictionaryWithObjectsAndKeys:className,@"className",superClassName,@"superClassName", nil];

    return results;
}

+(NSArray*)parsePropertyStringFromString:(NSString*)str{
    Rx* rx = RX(@"@property\\s*(\\([\\w, ]+\\))?\\s*(\\w*)\\s+\\*?(\\S*)\\s*;");
    NSLog(@"isMATCH?:%i",[str isMatch:rx]);
    NSArray *matches = [str matchesWithDetails:rx];
    NSMutableArray *results = [NSMutableArray new];
    for (RxMatch *match in matches) {
        NSLog(@"PROP:%@",match.value);
        NSString *modificators = [[match.groups[1] value]stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"()"]];
        NSDictionary *attributes = @{
                                     @"name" : [match.groups[3] value]  ,
                                     @"type" : [match.groups[2] value]  ,
                                     @"modificators" : (modificators?modificators :@"")
                                     };
        [results addObject:attributes];
    }
    return [NSArray arrayWithArray:results];
}

+(NSArray*)parseMethodsFromString:(NSString*)str{
    Rx* rx = RX(@"(-|\\+)\\s\\(([\\w|\\*|\\s]*)\\)(\\s*(\\w+)(:\\(\\s*(\\w+)\\s*.?\\)\\s*(\\w+))?)*\\s*;");
    NSLog(@"METHODSisMATCH?:%i",[str isMatch:rx]);
    NSArray *matches = [str matchesWithDetails:rx];
    NSMutableArray *results = [NSMutableArray new];
    for (int i=0; i<[matches count]; i++) {
        RxMatch *thisMethod = [matches objectAtIndex:i];
        NSString *methodStr = thisMethod.value;
        Rx* returnTypeRX = RX(@"(-|\\+)\\s\\(([\\w|\\*|\\s]*)\\)\\s*");
        NSString *retType = [methodStr firstMatch:returnTypeRX];
        NSString *withoutRetType = [methodStr stringByReplacingOccurrencesOfString: retType
                                    withString:@""];
        Rx* argRX = RX(@"\\(\\s*(\\w+)\\s*.?\\)\\s*(\\w+)");
        NSString *methodName = [NSString stringWithString:withoutRetType];
        
        NSMutableArray *argTypes = [NSMutableArray new];
        NSMutableArray *argNames = [NSMutableArray new];
        if ([withoutRetType isMatch:argRX]) {
            NSArray *mArgs = [withoutRetType matchesWithDetails:argRX];
            for (int j=0;j< mArgs.count; j++) {
                RxMatch *thisArg = [mArgs objectAtIndex:j];
                NSString *argType = [thisArg.groups[1] value];
                [argTypes addObject:argType];
                NSLog(@"argType:%@",argType);
                NSString *argName = [thisArg.groups[2] value];
                [argNames addObject:argName];
                NSLog(@"argName:%@",argName);
                methodName = [methodName stringByReplacingOccurrencesOfString:thisArg.value withString:@""];
            }
            methodName = [methodName stringByReplacingOccurrencesOfString:@" "
                                                               withString:@""];
        } else {
            methodName = [withoutRetType firstMatch:RX(@"\\w+")];
        }
        methodName = [methodName stringByReplacingOccurrencesOfString:@";"
                                                           withString:@""];
        NSLog(@"!!! METHOD NAME:%@",methodName);
        NSDictionary *methodDict = [NSDictionary dictionaryWithObjectsAndKeys:methodName,@"selector",thisMethod.groups[1],@"type",thisMethod.groups[2],@"returnType",[NSArray arrayWithArray:argTypes] ,@"types",[NSArray arrayWithArray:argNames],@"names", nil];
        

        [results addObject:methodDict];
    }
    return results;
}

@end
