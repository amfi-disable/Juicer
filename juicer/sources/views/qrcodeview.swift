import SwiftUI
import CoreImage.CIFilterBuiltins
import AppKit

struct qrcodeview: View {
    @State private var value = "https://"
    @State private var image: NSImage?
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            JuicerFeatureHeader(title: "QR Code Generator", subtitle: "Create a crisp QR code from text, a URL, or contact data.", icon: "qrcode", refreshing: false, action: generate)
            TextField("Text or URL", text: $value)
            HStack { Button("Generate") { generate() }.buttonStyle(.borderedProminent); Button("Copy Image") { copy() }.disabled(image == nil) }
            if let image { Image(nsImage: image).interpolation(.none).resizable().scaledToFit().frame(width: 260, height: 260).background(.white).padding() }
            Spacer()
        }.padding(24).onAppear(perform: generate)
    }
    private func generate() { let filter = CIFilter.qrCodeGenerator(); filter.message = Data(value.utf8); filter.correctionLevel = "M"; guard let output = filter.outputImage, let cg = CIContext().createCGImage(output.transformed(by: CGAffineTransform(scaleX: 8, y: 8)), from: output.extent) else { return }; image = NSImage(cgImage: cg, size: NSSize(width: cg.width, height: cg.height)) }
    private func copy() { guard let image else { return }; NSPasteboard.general.clearContents(); NSPasteboard.general.writeObjects([image]) }
}
