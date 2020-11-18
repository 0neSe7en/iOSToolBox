//
//  RealtimeLineChart.swift
//  RealtimeLineChart
//
//  Created by Kael Yang on 2020/11/13.
//

import UIKit

public class RealtimeLineChart: UIView {
    public let container = UIView()
    private var pathLayerGroups: [CAShapeLayer] = []
    private var auxiliaryValues: [CGFloat] = []
    public let horizontalAuxiliaryLineLayer = CAShapeLayer()
    private var didDrawXAxis = false
    public let xAxisLayer = CAShapeLayer()

    private var displayLink: CADisplayLink?

    /// Defines the desired frames-per-second for this chart view. (aka CADisplayLink's preferredFramesPerSecond)
    public var fps: Int = 30

    /// The delay of the latest data to be displayed.
    /// Since we need to line to the latest data, we preferred to set it equal to the max duration between two data.
    public var delay: TimeInterval = 1

    /// The duration of the whole chart coverred.
    public var duration: TimeInterval = 10

    /// The maximum value the chart can display.
    public var maxValue: CGFloat = 10

    /// The minimum value the chart can display.
    public var minValue: CGFloat = -10

    private var points: [PointGroup] = []

    private var needRedrawPath = true
    private var pathMinX: CGFloat = 0

    /// The path config
    public struct PathConfig {
        var color: UIColor
        var lineWidth: CGFloat

        public init(color: UIColor, lineWidth: CGFloat) {
            self.color = color
            self.lineWidth = lineWidth
        }
    }

    /// The internal value type.
    private struct PointGroup {
        var xPercentage: CGFloat
        var values: [CGFloat]
        var isPlaceholder: Bool

        static func placeholder(xPercentage: CGFloat, values: [CGFloat]) -> PointGroup {
            return .init(xPercentage: xPercentage, values: values, isPlaceholder: true)
        }
        static func values(xPercentage: CGFloat, values: [CGFloat]) -> PointGroup {
            return .init(xPercentage: xPercentage, values: values, isPlaceholder: false)
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(container)
        container.clipsToBounds = true

        container.layer.addSublayer(horizontalAuxiliaryLineLayer)
        container.layer.addSublayer(xAxisLayer)
        horizontalAuxiliaryLineLayer.fillColor = UIColor.clear.cgColor
        xAxisLayer.fillColor = UIColor.clear.cgColor

        horizontalAuxiliaryLineLayer.strokeColor = UIColor.darkGray.cgColor
        horizontalAuxiliaryLineLayer.lineWidth = 1 / UIScreen.main.scale
        xAxisLayer.strokeColor = UIColor.lightGray.cgColor
        xAxisLayer.lineWidth = 1
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        if container.frame != self.bounds {
            container.frame = self.bounds

            horizontalAuxiliaryLineLayer.frame = container.bounds
            xAxisLayer.frame = container.bounds
            drawAuxiliaryLine(at: auxiliaryValues)
            if didDrawXAxis {
                drawXAxis()
            }
            needRedrawPath = true
        }
    }

    public override func removeFromSuperview() {
        super.removeFromSuperview()
        self.stop()
    }

