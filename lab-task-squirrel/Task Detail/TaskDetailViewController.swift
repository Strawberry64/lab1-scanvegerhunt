//
//  TaskDetailViewController.swift
//  lab-task-squirrel
//
//  Created by Charlie Hieger on 11/15/22.
//

import UIKit
import MapKit
import PhotosUI
import CoreLocation


// TODO: Import PhotosUI
// done

class TaskDetailViewController: UIViewController, UINavigationControllerDelegate {

    @IBOutlet private weak var completedImageView: UIImageView!
    @IBOutlet private weak var completedLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var attachPhotoButton: UIButton!

    // MapView outlet
    @IBOutlet private weak var mapView: MKMapView!
    
    @IBOutlet weak var viewPhoto: UIButton!
    
    var task: Task!
    
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        // TODO: Register custom annotation view
        // Register custom annotation view
        mapView.register(TaskAnnotationView.self, forAnnotationViewWithReuseIdentifier: TaskAnnotationView.identifier)

        // TODO: Set mapView delegate
        // Set mapView delegate
        mapView.delegate = self

        // UI Candy
        mapView.layer.cornerRadius = 12


        updateUI()
        updateMapView()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

            // Segue to Detail View Controller
         if segue.identifier == "PhotoSegue" {
             if let photoViewController = segue.destination as? PhotoViewController {
                 photoViewController.task = task
              }
          }
      }
    

    /// Configure UI for the given task
    private func updateUI() {
        titleLabel.text = task.title
        descriptionLabel.text = task.description

        let completedImage = UIImage(systemName: task.isComplete ? "circle.inset.filled" : "circle")

        // calling `withRenderingMode(.alwaysTemplate)` on an image allows for coloring the image via it's `tintColor` property.
        completedImageView.image = completedImage?.withRenderingMode(.alwaysTemplate)
        completedLabel.text = task.isComplete ? "Complete" : "Incomplete"

        let color: UIColor = task.isComplete ? .systemBlue : .tertiaryLabel
        completedImageView.tintColor = color
        completedLabel.textColor = color

        mapView.isHidden = !task.isComplete
        attachPhotoButton.isHidden = task.isComplete
        
        viewPhoto.isHidden = !task.isComplete
    }

    
//    we need to show a pop up, then after a user select an option check if the permission to access photo library and/or camera is granted or not.
    @IBAction func didTapAttachPhotoButton(_ sender: Any) {
        // TODO: Check and/or request photo library access authorization.
        
        // 1. Create the alert controller
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        // 2. Define the action for the Photo Library
        let photoLibraryAction = UIAlertAction(title: "Photo Library", style: .default) { [weak self] _ in
            // This function is called when "Photo Library" is clicked
            self?.tapPhotoLibrary(sender)
        }

        // 3. Define another action (e.g., Camera)
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { [weak self]_ in
            // This function would be called when "Camera" is clicked
            print("Camera option selected")
            self?.tapCameraFeed(sender)
        }

        // 4. Define a cancel action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        // 5. Add actions and present
        alertController.addAction(photoLibraryAction)
        alertController.addAction(cameraAction)
        alertController.addAction(cancelAction)

        present(alertController, animated: true)
        
        

    }
    
    private func tapPhotoLibrary(_ sender: Any){
        if PHPhotoLibrary.authorizationStatus(for: .readWrite) != .authorized {
            // Request photo library access
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
                switch status {
                case .authorized:
                    // The user authorized access to their photo library
                    // show picker (on main thread)
                    DispatchQueue.main.async {
                        self?.presentImagePicker()
                    }
                default:
                    // show settings alert (on main thread)
                    DispatchQueue.main.async {
                        // Helper method to show settings alert
                        self?.presentGoToSettingsAlert()
                    }
                }
            }
        } else {
            // Show photo picker
            presentImagePicker()
        }
    }
    
    private func tapCameraFeed(_ sender: Any){
        
        // 1. Check if camera is available on the device
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            print("Camera not available")
            return
        }
        
        // 2. Check Camera permission
        let statusCamera = AVCaptureDevice.authorizationStatus(for: .video)
        switch statusCamera {
        case .authorized:
            self.requestLocationAndPresentCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.requestLocationAndPresentCamera()
                    }
                }
            }
        default:
            presentGoToSettingsAlert()
        }
    }
    
    private func requestLocationAndPresentCamera() {
            // Check Location permission
            let statusLocation = locationManager.authorizationStatus
            
            if statusLocation == .notDetermined {
                locationManager.requestWhenInUseAuthorization()
            }
            
            // Present camera regardless of location status;
            // if denied, the delegate will use a default CLLocation()
            presentCamera()
        }
        
        
    private func presentCamera() {
        let imagePicker = UIImagePickerController()
            imagePicker.sourceType = .camera
            imagePicker.allowsEditing = true
            imagePicker.delegate = self
            present(imagePicker, animated: true)
    }
    
    
    private func presentImagePicker() {
        // TODO: Create, configure and present image picker.
        // Create a configuration object
        var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())

        // Set the filter to only show images as options (i.e. no videos, etc.).
        config.filter = .images

        // Request the original file format. Fastest method as it avoids transcoding.
        config.preferredAssetRepresentationMode = .current

        // Only allow 1 image to be selected at a time.
        config.selectionLimit = 1

        // Instantiate a picker, passing in the configuration.
        let picker = PHPickerViewController(configuration: config)

        // Set the picker delegate so we can receive whatever image the user picks.
        picker.delegate = self

        // Present the picker.
        present(picker, animated: true)
    }

    func updateMapView() {
        // TODO: Set map viewing region and scale
        // Make sure the task has image location.
        guard let imageLocation = task.imageLocation else { return }

        // Get the coordinate from the image location. This is the latitude / longitude of the location.
        // https://developer.apple.com/documentation/mapkit/mkmapview
        let coordinate = imageLocation.coordinate

        // Set the map view's region based on the coordinate of the image.
        // The span represents the maps's "zoom level". A smaller value yields a more "zoomed in" map area, while a larger value is more "zoomed out".
        let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        mapView.setRegion(region, animated: true)
        // TODO: Add annotation to map view
        // Add an annotation to the map view based on image location.
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }
    
    
}

