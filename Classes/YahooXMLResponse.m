//
//  YahooXMLResponse.m
//

#import "YahooXMLResponse.h"
#import "SearchResult.h"
#import "DDXMLDocument.h"

@implementation YahooXMLResponse

/////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark TTURLResponse

- (NSError*)request:(TTURLRequest*)request processResponse:(NSHTTPURLResponse*)response data:(id)data
{
    NSError *error = nil;
    
    // Parse the XML document.
    DDXMLDocument *doc = [[[DDXMLDocument alloc] initWithData:data options:0 error:&error] autorelease];
    NSAssert(doc, @"Failed to parse XML. The document is nil.");
    
    // Explicitly specify the default namespace (I don't have much experience
    // with KissXML, but this is the only way I was able to get the XPath queries
    // to work).
    DDXMLElement *root = [doc rootElement];
    [root addNamespace:[DDXMLNode namespaceWithName:@"foo" stringValue:@"urn:yahoo:srchmi"]];

    // Query the XML tree according to the Yahoo Image Search API specification.
    NSArray *titles = [root nodesForXPath:@"//foo:Title" error:&error];
    NSArray *fullSizeURLs = [root nodesForXPath:@"//foo:Result/foo:Url" error:&error];
    NSArray *thumbnailURLs = [root nodesForXPath:@"//foo:Result/foo:Thumbnail/foo:Url" error:&error];
    totalObjectsAvailableOnServer = [[[[root nodesForXPath:@"foo:ResultSet[@totalResultsAvailable]" error:&error] lastObject] stringValue] integerValue];
    
    NSAssert1(!error, @"XML Parse error: %@", error);
    NSAssert([titles count] == [fullSizeURLs count] && [titles count] == [thumbnailURLs count], 
             @"XPath error: the quantity of the data retrieved does not match.");
    
    // Now construct our domain-specific object.
    for (NSUInteger i = 0; i < [titles count]; i++) {
        SearchResult *result = [[[SearchResult alloc] init] autorelease];
        result.title = [[titles objectAtIndex:i] stringValue];
        result.imageURL = [[fullSizeURLs objectAtIndex:i] stringValue];
        result.thumbnailURL = [[thumbnailURLs objectAtIndex:i] stringValue];
        [self.objects addObject:result];
    }
    
    return nil;
}

@end
