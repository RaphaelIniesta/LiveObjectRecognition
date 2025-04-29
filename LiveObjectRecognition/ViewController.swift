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
    
    var boundingBoxes: [UIView] = []
    
    // Essa função é o que inicia a visualização de todos os elementos que aparecerão na tela
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        // Setup camera
//        let session = AVCaptureSession()
//        
//        guard let device = AVCaptureDevice.default(for: .video) else { return }
//        guard let input = try? AVCaptureDeviceInput(device: device) else { return }
//        session.addInput(input)
//        
//        // Envia uma chamada para uma thread em background para evitar que o aplicativo congele
//        DispatchQueue.global(qos: .background).async {
//            session.startRunning()
//        }
//        
//        // Adiciona uma camada para que possamos ver as imagens da câmera
//        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
//        view.layer.addSublayer(previewLayer)
//        previewLayer.frame = view.frame
//        
//        // Dados coletados pela câmera
//        let dataOutput = AVCaptureVideoDataOutput()
//        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
//        session.addOutput(dataOutput)
        
        Task {
            do {
                let quantidade = try await fetchPessoas()
                print(quantidade)
            } catch {
                print("Error: \(error)")
            }
        }
    }
    
    func removeBoundingBoxes() {
        for box in boundingBoxes {
            box.removeFromSuperview()
        }
        boundingBoxes.removeAll()
    }
    
    func drawBoundingBox(_ boundingBox: CGRect, identifier: String, confidence: VNConfidence) {
        let frameWidth = view.bounds.width
        let frameHeight = view.bounds.height
        
        // A boundingBox do Vision está no formato [0,1], com origem no canto inferior esquerdo.
        let x = boundingBox.origin.x * frameWidth
        let height = boundingBox.size.height * frameHeight
        let y = (1 - boundingBox.origin.y - boundingBox.size.height) * frameHeight
        let width = boundingBox.size.width * frameWidth
        
        let boxView = UIView(frame: CGRect(x: x, y: y, width: width, height: height))
        boxView.layer.borderColor = UIColor.red.cgColor
        boxView.layer.borderWidth = 2
        boxView.backgroundColor = UIColor.clear
        
        // Opcional: label com o nome e confiança
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: 20))
        label.backgroundColor = UIColor.red.withAlphaComponent(0.6)
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 12)
        label.text = "\(identifier) (\(Int(confidence * 100))%)"
        boxView.addSubview(label)
        
        view.addSubview(boxView)
        boundingBoxes.append(boxView)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let model = try? VNCoreMLModel(for: YOLOv3().model) else { return }
        
        let request = VNCoreMLRequest(model: model) { [weak self] (finishedRequest, error) in
            guard let results = finishedRequest.results as? [VNRecognizedObjectObservation], let self = self else { return }
            
            DispatchQueue.main.async {
                self.removeBoundingBoxes()
                for result in results {
                    if let label = result.labels.first, label.identifier == "person", result.confidence > 0.5 {
                        self.drawBoundingBox(result.boundingBox, identifier: label.identifier, confidence: result.confidence)
                    }
                }
            }
        }
        
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
    
}
