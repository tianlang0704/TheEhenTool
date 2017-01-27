//
//  ConfigurationHelper.swift
//  TheEhenTool
//
//  Created by CMonk on 1/7/17.
//  Copyright © 2017 acrew. All rights reserved.
//

import Foundation
import UIKit

protocol EnumCollection : Hashable {}
extension EnumCollection {
    static func cases() -> AnySequence<Self> {
        typealias S = Self
        return AnySequence { () -> AnyIterator<S> in
            var raw = 0
            return AnyIterator {
                let current : Self = withUnsafePointer(to: &raw) { $0.withMemoryRebound(to: S.self, capacity: 1) { $0.pointee } }
                guard current.hashValue == raw else { return nil }
                raw += 1
                return current
            }
        }
    }
}

class SearchConfiguration {
    //http://g.e-hentai.org/?f_doujinshi=1&f_manga=1&f_artistcg=1&f_gamecg=1&f_western=1&f_non-h=1&f_imageset=1&f_cosplay=1&f_asianporn=1&f_misc=1&f_search=&f_apply=Apply+Filter
    //let searchQueryURLTemplate = ""
    let searchQueryURLTemplate = "https://g.e-hentai.org/?inline_set=dm_t&{{page}}&{{options}}&{{search}}&f_apply=Apply+Filter"
    //let searchQueryURLTemplate = "http://g.e-hentai.org/?inline_set=dm_t&{{page}}&{{options}}&{{search}}&f_apply=Apply+Filter"
    
//    enum EHenFilterOptions: String, EnumCollection {
//        case DouJinShi = "f_doujinshi"
//        case Manga = "f_manga"
//        case ArtistCG = "f_artistcg"
//        case GameCG = "f_gamecg"
//        case Western = "f_western"
//        case NonH = "f_non-h"
//        case ImageSet = "f_imageset"
//        case Cosplay = "f_cosplay"
//        case AsianPorn = "f_asianporn"
//        case Misc = "f_misc"
//    }
    
    enum EHenFilterOptions: String, EnumCollection {
        case DouJinShi
        case Manga
        case ArtistCG
        case GameCG
        case Western
        case Non_H
        case ImageSet
        case Cosplay
        case AsianPorn
        case Misc
    }
    
    let searchPageKey = "page"
    let searchKey = "f_search"
    
    var toggleFilterSettings = Dictionary<EHenFilterOptions, Bool>()
    
    func GetSearchString(searchWords: String = "", page: Int = 0) -> String {
        let pageString = "\(self.searchPageKey)=\(page)"
        
        let replacedWords = searchWords.replacingOccurrences(of: " ", with: "+")
        let escapedWords = replacedWords.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
        let searchString = "\(self.searchKey)=\(escapedWords)"
        
        var optionsString = ""
        let optionList = Array(EHenFilterOptions.cases())
        for optionIndex in 0..<optionList.count {
            let keyString = "f_" + optionList[optionIndex].rawValue.lowercased().replacingOccurrences(of: "_", with: "-")
            optionsString.append(keyString + "=")
            self.toggleFilterSettings[optionList[optionIndex]] ?? true ? optionsString.append("1") : optionsString.append("0")
            optionIndex != optionList.count - 1 ? optionsString.append("&") : ()
        }
        
        let searchStringPage = self.searchQueryURLTemplate.replacingOccurrences(of: "{{page}}", with: pageString)
        let searchStringOptions = searchStringPage.replacingOccurrences(of: "{{options}}", with: optionsString)
        let searchStringWtihWords = searchStringOptions.replacingOccurrences(of: "{{search}}", with: searchString)
        return searchStringWtihWords
    }
}

class ConfigurationHelper: SearchConfiguration{
    let previewListXPath = "/html/body/div[1]/div[2]/div[2]/div"
    let previewThumbXPath = "div[2]/a/img/@src"
    let previewHrefXPath = "div[1]/a/@href"
    let previewTitleXPath = "div[1]/a"
    let previewIdXPath = "div[1]/a/@href"
    let previewIdRegEx = "^http[s]*:\\/\\/.*\\/g\\/(\\d*)\\/.*\\/$"
    
    let bookTitleXPath = "//*[@id=\"gn\"]"
    let bookPageNumberXPath = "//*[@id=\"gdd\"]/table/tr[6]/td[2]"
    let bookPageNumberRegEx = "^(\\d*) pages$"
    let bookIdRegEx = "^http[s]*:\\/\\/.*\\/g\\/(\\d*)\\/.*\\/$"
    let bookThumbXPath = "//*[@id=\"gd1\"]/img/@src"
    let bookSectionNumberXPath = "/html/body/div[3]/table/tr/td[position() = (last()-1)]"
    
    let pageListXPath = "//*[@id=\"gdt\"]/div"
    let pageHrefXPath = "div/a/@href"
    let Page2ndHrefXPath = "/html/body/div/a/img/@src"
    let pageNumberXPath = "div/a/@href"
    let pageNumberRegEx = "http[s]*://.*/s/.*/\\d*-(\\d*)"
    
    let ScrollLoadOffsetP = CGFloat(100)
    let ScrollLoadOffsetL = CGFloat(50)
    
    static let shared = ConfigurationHelper()
}
