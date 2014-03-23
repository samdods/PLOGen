//
//  EnvironmentHelper.m
//  MacTest
//
//  Created by Sam Dods on 19/03/2014.
//  Copyright (c) 2014 Sam Dods. All rights reserved.
//

#import "EnvironmentHelper.h"
#import "NSString+Additions.h"


@implementation ClassDescription

- (NSString *)interfaceDescription
{
  NSMutableString *description = [NSMutableString stringWithFormat:@""];
  
  [description appendFormat:@"#import \"DZLPlistObject.h\"\n"];
  
  for (NSString *header in self.headers) {
    [description appendFormat:@"#import \"%@.h\"\n", header];
  }
  
  [description appendFormat:@"\n\n@interface %@ : DZLPlistObject\n\n", self.name];
  
  if (self.isRootClass) {
    [description appendFormat:@"+ (instancetype)%@;\n\n", self.name.lowerCamelCase];
  }
  
  for (PropertyDescription *propertyDescription in self.properties) {
    [description appendFormat:@"@property (nonatomic, %@, readonly) %@ %@;\n", propertyDescription.referenceTypeString, propertyDescription.typeString, propertyDescription.name];
  }
  
  [description appendFormat:@"\n@end\n\n"];
  return description;
}

- (NSString *)implementationDescription
{
  NSString *otherImports = @"";
  NSMutableString *description = [NSMutableString stringWithFormat:@"#import \"%@.h\"\n%@\n\n@implementation %@\n\n", self.name, otherImports, self.name];
  
  if (self.isRootClass) {
    
    [description appendFormat:@"+ (void)load\n"];
    [description appendFormat:@"{\n"];
    [description appendFormat:@"  if ([[self class] respondsToSelector:@selector(plistObjectClassWillLoad)]) {\n"];
    [description appendFormat:@"    [self plistObjectClassWillLoad];\n"];
    [description appendFormat:@"  }\n"];
    [description appendFormat:@"  [[self %@] populateFromResource:@\"%@\"];\n", self.name.lowerCamelCase, self.resourceFilename];
    [description appendFormat:@"}\n\n"];
    
    [description appendFormat:@"+ (instancetype)%@\n", self.name.lowerCamelCase];
    [description appendFormat:@"{\n"];
    [description appendFormat:@"  static %@ *singleton;\n", self.name];
    [description appendFormat:@"  static dispatch_once_t once;\n"];
    [description appendFormat:@"  dispatch_once(&once, ^{\n"];
    [description appendFormat:@"    singleton = [%@ new];\n", self.name];
    [description appendFormat:@"  });\n"];
    [description appendFormat:@"  return singleton;\n"];
    [description appendFormat:@"}\n"];
  }
  
  [description appendFormat:@"\n@end\n\n"];
  return description;
}

- (NSMutableSet *)properties
{
  return _properties ?: (_properties = [NSMutableSet new]);
}

- (NSMutableSet *)headers
{
  return _headers ?: (_headers = [NSMutableSet new]);
}

@end


@implementation PropertyDescription

- (BOOL)isEqual:(PropertyDescription *)object
{
  return [self.name isEqualToString:object.name];
}

- (NSUInteger)hash
{
  NSUInteger prime = 31;
  NSUInteger result = 1;
  result = prime * result + self.name.hash;
  return result;
}

- (void)setName:(NSString *)name
{
  _name = name.lowerCamelCase;
}

- (NSString *)typeString
{
  if (_typeString) {
    return _typeString;
  }
  switch (self.type) {
    case PropertyTypeDouble:
      return @"double";
    case PropertyTypeBool:
      return @"BOOL";
    case PropertyTypeArray:
      return @"NSArray *";
    case PropertyTypeString:
      return @"NSString *";
    case PropertyTypeDate:
      return @"NSDate *";
    default:
      break;
  }
  return @"id";
}

- (NSString *)referenceTypeString
{
  switch (self.type) {
    case PropertyTypeDouble:
    case PropertyTypeBool:
      return @"assign";
    case PropertyTypeObject:
    case PropertyTypeArray:
    case PropertyTypeString:
    case PropertyTypeDate:
    default:
      break;
  }
  return @"strong";
}

@end



