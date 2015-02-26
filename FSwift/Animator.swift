//
//  Animation.swift
//  FSwift
//
//  Created by Maxime Ollivier on 2/23/15.
//  Copyright (c) 2015 Kelton. All rights reserved.
//

import UIKit

public enum QueueItem {
    case Then(duration:CFTimeInterval, block:()->())
    case Now(block:()->())
    case ThenQueue(Queue)
    case ThenQueues([Queue])
    case Also(block:(duration:CFTimeInterval)->())
    case AlsoQueue(Queue)
    case StepBack(duration:CFTimeInterval)
}

public class Queue {
    
    private var _items:[QueueItem] = []
    private var _onCompletion:(()->())?

    public init() {
        
    }
    
    public func then(duration:CFTimeInterval, block:()->()) -> Queue {
        _items.append(QueueItem.Then(duration: duration, block: block))
        return self
    }
    
    public func now(block:()->()) -> Queue {
        _items.append(QueueItem.Now(block: block))
        return self
    }
    
    public func thenQueue(q:Queue) -> Queue {
        _items.append(QueueItem.ThenQueue(q))
        return self
    }
    
    public func thenQueues(qs:[Queue]) -> Queue {
        _items.append(QueueItem.ThenQueues(qs))
        return self
    }
    
    public func also(block:(duration:CFTimeInterval)->()) -> Queue {
        _items.append(QueueItem.Also(block: block))
        return self
    }
    
    public func alsoQueue(q:Queue) -> Queue {
        _items.append(QueueItem.AlsoQueue(q))
        return self
    }
    
    public func stepback(duration:CFTimeInterval) -> Queue {
        _items.append(QueueItem.StepBack(duration: duration))
        return self
    }
    
    public func addItem(item:QueueItem) -> Queue {
        _items.append(item)
        return self
    }
    
    private var currentTime:CFTimeInterval = 0
    private var currentDuration:CFTimeInterval = 0
    
    public func begin() {
        for item in _items {
            playItem(item)
        }
    }
    
    private func playItem(item:QueueItem) {
        
        switch item {
        case .Then(duration: let duration, block: let block):
            currentTime = currentTime + currentDuration
            currentDuration = duration
            delay(currentTime, block)
            
        case .ThenQueue(let queue):
            currentTime = currentTime + currentDuration
            currentDuration = queue.totalDuration
            delay(currentTime) {queue.begin()}
            
        case .ThenQueues(let qs):
            currentTime = currentTime + currentDuration
            currentDuration = maxTimeOfQueues(qs)
            delay(currentTime) {
                for q in qs {q.begin()}
            }
            
        case .Also(block: let block):
            delay(currentTime) {
                block(duration:self.currentDuration)
            }
            
        case .Now(block: let block):
            delay(currentTime + currentDuration, block)
            
        case .AlsoQueue(let queue):
            delay(currentTime) {queue.begin()}
            
        case .StepBack(duration: let duration):
            currentTime -= duration
            
        }
        
    }
    
    public var totalDuration:CFTimeInterval {
        var cumulativeDuration:CFTimeInterval = 0
        for item in _items {
            switch item {
            case .Then(duration: let duration, block: _):
                cumulativeDuration += duration
                
            case .ThenQueue(let queue):
                cumulativeDuration += queue.totalDuration
                
            case .ThenQueues(let qs):
                cumulativeDuration += maxTimeOfQueues(qs)
                
            case .StepBack(duration: let duration):
                cumulativeDuration -= duration
                
            case .Also(block: _), .Then(block: _), .AlsoQueue(_), .Now(block: _):
                Void()
                
            }
        }
        return cumulativeDuration
    }
    
    private func maxTimeOfQueues(qs:[Queue]) -> CFTimeInterval {
        let times = qs.map {q in q.totalDuration}
        return maxElement(times)
    }
    
}


extension CALayer {
    
    public func drawPath(path:CGPathRef) {
        let layer = CAShapeLayer()
        layer.frame = self.bounds
        layer.fillColor = UIColor.clearColor().CGColor
        layer.strokeColor = UIColor.blackColor().colorWithAlphaComponent(0.3).CGColor
        layer.lineWidth = 2
        layer.path = path
        self.addSublayer(layer)
    }
    
    public func drawPoint(point:CGPoint, color:UIColor = UIColor.blackColor().colorWithAlphaComponent(0.3)) {
        let layer = CAShapeLayer()
        layer.frame = self.bounds
        layer.fillColor = color.CGColor
        layer.strokeColor = UIColor.clearColor().CGColor
        layer.lineWidth = 0
        layer.path = UIBezierPath(ovalInRect: CGRect(center: point, size: CGSize(width: 10, height: 10))).CGPath
        self.addSublayer(layer)
    }
    
    public func drawVector(vector:CGVector, fromPoint:CGPoint) {
        let path = UIBezierPath()
        path.moveToPoint(fromPoint)
        path.addLineToPoint(fromPoint + vector)
        self.drawPath(path.CGPath)
    }
    
