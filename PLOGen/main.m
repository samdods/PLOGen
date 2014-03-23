//
//  main.m
//  MacTest
//
//  Created by Sam Dods on 21/03/2014.
//  Copyright (c) 2014 Sam Dods. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EnvironmentHelper.h"

int main(int argc, const char * argv[])
{
  @autoreleasepool {
    
    unsigned long l;                       /* String length. */
    int m, n,                              /* Loop counters. */
    x,                                 /* Exit code. */
    ch;                                /* Character buffer. */
    char outputPathStr[1024] = {0};                           /* String buffer. */
    char inputPathStr[1024] = {0};                           /* String buffer. */
    char plistClassNameStr[1024] = {0};                           /* String buffer. */
    char otherClassesPrefixStr[1024] = {0};                           /* String buffer. */
    char resourceFileNameStr[1024] = {0};                           /* String buffer. */
    
    for( n = 1; n < argc; n++ )            /* Scan through args. */
    {
      switch( (int)argv[n][0] )            /* Check for option character. */
      {
        case '-':
        case '/': x = 0;                   /* Bail out if 1. */
          l = strlen( argv[n] );
          for( m = 1; m < l; ++m ) /* Scan through options. */
          {
            ch = (int)argv[n][m];
            switch( ch )
            {
              case 'o':              /* String parameter. */
                if( m + 1 >= l )
                {
                  puts( "Illegal syntax -- no string!" );
                  exit( 1 );
                }
                else
                {
                  strcpy( outputPathStr, &argv[n][m+1] );
                  printf( "-%c %s\n", ch, outputPathStr );
                }
                x = 1;
                break;
                
              case 'p':              /* String parameter. */
                if( m + 1 >= l )
                {
                  puts( "Illegal syntax -- no string!" );
                  exit( 1 );
                }
                else
                {
                  strcpy( inputPathStr, &argv[n][m+1] );
                  printf( "-%c %s\n", ch, inputPathStr );
                }
                x = 1;
                break;
                
              case 'c':              /* String parameter. */
                if( m + 1 >= l )
                {
                  puts( "Illegal syntax -- no string!" );
                  exit( 1 );
                }
                else
                {
                  strcpy( plistClassNameStr, &argv[n][m+1] );
                  printf( "-%c %s\n", ch, plistClassNameStr );
                }
                x = 1;
                break;
                
              case 'f':              /* String parameter. */
                if( m + 1 >= l )
                {
                  puts( "Illegal syntax -- no string!" );
                  exit( 1 );
                }
                else
                {
                  strcpy( otherClassesPrefixStr, &argv[n][m+1] );
                  printf( "-%c %s\n", ch, otherClassesPrefixStr );
                }
                x = 1;
                break;
                
              case 'r':              /* String parameter. */
                if( m + 1 >= l )
                {
                  puts( "Illegal syntax -- no string!" );
                  exit( 1 );
                }
                else
                {
                  strcpy( resourceFileNameStr, &argv[n][m+1] );
                  printf( "-%c %s\n", ch, resourceFileNameStr );
                }
                x = 1;
                break;
                
              default:
                printf( "Illegal option code = %c\n", ch );
                x = 1;      /* Not a legal option. */
                exit( 1 );
                break;
            }
            if( x == 1 )
            {
              break;
            }
          }
          break;
        default:  printf( "Text = %s\n", argv[n] ); /* Not option -- text. */
          break;
      }
    }
    
    if (!strlen(inputPathStr) || !strlen(outputPathStr) || !strlen(plistClassNameStr)) {
      fprintf(stderr, "missing command-line parameter");
      return 1;
    }
    
    if (!strlen(resourceFileNameStr)) {
      strcpy(resourceFileNameStr, plistClassNameStr);
    }
    
    NSString *plistClassName = [NSString stringWithFormat:@"%s", plistClassNameStr];
    NSString *otherClassesPrefixString = [NSString stringWithFormat:@"%s", otherClassesPrefixStr];
    
    NSSet *classDescriptions = [EnvironmentHelper classDescriptionsForPlistFile:[NSString stringWithFormat:@"%s", inputPathStr] withRootClassName:plistClassName otherClassesPrefix:otherClassesPrefixString];
    
    
    for (ClassDescription *classDescription in classDescriptions) {
      
      char cwd[1024];
      if (getcwd(cwd, sizeof(cwd)) != NULL) {
        fprintf(stdout, "Current working dir: %s\n", cwd);
      }
      
      if (classDescription.isRootClass) {
        classDescription.resourceFilename = [NSString stringWithFormat:@"%s", resourceFileNameStr];
      }
      
      NSString *path = nil;
      if (outputPathStr[0] != '/') {
        path = [NSString stringWithFormat:@"%s/%s", cwd, outputPathStr];
      }
      
      NSString *hFileString = path ? [NSString stringWithFormat:@"%@/%@.h", path, classDescription.name] : [NSString stringWithFormat:@"%s/%@.h", outputPathStr, classDescription.name];
      FILE *fp = fopen(hFileString.UTF8String, "w");
      if (fp) {
        fprintf(fp, "%s", classDescription.interfaceDescription.UTF8String);
      }
      fclose(fp);
      
      NSString *mFileString = path ? [NSString stringWithFormat:@"%@/%@.m", path, classDescription.name] : [NSString stringWithFormat:@"%s/%@.m", outputPathStr, classDescription.name];
      fp = fopen(mFileString.UTF8String, "w");
      if (fp) {
        fprintf(fp, "%s", classDescription.implementationDescription.UTF8String);
      }
      fclose(fp);
    }
      
  }
  return 0;
}
