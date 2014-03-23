//
//  EnvironmentHelper.h
//  MacTest
//
//  Created by Sam Dods on 19/03/2014.
//  Copyright (c) 2014 Sam Dods. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, PropertyType) {
  PropertyTypeObject,
  PropertyTypeString,
  PropertyTypeDouble,
  PropertyTypeBool,
  PropertyTypeDate,
  PropertyTypeArray,
};

#define Environment(keyPath) [[EnvironmentHelper defaultHelper] valueForKeyPath:keyPath]

@interface EnvironmentHelper : NSObject

+ (NSSet *)classDescriptionsForPlistFile:(NSString *)file withRootClassName:(NSString *)rootClassName otherClassesPrefix:(NSString *)otherClassesPrefix;

@end

@interface PropertyDescription : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) PropertyType type;
@property (nonatomic, copy) NSString *typeString;
- (NSString *)referenceTypeString;
@end

@interface ClassDescription : NSObject
@property (nonatomic, assign) BOOL isRootClass;
@property (nonatomic, assign) NSString *resourceFilename;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSMutableSet *properties;
@property (nonatomic, copy) NSMutableSet *headers;
- (NSString *)interfaceDescription;
- (NSString *)implementationDescription;
@end
