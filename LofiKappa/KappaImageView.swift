import SwiftUI

// MARK: - Image Loader with retry & in-memory cache

/// AsyncImage はスワイプ中のビュー破棄でリクエストがキャンセル（Code=-999）されると
/// エラー状態のまま永久に止まってしまう問題があるため、
/// 自前でダウンロード＋キャッシュ＋リトライを行うローダーを使用する。
final class KappaImageLoader: ObservableObject {
    @Published var uiImage: UIImage?
    @Published var isLoading = false
    @Published var hasFailed = false
    
    private var currentUrl: URL?
    private var task: URLSessionDataTask?
    private var retryCount = 0
    private let maxRetries = 3
    
    // アプリ全体で共有するインメモリキャッシュ
    private static var cache = NSCache<NSURL, UIImage>()
    
    /// URLを受け取って画像をロードする。URLが変わった場合は前のタスクをキャンセルして新しくロードする。
    func load(url: URL) {
        // 同じURLを再度リクエストされた場合、すでに画像があればスキップ
        if url == currentUrl, uiImage != nil { return }
        
        // URLが変わった場合はリセット
        if url != currentUrl {
            cancel()
            currentUrl = url
            uiImage = nil
            hasFailed = false
            retryCount = 0
            
            // キャッシュにヒットすれば即座に返す
            if let cached = Self.cache.object(forKey: url as NSURL) {
                self.uiImage = cached
                return
            }
        }
        
        guard !isLoading else { return }
        
        isLoading = true
        hasFailed = false
        
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        
        task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                // URLが途中で変わっていたら、この結果は捨てる
                guard self.currentUrl == url else {
                    self.isLoading = false
                    return
                }
                self.isLoading = false
                
                // ダウンロード成功
                if let data = data, let image = UIImage(data: data) {
                    Self.cache.setObject(image, forKey: url as NSURL)
                    self.uiImage = image
                    self.retryCount = 0
                    return
                }
                
                // キャンセルエラーの場合は自動リトライ
                if let nsError = error as? NSError, nsError.code == NSURLErrorCancelled {
                    if self.retryCount < self.maxRetries {
                        self.retryCount += 1
                        print("🔄 [KappaImageLoader] Cancelled, retrying (\(self.retryCount)/\(self.maxRetries))... url=\(url)")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 * Double(self.retryCount)) {
                            self.load(url: url)
                        }
                        return
                    }
                }
                
                // その他のエラー
                if let error = error {
                    print("🔴 [KappaImageLoader] Failed to load image. url=\(url), error=\(error)")
                    if self.retryCount < self.maxRetries {
                        self.retryCount += 1
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 * Double(self.retryCount)) {
                            self.load(url: url)
                        }
                        return
                    }
                }
                
                self.hasFailed = true
            }
        }
        task?.resume()
    }
    
    func cancel() {
        task?.cancel()
        task = nil
        isLoading = false
    }
}

// MARK: - KappaImageView

struct KappaImageView: View {
    let kappaId: String
    let stage: Int
    
    @StateObject private var loader = KappaImageLoader()
    
    private var imageUrl: URL? {
        SupabaseConfig.imageUrl(for: kappaId, stage: stage)
    }
    
    var body: some View {
        Group {
            if let uiImage = loader.uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else if loader.hasFailed {
                errorPlaceholderView()
            } else {
                loadingIndicatorView()
            }
        }
        .onAppear {
            loadCurrentImage()
        }
        .onChange(of: stage) { _ in
            loadCurrentImage()
        }
        .onChange(of: kappaId) { _ in
            loadCurrentImage()
        }
    }
    
    private func loadCurrentImage() {
        if let url = imageUrl {
            loader.load(url: url)
        }
    }
    
    @ViewBuilder
    private func loadingIndicatorView() -> some View {
        ZStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.primaryBlue))
                .scaleEffect(1.2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func errorPlaceholderView() -> some View {
        VStack(spacing: 8) {
            Image(systemName: "photo")
                .font(.system(size: 32))
                .foregroundColor(Theme.Colors.primaryBlue.opacity(0.6))
            Text("No Image")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(Theme.Colors.primaryBlue.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.Colors.primaryBlue.opacity(0.15), lineWidth: 1)
        )
    }
}