    public func drawAngle(angle:CGFloat, fromPoint:CGPoint) {
        let path = UIBezierPath()
        path.moveToPoint(fromPoint)
        path.addLineToPoint(fromPoint + CGVector(angle: angle, radius: 100))
        self.drawPath(path.CGPath)
    }
    
    public func drawLineAtX(x:CGFloat) {
        let path = UIBezierPath()
        path.moveToPoint(CGPoint(x: x, y: 0))
        path.addLineToPoint(CGPoint(x: x, y: self.bounds.height))
        self.drawPath(path.CGPath)
    }
    
    public func drawLineAtY(y:CGFloat) {
        let path = UIBezierPath()
        path.moveToPoint(CGPoint(x: 0, y: y))
        path.addLineToPoint(CGPoint(x: self.bounds.width, y: y))
        self.drawPath(path.CGPath)
    }
    
    public func drawMidLines() {
        drawLineAtX(self.bounds.width / 2.0)
        drawLineAtY(self.bounds.height / 2.0)
    }
    
    public func drawRectangle(rect:CGRect) {
        drawPath(UIBezierPath(rect: rect).CGPath)
    }
    
}

extension CGFloat {
    
    public func percentFrom(from:CGFloat, to:CGFloat) -> CGFloat {
        if self < from {
            return 0
        } else if self > to {
            return 1
        } else {
            return (self - from) / (to - from)
        }
    }
    
    public func randomSignFlip() -> CGFloat {
        return (randomBool()) ? self : -self
    }
    
    public var half:CGFloat {
        return self / 2.0
    }
    
}

public func randomPercent() -> CGFloat {
    return randomFloatFrom(0, 1)
}

public func randomFloatFrom(from:CGFloat, to:CGFloat, increment:CGFloat = 0.01) -> CGFloat {
    var incrementAmount = Int((to - from) / increment)
    return from + increment * CGFloat(randomIntFrom(0, incrementAmount))
}

public func randomIntFrom(from:Int, to:Int) -> Int {
    let size = from - to
    return from + (random() % (size + 1))
}

public func randomBool() -> Bool {
    return (random() % 2 == 0) ? false : true
}

extension CGPoint {
    
    public func vectorToPoint(point:CGPoint) -> CGVector {
        return point - self
    }
    
    public func vectorFromPoint(point:CGPoint) -> CGVector {
        return self - point
    }
    
    public func distanceToPoint(point:CGPoint) -> CGFloat {
        return vectorToPoint(point).magnitude()
    }
}

extension CGVector {
    
    public init(angle:CGFloat, radius:CGFloat) {
        dx = radius * cos(angle)
        dy = radius * sin(angle)
    }
    
    public func magnitude() -> CGFloat {
        return sqrt(self * self)
    }
    
    public func scaleBy(scale:CGFloat) -> CGVector {
        return self * scale
    }
    
    public func normalize() -> CGVector {
        return self.scaleBy(1.0 / self.magnitude())
    }
    
    public func perpendicularLeft() -> CGVector {
        return CGVector(dx: -dy, dy: dx)
    }
    
    public func perpendicularRight() -> CGVector {
        return -perpendicularLeft()
    }
    
   public  var angle:CGFloat {
        if dx == 0 {
            if dy > 0 {
                return CGFloat(M_PI / 2.0)
            } else {
                return CGFloat(3.0 * M_PI / 2.0)
            }
        } else {
            let arcTanValue = atan(dy / dx)
            
            if dx < 0 {
                return arcTanValue + CGFloat(M_PI)
            } else if dy < 0 {
                return arcTanValue + CGFloat(M_PI) * 2
            } else {
                return arcTanValue
            }
        }
    }
}

public func *(left:CGVector,right:CGVector) -> CGFloat {
    return left.dx * right.dx + left.dy * right.dy
}

public func *(vector:CGVector, scale:CGFloat) -> CGVector {
    return CGVector(dx: vector.dx * scale, dy: vector.dy * scale);
}

public func +(left:CGVector,right:CGVector) -> CGVector {
    return CGVector(dx: left.dx + right.dx,dy:left.dy + right.dy)
}

public func +(point:CGPoint,vector:CGVector) -> CGPoint {
    return CGPoint(x: point.x + vector.dx, y: point.y + vector.dy)
}

public func -(left:CGVector,right:CGVector) -> CGVector {
    return CGVector(dx: left.dx - right.dx, dy: left.dy - right.dy)
}

public func -(left:CGPoint,right:CGPoint) -> CGVector {
    return CGVector(dx: left.x - right.x, dy: left.y - right.y)
}

public func -(point:CGPoint,vector:CGVector) -> CGPoint {
    return CGPoint(x: point.x - vector.dx, y: point.y - vector.dy)
}

public prefix func - (vector: CGVector) -> CGVector {
    return CGVector(dx: -vector.dx, dy: -vector.dy)
}
