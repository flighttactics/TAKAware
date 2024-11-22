//
//  IconDataTests.swift
//  TAKTrackerTests
//
//  Created by Cory Foy on 7/6/24.
//

import Foundation
import XCTest
@testable import TAKAware

final class IconDataTests: TAKAwareTestCase {
    
    var someVar: String?
    
    func testRetrieveIconSets() {
        let iconSets = IconData.availableIconSets()
        XCTAssertEqual(10, iconSets.count, "No Iconsets may have been found")
    }
    
    func buildTestIconFromBase64String(_ iconData: String) -> Icon {
        let imgData = Data(base64Encoded: iconData)!
        let cgDp = CGDataProvider(data: imgData as CFData)!
        let cgImg = CGImage(pngDataProviderSource: cgDp, decode: nil, shouldInterpolate: false, intent: .perceptual)!
        let img = UIImage(cgImage: cgImg)
        let icon = Icon(id: 0, iconset_uid: UUID().uuidString, filename: "none", groupName: "none", icon: img)
        return icon
    }
    
    func testRetrieveIconForIconset() throws {
        let ladderTruckImgData = "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"
        let expectedIcon = buildTestIconFromBase64String(ladderTruckImgData)
        
        let iconString = "de450cbf-2ffc-47fb-bd2b-ba2db89b035e/Resources/ESF4-FIRE-HAZMAT_Aerial-Apparatus-Ladder.png"
        let actualIcon = IconData.iconFor(type2525: "a-F-G", iconsetPath: iconString)
        XCTAssertEqual(actualIcon.icon.pngData(), expectedIcon.icon.pngData())
    }
    
    func testIconForReturnsUnknownMarkerWhenNo2525ImgFound() {
        let unknownCloverImgData = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAIRlWElmTU0AKgAAAAgABQESAAMAAAABAAEAAAEaAAUAAAABAAAASgEbAAUAAAABAAAAUgEoAAMAAAABAAIAAIdpAAQAAAABAAAAWgAAAAAAAABIAAAAAQAAAEgAAAABAAOgAQADAAAAAQABAACgAgAEAAAAAQAAACCgAwAEAAAAAQAAACAAAAAAX7wP8AAAAAlwSFlzAAALEwAACxMBAJqcGAAAABxpRE9UAAAAAgAAAAAAAAAQAAAAKAAAABAAAAAQAAAB/qNiFcEAAAHKSURBVFgJ7FW7TgJBFOW5BrIQpCA0RMJf8EiQQE8DRk20lYoQaSCGxdlf0EIbaCHRH6CVD1BbCBRArzxsEMZ7AhuEgIAunTe5md3Ze885M3Pnrkbzb9vtgJbC3Xq9/kQQDMzhEO/heMYcfTsgR8xOzCqKxoTf76pKUrBXLsd5pXI+guMZcz6f64liLojdqraCfadTvM1mA916PcmHQ4lzLs855vAtkwl0KfaGBOyrJUJrs5nStMKPweCKSBn59QpnHDGIpZxLEqDKcbjDYc9Lu51eQ66IYrzVSnPKeSYBqIm/mckkHMty6H00yq9YtUI8GxHLWOiNco9+y66jRLcoCnGbbe+xWIyOV2/7jPh7TKEQHVPuA2HEgEUOzI3MjjOPRDyvWDmAms3UxqtXRDQaKY5cYOAIpzVhX6fAggrO54ODTifNx+PNt10hXhyBASwqzMH0dlhWijCbjQm6ar1+f121L9/2RfLZO+PABDZxoE8sNbfX66rWakna7p+u2rbkSjzjwEazIvalt+NUkg77kyajJKk7AjuXC/ZIANr2vAmCTkZLnXQ4dYlnRyHzUinGDQYdm2enN/xUqK9/7lpApXI2cjjMd4qALwAAAP//CznKKAAAAcVJREFUzVXNSgJRFFZHJ5QZGUF0Eab0FCNIEj6AG/txYcvcSelGCW3GR6hFtdCtCr2ALqsHqK2KG3Vf+bNQxtM55ZiSlIMjdOFwj3fu+b5zz58Gw3S5XNxdrXaiAOQBQNqQ5KFajSlOp+1G5Z3tLGvKVyoHSLxZB0qlCJjNJmlGrCoMY4jmcsH+eJzb0OslGI1ykM0Ge8h1rPLO7z5R9Dw1Ggl0QN6AEzLU6wnw+z0PSLozTzzTbTZLPJMJ9Pr9C52dkIEw0+lADzlOZ4RLFN7t5q4wFYNuNwWTyeXakSCMTieJod8bEDZy8kt4F44cgmBNhkK7L7K8/1Yshiet1plmR8iGbBHjlbAEYescWRwLTL/8MOE3L8exETS8JyCtrVkohCdkSxiEhUKY2pfVyh5RJBRl9XTQXXo52h5qZ/xp4aMQdjopTMMq3SFDu50CtHlGKHr52stINYGFORwM/uoOGegOFtxwmnPj2uxTAAdW8DW20XuzmYCvYUUT81vojGYI3ZlWu6AXuYpj5zhLXBS3H2malcsRqNViCgnpdEbfeP6zz+2qkd47hdTLMEyUZc0S/qnckpCOZzReKee6hV1v5/8n3gc+jVkHEhBCbgAAAABJRU5ErkJggg=="
        let expectedIcon = buildTestIconFromBase64String(unknownCloverImgData)
        
        let actualIcon = IconData.iconFor(type2525: "a-X-Y-Z", iconsetPath: "")
        XCTAssertEqual(actualIcon.icon.pngData(), expectedIcon.icon.pngData())
    }
    