@interface EnvironmentHelper ()
@property (nonatomic, strong) NSMutableSet *classDescriptions;
@property (nonatomic, strong) NSString *otherClassesPrefix;
@end

@implementation EnvironmentHelper

+ (NSSet *)classDescriptionsForPlistFile:(NSString *)file withRootClassName:(NSString *)rootClassName otherClassesPrefix:(NSString *)otherClassesPrefix
{
  EnvironmentHelper *helper = [EnvironmentHelper new];
  helper.otherClassesPrefix = otherClassesPrefix;
  
  [helper processDictionary:[NSDictionary dictionaryWithContentsOfFile:file] withClassName:rootClassName isRootClass:YES];
  
//  for (ClassDescription *classDescription in helper.classDescriptions.copy) {
//    if (classDescription.properties.count == 0) {
//      [helper.classDescriptions removeObject:classDescription];
//    }
//  }
//  
//  for (ClassDescription *classDescription in helper.classDescriptions) {
//    for (NSString *header in classDescription.headers.copy) {
//      if (![[helper.classDescriptions valueForKey:@"name"] containsObject:header]) {
//        [classDescription.headers removeObject:header];
//      }
//    }
//  }
  
  return helper.classDescriptions.copy;
}

- (void)processDictionary:(NSDictionary *)dictionary withClassName:(NSString *)className isRootClass:(BOOL)isRootClass
{
  ClassDescription *classDescription = [ClassDescription new];
  classDescription.name = className.upperCamelCase;
  classDescription.isRootClass = isRootClass;
  
  for (NSString *key in dictionary.allKeys) {
    id obj = dictionary[key];
    
    BOOL isDictionary = [obj isKindOfClass:NSDictionary.class];
    
    if (isDictionary) {
      char firstChar = key.UTF8String[0];
      if (firstChar == '#') {
        // list
        PropertyDescription *propertyDescription = [self propertyDescriptionTypeListForKey:[key substringFromIndex:1] fromDictionary:obj];
        [classDescription.properties addObject:propertyDescription];
        
        [classDescription.headers addObject:[propertyDescription.name.upperCamelCase stringByAppendingString:@"List"]];
        
      } else if ([key rangeOfString:@"("].location == NSNotFound) {
        // sub-root
        [self processDictionary:obj withClassName:key.upperCamelCase isRootClass:NO];
        PropertyDescription *propertyDescription = [PropertyDescription new];
        propertyDescription.name = key;
        propertyDescription.typeString = [key.upperCamelCase stringByAppendingString:@" *"];
        [classDescription.properties addObject:propertyDescription];
        
        [classDescription.headers addObject:propertyDescription.name.upperCamelCase];
        
      } else {
        // conversion from dictionary
        [self addToClass:classDescription propertyDescriptionForKey:key value:obj];
      }
      
    } else {
      // normal property
      [self addToClass:classDescription propertyDescriptionForKey:key value:obj];
    }
    
    
//    char firstChar = key.UTF8String[0];
//    BOOL isClassType = (firstChar >= 'A' && firstChar <= 'Z');
//    BOOL isPropertyType = (firstChar >= 'a' && firstChar <= 'z');
//    if (isClassType) {
//      if (![obj isKindOfClass:NSDictionary.class]) {
//        fprintf(stderr, "Invalid value for class [%s]. Value should be a dictionary for a class.\n", key.UTF8String);
//        exit(1);
//      }
//      [self addToClass:classDescription objectOfType:[self.otherClassesPrefix stringByAppendingString:key] fromDictionary:obj];
//      [self.classDescriptions addObject:classDescription];
//    } else if (isPropertyType) {
//      
//      if ([obj isKindOfClass:NSDictionary.class]) {
//        
//        [self addToClass:classDescription objectOfType:[self.otherClassesPrefix stringByAppendingString:key.upperCamelCase] fromDictionary:obj];
//        
//      } else {
//        
//        PropertyDescription *propertyDescription = [PropertyDescription new];
//        propertyDescription.name = key;
//        propertyDescription.type = [self propertyTypeFromObject:obj];
//        propertyDescription.typeString = [className stringByAppendingString:@" *"];
//        
//        [classDescription.properties addObject:propertyDescription];
//      }
//      
//    } else {
//      fprintf(stderr, "Invalid key [%s]. Key should begin with a letter (A-Z for class, or a-z for property).\n", key.UTF8String);
//      exit(1);
//    }
  }
  
  [self.classDescriptions addObject:classDescription];
}

