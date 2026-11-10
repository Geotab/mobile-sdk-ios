import UIKit

/// Fills the bottom safe area (the home indicator region) with the color the web app asks for, so the web app's own
/// bottom bar appears to run to the bottom edge of the screen.
///
/// It only paints. The web view keeps reserving that area exactly as before, so nothing is reserved twice.
final class BottomSafeAreaView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        isUserInteractionEnabled = false
        isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Places the view directly above `sibling`, covering the container's bottom safe area. A view added later above
    /// `sibling` therefore stays on top of it.
    func install(in container: UIView, above sibling: UIView) {
        container.insertSubview(self, aboveSubview: sibling)
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: container.safeAreaLayoutGuide.bottomAnchor),
            bottomAnchor.constraint(equalTo: container.bottomAnchor),
            leadingAnchor.constraint(equalTo: container.leadingAnchor),
            trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])
    }

    /// Nil returns the area to the app's own appearance. Safe to call from any thread.
    func setColor(_ color: UIColor?) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in self?.setColor(color) }
            return
        }
        backgroundColor = color
        isHidden = color == nil
    }
}