    func testIconForReturns2525ImgWhenIconsetPopulatedButNotPresent() {
        let hostileGroundImgData = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAIRlWElmTU0AKgAAAAgABQESAAMAAAABAAEAAAEaAAUAAAABAAAASgEbAAUAAAABAAAAUgEoAAMAAAABAAIAAIdpAAQAAAABAAAAWgAAAAAAAABIAAAAAQAAAEgAAAABAAOgAQADAAAAAQABAACgAgAEAAAAAQAAACCgAwAEAAAAAQAAACAAAAAAX7wP8AAAAAlwSFlzAAALEwAACxMBAJqcGAAAABxpRE9UAAAAAgAAAAAAAAAQAAAAKAAAABAAAAAQAAABPNYItl0AAAEISURBVFgJ7JRdCoMwEITFGPAwBuNlin3xpzfQE+hRq7HXSHfTbBG1RFv1qYEQYWlndvZjPe9/vk+AwU8Le/H71MNDxrI0ivqrECrkvAB1fpYDH8WzOB66qtKqrnUh5QNMlGDg8CQCDuK5lD2K67Y1twcTtyRRUEMTwVFJGHHoXN1JvGm0xgtGOkriIBM+dr4oPjKBSZRSDjCiXcfBKfZZ5yROLyQxGcfPYDICzik+MbEHmIw6fwNHIq53nsRmMF+0LwHnEqe6BXPExOpxuIEjEddrk4BxrAZzPXAucarPx/Exie3AkYjrteMYgbnIRH6B3Y4LxWw4159urYMJXNupEANsStwT5jwBAAD//8q1LRoAAAEbSURBVN2UXQ6CMBCECaUJh8FQLqO8KMUbyAngqPLjNeou2aZQ1ILUF0kaKIR+s7PTBoG5imOSdO3tplTTKFXXfges2VeVyg+HAZClwZonFjN2vqTpcPctAuAtwGWaPmLOJSAjg50/RZyxi8yy1psIgHcAvwrRw9pYOZ8jl7MQRYAT/W4RBJdCPMBdhIdL3Os3oxPFHhFkeynEQHBn5bYUptuxOZhL29/23IbacwwmtmN9MKlyChzazuxFt845OlEI0TkzQfAtgVsrZgzmx0yQ7ZOe767cFjcG8+Xu0LabtH/dcxtqz5fnBFU+sf1ncC0m1MHE3YHHq8/AaYjrzlHEKUn6HAYcrwX8sHmfuyCu7xgyScN74Fzw//n+BJokCCgQid0kAAAAAElFTkSuQmCC"
        let expectedIcon = buildTestIconFromBase64String(hostileGroundImgData)
        let actualIcon = IconData.iconFor(type2525: "a-H-G", iconsetPath: "1234abz1234/Fake/Nothing-To-See.png")
        XCTAssertEqual(actualIcon.icon.pngData(), expectedIcon.icon.pngData())
    }
    
