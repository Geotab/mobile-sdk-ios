import UIKit

class ImageAccessHelper: ImageAccessing {
    
    private let sourceType: UIImagePickerController.SourceType
    private weak var viewPresenter: (any ViewPresenter)?

    private var requests: [ImageFileControllerRequest] = []

    init(viewPresenter: any ViewPresenter, sourceType: UIImagePickerController.SourceType) {
        self.viewPresenter = viewPresenter
        self.sourceType = sourceType
    }

    func requestImage(resizeTo: CGSize?, completion: ((Result<UIImage?, any Error>) -> Void)?) {
        guard let viewPresenter else {
            completion?(.failure(GeotabDriveErrors.InvalidObjectError))
            return
        }
        
        let request = ImageFileControllerRequest(viewPresenter: viewPresenter, sourceType: sourceType)
        requests.append(request)
        request.captureImage(resizeTo: resizeTo) { [weak self] result in
            guard let self = self else {
                completion?(.failure(GeotabDriveErrors.InvalidObjectError))
                return
            }
            self.requests.removeAll { $0 == request}
            completion?(result)
        }
    }
}
