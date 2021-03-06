import Foundation
import AVFoundation
import UIKit
import MozjpegBinding

public func extractImageExtraScans(_ data: Data) -> [Int] {
    return extractJPEGDataScans(data).map { item in
        return item.intValue
    }
}

public func compressImageToJPEG(_ image: UIImage, quality: Float) -> Data? {
    if let result = compressJPEGData(image) {
        return result
    }
    
    let data = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(data as CFMutableData, "public.jpeg" as CFString, 1, nil) else {
        return nil
    }
    
    let options = NSMutableDictionary()
    options.setObject(quality as NSNumber, forKey: kCGImageDestinationLossyCompressionQuality as NSString)
    
    guard let cgImage = image.cgImage else {
        return nil
    }
    CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
    CGImageDestinationFinalize(destination)
    
    if data.length == 0 {
        return nil
    }
    
    return data as Data
}

@available(iOSApplicationExtension 11.0, iOS 11.0, *)
public func compressImage(_ image: UIImage, quality: Float) -> Data? {
    let data = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(data as CFMutableData, AVFileType.heic as CFString, 1, nil) else {
        return nil
    }
    
    let options = NSMutableDictionary()
    options.setObject(quality as NSNumber, forKey: kCGImageDestinationLossyCompressionQuality as NSString)
    
    guard let cgImage = image.cgImage else {
        return nil
    }
    CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
    CGImageDestinationFinalize(destination)
    
    if data.length == 0 {
        return nil
    }
    
    return data as Data
}

public func compressImageMiniThumbnail(_ image: UIImage) -> Data? {
    return compressMiniThumbnail(image)
}
