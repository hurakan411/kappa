import SwiftUI

struct PolicyDocumentView: View {
    let title: String
    let content: String
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                // 手帳テイスト背景
                TimeLightingBackground()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // 可愛いかっぱ風の飾り
                        HStack(spacing: 8) {
                            Image(systemName: "doc.text.image.fill")
                                .font(.title3)
                                .foregroundColor(Theme.Colors.primaryBlue)
                            Text(title)
                                .font(.system(.title2, design: .rounded).bold())
                                .foregroundColor(Theme.Colors.text(for: colorScheme))
                            Spacer()
                        }
                        .padding(.bottom, 8)
                        
                        HandDrawnDivider(color: Theme.Colors.text(for: colorScheme).opacity(0.18))
                        
                        // 本文テキスト
                        Text(content)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(Theme.Colors.text(for: colorScheme).opacity(0.9))
                            .lineSpacing(6)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(24)
                    .background(Theme.Colors.card(for: colorScheme))
                    .cornerRadius(20)
                    .handDrawnBorder(color: Theme.Colors.text(for: colorScheme).opacity(0.15), cornerRadius: 20)
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.06), radius: 10, x: 0, y: 4)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(AppTexts.closeBtnText) {
                        dismiss()
                    }
                    .font(.system(.body, design: .rounded).bold())
                    .foregroundColor(Theme.Colors.primaryBlue)
                }
            }
        }
    }
}

struct PolicyTexts {
    static let termsOfService = """
【利用規約】

本利用規約（以下、「本規約」といいます。）は、本アプリ「KapStation | Kappa Water Station」（以下、「本アプリ」といいます。）の提供するサービス（以下、「本サービス」といいます。）の利用条件を定めるものです。ユーザーの皆様には、本規約に従って本サービスをご利用いただきます。

1. はじめに
本アプリは、ユーザーの日々の水分補給を楽しく記録・習慣化し、キャラクター（かっぱ）の育成を楽しむためのヘルスケア・サポートアプリです。

2. 免責事項
・本アプリが算出および提示する「目標水分量」は、一般的な推奨値や簡易的なアンケート結果に基づく目安であり、医学的な診断や専門的なアドバイスに代わるものではありません。
・体調、気候、持病、服薬状況などによって適切な水分量は個別に異なります。ご利用にあたっては、ユーザーご自身の体調を最優先し、必要に応じて医師等の専門家にご相談ください。
・本アプリの使用によって生じた健康上の問題、不利益、損害等について、開発者は一切の責任を負いかねます。

3. 利用許諾と知的財産権
・本アプリに含まれる画像（かっぱのイラスト等）、テキスト、プログラム等のすべての知的財産権は、開発者または正当な権利者に帰属します。
・ユーザーは、私的利用の範囲に限定して本アプリをご利用いただけます。商用利用、転載、解析（逆コンパイル等）は禁止します。

4. データの管理
・本アプリが記録する給水ログやユーザー設定は、端末内のデータベース（SwiftData / UserDefaults）に保存されます。端末の紛失やアプリの削除によってデータが消失した場合の復元はできませんのでご了承ください。

5. 規約の変更
開発者は、事前通知なく本規約を変更できるものとします。変更後の規約は、本アプリ内に掲載された時点から効力を生じるものとします。
"""

    static let privacyPolicy = """
【プライバシーポリシー】

本アプリは、ユーザーの皆様の個人情報の保護を極めて重要視し、以下のように取り扱います。

1. 個人情報の収集について
本アプリは、ユーザーの氏名、メールアドレス、電話番号、位置情報など、個人を直接特定できる情報の収集は一切行いません。

2. アプリ内データの保存について
・ユーザーが入力した体重、性別、日々の給水履歴、目標水分量、解放された図鑑データは、すべてユーザーのデバイス内（SwiftDataおよびUserDefaultsを用いたローカルストレージ）にのみ保存されます。
・これらのデータが開発者のサーバーや第三者へ無断で送信されることはありません。

3. ネットワーク通信について
・本アプリは、かっぱのイラスト画像などをクラウドストレージ（Supabase）から安全に取得・ダウンロードするためにインターネット接続を使用します。
・この通信において、ユーザーの個人情報やプライベートな活動データが送信されることはありません。

4. 法令の遵守と改訂
・本アプリは、適用される日本の個人情報保護法その他の関係法令を遵守します。
・本プライバシーポリシーは、アプリの機能追加や法令の変更に伴い、予告なく改訂されることがあります。
"""
}
