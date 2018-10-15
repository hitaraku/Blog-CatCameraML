//
//  ViewController.swift
//  Blog-CatCameraML
//
//  Created by Hitaraku on 2018/10/15.
//  Copyright © 2018 Hitaraku. All rights reserved.
//

import UIKit
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource {

    // MARK: - Outlet Objects
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var resultTableView: UITableView!
    
    // MARK: - Model object
    let model = MobileNet()
    
    // MARK: - Result Relation
    var resultArray = [String]()
    var resultOddsArray = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //TODO: Register your MessageCell.xib file here:
        resultTableView.register(UINib(nibName: "CustomResultCell", bundle: nil), forCellReuseIdentifier: "ResultCell")
        
        resultTableView.delegate = self
        resultTableView.dataSource = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - TableView Datasource Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ResultCell", for: indexPath) as! CustomResultCell
        
        cell.resultLabel.text = resultArray[indexPath.row]
        cell.resultOdds.text = resultOddsArray[indexPath.row]
        
        return cell
    }

    
    // MARK: - TableView Delegate Methods
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    /*
     This uses the Vision framework to drive Core ML.
     Note that this actually gives a slightly different prediction. This must
     be related to how the UIImage gets converted.
     */
    func predictUsingVision(image: UIImage) {
        //モデルからコンテナ作成
        guard let visionModel = try? VNCoreMLModel(for: model.model) else {
            fatalError("Someone did a baddie")
        }
        
        // 作成したコンテナからCoreMLに対するリクエストを作成。
        let request = VNCoreMLRequest(model: visionModel) { request, error in
            if let observations = request.results as? [VNClassificationObservation] {
                
                // The observations appear to be sorted by confidence already, so we
                // take the top 3 and map them to an array of (String, Double) tuples.
                let top3 = observations.prefix(through: 2)
                    .map { ($0.identifier, Double($0.confidence)) }
                self.store(results: top3)
                self.resultTableView.reloadData()
            }
        }
        
        request.imageCropAndScaleOption = .centerCrop
        
        let handler = VNImageRequestHandler(cgImage: image.cgImage!)
        try? handler.perform([request])
    }
    
    // MARK: - UI stuff
    
    typealias Prediction = (String, Double)
    
    func store(results: [Prediction]) {
        // delete from Array
        resultArray.removeAll()
        resultOddsArray.removeAll()
        
        for (i, pred) in results.enumerated() {
            let start = pred.0.index(pred.0.startIndex, offsetBy: 9)
            
            // get first keyword
            let resultStr = String(pred.0[start..<pred.0.endIndex])
            var resultStrArr = resultStr.split(separator: " ")
            
            resultArray.append("\(i + 1): " + resultStrArr[0].replacingOccurrences(of: ",", with: ""))
            resultOddsArray.append(String(format: "%3.2f%%", pred.1 * 100))
        }
    }
    
    func top(_ k: Int, _ prob: [String: Double]) -> [Prediction] {
        precondition(k <= prob.count)
        
        return Array(prob.map { x in (x.key, x.value) }
            .sorted(by: { a, b -> Bool in a.1 > b.1 })
            .prefix(through: k - 1))
    }
    
    // MARK: Action
    @IBAction func startPhotoLibrary(_ sender: Any) {
        
        let sourceType: UIImagePickerControllerSourceType = UIImagePickerControllerSourceType.photoLibrary
        
        // check available photoLibrary
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary){
            let photoLibraryPicker = UIImagePickerController()
            photoLibraryPicker.delegate = self;
            photoLibraryPicker.sourceType = .photoLibrary
            self.present(photoLibraryPicker, animated: true, completion: nil)
        } else {
            // error
        }
    }
    
    func imagePickerController(_ imagePicker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageView.contentMode = .scaleAspectFit
            imageView.image = pickedImage
            
            // ML function
            predictUsingVision(image: pickedImage)
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    // cancel take a capture
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

