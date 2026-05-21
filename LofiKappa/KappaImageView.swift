import SwiftUI

struct KappaImageView: View {
    let kappaId: String
    let stage: Int
    
    @ObservedObject var storageManager = SupabaseStorageManager.shared
    
    var body: some View {
        if let imageUrl = SupabaseConfig.imageUrl(for: kappaId, stage: stage) {
            // Supabase Storage から非同期に画像をロード
            AsyncImage(url: imageUrl) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                case .failure(let error):
                    // 読み込みエラー時のプレースホルダー表示
                    let _ = print("🔴 [KappaImageView] Failed to load image. kappaId=\(kappaId), stage=\(stage), url=\(imageUrl), error=\(error)")
                    errorPlaceholderView()
                case .empty:
                    // ロード中のふわっとしたローディングインジケーター
                    loadingIndicatorView()
                @unknown default:
                    errorPlaceholderView()
                }
            }
            .onAppear {
                print("🟢 [KappaImageView] Loading image. kappaId=\(kappaId), stage=\(stage), url=\(imageUrl)")
            }
        } else {
            // URLが生成できなかった場合のプレースホルダー
            let _ = print("🔴 [KappaImageView] URL is nil. kappaId=\(kappaId), stage=\(stage)")
            errorPlaceholderView()
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
        // デモ用画像を使わないため、SF Symbols 等を利用した Lofi 風のプレースホルダーを表示
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
