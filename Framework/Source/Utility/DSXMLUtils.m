// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import "DSXMLUtils.h"
#import "DSDictionaryXSLArguments.h"


@implementation NSXMLNode (DSHelpers)

-(NSString *)ds_sanitizedText
{
    // Translation of private method ExtractSanitizedText
    /*
     It's a strange creature. Does this:
     - The first instance of the substring "#BR#" is deleted, but sets the internal flag as if it started a new line (i.e., it starts ignoring whitespace)
     - Subsequent instances of "#BR#" are actually turned into \n
     - Any number of tabs, newlines, or spaces at the beginning of a line are ignored
     - Tabs are actually always ignored lol
     - Multiple spaces in a row are collapsed to one space
     */

    NSString *rawText = self.stringValue;

    if(rawText.length == 0) return @"";


    const NSUInteger utf8Length = [rawText lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    const char *utf8Bytes = rawText.UTF8String;

    char *resBytes = calloc(utf8Length + 1, sizeof(char));
    NSUInteger resLength = 0;

    BOOL sawFirstBR = NO;
    BOOL atLineStart = YES;

    for(NSUInteger i = 0; i < utf8Length; i++) {
        const char c = utf8Bytes[i];
        const char nextC = utf8Bytes[i + 1];  // will give us the \0 at the end of string, which is fine

        if(i < utf8Length - 5 &&
           c == '#' &&
           nextC == 'B' &&
           utf8Bytes[i + 2] == 'R' &&
           utf8Bytes[i + 3] == '#')
        {
            // Skip past these guys in the input
            i += 3;

            // This makes little sense, but is what the framework does...
            atLineStart = YES;

            if(sawFirstBR) {
                resBytes[resLength++] = '\n';
            }

            sawFirstBR = YES;

            continue;
        }

        if(atLineStart) {
            if(c == '\t' || c == '\n' || c == ' ') continue;
        }
        else {
            if(c == '\t' || (c == ' ' && nextC == ' ')) continue;
        }

        resBytes[resLength++] = c;
        atLineStart = c == '\n';
    }

    // Built-in thing doesn't do this, but get rid of extra trailing spaces.
    if(resBytes[resLength - 1] == ' ') --resLength;

    NSString *res = [[NSString alloc] initWithBytesNoCopy:resBytes length:resLength encoding:NSUTF8StringEncoding freeWhenDone:YES];
    NSAssert(res != nil, @"Error reconstituting sanitized string");

    return res;
}

@end


@implementation NSXMLDocument (DSHelpers)

-(NSXMLDocument *)ds_XMLDocumentByApplyingXSL:(NSXMLDocument *)xslDoc
                                    arguments:(DSDictionaryXSLArguments *)xslArguments
{
    // TODO: if speed is unacceptable, switching to libxml2 here is the first logical step.
    // Just caching the pre-compiled XSLs would be a *huge* improvement.

    NSError *xformError = nil;
    NSXMLDocument *transformedDoc = [self objectByApplyingXSLT:xslDoc.XMLData
                                                     arguments:xslArguments.rawDictionary
                                                         error:&xformError];

    NSAssert(transformedDoc, @"Error applying XSL: %@", xformError);

    NSAssert([transformedDoc isKindOfClass:[NSXMLDocument class]], @"XSL returned an instance of %@; expected an NSXMLDocument", transformedDoc.class);

    [transformedDoc setDocumentContentKind:NSXMLDocumentXMLKind];

    return transformedDoc;
}

-(NSXMLDocument *)ds_XMLDocumentByApplyingXSLs:(NSArray *)xslDocs
                                     arguments:(DSDictionaryXSLArguments *)xslArguments
{
    NSXMLDocument *res = self;
    for(NSXMLDocument *xslDoc in xslDocs) {
        res = [res ds_XMLDocumentByApplyingXSL:xslDoc arguments:xslArguments];
    }

    return res;
}

-(BOOL)ds_replaceCSSPlaceholderWithContent:(NSString *)css
{
    // Seems like a safe assumption it's in a <style>, yah?
    NSString *placeholderXPath = [NSString stringWithFormat:@"//style[contains(text(), '%@')]", DSDictionaryXSLStyleSheetContentPlaceholder];

    NSError *xpathError = nil;
    NSArray *placeholderNodes = [self nodesForXPath:placeholderXPath error:&xpathError];
    NSAssert(placeholderNodes != nil, @"XPath error: %@", xpathError);

    if(placeholderNodes.count == 0) return NO;

    NSXMLElement *placeholderNode = placeholderNodes[0];
    NSAssert(placeholderNode.childCount == 1 && placeholderNode.children[0].kind == NSXMLTextKind, @"Placeholder node should have exactly one child, and it should be text.");

    NSString *escapedCSS = [NSString stringWithFormat:@"/*<![CDATA[*/ %@ /*]]>*/", css];

    NSMutableString *nodeContent = [placeholderNode.stringValue mutableCopy];
    // Only replacing the first match. Seems safe.
    NSRange replacementRange = [nodeContent rangeOfString:DSDictionaryXSLStyleSheetContentPlaceholder];
    [nodeContent replaceCharactersInRange:replacementRange withString:css];

    NSXMLNode *newTextNode = [[NSXMLNode alloc] initWithKind:NSXMLTextKind options:NSXMLNodeNeverEscapeContents | NSXMLNodePreserveAll];
    newTextNode.stringValue = escapedCSS;

    [placeholderNode setChildren:@[ newTextNode ]];

    return YES;
}

-(NSString *)ds_canonicalXMLStringIncludingContentType:(BOOL)includeContentType
{
    // This makes it spit out the processing directive & actually collapse empty tags
    self.documentContentKind = NSXMLDocumentXMLKind;

    self.version = @"1.0";
    self.characterEncoding = @"UTF-8";
    self.standalone = YES;

    // NSXMLDocumentIncludeContentTypeDeclaration does nothing unless our kind == XHTML or HTML
    // But if we're XHTML, it forces the output of a default xmlns, which we don't want.
    // This is just sisyphean
    if(includeContentType) {
        NSXMLElement *head = [self.rootElement elementsForName:@"head"].firstObject;
        NSAssert(head != nil, @"No <head> in document?");

        NSXMLElement *contentTypeElement = [[NSXMLElement alloc] initWithXMLString:@"<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\"/>" error:NULL];
        [head insertChild:contentTypeElement atIndex:0];
    }

    NSString *xmlString = [self XMLStringWithOptions:NSXMLNodeCompactEmptyElement];
    return [xmlString stringByAppendingString:@"\n"];  // just wanted -isEqualToString: to return YES, goddammit
}

-(BOOL)ds_isEffectivelyEqualToXMLDocument:(NSXMLDocument *)other
{
    NSString *ourCanon = [self canonicalXMLStringPreservingComments:YES];
    NSString *theirCanon = [other canonicalXMLStringPreservingComments:YES];

    return [ourCanon isEqualToString:theirCanon];
}

-(NSArray<NSString *> *)ds_nonEmptyTrimmedStringValuesForXPath:(NSString *)xpath
{
    // TODO: as with the XSL stuff, switching to libxml2 here would be a massive speed improvement.
    // Caching pre-compiled XPaths per-dictionary would be a *huge* improvement.

    NSError *xpathError = nil;
    NSArray *xpathResult = [self nodesForXPath:xpath error:&xpathError];
    NSAssert(xpathResult != nil, @"Error executing XPath: %@", xpathError);

    if(xpathResult.count == 0) return @[];

    NSMutableArray *res = [NSMutableArray arrayWithCapacity:xpathResult.count];
    for(NSXMLNode *xpathNode in xpathResult) {
        NSMutableString *stringValue = [xpathNode.stringValue mutableCopy];
        if(stringValue.length == 0) continue;

        // Calling this for parity with the framework; would call -stringByTrimmingCharactersInSet: in a sane world
        CFStringTrimWhitespace((__bridge CFMutableStringRef)stringValue);
        if(stringValue.length == 0) continue;

        [res addObject:stringValue];
    }

    return res;
}

@end


@implementation NSXMLElement (DSUtils)

-(BOOL)ds_attributeForName:(NSString *)attributeName containsToken:(NSString *)token
{
    NSXMLNode *attrNode = [self attributeForName:attributeName];
    if(!attrNode) return NO;

    NSString *attrString = attrNode.stringValue;
    if([attrString isEqualToString:token]) return YES;  // a common case

    NSArray<NSString *> *attrTokens = [attrString componentsSeparatedByCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    return [attrTokens containsObject:token];
}

-(BOOL)ds_hasClass:(NSString *)token
{
    return [self ds_attributeForName:@"class" containsToken:token];
}

-(NSArray<NSXMLElement *> *)ds_childElementsWithAttributeForName:(NSString *)attributeName containingToken:(NSString *)token
{
    NSMutableArray *res = [NSMutableArray new];

    for(NSXMLNode *childNode in self.children) {
        if(childNode.kind != NSXMLElementKind) continue;
        NSXMLElement *childElem = (NSXMLElement *)childNode;

        if([childElem ds_attributeForName:attributeName containsToken:token]) {
            [res addObject:childElem];
        }
    }

    return res.count == 0 ? nil : res;
}

-(NSArray<NSXMLElement *> *)ds_childElementsWithClass:(NSString *)token
{
    return [self ds_childElementsWithAttributeForName:@"class" containingToken:token];
}

-(NSXMLElement *)ds_firstChildElementWithAttributeForName:(NSString *)attributeName
                                          containingToken:(NSString *)token
                                      minMatchingChildren:(NSUInteger)minMatchingChildren
                                      maxMatchingChildren:(NSUInteger)maxMatchingChildren
{
    NSArray *elems = [self ds_childElementsWithAttributeForName:attributeName containingToken:token];

    NSAssert(elems.count >= minMatchingChildren, @"Expected at least @lu matching children, but got %lu", minMatchingChildren, elems.count);

    if(maxMatchingChildren != 0) {
        NSAssert(elems.count <= maxMatchingChildren, @"Expected at most %lu matching children, but got %lu", maxMatchingChildren, elems.count);
    }

    return elems.firstObject;
}

-(NSXMLElement *)ds_firstChildElementWithAttributeForName:(NSString *)attributeName
                                          containingToken:(NSString *)token
{
    return [self ds_firstChildElementWithAttributeForName:attributeName
                                          containingToken:token
                                      minMatchingChildren:0
                                      maxMatchingChildren:0];
}

-(NSXMLElement *)ds_firstChildElementWithClass:(NSString *)token
{
    return [self ds_firstChildElementWithAttributeForName:@"class" containingToken:token];
}

-(NSXMLElement *)ds_singleChildElementWithAttributeForName:(NSString *)attributeName containingToken:(NSString *)token
{
    return (NSXMLElement * __nonnull)[self ds_firstChildElementWithAttributeForName:attributeName
                                                                    containingToken:token
                                                                minMatchingChildren:1
                                                                maxMatchingChildren:1];
}

-(NSXMLElement *)ds_singleChildElementWithClass:(NSString *)token
{
    return [self ds_singleChildElementWithAttributeForName:@"class" containingToken:token];
}

-(NSXMLElement *)ds_optionalSingleChildElementWithAttributeForName:(NSString *)attributeName containingToken:(NSString *)token
{
    return [self ds_firstChildElementWithAttributeForName:attributeName
                                          containingToken:token
                                      minMatchingChildren:0
                                      maxMatchingChildren:1];
}

-(NSXMLElement *)ds_optionalSingleChildElementWithClass:(NSString *)token
{
    return [self ds_optionalSingleChildElementWithAttributeForName:@"class" containingToken:token];
}

-(NSXMLElement *)ds_nearestPreviousSiblingWithAttributeForName:(NSString *)attributeName containingToken:(NSString *)token
{
    NSXMLNode *sibling = self.previousSibling;
    while(sibling != nil) {
        if(sibling.kind == NSXMLElementKind) {
            NSXMLElement *siblingElem = (NSXMLElement *)sibling;
            if([siblingElem ds_attributeForName:attributeName containsToken:token]) {
                return siblingElem;
            }
        }

        sibling = sibling.previousSibling;
    }

    return nil;
}

-(NSXMLElement *)ds_nearestPreviousSiblingWithClass:(NSString *)token
{
    return [self ds_nearestPreviousSiblingWithAttributeForName:@"class" containingToken:token];
}

-(NSArray<NSXMLElement *> *)ds_selfOrChildrenWithClass:(NSString *)token
{
    if([self ds_hasClass:token]) return @[ self ];
    return [self ds_childElementsWithClass:token];
}

-(NSXMLElement *)ds_selfOrSingleChildWithClass:(NSString *)token
{
    if([self ds_hasClass:token]) return self;
    return [self ds_singleChildElementWithClass:token];
}

-(NSXMLElement *)ds_selfOrOptionalSingleChildWithClass:(NSString *)token
{
    if([self ds_hasClass:token]) return self;
    return [self ds_optionalSingleChildElementWithClass:token];
}

@end


@implementation DSXMLUtils

+(NSString *)sanitizedConcatenatedStringValueOfElements:(NSArray<NSXMLElement *> *)elems
{
    if(elems == nil || elems.count == 0) return @"";

    NSMutableString *s = [NSMutableString new];
    BOOL first = YES;

    for(NSXMLElement *elem in elems) {
        [s appendFormat:@"%@%@", first ? @"" : @" ", elem.ds_sanitizedText];
        first = NO;
    }

    return [s stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
}

@end
