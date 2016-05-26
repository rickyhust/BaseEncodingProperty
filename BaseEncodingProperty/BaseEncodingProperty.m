//
//  BaseEncodingProperty.m
//  BaseHome
//
//  Created by guang on 14-9-19.
//  Copyright (c) 2014年 ___zhoujianguang___. All rights reserved.
//

#import "BaseEncodingProperty.h"

#import <objc/runtime.h>

@implementation BaseEncodingProperty

- (id)init
{
   if (self = [super init]) {
      
   }
   
   return self;
}

///接收服务器返回值时的解析方法，基类中会判断dict是否是NSDictionary，若否则返回nil
- (id)initWithDict:(NSDictionary *)dict
{
    if (! [dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
   return [self init];
}

///自动数据解析。属性名必须和服务端返回的参数名完全一致，dict若非NSDictionary则返回nil；
///此方法可能需要子类实现AutoParseProtocol
- (id)initAndParseWithDict:(NSDictionary *)dict
{
    if (! [dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    self = [self init];
    if (self) {
        [self parseDict:dict forClass:[self class]];
    }
    return self;
}

- (void)parseDict:(NSDictionary *)dict forClass:(Class)aClass
{
    const char* className = class_getName(aClass);
    if (strcasecmp(className, "BaseEncodingProperty") == 0) {
        return;
    }
    
    //先解析父类属性
    Class superClass = class_getSuperclass(aClass);
    if ([superClass isSubclassOfClass:[BaseEncodingProperty class]]) {
        [self parseDict:dict forClass:superClass];
    }
    
    //再解析此类属性
    unsigned int count = 0;
    objc_property_t* list = class_copyPropertyList(aClass, &count);
    for (unsigned int idx = 0; idx < count; idx++) {
        objc_property_t property = list[idx];
        
        const char* name = property_getName(property);
        NSString* propertyName = [NSString stringWithUTF8String:name];
        if ([propertyName length] == 0) {
            continue;
        }
        if ([self isInnerProperty:propertyName]) {
            continue;
        }
        id value = [dict objectForKey:propertyName];
        if ([value isKindOfClass:[NSDictionary class]]) {//数据是dictionary，则使用属性对应的类去解析
            Class classOfProperty = [self classOfProperty:property];
            if ([classOfProperty isSubclassOfClass:[BaseEncodingProperty class]]) {
                [self setValue:[[classOfProperty alloc] initAndParseWithDict:value] forKey:propertyName];
            }
        }
        else if ([value isKindOfClass:[NSArray class]] && [[self classOfProperty:property] isSubclassOfClass:[NSArray class]]) {
            //数据是数组，则遍历数据数组，并使用属性数组应该包含的对象的类去解析
            
            Class classInArray = [self classInPropertyArray:propertyName];
            if ([classInArray isSubclassOfClass:[BaseEncodingProperty class]] && strcasecmp(class_getName(classInArray), "BaseEncodingProperty") != 0) {
                
                NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:[value count]];
                for (NSDictionary *obj in value) {
                    if ([obj isKindOfClass:[NSDictionary class]]) {
                        [arr addObject:[[classInArray alloc] initAndParseWithDict:obj]];
                    }
                }
                if (arr.count > 0) {
                    [self setValue:arr forKey:propertyName];
                }
            }
        }
        else {
            [self setValue:value forKey:propertyName];
        }
    }
    
    if (list) {
        free(list);
    }
}

//默认实现，子类应该覆盖
- (Class)classInPropertyArray:(NSString *)propetyName
{
    return [BaseEncodingProperty class];
}

-(Class)classOfProperty:(objc_property_t) property
{
    NSString* propertyAttributes = [NSString stringWithUTF8String:property_getAttributes(property)];
    NSArray* splitPropertyAttributes = [propertyAttributes componentsSeparatedByString:@"\""];
    if ([splitPropertyAttributes count] >= 2)
    {
        return NSClassFromString([splitPropertyAttributes objectAtIndex:1]);
    }
    return [BaseEncodingProperty class];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
   if (self = [super init]) {
      
      Class currentClass = object_getClass(self);
      [self decode:aDecoder class:currentClass];
   }
   
   return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
   Class currentClass = object_getClass(self);
   [self encode:aCoder class:currentClass];
}

- (NSString*)getEncodeName:(NSString*)propetyName
{
   const char* name = object_getClassName(self);
   return [[NSString stringWithUTF8String:name] stringByAppendingFormat:@"_%@", propetyName];
}

- (void)decode:(NSCoder*)aDecoder class:(Class)curClass
{
   const char* className = class_getName(curClass);
   if (strcasecmp(className, "BaseEncodingProperty") == 0) {
      ////已经解析到基类里面，不再继续查询
      return ;
   }
   
   unsigned int count = 0;
   objc_property_t* list = class_copyPropertyList(curClass, &count);
   for (unsigned int idx = 0; idx < count; idx++) {
      objc_property_t property = list[idx];
      
      const char* name = property_getName(property);
      NSString* propertyName = [NSString stringWithUTF8String:name];
      if ([propertyName length] == 0) {
         continue;
      }
      if ([self isInnerProperty:propertyName]) {
         continue;
      }
      id value = [aDecoder decodeObjectForKey:[self getEncodeName:propertyName]];
      if (value) {
         [self setValue:value forKey:propertyName];
      }
   }

   if (list) {
      free(list);
   }
   
   Class superClass = class_getSuperclass(curClass);
   if (superClass) {
      [self decode:aDecoder class:superClass];
   }
}

- (void)encode:(NSCoder*)aDecoder class:(Class)curClass
{
   const char* className = class_getName(curClass);
   if (strcasecmp(className, "BaseEncodingProperty") == 0) {
      ////已经解析到基类里面，不再继续查询
      return ;
   }
   
   unsigned int count = 0;
   objc_property_t* list = class_copyPropertyList(curClass, &count);
   for (unsigned int idx = 0; idx < count; idx++) {
      objc_property_t property = list[idx];
      
      const char* name = property_getName(property);
      NSString* propertyName = [NSString stringWithUTF8String:name];
      if ([propertyName length] == 0) {
         continue;
      }
      if ([self isInnerProperty:propertyName]) {
         continue;
      }
      
      id value = [self valueForKey:propertyName];
      [aDecoder encodeObject:value forKey:[self getEncodeName:propertyName]];
   }

   if (list) {
      free(list);
   }
   
   Class superClass = class_getSuperclass(curClass);
   if (superClass) {
      [self encode:aDecoder class:superClass];
   }
}

// 兼容IOS8-XCODE6
- (BOOL)isInnerProperty:(NSString*)propertyName
{
   // primaryKey | rowid
   if ([propertyName isEqualToString:@"hash"]|| [propertyName isEqualToString:@"superclass"]|| [propertyName isEqualToString:@"description"] || [propertyName isEqualToString:@"debugDescription"]) {
      return YES;
   }
   
   return NO;
}

- (id)initWithObj:(id)base
{
   self = [super init];
   if (self) {
      Class aClass = [self class];
      const char* className = class_getName(aClass);
      while (strcasecmp(className, "BaseEncodingProperty") != 0) {
         unsigned int count = 0;
         objc_property_t* list = class_copyPropertyList(aClass, &count);
         for (unsigned int idx = 0; idx < count; idx++) {
            objc_property_t property = list[idx];
            
            const char* name = property_getName(property);
            NSString* propertyName = [NSString stringWithUTF8String:name];
            if ([propertyName length] == 0) {
               continue;
            }
            if ([self isInnerProperty:propertyName]) {
               continue;
            }
            if (class_getProperty([base class], name)) {
               id value = [base valueForKey:propertyName];
               [self setValue:value forKey:propertyName];
            }
         }
         
         if (list) {
            free(list);
         }
         aClass = class_getSuperclass(aClass);
         className = class_getName(aClass);
      }
   }
   return self;
}

@end
