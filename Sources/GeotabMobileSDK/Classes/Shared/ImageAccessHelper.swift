import UIKit

class ImageAccessHelper: ImageAccessing {
    
    private let sourceType: UIImagePickerController.SourceType
    private let viewPresenter: ViewPresenter

    private var requests: [ImageFileControllerRequest] = []

    init(viewPresenter: ViewPresenter, sourceType: UIImagePickerController.SourceType) {
        self.viewPresenter = viewPresenter
        self.sourceType = sourceType
    }

    func requestImage(resizeTo: CGSize?, completion: ((Result<UIImage?, Error>) -> Void)?) {
        let request = ImageFileControllerRequest(viewPresenter: viewPresenter, sourceType: sourceType)
        requests.append(request)
        request.captureImage(resizeTo: resizeTo) { [weak self] result in
            guard let self = self else {
                return
            }
            self.requests.removeAll { $0 == request}
            completion?(result)
        }
    }
}
