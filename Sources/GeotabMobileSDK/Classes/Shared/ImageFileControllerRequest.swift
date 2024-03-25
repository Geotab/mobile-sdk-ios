import Foundation
import UIKit

class ImageFileControllerRequest: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    let imagePicker = UIImagePickerController()
    let sourceType: UIImagePickerController.SourceType
    let viewPresenter: ViewPresenter
    var completion: ((Result<UIImage?, Error>) -> Void)?
    var resizeTo: CGSize?

    init(viewPresenter: ViewPresenter, sourceType: UIImagePickerController.SourceType) {
        self.viewPresenter = viewPresenter
        self.sourceType = sourceType
        super.init()
        
    }
    
    public func captureImage(resizeTo: CGSize?, completion: ((Result<UIImage?, Error>) -> Void)?) {
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) == true else {
            completion?(.failure(GeotabDriveErrors.NoImageFileAvailableError))
            return
        }
        self.completion = completion
        self.resizeTo = resizeTo
        imagePicker.sourceType = sourceType
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        viewPresenter.present(imagePicker, animated: true, completion: nil)
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        guard let image = info[UIImagePickerController.InfoKey(rawValue: UIImagePickerController.InfoKey.editedImage.rawValue)] as? UIImage else {
            completion?(Result.failure(GeotabDriveErrors.CaptureImageError(error: "No image data")))
            return
        }
        completion?(Result.success(resizeImage(image: image)))
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        completion?(Result.success(nil))
    }
    
    private func resizeImage(image: UIImage) -> UIImage? {
        guard let resizeTo = resizeTo else {
            return image
        }
        var size = image.size

        let ratio = (resizeTo.width/size.width > resizeTo.height/size.height) ? resizeTo.height/size.height : resizeTo.width/size.width

        size = CGSize(width: size.width * ratio, height: size.height * ratio)

        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = 1
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let resizedImage = renderer.image { (_) in
            image.draw(in: rect)
        }

        return resizedImage
    }
}