    func testIconForReturnsUnknownMarkerWhenIconsetPopulatedButNotPresentAndNo2525ImgFound() {
        let unknownCloverImgData = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAIRlWElmTU0AKgAAAAgABQESAAMAAAABAAEAAAEaAAUAAAABAAAASgEbAAUAAAABAAAAUgEoAAMAAAABAAIAAIdpAAQAAAABAAAAWgAAAAAAAABIAAAAAQAAAEgAAAABAAOgAQADAAAAAQABAACgAgAEAAAAAQAAACCgAwAEAAAAAQAAACAAAAAAX7wP8AAAAAlwSFlzAAALEwAACxMBAJqcGAAAABxpRE9UAAAAAgAAAAAAAAAQAAAAKAAAABAAAAAQAAAB/qNiFcEAAAHKSURBVFgJ7FW7TgJBFOW5BrIQpCA0RMJf8EiQQE8DRk20lYoQaSCGxdlf0EIbaCHRH6CVD1BbCBRArzxsEMZ7AhuEgIAunTe5md3Ze885M3Pnrkbzb9vtgJbC3Xq9/kQQDMzhEO/heMYcfTsgR8xOzCqKxoTf76pKUrBXLsd5pXI+guMZcz6f64liLojdqraCfadTvM1mA916PcmHQ4lzLs855vAtkwl0KfaGBOyrJUJrs5nStMKPweCKSBn59QpnHDGIpZxLEqDKcbjDYc9Lu51eQ66IYrzVSnPKeSYBqIm/mckkHMty6H00yq9YtUI8GxHLWOiNco9+y66jRLcoCnGbbe+xWIyOV2/7jPh7TKEQHVPuA2HEgEUOzI3MjjOPRDyvWDmAms3UxqtXRDQaKY5cYOAIpzVhX6fAggrO54ODTifNx+PNt10hXhyBASwqzMH0dlhWijCbjQm6ar1+f121L9/2RfLZO+PABDZxoE8sNbfX66rWakna7p+u2rbkSjzjwEazIvalt+NUkg77kyajJKk7AjuXC/ZIANr2vAmCTkZLnXQ4dYlnRyHzUinGDQYdm2enN/xUqK9/7lpApXI2cjjMd4qALwAAAP//CznKKAAAAcVJREFUzVXNSgJRFFZHJ5QZGUF0Eab0FCNIEj6AG/txYcvcSelGCW3GR6hFtdCtCr2ALqsHqK2KG3Vf+bNQxtM55ZiSlIMjdOFwj3fu+b5zz58Gw3S5XNxdrXaiAOQBQNqQ5KFajSlOp+1G5Z3tLGvKVyoHSLxZB0qlCJjNJmlGrCoMY4jmcsH+eJzb0OslGI1ykM0Ge8h1rPLO7z5R9Dw1Ggl0QN6AEzLU6wnw+z0PSLozTzzTbTZLPJMJ9Pr9C52dkIEw0+lADzlOZ4RLFN7t5q4wFYNuNwWTyeXakSCMTieJod8bEDZy8kt4F44cgmBNhkK7L7K8/1Yshiet1plmR8iGbBHjlbAEYescWRwLTL/8MOE3L8exETS8JyCtrVkohCdkSxiEhUKY2pfVyh5RJBRl9XTQXXo52h5qZ/xp4aMQdjopTMMq3SFDu50CtHlGKHr52stINYGFORwM/uoOGegOFtxwmnPj2uxTAAdW8DW20XuzmYCvYUUT81vojGYI3ZlWu6AXuYpj5zhLXBS3H2malcsRqNViCgnpdEbfeP6zz+2qkd47hdTLMEyUZc0S/qnckpCOZzReKee6hV1v5/8n3gc+jVkHEhBCbgAAAABJRU5ErkJggg=="
        let expectedIcon = buildTestIconFromBase64String(unknownCloverImgData)
        
        let actualIcon = IconData.iconFor(type2525: "a-X-Y-Z", iconsetPath: "1234abz1234/Fake/Nothing-To-See.png")
        XCTAssertEqual(actualIcon.icon.pngData(), expectedIcon.icon.pngData())
    }
    
