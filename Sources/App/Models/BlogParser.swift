//
//  BlogParser.swift
//  EbloVaporServer
//
//  Created by yansong li on 2017-04-16.
//
//

import Foundation
import Kanna
import Utilities

/// This is a class used for parse a url.
public class BlogParser {
  
  /// The string to parse.
  public var baseURLString: String
  
  /// Whether or not be need the base url to composite a valid URL.
  public let basedOnBaseURL: Bool
  
  /// XPath infos for article.
  public let articlePath: ArticleInfoPath
  
  /// Meta data for article.
  public let metaData: BlogMetaInfo
  
  /// Array contains all the article titles founded.
  public private(set) var articles: [String] = []
  
  /// The maximum depth for blog pagination.
  private let maxDepth: Int = 10
  
  /// Current depth has processed.
  private var currentDepth: Int = 0
  
  init(baseURLString: String,
       articlePath: ArticleInfoPath,
       metaData: BlogMetaInfo,
       basedOnBaseURL: Bool) {
    self.baseURLString = baseURLString
    self.articlePath = articlePath
    self.metaData = metaData
    self.basedOnBaseURL = basedOnBaseURL
  }
  
  /// Parse this company's blog.
  public func parse() {
    parse(url: self.baseURLString)
    print("Parse Finished, total found \(self.articles.count) aritcles")
  }
  
  // MARK: Priave
  /// Parse a URL.
  public func parse(url: String) {
    guard self.currentDepth < maxDepth else {
      print("Blog Parser has reached the max depth")
      return
    }
    
    // 1. Find and print all title in current page.
    parse(url: url, xPath: self.articlePath.title) { title in
      print("Find article \(title)")
      articles.append(title)
    }
    
    self.currentDepth += 1
    
    if let nextPageXPath = self.metaData.nextPageXPath {
      parse(url: url, xPath: nextPageXPath) { nextPage in
        var toBeParseURLString =
          self.basedOnBaseURL ? self.baseURLString.appendTrimmedRepeatedElementString(nextPage) : nextPage
        toBeParseURLString = toBeParseURLString.appendTrimmedRepeatedElementString("/")
        print("next to be parsed url: \(toBeParseURLString)")
        self.parse(url: toBeParseURLString)
      }
    }
  }
  
  /// Parse `xPath`, with url.
  private func parse(url: String, xPath: String, execute:(String) -> ()) {
    guard let url = URL(string: url) else {
      print("Invalid url");
      return
    }
    guard let doc = HTML(url: url, encoding: .utf8) else {
      print("Invalid doc");
      return
    }
    for title in doc.xpath(xPath) {
      if let result = title.text {
        execute(result)
      }
    }
  }
}
