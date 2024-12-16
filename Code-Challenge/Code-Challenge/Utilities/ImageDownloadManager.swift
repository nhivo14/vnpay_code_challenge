//
//  ImageDownloadManager.swift
//  Code-Challenge
//
//  Created by Nhi on 12/16/24.
//

import UIKit

class ImageDownloadManager {
    static let shared = ImageDownloadManager()
    private init() {
    }

    private var tasks: [String: URLSessionDataTask] = [:]
    private let cache = NSCache<NSString, UIImage>()
    
    // Download image from url
    func downloadImage(with url: URL, placeholder: UIImage? = UIImage(named: "placeholder"), completion: @escaping (UIImage?) -> Void) {
        let cacheKey = url.absoluteString
        
        // Check if the image is already cached
        if let cachedImage = cache.object(forKey: cacheKey as NSString) {
            completion(cachedImage)
            return
        }
        
        // Check if image is downloading, if it is -> continue
        if let existingTask = tasks[cacheKey] {
            existingTask.resume()
            return
        }
        
        // Create download image task
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            defer { self.tasks.removeValue(forKey: cacheKey) }
            
            if let data = data, let image = UIImage(data: data) {
                // Lưu ảnh vào cache
                self.cache.setObject(image, forKey: cacheKey as NSString)
                completion(image)
            } else {
                completion(placeholder)
            }
        }
        
        tasks[cacheKey] = task
        task.resume() // Start downloading
    }
    
    // Cancel downloading
    func cancelDownload(for url: URL) {
        let cacheKey = url.absoluteString
        if let task = tasks[cacheKey] {
            task.cancel()
            tasks.removeValue(forKey: cacheKey)
        }
    }
    
    // Pause downloading
    func pauseDownload(for url: URL) {
        let cacheKey = url.absoluteString
        tasks[cacheKey]?.suspend()
    }
    
    // Continue downloading
    func resumeDownload(for url: URL) {
        let cacheKey = url.absoluteString
        tasks[cacheKey]?.resume()
    }
    
    func getCachedImage(with cacheKey: String) -> UIImage? {
        if let cachedImage = cache.object(forKey: cacheKey as NSString) {
            return cachedImage
        }
        return nil
    }
    
}
