//
//  NSString+Additions.m
//  MacTest
//
//  Created by Sam Dods on 21/03/2014.
//  Copyright (c) 2014 Sam Dods. All rights reserved.
//

#import "NSString+Additions.h"

@implementation NSString (Additions)

- (NSString *)upperCamelCase
{
  return [NSString stringWithFormat:@"%@%@", [self substringToIndex:1].uppercaseString, [self substringFromIndex:1]];
}

- (NSString *)lowerCamelCase
{
  return [NSString stringWithFormat:@"%@%@", [self substringToIndex:1].lowercaseString, [self substringFromIndex:1]];
}

@end
