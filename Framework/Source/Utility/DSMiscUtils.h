// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import <Foundation/Foundation.h>
#import "DSDefines.h"


// Hey thanks, user1187902 @ https://stackoverflow.com/a/16926582. Very clever.
#define DSCountArgs(...) DSCountArgs_(,##__VA_ARGS__,10,9,8,7,6,5,4,3,2,1,0)
#define DSCountArgs_(z,a,b,c,d,e,f,g,h,i,j,cnt,...) cnt


NS_ASSUME_NONNULL_BEGIN


NSString * __nullable __DSFirstNonEmptyString(size_t numArgs, NSString * __nullable first, ...) DS_WARN_UNUSED_RESULT;
#define DSFirstNonEmptyString(...) __DSFirstNonEmptyString(DSCountArgs(__VA_ARGS__), __VA_ARGS__)

NSArray * __nullable __DSArrayOfNonNilValues(size_t numArgs, id __nullable first, ...) DS_WARN_UNUSED_RESULT;
#define DSArrayOfNonNilValues(...) __DSArrayOfNonNilValues(DSCountArgs(__VA_ARGS__), __VA_ARGS__)


// explodes on error
void DSWritePlistObjectToFile(id plistObj, NSURL *fileURL);

// returns nil if no such file. otherwise explodes on error.
id __nullable DSReadPlistObjectFromFile(NSURL *fileURL, BOOL mutableContainers) DS_WARN_UNUSED_RESULT;


NS_ASSUME_NONNULL_END
