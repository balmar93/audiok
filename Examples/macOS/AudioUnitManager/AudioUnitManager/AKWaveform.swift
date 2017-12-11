//
//  AKWaveform.swift
//  AudioUnitManager
//
//  Created by Ryan Francesconi on 12/7/17.
//  Copyright © 2017 Ryan Francesconi. All rights reserved.
//

import AudioKitUI

/// This is a demo of an Audio Region class. Not for production use... ;)
public class AKWaveform: AKView {
    public var url: URL?
    public var plots = [EZAudioPlot?]()
    public var file: EZAudioFile?
    public var visualScaleFactor: Double = 30
    public var color = NSColor.black
    public weak var delegate: AKWaveformDelegate?
    private var loopStartMarker = LoopMarker(.start)
    private var loopEndMarker = LoopMarker(.end)

    public var displayTimebar: Bool = true {
        didSet {
            timelineBar.isHidden = !displayTimebar
        }
    }

    private var timelineBar = TimelineBar()

    /// position in seconds of the bar
    public var position: Double {
        get {
            return Double(timelineBar.frame.origin.x) / visualScaleFactor
        }

        set {
            timelineBar.frame.origin.x = CGFloat(newValue * visualScaleFactor)
        }
    }

    public var loopStart: Double {
        get {
            return Double(loopStartMarker.frame.origin.x) / visualScaleFactor
        }

        set {
            loopStartMarker.frame.origin.x = CGFloat(newValue * visualScaleFactor)
        }
    }

    public var loopEnd: Double {
        get {
            return Double(loopEndMarker.frame.origin.x + loopEndMarker.frame.width) / visualScaleFactor
        }

        set {
            loopEndMarker.frame.origin.x = CGFloat(newValue * visualScaleFactor) - loopEndMarker.frame.width
        }
    }

    public var isLooping: Bool = false {
        didSet {
            loopStartMarker.isHidden = !isLooping
            loopEndMarker.isHidden = !isLooping
            needsDisplay = true
        }
    }

    public var isReversed: Bool = true {
        didSet {
            for plot in plots {
                if isReversed {
                    plot?.waveformLayer?.transform = CATransform3DMakeRotation(CGFloat(Double.pi), 0, 1, 0)
                } else {
                    //To flip back to normal
                    plot?.waveformLayer?.transform = CATransform3DMakeRotation(0, 0, 1, 0)
                }
            }
        }
    }

    convenience init?(url: URL, color: NSColor = NSColor.black) {
        self.init()
        self.file = EZAudioFile(url: url)
        self.color = color
        if file == nil { return nil }
        initialize()
    }

    private func initialize() {
        frame = NSRect(x: 0, y: 0, width: 200, height: 20)

        guard let file = file else { return }
        guard let data = file.getWaveformData(withNumberOfPoints: 256) else { return }
        guard let leftData = data.buffers?[0] else { return }
        let leftPlot = createPlot(data: leftData, size: data.bufferSize)
        addSubview( leftPlot )
        leftPlot.redraw()
        plots.insert(leftPlot, at: 0)

        // if the file is stereo add a second plot for the right channel
        if file.fileFormat.mChannelsPerFrame > 1, let rightData = data.buffers?[1] {
            let rightPlot = createPlot(data: rightData, size: data.bufferSize)
            addSubview( rightPlot )
            rightPlot.redraw()
            plots.insert(rightPlot, at: 1)
        }

        ////////////
        loopStartMarker.delegate = self
        loopEndMarker.delegate = self
        addSubview(loopStartMarker)
        addSubview(loopEndMarker)
        addSubview(timelineBar)
        isLooping = false
    }

    private func createPlot( data: UnsafeMutablePointer<Float>, size: UInt32 ) -> EZAudioPlot {
        let plot = EZAudioPlot()
        plot.frame = NSRect(x: 0, y: 0, width: 200, height: 20)
        plot.plotType = EZPlotType.buffer
        plot.shouldFill = true
        plot.shouldMirror = true
        plot.color = self.color
        plot.wantsLayer = true
        plot.gain = 1.5 // just make it a bit more present looking

        // customize the waveform
        plot.waveformLayer.fillColor = self.color.cgColor
        plot.waveformLayer.lineWidth = 0.1
        plot.waveformLayer.strokeColor = self.color.withAlphaComponent(0.6).cgColor
        // add a shadow
        plot.waveformLayer.shadowColor = NSColor.black.cgColor
        plot.waveformLayer.shadowOpacity = 0.4
        plot.waveformLayer.shadowOffset = NSSize( width: 1, height: -1 )
        plot.waveformLayer.shadowRadius = 2.0
        plot.updateBuffer( data, withBufferSize: size)
        return plot
    }

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard isLooping else { return }
        let loopShading = NSRect(x: loopStartMarker.frame.origin.x,
                                 y: 0,
                                 width: loopEndMarker.frame.origin.x - loopStartMarker.frame.origin.x +
                                    loopEndMarker.frame.width,
                                 height: frame.height)
        let rectanglePath = NSBezierPath(rect: loopShading)
        let color = NSColor(calibratedRed: 0.975, green: 0.823, blue: 0.573, alpha: 0.328)
        color.setFill()
        rectanglePath.fill()
    }

    public func fitToFrame() {
        guard file != nil, file?.duration != 0 else { return }
        let w = Double(frame.width)
        let scale = w / file!.duration
        visualScaleFactor = scale
        loopEndMarker.frame.origin.x = frame.width - loopEndMarker.frame.width - 3
    }

    override public func setFrameSize(_ newSize: NSSize) {
        guard file != nil else { return }
        super.setFrameSize(newSize)
        guard plots.count > 0 else { return }

        let count = CGFloat(file!.fileFormat.mChannelsPerFrame)

        plots[0]?.frame = NSRect(x: 0,
                                 y: count == 1 ? 0 : newSize.height / count,
                                 width: newSize.width,
                                 height: newSize.height / count)
        plots[0]?.redraw()

        if count > 1 {
            plots[1]?.frame = NSRect(x: 0, y: 0, width: newSize.width, height: newSize.height / count)
            plots[1]?.redraw()
        }
    }

    override public func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        position = mousePositionToTime(with: event)
        delegate?.waveformSelected(source: self, at: position)

    }

    override public func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        delegate?.waveformScrubComplete(source: self, at: position)
    }

    override public func mouseDragged(with event: NSEvent) {
        position = mousePositionToTime(with: event)
        delegate?.waveformScrubbed(source: self, at: position)
        needsDisplay = true
    }

    private func mousePositionToTime(with event: NSEvent) -> Double {
        guard file != nil else { return 0 }
        let loc = convert( event.locationInWindow, from: nil)
        let mouseTime = Double(loc.x / frame.width) * file!.duration
        return mouseTime
    }

    public func dispose() {
        file = nil
        plots.removeAll()
        removeFromSuperview()
    }

}