    public func start() {
        guard displayLink == nil else {
            return
        }
        let new = CADisplayLink(target: self, selector: #selector(RealtimeLineChart.didCall(selectorWithDisplaylink:)))
        new.preferredFramesPerSecond = fps
        new.add(to: RunLoop.main, forMode: .common)
        self.displayLink = new
    }

    public func stop() {
        self.displayLink?.invalidate()
        self.displayLink = nil
    }

    public func preparePath(with configs: [PathConfig]) {
        stop()
        let zeroValue: [CGFloat] = .init(repeating: 0, count: configs.count)
        points = [.values(xPercentage: 0, values: zeroValue), .placeholder(xPercentage: 2, values: zeroValue)]
        self.pathLayerGroups = configs.map { pathConfig in
            let path = CAShapeLayer()
            path.strokeColor = pathConfig.color.cgColor
            path.lineWidth = pathConfig.lineWidth
            path.fillColor = UIColor.clear.cgColor
            path.lineJoin = .round
            container.layer.addSublayer(path)
            return path
        }
    }

    public func addPointGroup(withValues values: [CGFloat]) {
        let fixedValues: [CGFloat]
        switch values.count {
        case pathLayerGroups.count...:
            fixedValues = Array(values.prefix(pathLayerGroups.count))
        default:
            fixedValues = values + .init(repeating: 0, count: pathLayerGroups.count - values.count)
        }

        removeUselessPointGroupIfNeeded()
        if points.last?.isPlaceholder == true {
            points[points.count - 1].xPercentage = 1
        }
        points.append(.values(xPercentage: 1 + CGFloat(delay / duration), values: fixedValues))
        needRedrawPath = true
    }

    public func drawAuxiliaryLine(at values: [CGFloat], pathConfig: PathConfig? = nil) {
        auxiliaryValues = values
        let path = UIBezierPath()
        values.map(y(for:)).forEach { y in
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: container.bounds.width, y: y))
        }
        horizontalAuxiliaryLineLayer.path = path.cgPath
        if let pathConfig = pathConfig {
            horizontalAuxiliaryLineLayer.strokeColor = pathConfig.color.cgColor
            horizontalAuxiliaryLineLayer.lineWidth = pathConfig.lineWidth
        }
    }

    public func drawXAxis() {
        didDrawXAxis = true
        let path = UIBezierPath()
        let zeroY = y(for: 0)
        path.move(to: CGPoint(x: 0, y: zeroY))
        path.addLine(to: CGPoint(x: container.bounds.width, y: zeroY))
        xAxisLayer.path = path.cgPath
    }

    public func removeXAxis() {
        didDrawXAxis = false
        xAxisLayer.path = nil
    }
}

extension RealtimeLineChart {
    @objc func didCall(selectorWithDisplaylink displaylink: CADisplayLink) {
        drawPathIfNeeded()
        shiftData()
    }

    private func removeUselessPointGroupIfNeeded() {
        if let index = points.lastIndex(where: { $0.xPercentage <= 0 }) {
            points.removeFirst(index)
        }
    }

    private func shiftData() {
        let step: CGFloat = 1 / CGFloat(duration) / CGFloat(fps)
        points.indices.forEach { index in
            points[index].xPercentage -= step
        }

        // Add placeholder if needed.
        if points[points.count - 1].xPercentage <= 1 {
            removeUselessPointGroupIfNeeded()
            points.append(.placeholder(xPercentage: 2, values: points[points.count - 1].values))
            needRedrawPath = true
        }
    }

    private func y(for value: CGFloat) -> CGFloat {
        return (value - minValue) / (maxValue - minValue) * container.bounds.height
    }

    private func drawPathIfNeeded() {
        guard pathLayerGroups.count > 0 else {
            return
        }

        if needRedrawPath {
            let paths = (0..<pathLayerGroups.count).map { _ in UIBezierPath() }

            points.enumerated().forEach { offset, pointGroup in
                let x = pointGroup.xPercentage * container.bounds.width

                if offset == 0 {
                    pointGroup.values.enumerated().forEach { pathIndex, value in
                        paths[pathIndex].move(to: CGPoint(x: x, y: y(for: value)))
                    }
                    pathMinX = x
                } else {
                    pointGroup.values.enumerated().forEach { pathIndex, value in
                        paths[pathIndex].addLine(to: CGPoint(x: x, y: y(for: value)))
                    }
                }
            }

            pathLayerGroups.enumerated().forEach { offset, layer in
                layer.path = paths[offset].cgPath
                layer.frame = container.bounds
            }
        } else {
            let x = points[0].xPercentage * container.bounds.width
            pathLayerGroups.forEach { layer in
                layer.frame.origin.x = x - pathMinX
                layer.frame.size.width = container.bounds.width - x
            }
        }
    }
}