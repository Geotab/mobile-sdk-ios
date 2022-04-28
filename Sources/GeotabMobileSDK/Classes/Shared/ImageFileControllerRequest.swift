import Foundation
import UIKit

class ImageFileControllerRequest: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    let imagePicker = UIImagePickerController()
    let sourceType: UIImagePickerController.SourceType
    let viewPresenter: ViewPresenter
    let completed: (ImageFileControllerRequest, Result<UIImage?, Error>) -> Void
    let resizeTo: CGSize?

    init(viewPresenter: ViewPresenter, sourceType: UIImagePickerController.SourceType, resizeTo: CGSize?, completed: @escaping (ImageFileControllerRequest, Result<UIImage?, Error>) -> Void) {
        self.viewPresenter = viewPresenter
        self.sourceType = sourceType
        self.completed = completed
        self.resizeTo = resizeTo
        super.init()
        
    }
    public func captureImage() {
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) == true else {
            completed(self, Result.failure(GeotabDriveErrors.NoImageFileAvailableError))
            return
        }
        imagePicker.sourceType = sourceType
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        viewPresenter.present(imagePicker, animated: true, completion: nil)
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        guard let image = info[UIImagePickerController.InfoKey(rawValue: UIImagePickerController.InfoKey.editedImage.rawValue)] as? UIImage else {
            completed(self, Result.failure(GeotabDriveErrors.CaptureImageError(error: "No image data")))
            return
        }
        completed(self, Result.success(resizeImage(image: image)))
    }
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        completed(self, Result.success(nil))
    }
    
    private func resizeImage(image: UIImage) -> UIImage? {
        guard let resizeTo = resizeTo else {
            return image
        }
        var size = image.size

        let ratio = (resizeTo.width/size.width > resizeTo.height/size.height) ? resizeTo.height/size.height : resizeTo.width/size.width

        size = CGSize(width: size.width * ratio, height: size.height * ratio)

        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)

        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        image.draw(in: rect)
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage
    }
}
