// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import "DSRecordPrivate.h"
#import "FrameworkInternals.h"
#import "DSDictionary.h"
#import "DSEnvironment.h"
#import "DSXMLUtils.h"
#import "DSMiscUtils.h"


@interface DSSyntheticRecord ()

@property (nonatomic, readwrite, nullable, copy) NSString *keyword;

@property (nonatomic, readwrite, copy) NSString *headword;
@property (nonatomic, readwrite, nullable, copy) NSString *rawHeadword;
@property (nonatomic, readwrite, nullable, copy) NSString *supplementalHeadword;

@property (nonatomic, readwrite, copy) NSString *title;

@property (nonatomic, readwrite, nullable, copy) NSString *anchor;

@property (nonatomic, readwrite, strong) NSXMLDocument *bodyXML;

@end


@implementation DSSyntheticRecord

// What is this, 2010???
// jk obvi... one of the last edge cases for autosynthesis
@synthesize keyword=_keyword;
@synthesize headword=_headword;
@synthesize rawHeadword=_rawHeadword;
@synthesize supplementalHeadword=_supplementalHeadword;
@synthesize title=_title;
@synthesize anchor=_anchor;
@synthesize textElements=_textElements;

-(instancetype)initWithDictionary:(DSDictionary *)dictionary
                       indexEntry:(DSIndexEntry *)indexEntry
{
    DSBodyDataID bodyDataID = indexEntry.externalBodyID;
    NSAssert(bodyDataID != 0, @"Missing body ID for index entry");

    DSIndex *bodyDataIdx = dictionary.bodyDataIndex;
    NSAssert(bodyDataIdx != nil, @"Couldn't get body data index from dictionary");

    NSString *xmlString = [bodyDataIdx dataForRecordID:bodyDataID];
    NSAssert(bodyDataIdx != nil, @"No entry for body data ID %@ in index", DSStringForBodyDataID(bodyDataID));

    self = [self initWithDictionary:dictionary indexEntry:indexEntry recordXMLString:xmlString];
    return self;
}

-(instancetype)initWithDictionary:(DSDictionary *)dictionary
                       indexEntry:(DSIndexEntry *)indexEntry
                  recordXMLString:(NSString *)xmlString
{
    NSError *xmlError = nil;
    NSXMLDocument *xmlDoc = [[NSXMLDocument alloc] initWithXMLString:xmlString options:NSXMLNodeOptionsNone error:&xmlError];
    NSAssert(xmlDoc != nil, @"Error parsing record XML: %@", xmlError);
    [xmlDoc setDocumentContentKind:NSXMLDocumentXMLKind];

    self = [self initWithDictionary:dictionary indexEntry:indexEntry recordXMLNoCopy:xmlDoc];
    return self;
}

-(instancetype)initWithDictionary:(DSDictionary *)dictionary
                       indexEntry:(DSIndexEntry *)indexEntry
                        recordXML:(NSXMLDocument *)xmlDoc
{
    self = [self initWithDictionary:dictionary indexEntry:indexEntry recordXMLNoCopy:[xmlDoc copy]];
    return self;
}

-(instancetype)initWithDictionary:(DSDictionary *)dictionary
                       bodyDataID:(DSBodyDataID)bodyDataID
{
    DSIndex *bodyIdx = dictionary.bodyDataIndex;
    NSString *xmlString = [bodyIdx dataForRecordID:bodyDataID];

    NSAssert(xmlString != nil, @"No body data entry for id %@", DSStringForBodyDataID(bodyDataID));

    self = [self initWithDictionary:dictionary recordXMLString:xmlString];
    return self;
}

-(instancetype)initWithDictionary:(DSDictionary *)dictionary recordXMLString:(NSString *)xmlString
{
    NSError *xmlError = nil;
    NSXMLDocument *xmlDoc = [[NSXMLDocument alloc] initWithXMLString:xmlString options:NSXMLNodeOptionsNone error:&xmlError];
    NSAssert(xmlDoc != nil, @"Error parsing XML from body data: %@", xmlError);

    self = [self initWithDictionary:dictionary recordXMLNoCopy:xmlDoc];
    return self;
}

