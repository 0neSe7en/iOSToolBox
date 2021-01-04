//
//  ContinuousPath.swift
//  ContinuousPath
//
//  Created by Kael Yang on 2020/11/19.
//

public extension UIBezierPath {
    enum ContinuousCorner {
        case topLeft, topRight, bottomLeft, bottomRight

        var signConfig: (xSign: Bool, ySign: Bool, reversedClockwise: Bool) {
            switch self {
            case .topLeft: return (true, true, false)
            case .topRight: return (false, true, true)
            case .bottomLeft: return (true, false, true)
            case .bottomRight: return (false, false, false)
            }
        }
    }

    private static let coefficients: [CGFloat] = [1.528665, 1.088492957618529, 0.868406944063002, 0.631493792830993, 0.372823826625747, 0.16905955604437, 0.074911387847016]

    func iOSContinuousCurveEnd(cornerPoint: CGPoint, cornerType: ContinuousCorner, cornerRadius: CGFloat, clockwise: Bool) -> CGPoint {
        let cornerCoefficient = Self.coefficients[0]

        let signConfig = cornerType.signConfig
        let realClockwise = (signConfig.reversedClockwise != clockwise)

        let xValue, yValue: CGFloat
        let corner = cornerRadius * cornerCoefficient
        if realClockwise {
            (xValue, yValue) = (corner, 0)
        } else {
            (xValue, yValue) = (0, corner)
        }

        return CGPoint(x: cornerPoint.x + (signConfig.xSign ? xValue : -xValue), y: cornerPoint.y + (signConfig.ySign ? yValue : -yValue))
    }

    func addiOSContinuousCurve(shouldLineToPathStart lineToPathStart: Bool, cornerPoint: CGPoint, cornerType: ContinuousCorner, cornerRadius: CGFloat, clockwise: Bool) {
        let calculatingHelpers: [CGFloat] = Self.coefficients.map { $0 * cornerRadius } + [0, 0, 0]

        let signConfig = cornerType.signConfig

        let pointCount = 10

        let realClockwise = (signConfig.reversedClockwise != clockwise)
        let points: [CGPoint] = {
            if realClockwise {
                return (0 ..< pointCount).map { index -> CGPoint in
                    let reversedIndex = pointCount - index - 1
                    return CGPoint(x: cornerPoint.x + (signConfig.xSign ? calculatingHelpers[reversedIndex] : -calculatingHelpers[reversedIndex]), y: cornerPoint.y + (signConfig.ySign ? calculatingHelpers[index] : -calculatingHelpers[index]))
                }
            } else {
                return (0 ..< pointCount).map { index -> CGPoint in
                    let reversedIndex = pointCount - index - 1
                    return CGPoint(x: cornerPoint.x + (signConfig.xSign ? calculatingHelpers[index] : -calculatingHelpers[index]), y: cornerPoint.y + (signConfig.ySign ? calculatingHelpers[reversedIndex] : -calculatingHelpers[reversedIndex]))
                }
            }
        }()

        if lineToPathStart {
            addLine(to: points[0])
        } else {
            move(to: points[0])
        }

        let curveCount = 3
        (0 ..< curveCount).forEach { curveIndex in
            self.addCurve(to: points[3 + curveIndex * 3], controlPoint1: points[1 + curveIndex * 3], controlPoint2: points[2 + curveIndex * 3])
            if curveIndex == 0 {
                self.addLine(to: points[3 + curveIndex * 3]) // Apple add this line to path, but we don't know why :( .
            }
        }
    }
}

let bezierPath = UIBezierPath()
bezierPath.addiOSContinuousCurve(shouldLineToPathStart: false, cornerPoint: CGPoint.zero, cornerType: .topLeft, cornerRadius: 10, clockwise: true)
print(bezierPath)
