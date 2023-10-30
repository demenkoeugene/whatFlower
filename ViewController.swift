//
//  ViewController.swift
//  whatFlower
//
//  Created by Eugene Demenko on 30.10.2023.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage



class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let wikipediaURL = "https://en.wikipedia.org/w/api.php"
    @IBOutlet weak var imageView: UIImageView!
    var pickedImage : UIImage?
    
    @IBOutlet weak var label: UILabel!
    let imagePicker = UIImagePickerController()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            imageView.image = image
            imagePicker.dismiss(animated: true, completion: nil)
            guard let ciImage = CIImage(image: image) else {
                fatalError("couldn't convert uiimage to CIImage")
            }
            detected(image: ciImage)
        }
    }
    
    
    
    func showAlert(inputText: String){
        let alertView = UIAlertController(title: "Search", message: "It's \(inputText)", preferredStyle: .alert)
        alertView.addAction(UIAlertAction(title: "Done", style: .default))
        
        self.present(alertView, animated: true, completion: nil)
    }
    
    func requestInfo(flowerName: String){
        let parameters : [String:String] = [
            
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimage",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1"
            
        ]
        
        AF.request(wikipediaURL, method: .get, parameters: parameters).responseJSON { response in
            switch response.result {
            case .success:
                print("We got the Wikipedia info")
                
                if let data = response.data {
                    do {
                        let flowerJSON: JSON = try JSON(data: data)
                        print(flowerJSON)
                        
                        if let pageid = flowerJSON["query"]["pageids"][0].string {
                            let flowerDescription = flowerJSON["query"]["pages"][pageid]["extract"].string
                            let flowerImageURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].string
                            
                            self.label.text = flowerDescription
                            
                            self.imageView.sd_setImage(with: URL(string: flowerImageURL ?? "error"), completed: nil)
                        }
                    } catch {
                        print("Error parsing JSON: \(error)")
                    }
                }
                
            case .failure(let error):
                print("Request failed with error: \(error)")
            }
        }
        
        
    }
    func detected(image: CIImage){
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Cannot import model")
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            let classification = request.results?.first as? VNClassificationObservation
            var output = classification?.identifier.capitalized
            self.showAlert(inputText: output ?? "error")
            self.requestInfo(flowerName: classification?.identifier ?? "error")
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        do{
            try handler.perform([request])
        }catch{
            print(error)
        }
        
    }
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false
        present(imagePicker, animated: true, completion: nil)
    }
    
    
    @IBAction func galerryTapped(_ sender: UIBarButtonItem) {
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = false
        present(imagePicker, animated: true, completion: nil)
    }
}