- (PropertyDescription *)propertyDescriptionTypeListForKey:(NSString *)key fromDictionary:(NSDictionary *)dictionary
{
  PropertyDescription *propertyDescription = [PropertyDescription new];
  NSString *typeString;
  
  
  ClassDescription *customClass = nil;
  
  NSUInteger location = [key rangeOfString:@"("].location;
  if (location != NSNotFound) {
    propertyDescription.name = [key substringToIndex:location];
    
    NSString *type = [key substringFromIndex:location + 1];
    location = [type rangeOfString:@")"].location;
    typeString = [[type substringToIndex:location] stringByAppendingString:@" *"];
  } else {
    customClass = [ClassDescription new];
    customClass.name = key.upperCamelCase;
    
    propertyDescription.name = key;
    typeString = [customClass.name stringByAppendingString:@" *"];
    
    [self.classDescriptions addObject:customClass];
  }
  
  NSString *className = [propertyDescription.name.upperCamelCase stringByAppendingString:@"List"];
  ClassDescription *classDescription = [self existingClassWithName:className];
  if (!classDescription) {
    classDescription = [ClassDescription new];
    classDescription.name = [propertyDescription.name.upperCamelCase stringByAppendingString:@"List"];
  }
  
  propertyDescription.typeString = [classDescription.name stringByAppendingString:@" *"];
  
  if (customClass != nil) {
    for (NSString *key2 in dictionary.allKeys) {
      id obj = dictionary[key2];
      
      if (![obj isKindOfClass:NSDictionary.class]) {
        fprintf(stderr, "Invalid value for class [%s]. Value should be a dictionary for a class.\n", key2.UTF8String);
        exit(1);
      }
      
      [self updateClassDescription:customClass fromDictionary:obj];
      PropertyDescription *eachPropertyDescription = [PropertyDescription new];
      eachPropertyDescription.name = key2;
      eachPropertyDescription.typeString = typeString;
      [classDescription.properties addObject:eachPropertyDescription];
    }
    [classDescription.headers addObject:customClass.name];
  } else {
    for (NSString *key2 in dictionary.allKeys) {
      
      PropertyDescription *eachPropertyDescription = [PropertyDescription new];
      eachPropertyDescription.name = key2;
      eachPropertyDescription.typeString = typeString;
      [classDescription.properties addObject:eachPropertyDescription];
    }
  }
  
  [self.classDescriptions addObject:classDescription];
  
  return propertyDescription;
}

- (void)addToClass:(ClassDescription *)classToAddTo objectOfType:(NSString *)className fromDictionary:(NSDictionary *)dictionary
{
  ClassDescription *classDescription = [ClassDescription new];
  classDescription.name = className.upperCamelCase;
  
  for (NSString *key in dictionary.allKeys) {
    char firstChar = key.UTF8String[0];
    BOOL isClassType = (firstChar >= 'A' && firstChar <= 'Z');
    BOOL isPropertyType = (firstChar >= 'a' && firstChar <= 'z');
    id obj = dictionary[key];
    if (isPropertyType) {
      BOOL isDictionary = [obj isKindOfClass:NSDictionary.class];
      if (isDictionary) {
        [self updateClassDescription:classDescription fromDictionary:obj];
      }
      
      PropertyDescription *propertyDescription = [PropertyDescription new];
      propertyDescription.name = key;
      propertyDescription.type = [self propertyTypeFromObject:obj];
//      if (isDictionary) {
        propertyDescription.typeString = [className stringByAppendingString:@" *"];
//      }
      
      [classToAddTo.properties addObject:propertyDescription];
      
      [classToAddTo.headers addObject:className];
      
    } else if (isClassType) {
      
      if (![obj isKindOfClass:NSDictionary.class]) {
        fprintf(stderr, "Invalid value for class [%s]. Value should a dictionary for a class.\n", key.UTF8String);
        exit(1);
      }
      [self addToClass:classDescription objectOfType:[self.otherClassesPrefix stringByAppendingString:key] fromDictionary:obj];
      [self.classDescriptions addObject:classDescription];
      
    } else {
      fprintf(stderr, "Invalid key [%s.%s]. Class can only contain properties.\n", className.UTF8String, key.UTF8String);
      exit(1);
    }
  }
  
  [self.classDescriptions addObject:classDescription];
}

