// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import <Foundation/Foundation.h>

NS_FORMAT_FUNCTION(1, 2)
void info(NSString *format, ...);

__attribute__((__overloadable__))
id task(NSString *label, id (^block)(NSString **errorMessage));

__attribute__((__overloadable__))
id task(NSString *label, id (^block)(void));

__attribute__((__overloadable__))
void task(NSString *label, void (^block)(void));

__attribute__((__overloadable__))
void task(NSString *label, void (^block)(NSString **errorMessage));