extension AKWaveform: LoopMarkerDelegate {
    func markerMoved(source: LoopMarker) {
        if source.loopType == .start {
            source.frame.origin.x = max(0, source.frame.origin.x)
            source.frame.origin.x = min(source.frame.origin.x, loopEndMarker.frame.origin.x - loopEndMarker.frame.width)
        } else if source.loopType == .end {
            source.frame.origin.x = max(loopStartMarker.frame.origin.x + loopStartMarker.frame.width,
                                        source.frame.origin.x)
            source.frame.origin.x = min(source.frame.origin.x, frame.width - source.frame.width - 3)
        }
        needsDisplay = true
        delegate?.loopChanged(source: self)
    }
}

public protocol AKWaveformDelegate: class {
    func waveformSelected(source: AKWaveform, at time: Double)
    func waveformScrubbed(source: AKWaveform, at time: Double)
    func waveformScrubComplete(source: AKWaveform, at time: Double)
    func loopChanged(source: AKWaveform)
}

class LoopMarker: AKView {
    public enum MarkerType {
        case start, end
    }

    public weak var delegate: LoopMarkerDelegate?
    public var loopType: MarkerType = .start
    private var mouseDownLocation: NSPoint?

    convenience init(_ loopType: MarkerType) {
        self.init(frame: NSRect(x: 0, y: 0, width: 5, height: 70) )
        self.loopType = loopType
    }

    public func fitToFrame() {
        guard superview != nil else { return }
        frame = NSRect(x: 0, y: 0, width: 6, height: superview!.frame.height)
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        if loopType == .start {
            drawStartRepeat()
        } else if loopType == .end {
            drawEndRepeat()
        }
    }

    fileprivate func drawStartRepeat() {
        NSColor.black.setFill()
        let rectanglePath = NSBezierPath(rect: NSRect(x: 0, y: 0, width: 2, height: 70))
        rectanglePath.fill()

        let rectangle2Path = NSBezierPath(rect: NSRect(x: 0, y: 69, width: 5, height: 2))
        rectangle2Path.fill()

        let rectangle3Path = NSBezierPath(rect: NSRect(x: 0, y: 0, width: 5, height: 2))
        rectangle3Path.fill()
    }

    fileprivate func drawEndRepeat() {
        NSColor.black.setFill()
        let rectanglePath = NSBezierPath(rect: NSRect(x: 3, y: 0, width: 2, height: 70))
        rectanglePath.fill()

        let rectangle2Path = NSBezierPath(rect: NSRect(x: 0, y: 69, width: 5, height: 2))
        rectangle2Path.fill()

        let rectangle3Path = NSBezierPath(rect: NSRect(x: 0, y: 0, width: 5, height: 2))
        rectangle3Path.fill()
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        mouseDownLocation = convert( event.locationInWindow, from: nil)
    }

    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        guard mouseDownLocation != nil else { return }

        let svLocation = convertEventToSuperview( theEvent: event )
        let pt = CGPoint(x: svLocation.x - mouseDownLocation!.x, y: 0)
        setFrameOrigin( pt )
    }

    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        guard superview != nil else { return }
        delegate?.markerMoved(source: self)
    }

    deinit {
        AKLog("* deinit AKWaveform")
    }
}

protocol LoopMarkerDelegate: class {
    func markerMoved(source: LoopMarker)
}

class TimelineBar: AKView {
    private let red = NSColor( red: 0.6, green: 0.3, blue: 0.3, alpha: 0.5 )
    private var rect = NSRect(x: 0, y: 0, width: 2, height: 70)

    convenience init() {
        self.init(frame: NSRect(x: 0, y: 0, width: 2, height: 70) )
    }

    public func updateSize(height: CGFloat = 0) {
        guard self.superview != nil else { return }
        let theHeight = height > 0 ? height : superview!.frame.height
        setFrameSize(NSSize( width: 2, height: theHeight))
        rect = NSRect(x: 0, y: 0, width: 2, height: bounds.height)
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        if let context = NSGraphicsContext.current {
            context.shouldAntialias = false
        }
        red.setFill()
        rect.fill()
    }
}