-(instancetype)initWithDictionary:(DSDictionary *)dictionary recordXMLNoCopy:(NSXMLDocument *)xmlDoc
{
    self = [super initWithDictionary:dictionary];
    if(self) {
        // Just kind of making this up.
        _textElements = [[DSRecordTextElements alloc] initWithXMLDocument:xmlDoc dictionary:dictionary];

        _keyword = _textElements.headword;
        _headword = _textElements.headword;
        _rawHeadword = _headword;
        _supplementalHeadword = nil;
        _title = _textElements.title;
        _anchor = nil;
        _bodyXML = xmlDoc;
    }

    return self;
}

-(instancetype)initWithDictionary:(DSDictionary *)dictionary
                       indexEntry:(DSIndexEntry *)indexEntry
                  recordXMLNoCopy:(NSXMLDocument *)xmlDoc
{
    self = [super initWithDictionary:dictionary];
    if(self) {
        // TODO: the internal stuff that instantiates DCSRecords has a lot of logic on these
        // for instance, it seems to make headword = rawheadword + supplemental headword,
        // and has some fallbacks
        _keyword = [indexEntry.keyword copy];
        _headword = [indexEntry.headword copy];
        _rawHeadword = _headword;
        _supplementalHeadword = [indexEntry.supplementalHeadword copy];
        _title = [indexEntry.entryTitle copy];
        _anchor = [indexEntry.anchor copy];
        _bodyXML = xmlDoc;
    }

    return self;
}

-(DSRecordTextElements *)textElements
{
    if(!_textElements) {
        _textElements = [[DSRecordTextElements alloc] initWithXMLDocument:self.bodyXML dictionary:self.dictionary];

        // weird canon behavior - text elements gets the title thrown in as "headword", with the
        // real headword as the fallback
//        if(!_textElements.headword) _textElements.headword = _title ?: _headword;
    }

    return _textElements;
}

-(BOOL)supportsDefinitionStyle:(DSDefinitionStyle)style
{
    // May as well... we have the XSLs for all of these in the framework...
    return style == DSDefinitionStyleBareXHTML ||
           style == DSDefinitionStyleXHTMLForApp ||
           style == DSDefinitionStyleXHTMLForPanel ||
           style == DSDefinitionStylePlainText ||
           style == DSDefinitionStyleRaw;
}

-(NSString *)definitionWithStyle:(DSDefinitionStyle)style
{
    NSAssert([self supportsDefinitionStyle:style], @"Unsupported definition style %lu", style);

    // TODO: all this going back and forth between text & XML is silly.

    if(style == DSDefinitionStyleRaw) {
        return [self.bodyXML XMLString];
    }

    // Seems like the internal rule is ...
    // base XSL from framework (Transform.xsl)
    // then style XSL from framwork (Transform*.xsl)
    // then the dictionary's XSL

    NSXMLDocument *baseXSL = DSEnvironment.baseDefinitionXSLDocument;
    NSXMLDocument *styleXSL = [DSEnvironment XSLDocumentForDefinitionStyle:style];
    NSXMLDocument *dictionaryXSL = self.dictionary.xslDocument;

    NSArray *xslStack = DSArrayOfNonNilValues(baseXSL, dictionaryXSL, styleXSL);


    NSXMLDocument *transformedDoc = nil;

    if(xslStack) {
        NSString *titleForXSL = self.title.length == 0 ? self.headword : self.title;
        DSDictionaryXSLArguments *xslArgs = self.dictionary.defaultXSLArguments;
        [xslArgs setString:titleForXSL forKey:DSXSLArgumentKeyAriaLabel escape:YES];
        if(style != DSDefinitionStylePlainText) [xslArgs setStylesheetContentPlaceholder];

        transformedDoc = [self.bodyXML ds_XMLDocumentByApplyingXSLs:xslStack arguments:xslArgs];
    }
    else {
        transformedDoc = self.bodyXML;
    }


    if(style == DSDefinitionStylePlainText) {
        NSAssert([transformedDoc.rootElement.localName isEqualToString:@"text"], @"Transformed plaintext definition XML should have a <text> root element, not %@", transformedDoc.rootElement.localName);

        return transformedDoc.ds_sanitizedText;
    }

    [transformedDoc ds_replaceCSSPlaceholderWithContent:self.dictionary.styleSheetContent];

    // Got me... framework behavior to not put the <meta> content-type tag in style 0
    BOOL includeContentTypeInOutput = style != DSDefinitionStyleBareXHTML;
    return [transformedDoc ds_canonicalXMLStringIncludingContentType:includeContentTypeInOutput];
}

@end