// TODO: Conform to PHPickerViewControllerDelegate + implement required method(s)

// TODO: Conform to MKMapKitDelegate + implement mapView(_:viewFor:) delegate method.

// Helper methods to present various alerts
extension TaskDetailViewController {

    /// Presents an alert notifying user of photo library access requirement with an option to go to Settings in order to update status.
    func presentGoToSettingsAlert() {
        let alertController = UIAlertController (
            title: "Photo Access Required",
            message: "In order to post a photo to complete a task, we need access to your photo library. You can allow access in Settings",
            preferredStyle: .alert)

        let settingsAction = UIAlertAction(title: "Settings", style: .default) { _ in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }

            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
            }
        }

        alertController.addAction(settingsAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }

    /// Show an alert for the given error
    private func showAlert(for error: Error? = nil) {
        let alertController = UIAlertController(
            title: "Oops...",
            message: "\(error?.localizedDescription ?? "Please try again...")",
            preferredStyle: .alert)

        let action = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(action)

        present(alertController, animated: true)
    }
}


extension TaskDetailViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        //stuff
        // Dismiss the picker
        picker.dismiss(animated: true)

        // Get the selected image asset (we can grab the 1st item in the array since we only allowed a selection limit of 1)
        let result = results.first

        // Get image location
        // PHAsset contains metadata about an image or video (ex. location, size, etc.)
        guard let assetId = result?.assetIdentifier,
              let location = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil).firstObject?.location else {
            return
        }

        print("📍 Image location coordinate: \(location.coordinate)")
        
        
        
        
        
        // Make sure we have a non-nil item provider
        guard let provider = result?.itemProvider,
              // Make sure the provider can load a UIImage
              provider.canLoadObject(ofClass: UIImage.self) else { return }

        // Load a UIImage from the provider
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in

            // Handle any errors
            if let error = error {
              DispatchQueue.main.async { [weak self] in self?.showAlert(for:error) }
            
            }

            // Make sure we can cast the returned object to a UIImage
            guard let image = object as? UIImage else { return }

            print("🌉 We have an image!")

            // UI updates should be done on main thread, hence the use of `DispatchQueue.main.async`
            DispatchQueue.main.async { [weak self] in

                // Set the picked image and location on the task
                self?.task.set(image, with: location)

                // Update the UI since we've updated the task
                self?.updateUI()

                // Update the map view since we now have an image an location
                self?.updateMapView()
            }
        }
    }
    
    
}

extension TaskDetailViewController: MKMapViewDelegate {
    // Implement mapView(_:viewFor:) delegate method.
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

        // Dequeue the annotation view for the specified reuse identifier and annotation.
        // Cast the dequeued annotation view to your specific custom annotation view class, `TaskAnnotationView`
        // 💡 This is very similar to how we get and prepare cells for use in table views.
        guard let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: TaskAnnotationView.identifier, for: annotation) as? TaskAnnotationView else {
            fatalError("Unable to dequeue TaskAnnotationView")
        }

        // Configure the annotation view, passing in the task's image.
        annotationView.configure(with: task.image)
        return annotationView
    }
}

//extension TaskDetailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
//    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//        
//        // 1. Dismiss picker
//        picker.dismiss(animated: true)
//
//        // 2. Extract the image
//        guard let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage else {
//            return
//        }
//
//        // 3. Update task (Note: Camera photos do not contain location metadata by default)
//        // You may need to use CLLocationManager to get current location if task requires it
//        DispatchQueue.main.async { [weak self] in
//            // Using a placeholder location if your task requires one
//            // self?.task.set(image, with: nil)
//            
//            self?.updateUI()
//        }
//    }
//
//    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//        picker.dismiss(animated: true)
//    }
//}

extension TaskDetailViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // 1. Dismiss the camera interface
        picker.dismiss(animated: true)

        // 2. Extract the captured image (prefer edited if available)
        guard let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage else {
            return
        }

        
        let location = currentLocation
        // 3. Update the task and UI on the main thread
        DispatchQueue.main.async { [weak self] in
            // Update the task with the new image.
            // Camera photos don't provide location metadata directly; passing nil.
            self?.task.set(image, with: location)
            
            // Refresh the UI elements
            self?.updateUI()
            
            // Update the map (this will return early if location is nil)
            self?.updateMapView()
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

extension TaskDetailViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get user location: \(error.localizedDescription)")
    }
}
    