- (ClassDescription *)classDescriptionFromDictionary:(NSDictionary *)dictionary withName:(NSString *)className
{
  ClassDescription *classDescription = [ClassDescription new];
  classDescription.name = className.upperCamelCase;
  
  
  
  [self updateClassDescription:classDescription fromDictionary:dictionary];
  
  [self.classDescriptions addObject:classDescription];
  
  return classDescription;
}

- (void)updateClassDescription:(ClassDescription *)classDescription fromDictionary:(NSDictionary *)dictionary
{
  for (NSString *key in dictionary.allKeys) {
    id obj = dictionary[key];
    [self addToClass:classDescription propertyDescriptionForKey:key value:obj];
  }
}

- (void)addToClass:(ClassDescription *)classDescription propertyDescriptionForKey:(NSString *)key value:(id)obj
{
  PropertyDescription *propertyDescription = [PropertyDescription new];
  
  NSUInteger location = [key rangeOfString:@"("].location;
  if (location != NSNotFound) {
    propertyDescription.name = [key substringToIndex:location];
    NSString *type = [key substringFromIndex:location + 1];
    location = [type rangeOfString:@")"].location;
    propertyDescription.typeString = [[type substringToIndex:location] stringByAppendingString:@" *"];
    [classDescription.properties addObject:propertyDescription];
    return;
  }
  
  propertyDescription.name = key;
  
  if ([obj isKindOfClass:NSString.class]) {
    
    propertyDescription.type = PropertyTypeString;
    
  } else if ([obj isKindOfClass:NSArray.class]) {
    
    propertyDescription.type = PropertyTypeArray;
    
  } else if ([obj isKindOfClass:NSDate.class]) {
    
    propertyDescription.type = PropertyTypeDate;
    
  } else if ([obj isKindOfClass:NSDictionary.class]) {
    
    ClassDescription *anotherClassDescription = [self existingClassWithName:key];
    if (!anotherClassDescription) {
      anotherClassDescription = [self classDescriptionFromDictionary:obj withName:key];
    } else {
      [self updateClassDescription:anotherClassDescription fromDictionary:obj];
    }
    
    propertyDescription.type = PropertyTypeObject;
    propertyDescription.typeString = [anotherClassDescription.name stringByAppendingString:@" *"];
    
    [classDescription.headers addObject:anotherClassDescription.name];
    
  } else if ([obj isKindOfClass:NSNumber.class]) {
    
    BOOL isBool = [NSStringFromClass([obj class]) rangeOfString:@"Boolean"].location != NSNotFound;
    
    propertyDescription.type = isBool ? PropertyTypeBool : PropertyTypeDouble;
    
  } else {
    
  }
  
  [classDescription.properties addObject:propertyDescription];
}

- (PropertyType)propertyTypeFromObject:(id)obj
{
  if ([obj isKindOfClass:NSString.class]) {
    return PropertyTypeString;
  }
  else if ([obj isKindOfClass:NSNumber.class]) {
    BOOL isBool = [NSStringFromClass([obj class]) rangeOfString:@"Boolean"].location != NSNotFound;
    return isBool ? PropertyTypeBool : PropertyTypeDouble;
  }
  else if ([obj isKindOfClass:NSArray.class]) {
    return PropertyTypeArray;
  }
  else if ([obj isKindOfClass:NSDate.class]) {
    return PropertyTypeDate;
  }
  else /*if ([obj isKindOfClass:NSDictionary.class])*/ {
    return PropertyTypeObject;
  }
}

- (NSMutableSet *)classDescriptions
{
  return _classDescriptions ?: (_classDescriptions = [NSMutableSet new]);
}

- (ClassDescription *)existingClassWithName:(NSString *)name
{
  for (ClassDescription *classDescription in self.classDescriptions) {
    if ([classDescription.name isEqualToString:name]) {
      return classDescription;
    }
  }
  return nil;
}

@end
