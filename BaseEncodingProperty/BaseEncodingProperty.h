//
//  BaseEncodingProperty.h
//  BaseHome
//
//  Created by guang on 14-9-19.
//  Copyright (c) 2014年 ___zhoujianguang___. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSDictionary+JSON.h"
#import "NSDictionary+MyCategory.h"

@protocol AutoParseProtocol <NSObject>
@optional
///使用initAndParseWithDict自动解析时，如果有属性为数组则需要实现此方法，返回该数组中的对象的类
- (Class)classInPropertyArray:(NSString *)propetyName;

@end

/**
 沙盒文件存储的数据类的基类，主要做序列化和数据解析操作
 */
@interface BaseEncodingProperty : NSObject <NSCoding, AutoParseProtocol>

///自动数据解析。属性名必须和服务端返回的参数名完全一致; dict若非NSDictionary则返回nil；
///此方法可能需要子类实现AutoParseProtocol
///此方法有问题（类型必须一致，而如果是数字，会产生精度误差）
- (id)initAndParseWithDict:(NSDictionary *)dict;

///数据解析方法，基类不做解析工作，仅仅判断dict是否是NSDictionary，若否则返回nil；
- (id)initWithDict:(NSDictionary *)dict;

///可以将base中属性名相同的值拷贝到此类的对象中
- (id)initWithObj:(id)base;


@end
