import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    let name: String
    var loopMode: LottieLoopMode = .loop

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        
        let animationView = LottieAnimationView()
        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)
        
        NSLayoutConstraint.activate([
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor),
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
            animationView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            animationView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // .lottie (dotLottie) ファイルの読み込み
        DotLottieFile.named(name) { result in
            switch result {
            case .success(let dotLottieFile):
                animationView.loadAnimation(from: dotLottieFile)
                animationView.loopMode = loopMode
                animationView.play()
            case .failure(let error):
                // dotLottieのロードに失敗した場合、通常のJSONアニメーションとしての読み込みを試みる
                print("Failed to load dotLottie, trying fallback JSON: \(error)")
                animationView.animation = LottieAnimation.named(name)
                animationView.loopMode = loopMode
                animationView.play()
            }
        }
        
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
