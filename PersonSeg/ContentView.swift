//
//  ContentView.swift
//  PersonSeg
//
//  Created by raykim on 1/30/24.
//

import SwiftUI
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

struct ContentView: View {
    @State private var maskImage: UIImage?
    @State private var disImage: UIImage?
    @State private var maskImages: [UIImage] = []
    var body: some View {
        VStack {
            ScrollView {
               ForEach(maskImages, id: \.self) { maskImage in
                   Image(uiImage: maskImage)
                       .resizable()
                       .scaledToFit()
               }
           }
            Button("Load Image and Generate Mask") {
                let image = UIImage(named: "persons")!
                self.disImage = UIImage(named: "persons")
                generatePersonInstanceMasks(for: image) { masks in
                    self.maskImages = masks ?? []
                }
            }
        }
    }
    


    func generatePersonInstanceMasks(for image: UIImage, completion: @escaping ([UIImage]?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }

        let request = VNGeneratePersonInstanceMaskRequest() { request, error in
            if let error = error {
                completion(nil)
                return
            }
            guard let observations = request.results as? [VNInstanceMaskObservation] else {
                completion(nil)
                return
            }
            let context = CIContext()
            var maskImages: [UIImage] = []
            for observation in observations {
                for instance in observation.allInstances {
                    do {
                        let maskBuffer = try observation.generateMask(forInstances: [instance])
                        let ciMaskImage = CIImage(cvPixelBuffer: maskBuffer)
                        
                        // Generate a random color for each mask
                        let color = UIColor(
                            red: CGFloat.random(in: 0...1),
                            green: CGFloat.random(in: 0...1),
                            blue: CGFloat.random(in: 0...1),
                            alpha: 1
                        )
                        let coloredImage = CIImage(color: CIColor(color: color))
                            .cropped(to: ciMaskImage.extent)

                        // Blend the colored image with the mask
                        let blendFilter = CIFilter.blendWithMask()
                        blendFilter.inputImage = coloredImage
                        blendFilter.maskImage = ciMaskImage
                        blendFilter.backgroundImage = CIImage(cgImage: cgImage)

                        if let blendedImage = blendFilter.outputImage,
                           let cgBlendedImage = context.createCGImage(blendedImage, from: blendedImage.extent) {
                            maskImages.append(UIImage(cgImage: cgBlendedImage))
                        }
                    } catch {
                        print("Error generating mask for instance: \(error.localizedDescription)")
                    }
                }
            }
            DispatchQueue.main.async {
                completion(maskImages)
            }
        }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try requestHandler.perform([request])
        } catch {
            print("Error performing request: \(error.localizedDescription)")
            completion(nil)
        }
    }
}

#Preview {
    ContentView()
}
