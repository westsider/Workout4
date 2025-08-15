//
//  VideoManager.swift
//  Workout4
//
//  Created by Assistant on Current Date
//

import Foundation
import AVKit

class VideoManager {
    static let shared = VideoManager()
    
    private init() {}
    
    // Get video filename for any exercise based on group and name
    func getVideoFileName(for exerciseName: String, in group: String) -> String? {
        let groupLower = group.lowercased()
        let nameLower = exerciseName.lowercased()
        
        switch groupLower {
        case "falcon":
            switch nameLower {
            case "bb squat":
                return "falcon/barbell-squat"
            case "incline db press":
                return "falcon/incline-db-press"
            case "db seal row":
                return "falcon/db-seal-row"
            case "one arm delta fly's":
                return "falcon/one-arm-delta-flys"
            case "barbell curl":
                return "falcon/barbell-curl"
            default:
                return nil
            }
            
        case "deep horizon":
            switch nameLower {
            case "bulgarian split squat":
                return "deep horizon/bugarian-split-squat"
            case "military press":
                return "deep horizon/military-press"
            case "lat pulldown":
                return "deep horizon/lat-pull-down"
            case "rear delta fly":
                return "deep horizon/rear-delta-fly"
            case "decline sit up":
                return "deep horizon/decline-sit-up"
            default:
                return nil
            }
            
        case "challenger":
            switch nameLower {
            case "leg press":
                return "challenger/leg-press"
            case "incline chest machine":
                return "challenger/inclined-chest-machine"
            case "back row machine":
                return "challenger/back-row-machine"
            case "sholder press machine":
                return "challenger/sholder-press-machine"
            case "leg raises":
                return "challenger/leg-raises"
            default:
                return nil
            }
            
        case "trident":
            switch nameLower {
            case "bb upright row":
                return "trident/bb-upright-row"
            case "bench press":
                return "trident/bench-press"
            case "barbell curls":
                return "trident/barbell-curls"
            case "db flys":
                return "trident/db-flys"
            case "horizontal press":
                return "trident/horizontal-press"
            default:
                return nil
            }
            
        case "stretch":
            switch nameLower {
            case "band pulls":
                return "band_pulls_final"
            case "glute back bridges":
                return "glute-bridges-final"
            case "hip flexor stretch":
                return "hip-flexor-final"
            case "yoga push up":
                return "Yoga-push-up-final"
            case "fire hydrant":
                return "fire-hydrant-final"
            default:
                return nil
            }
            
        default:
            return nil
        }
    }
    
    // Find video URL for an exercise
    func findVideoURL(for exerciseName: String, in group: String) -> URL? {
        guard let videoName = getVideoFileName(for: exerciseName, in: group) else { 
            print("No video mapping for: \(exerciseName) in \(group)")
            return nil 
        }
        
        print("Looking for video: \(videoName)")
        
        // Check if video name contains a folder path
        if videoName.contains("/") {
            // Split by the last "/" to get just the filename
            if let lastSlashIndex = videoName.lastIndex(of: "/") {
                let filename = String(videoName[videoName.index(after: lastSlashIndex)...])
                
                print("Checking for filename: '\(filename)'")
                
                // The videos are copied to the app bundle root, so just look for the filename
                if let url = Bundle.main.url(forResource: filename, withExtension: "mov") {
                    print("Found video in bundle: \(url)")
                    return url
                }
                if let url = Bundle.main.url(forResource: filename, withExtension: "mp4") {
                    print("Found video in bundle: \(url)")
                    return url
                }
            }
        } else {
            // Video is in root (for stretch videos)
            if let url = Bundle.main.url(forResource: videoName, withExtension: "mov") {
                print("Found video in bundle: \(url)")
                return url
            }
            if let url = Bundle.main.url(forResource: videoName, withExtension: "mp4") {
                print("Found video in bundle: \(url)")
                return url
            }
        }
        
        print("Video not found for: \(videoName)")
        print("Available videos can be seen in the debug output above.")
        return nil
    }
    
    // Debug function to list all video files in the bundle
    func listAvailableVideos() {
        print("\n=== Available Videos in Bundle ===")
        
        guard let bundlePath = Bundle.main.resourcePath else {
            print("No bundle resource path found")
            return
        }
        
        print("Bundle path: \(bundlePath)")
        
        let fileManager = FileManager.default
        
        // Check for Videos folder
        let videosPath = "\(bundlePath)/Videos"
        if fileManager.fileExists(atPath: videosPath) {
            print("Videos folder found at: \(videosPath)")
            
            do {
                let contents = try fileManager.contentsOfDirectory(atPath: videosPath)
                print("Contents of Videos folder:")
                for item in contents {
                    print("  - \(item)")
                    
                    // Check if it's a directory
                    let itemPath = "\(videosPath)/\(item)"
                    var isDirectory: ObjCBool = false
                    if fileManager.fileExists(atPath: itemPath, isDirectory: &isDirectory) && isDirectory.boolValue {
                        print("    (folder)")
                        do {
                            let subContents = try fileManager.contentsOfDirectory(atPath: itemPath)
                            for subItem in subContents {
                                print("      - \(subItem)")
                            }
                        } catch {
                            print("      Error reading subfolder: \(error)")
                        }
                    }
                }
            } catch {
                print("Error reading Videos folder: \(error)")
            }
        } else {
            print("Videos folder not found in bundle")
        }
        
        // Also check for videos directly in bundle root
        do {
            let bundleContents = try fileManager.contentsOfDirectory(atPath: bundlePath)
            let videoFiles = bundleContents.filter { $0.hasSuffix(".mov") || $0.hasSuffix(".mp4") }
            if !videoFiles.isEmpty {
                print("\nVideo files in bundle root:")
                for video in videoFiles {
                    print("  - \(video)")
                }
            }
        } catch {
            print("Error reading bundle contents: \(error)")
        }
        
        print("=== End Video List ===\n")
    }
}