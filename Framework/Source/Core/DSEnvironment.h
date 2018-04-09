// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import <Foundation/Foundation.h>
#import "DSDefines.h"
#import "DSConstants.h"


NS_ASSUME_NONNULL_BEGIN


@interface DSEnvironment : NSObject

@property (nonatomic, readonly, copy, class) NSURL *frameworkURL;

+(nullable NSURL *)URLForFrameworkResource:(NSString *)name withExtension:(NSString *)extension DS_WARN_UNUSED_RESULT;

+(nullable NSURL *)URLForXSLForDefinitionStyle:(DSDefinitionStyle)style DS_WARN_UNUSED_RESULT;
+(nullable NSXMLDocument *)XSLDocumentForDefinitionStyle:(DSDefinitionStyle)style DS_WARN_UNUSED_RESULT;
@property (nonatomic, readonly, copy, class) NSXMLDocument *baseDefinitionXSLDocument;

@end


NS_ASSUME_NONNULL_END
