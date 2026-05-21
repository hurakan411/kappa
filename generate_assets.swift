import Cocoa

let kappas = [
    "raincoat", "hojicha", "lofi", "salaryman", "book",
    "onigiri", "sauna", "hoodie", "gamer", "cardboard"
]

let stages = [1, 2, 3, 4, 5]

let fm = FileManager.default
let outputDir = URL(fileURLWithPath: "./LofiKappa/Assets.xcassets")

for kappa in kappas {
    for stage in stages {
        let name = "kappa_\(kappa)_stage\(stage)"
        let imagesetDir = outputDir.appendingPathComponent("\(name).imageset")
        try? fm.createDirectory(at: imagesetDir, withIntermediateDirectories: true)
        
        let contents = """
        {
          "images" : [
            {
              "filename" : "\(name).png",
              "idiom" : "universal",
              "scale" : "1x"
            }
          ],
          "info" : {
            "author" : "xcode",
            "version" : 1
          }
        }
        """
        try? contents.write(to: imagesetDir.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
        
        // Create an image
        let size = NSSize(width: 400, height: 400)
        let image = NSImage(size: size)
        image.lockFocus()
        
        // Background
        NSColor(calibratedRed: 0.73, green: 0.9, blue: 0.99, alpha: 1.0).set() // Light blue
        let rect = NSRect(origin: .zero, size: size)
        NSBezierPath(roundedRect: rect, xRadius: 40, yRadius: 40).fill()
        
        // Text
        let text = "\(kappa)\nStage \(stage)"
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 40, weight: .bold),
            .foregroundColor: NSColor.black,
            .paragraphStyle: paragraphStyle
        ]
        
        text.draw(in: NSRect(x: 0, y: 150, width: 400, height: 100), withAttributes: attributes)
        
        image.unlockFocus()
        
        if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
            if let pngData = bitmapRep.representation(using: .png, properties: [:]) {
                try? pngData.write(to: imagesetDir.appendingPathComponent("\(name).png"))
            }
        }
    }
}

print("Generated 50 assets successfully.")
