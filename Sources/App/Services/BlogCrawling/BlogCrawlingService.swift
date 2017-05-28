//
//  BlogCrawlingService.swift
//  EbloVaporServer
//
//  Created by yansong li on 2017-04-28.
//
//

import Foundation

/// The service to start a blog crawling.
class BlogCrawlingService {

  /// The crawledblogs.
  var crawledBlog: [Blog] = []
  
  /// The blogParsers.
  private var blogParsers: [BlogParser] = []
  
  /// Whether or not automatically save crawled blog when crawling finishes.
  private var automaticallySaveWhenCrawlingFinished = false
  
  /// Whether or not blog crawling has finished.
  var crawlingFinished: Bool = false {
    didSet {
      if (crawlingFinished && !oldValue) && automaticallySaveWhenCrawlingFinished {
        print("---- AUTOMATICALLY SAVE BLOGS")
        // Add in a test yelp blog
//        let testBlog = Blog(title: "Hoooooool lllll",
//                            urlString: "http://yelp.com/test",
//                            companyName: "Yelp")
//        testBlog.publishDate = "May, 27, 2017"
//        testBlog.publishDateInterval = Date().timeIntervalSince1970
//        self.crawledBlog.append(testBlog)
        self.saveCrawledBlog()
      }
    }
  }
  
  /// Start service
  func startService(automaticallySaveWhenCrawlingFinished: Bool) {
    crawlingFinished = false
    self.automaticallySaveWhenCrawlingFinished = automaticallySaveWhenCrawlingFinished
    var url = URL(string: "https://api.myjson.com/bins/kt3e5")
    #if os(OSX)
    if EnviromentManager.local {
      let resourceName = EnviromentManager.newCompany ? "newCompany" : "company"
      let urlPath = Bundle.main.path(forResource: resourceName, ofType: "json")
      url = NSURL.fileURL(withPath: urlPath!)
    }
    #endif
    guard let data = try? Data(contentsOf: url!) else {
      print("\(self) can not load data from URL \(url!)")
      return
    }
    do {
      let json =
        try JSONSerialization.jsonObject(with: data,
                                         options: [.mutableContainers, .allowFragments])
      guard let jsonData = json as? [String: Any],
        let companies = jsonData["company"] as? [[String: Any]] else {
          return
      }
      
      for companyInfo in companies {
        // Create blog parsers.
        if let titlePath = companyInfo["title"] as? String,
          let href = companyInfo["href"] as? String,
          let baseURL = companyInfo["baseURL"] as? String,
          let basedOnBase = companyInfo["basedOnBase"] as? Bool,
          let companyName = companyInfo["name"] as? String {
          let articleInfo = ArticleInfoPath(title: titlePath,
                                            href: href,
                                            authorName: companyInfo["author"] as? String,
                                            authorAvatar: companyInfo["authorAvatar"] as? String,
                                            publishDate: companyInfo["date"] as? String)
          let metaInfo = BlogMetaInfo(nextPageXPath: companyInfo["nextPage"] as? String)
          let companyParser = BlogParser(baseURLString: baseURL,
                                         articlePath: articleInfo,
                                         metaData: metaInfo,
                                         companyName: companyName,
                                         basedOnBaseURL: basedOnBase)
          self.blogParsers.append(companyParser)
        }
      }
      
      self.blogParsers.forEach { parser in
        parser.parse { finished in
          self.crawledBlog.append(contentsOf: parser.Blogs)
          self.checkCrawlingStatus()
        }
      }
    } catch {
      print(error)
    }
  }
  
  /// Save crawled blogs.
  func saveCrawledBlog() {
    if self.crawlingFinished {
      do {
        let existingBlogs = try Blog.all()
        let existingIdentifiers = existingBlogs.map { blog in
          return blog.string()
        }
        self.crawledBlog.forEach { blog in
          if existingIdentifiers.contains(blog.string()) {
            return
          }
          print("This blog does not exist in our data base\(blog.string())")
          var toSave = blog
          do {
            try toSave.save()
          } catch {
            print("Some Error \(error)")
          }
        }
      } catch {
        print("Can not load Blogs from data base.")
      }
    } else {
      print("BlogCrawlingService not finish yet.")
    }
    self.automaticallySaveWhenCrawlingFinished = false
  }
  
  private func checkCrawlingStatus() {
    print("--- Before \(self.crawlingFinished)")
    self.crawlingFinished =
      self.blogParsers.filter { $0.finished == false }.count == 0
    print("--- After \(self.crawlingFinished)")
  }
}