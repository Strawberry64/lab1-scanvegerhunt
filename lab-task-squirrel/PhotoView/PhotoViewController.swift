//
//  PhotoViewController2.swift
//  lab-task-squirrel
//
//  Created by Alexangelo Orozco on 1/29/26.
//

import UIKit



class PhotoViewController: UIViewController {
    
    @IBOutlet weak var photoView: UIImageView!
    
    var task: Task!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        photoView.image = task.image
    }
}