    func testParseCotTypeTo2525() {
        let cotType = "a-H-G"
        let expected = "shgp-----------"
        XCTAssertEqual(IconData.mil2525FromCotType(cotType: cotType), expected)
    }
    
    func testParseSfgpiut() {
        let cotType = "a-f-G-I-U-T"
        let expected = "sfgpiut---h----"
        XCTAssertEqual(IconData.mil2525FromCotType(cotType: cotType), expected)
    }
    
    func testParseUnknown2525PrefixedProperly() {
        let cotType = "a-y"
        let expected = "su-------------"
        XCTAssertEqual(IconData.mil2525FromCotType(cotType: cotType), expected)
    }
    
    func testParseCustomIconWithSpaceInName() {
        let hostileGroundImgData = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAIRlWElmTU0AKgAAAAgABQESAAMAAAABAAEAAAEaAAUAAAABAAAASgEbAAUAAAABAAAAUgEoAAMAAAABAAIAAIdpAAQAAAABAAAAWgAAAAAAAABIAAAAAQAAAEgAAAABAAOgAQADAAAAAQABAACgAgAEAAAAAQAAACCgAwAEAAAAAQAAACAAAAAAX7wP8AAAAAlwSFlzAAALEwAACxMBAJqcGAAAABxpRE9UAAAAAgAAAAAAAAAQAAAAKAAAABAAAAAQAAABPNYItl0AAAEISURBVFgJ7JRdCoMwEITFGPAwBuNlin3xpzfQE+hRq7HXSHfTbBG1RFv1qYEQYWlndvZjPe9/vk+AwU8Le/H71MNDxrI0ivqrECrkvAB1fpYDH8WzOB66qtKqrnUh5QNMlGDg8CQCDuK5lD2K67Y1twcTtyRRUEMTwVFJGHHoXN1JvGm0xgtGOkriIBM+dr4oPjKBSZRSDjCiXcfBKfZZ5yROLyQxGcfPYDICzik+MbEHmIw6fwNHIq53nsRmMF+0LwHnEqe6BXPExOpxuIEjEddrk4BxrAZzPXAucarPx/Exie3AkYjrteMYgbnIRH6B3Y4LxWw4159urYMJXNupEANsStwT5jwBAAD//8q1LRoAAAEbSURBVN2UXQ6CMBCECaUJh8FQLqO8KMUbyAngqPLjNeou2aZQ1ILUF0kaKIR+s7PTBoG5imOSdO3tplTTKFXXfges2VeVyg+HAZClwZonFjN2vqTpcPctAuAtwGWaPmLOJSAjg50/RZyxi8yy1psIgHcAvwrRw9pYOZ8jl7MQRYAT/W4RBJdCPMBdhIdL3Os3oxPFHhFkeynEQHBn5bYUptuxOZhL29/23IbacwwmtmN9MKlyChzazuxFt845OlEI0TkzQfAtgVsrZgzmx0yQ7ZOe767cFjcG8+Xu0LabtH/dcxtqz5fnBFU+sf1ncC0m1MHE3YHHq8/AaYjrzlHEKUn6HAYcrwX8sHmfuyCu7xgyScN74Fzw//n+BJokCCgQid0kAAAAAElFTkSuQmCC"
        let expectedIcon = buildTestIconFromBase64String(hostileGroundImgData)
        
        let iconString = "83198b4872a8c34eb9c549da8a4de5a28f07821185b39a2277948f66c24ac17a/GeoOps/Fire Location.png"
        let actualIcon = IconData.iconFor(type2525: "a-H-G", iconsetPath: iconString)
        XCTAssertNotEqual(actualIcon.icon.pngData(), expectedIcon.icon.pngData())
    }
}
