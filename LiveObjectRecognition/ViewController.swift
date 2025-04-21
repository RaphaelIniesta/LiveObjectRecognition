//
//  ViewController.swift
//  LiveObjectRecognition
//
//  Created by Raphael Iniesta Reis on 16/04/25.
//

import UIKit
import AVKit
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    // Essa função é o que inicia a visualização de todos os elementos que aparecerão na tela
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup camera
        let session = AVCaptureSession()
        
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: device) else { return }
        session.addInput(input)
        
        // Envia uma chamada para uma thread em background para evitar que o aplicativo congele
        DispatchQueue.global(qos: .background).async {
            session.startRunning()
        }
        
        // Adiciona uma camada para que possamos ver as imagens da câmera
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        // Dados coletados pela câmera
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        session.addOutput(dataOutput)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        guard let model = try? VNCoreMLModel(for: YOLOv3().model) else { return }
        
        let request = VNCoreMLRequest(model: model) { (finishedRequest, error) in
            
            guard let results = finishedRequest.results as? [VNRecognizedObjectObservation] else { return }
            
            guard let firstResult = results.first else { return }
            
            if let first = firstResult.labels.first {
                print("Object: \(first.identifier) | Confidence: \(firstResult.confidence)")
                print(firstResult.boundingBox.origin.x, firstResult.boundingBox.origin.y)
            } else {
                print("No objects found!")
            }
            
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
    
}
