import SwiftUI

struct RipplePoint {
    var x: Float
    var y: Float
    var startTime: Float
}

private let imageNames = ["jellyfish", "frame_art", "nakamojo", "woodie"]

struct ContentView: View {
    @State private var startDate     = Date()
    @State private var ripples       = [RipplePoint]()
    @State private var hasInteracted = false
    @State private var lastPos: CGPoint? = nil
    @State private var imageIndex    = 0
    @State private var viewSize      = CGSize(width: 393, height: 852)

    var body: some View {
        ZStack {
            // Ripple-distorted image background
            imageBackground

            // Bottom UI — image picker dots + hint
            VStack {
                Spacer()
                VStack(spacing: 14) {
                    if !hasInteracted {
                        Text("tap · drag · ripple")
                            .font(.system(size: 10, weight: .light, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.45))
                            .transition(.opacity)
                    }

                    // Image selector dots
                    HStack(spacing: 8) {
                        ForEach(0..<imageNames.count, id: \.self) { i in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    imageIndex = i
                                }
                                // seed a ripple near center on image change
                                let t = Float(Date().timeIntervalSince(startDate))
                                ripples.append(RipplePoint(
                                    x: Float(viewSize.width  * 0.5),
                                    y: Float(viewSize.height * 0.45),
                                    startTime: t
                                ))
                            } label: {
                                Circle()
                                    .fill(i == imageIndex
                                          ? Color.white.opacity(0.75)
                                          : Color.white.opacity(0.22))
                                    .frame(width: i == imageIndex ? 7 : 5,
                                           height: i == imageIndex ? 7 : 5)
                                    .animation(.easeInOut(duration: 0.15), value: imageIndex)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.bottom, 48)
            }
        }
        .ignoresSafeArea()
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { v in
                    hasInteracted = true
                    let loc = v.location
                    let add: Bool
                    if let last = lastPos {
                        add = hypot(loc.x - last.x, loc.y - last.y) > 22
                    } else {
                        add = true
                    }
                    if add {
                        let t = Float(Date().timeIntervalSince(startDate))
                        ripples.append(RipplePoint(x: Float(loc.x), y: Float(loc.y), startTime: t))
                        ripples = ripples.filter { t - $0.startTime < 2.7 }
                        if ripples.count > 24 { ripples.removeFirst(ripples.count - 24) }
                        lastPos = loc
                    }
                }
                .onEnded { _ in lastPos = nil }
        )
        .background(
            GeometryReader { geo in
                Color.clear.onAppear {
                    viewSize = geo.size
                    seed()
                }
            }
        )
    }

    // MARK: — Background

    var imageBackground: some View {
        Image(imageNames[imageIndex])
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
    }

    // MARK: — Helpers

    func packed(at time: Float) -> Data {
        let active = ripples.filter { time - $0.startTime < 2.7 }
        var floats = [Float]()
        floats.reserveCapacity(active.count * 3)
        for r in active { floats += [r.x, r.y, r.startTime] }
        return Data(bytes: floats, count: floats.count * MemoryLayout<Float>.size)
    }

    func seed() {
        let w = viewSize.width, h = viewSize.height
        let seeds: [(Double, CGFloat, CGFloat)] = [
            (0.3,  0.38, 0.42),
            (1.0,  0.62, 0.55),
            (1.65, 0.50, 0.30),
        ]
        for (delay, fx, fy) in seeds {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let t = Float(Date().timeIntervalSince(startDate))
                ripples.append(RipplePoint(x: Float(w * fx), y: Float(h * fy), startTime: t))
            }
        }
    }
}
