// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import "DSEnvironment.h"


@interface DSEnvironment ()

@property (nonatomic, readonly, class) CFBundleRef frameworkBundle;

@end


@implementation DSEnvironment

+(CFBundleRef)frameworkBundle
{
    static CFBundleRef _frameworkBundle;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _frameworkBundle = CFBundleGetBundleWithIdentifier(CFSTR("com.apple.DictionaryServices"));
        CFRetain(_frameworkBundle);
    });

    return _frameworkBundle;
}

+(NSURL *)frameworkURL
{
    return (__bridge_transfer NSURL *)CFBundleCopyBundleURL(self.frameworkBundle);
}

+(NSURL *)URLForFrameworkResource:(NSString *)name withExtension:(NSString *)extension
{
    return (__bridge_transfer NSURL *)CFBundleCopyResourceURL(self.frameworkBundle,
                                                              (__bridge CFStringRef)name,
                                                              (__bridge CFStringRef)extension,
                                                              nil);
}

+(NSURL *)URLForXSLForDefinitionStyle:(DSDefinitionStyle)style
{
    static NSDictionary *xslFilenamesByStyle;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        xslFilenamesByStyle = @{ @(DSDefinitionStyleXHTMLForApp): @"TransformApp",
                                 @(DSDefinitionStyleXHTMLForPanel): @"TransformPanel",
                                 @(DSDefinitionStylePlainText): @"TransformText" };
    });

    // There's also TransformSimpleText, which seems to only be used by the Wikipedia dictionary?
    // It's essentially the panel version of TransformText - it snips out priority 2 elements.

    NSString *filename = xslFilenamesByStyle[@(style)];
    if(!filename) return nil;

    return [self URLForFrameworkResource:filename withExtension:@"xsl"];
}

+(NSXMLDocument *)XSLDocumentForDefinitionStyle:(DSDefinitionStyle)style
{
    static NSMutableDictionary *xslDocumentCache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        xslDocumentCache = [NSMutableDictionary new];
    });

    @synchronized(xslDocumentCache) {
        NSXMLDocument *doc = xslDocumentCache[@(style)];
        if((id)doc == [NSNull null]) return nil;  // Cached failure
        if(doc) return doc;

        NSURL *xslURL = [self URLForXSLForDefinitionStyle:style];
        if(!xslURL) {
            xslDocumentCache[@(style)] = [NSNull null];
            return nil;
        }

        NSError *xslParseError = nil;
        doc = [[NSXMLDocument alloc] initWithContentsOfURL:xslURL options:NSXMLNodeOptionsNone error:&xslParseError];
        NSAssert(doc != nil, @"Error parsing XSL document: %@", xslParseError);

        xslDocumentCache[@(style)] = doc;

        return doc;
    }
}

+(NSXMLDocument *)baseDefinitionXSLDocument
{
    static NSXMLDocument *_baseDefinitionXSLDocument;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *xslURL = [self URLForFrameworkResource:@"Transform" withExtension:@"xsl"];

        NSError *xslParseError = nil;
        _baseDefinitionXSLDocument = [[NSXMLDocument alloc] initWithContentsOfURL:xslURL options:NSXMLNodeOptionsNone error:&xslParseError];
        NSAssert(_baseDefinitionXSLDocument != nil, @"Error parsing XSL document: %@", xslParseError);
    });

    return [_baseDefinitionXSLDocument copy];
}

@end
