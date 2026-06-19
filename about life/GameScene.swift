import SpriteKit
import GameplayKit
import UIKit

// MARK: - 数据结构
struct HexCoord: Hashable {
    let q: Int
    let r: Int
    
    func toPoint(size: CGFloat) -> CGPoint {
        let x = size * 1.5 * CGFloat(q)
        let y = size * sqrt(3) * (CGFloat(r) + CGFloat(q) / 2.0)
        return CGPoint(x: x, y: y)
    }
    
    static func from(point: CGPoint, size: CGFloat) -> HexCoord {
        let q = (2.0/3.0 * point.x) / size
        let r = (-1.0/3.0 * point.x + sqrt(3)/3.0 * point.y) / size
        return roundHex(q: q, r: r)
    }
    
    static func roundHex(q: CGFloat, r: CGFloat) -> HexCoord {
        let s = -q - r
        var rq = round(q), rr = round(r), rs = round(s)
        let q_diff = abs(rq - q), r_diff = abs(rr - r), s_diff = abs(rs - s)
        if q_diff > r_diff && q_diff > s_diff { rq = -rr - rs }
        else if r_diff > s_diff { rr = -rq - rs }
        return HexCoord(q: Int(rq), r: Int(rr))
    }
    
    var neighbors: [HexCoord] {
        let dirs = [(1, 0), (1, -1), (0, -1), (-1, 0), (-1, 1), (0, 1)]
        return dirs.map { HexCoord(q: q + $0.0, r: r + $0.1) }
    }
}

// MARK: - 视觉节点类 (液态玻璃效果)
class HexNode: SKShapeNode {
    let coord: HexCoord
    
    init(size: CGFloat, coord: HexCoord) {
        self.coord = coord
        super.init()
        
        let path = CGMutablePath()
        let r = size - 1.0
        for i in 0..<6 {
            let angle = CGFloat(i) * 60 * .pi / 180
            let p = CGPoint(x: r * cos(angle), y: r * sin(angle))
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        
        self.path = path
        self.lineWidth = 1.5
        self.strokeColor = .white.withAlphaComponent(0.4)
        self.fillColor = .clear
        self.lineJoin = .round
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError() }
    
    func animateToState(color: UIColor) {
        if self.fillColor.isEqual(color) {
            let scaleDown = SKAction.scale(to: 0.9, duration: 0.1)
            let scaleUp = SKAction.scale(to: 1.0, duration: 0.3)
            scaleUp.timingMode = .easeOut
            self.run(SKAction.sequence([scaleDown, scaleUp]))
            return
        }
        
        let scaleDown = SKAction.scale(to: 0.6, duration: 0.15)
        scaleDown.timingMode = .easeIn
        
        let changeColor = SKAction.run {
            self.fillColor = color
            self.strokeColor = color.withAlphaComponent(0.8).lighter(by: 30) ?? .white
        }
        
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.4)
        scaleUp.timingMode = .easeOut
        
        self.run(SKAction.sequence([scaleDown, changeColor, scaleUp]))
    }
}

extension UIColor {
    func lighter(by percentage: CGFloat = 30.0) -> UIColor? {
        return self.adjust(by: abs(percentage) )
    }
    func adjust(by percentage: CGFloat = 30.0) -> UIColor? {
        var r:CGFloat=0, g:CGFloat=0, b:CGFloat=0, a:CGFloat=0
        if(getRed(&r, green: &g, blue: &b, alpha: &a)){
            return UIColor(red: min(r + percentage/100, 1.0),
                           green: min(g + percentage/100, 1.0),
                           blue: min(b + percentage/100, 1.0),
                           alpha: a)
        }
        return nil
    }
}

// MARK: - GameScene 主逻辑
class GameScene: SKScene, UIGestureRecognizerDelegate {
    
    let hexRadius: CGFloat = 16
    
    private var limitLower: Int = 5
    private var limitUpper: Int = 9
    private var speedMultiplier: Double = 1.0
    private let baseUpdateInterval: TimeInterval = 0.5
    
    private var worldData: [HexCoord: Int] = [:]
    private var visibleNodes: [HexCoord: HexNode] = [:]
    
    private var isDrawMode: Bool = false
    private var isDraggingToDraw: Bool = false
    private var lastAddedCoord: HexCoord?
    
    private var cameraNode: SKCameraNode!
    private var backgroundGridNode: SKShapeNode?
    
    private var isRunning: Bool = false {
        didSet { UIApplication.shared.isIdleTimerDisabled = isRunning }
    }
    private var lastUpdateTime: TimeInterval = 0
    
    private var pinchGesture: UIPinchGestureRecognizer?
    private var panGesture: UIPanGestureRecognizer?

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.10, green: 0.12, blue: 0.16, alpha: 1.0)
        
        updateSettings()
        setupCamera()
        drawStaticBackgroundGrid()
        setupGestures(in: view)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onStart), name: .gameStart, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onReset), name: .gameReset, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onRecenter), name: .gameRecenter, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onStep), name: .gameStep, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onModeChange(_:)), name: .drawModeChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onRulesChanged), name: .rulesChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onRulesChanged), name: .speedChanged, object: nil)
    }
    
    // 绘制无限网格背景
    private func drawStaticBackgroundGrid() {
        let gridShape = SKShapeNode()
        let path = CGMutablePath()
        let r = hexRadius
        let size = r - 0.5
        let mapRadius = 80
        
        for q in -mapRadius...mapRadius {
            let r1 = max(-mapRadius, -q - mapRadius)
            let r2 = min(mapRadius, -q + mapRadius)
            
            for rCoord in r1...r2 {
                let coord = HexCoord(q: q, r: rCoord)
                let center = coord.toPoint(size: r)
                for i in 0..<6 {
                    let angle = CGFloat(i) * 60 * .pi / 180
                    let p = CGPoint(x: center.x + size * cos(angle),
                                    y: center.y + size * sin(angle))
                    if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
                }
                path.closeSubpath()
            }
        }
        
        gridShape.path = path
        gridShape.strokeColor = UIColor.white.withAlphaComponent(0.05)
        gridShape.lineWidth = 1
        gridShape.zPosition = -100
        
        self.backgroundGridNode?.removeFromParent()
        addChild(gridShape)
        self.backgroundGridNode = gridShape
    }
    
    private func renderVisibleTiles() {
        for (coord, node) in visibleNodes {
            if worldData[coord] == nil {
                let scaleDown = SKAction.scale(to: 0.0, duration: 0.2)
                scaleDown.timingMode = .easeIn
                let remove = SKAction.removeFromParent()
                node.run(SKAction.sequence([scaleDown, remove]))
                visibleNodes.removeValue(forKey: coord)
            }
        }
        
        for (coord, val) in worldData {
            let node: HexNode
            if let existing = visibleNodes[coord] {
                node = existing
            } else {
                node = HexNode(size: hexRadius, coord: coord)
                node.position = coord.toPoint(size: hexRadius)
                node.setScale(0.0)
                addChild(node)
                visibleNodes[coord] = node
            }
            
            let targetColor: UIColor
            switch val {
            case 1: targetColor = UIColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 0.7)
            case 2: targetColor = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 0.7)
            case 3: targetColor = UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 0.7)
            default: targetColor = .clear
            }
            node.animateToState(color: targetColor)
        }
    }

    override func update(_ currentTime: TimeInterval) {
        let effectiveSpeed = max(0.1, speedMultiplier)
        let currentInterval = baseUpdateInterval / effectiveSpeed
        
        if isRunning && currentTime - lastUpdateTime > currentInterval {
            lastUpdateTime = currentTime
            stepSimulation()
        }
        renderVisibleTiles()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDrawMode, let t = touches.first else { return }
        let point = t.location(in: self)
        let coord = HexCoord.from(point: point, size: hexRadius)
        handleTap(coord)
        isDraggingToDraw = true
        lastAddedCoord = coord
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDrawMode, isDraggingToDraw, let t = touches.first else { return }
        let point = t.location(in: self)
        let coord = HexCoord.from(point: point, size: hexRadius)
        if coord != lastAddedCoord {
            if worldData[coord] == nil { worldData[coord] = 3; lastAddedCoord = coord }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { isDraggingToDraw = false }
    
    private func handleTap(_ coord: HexCoord) {
        let val = worldData[coord] ?? 0
        let newVal = (val == 0) ? 3 : val - 1
        if newVal == 0 { worldData.removeValue(forKey: coord) }
        else { worldData[coord] = newVal }
    }
    
    private func stepSimulation() {
        var nextWorld = worldData
        var candidates = Set<HexCoord>()
        for (c, _) in worldData {
            candidates.insert(c)
            for n in c.neighbors { candidates.insert(n) }
        }
        
        let safeLower = min(limitLower, limitUpper)
        let safeUpper = max(limitLower, limitUpper)
        
        for c in candidates {
            let current = worldData[c] ?? 0
            var neighborsSum = 0
            for n in c.neighbors { neighborsSum += worldData[n] ?? 0 }
            
            var nextVal = current
            
            if neighborsSum <= safeLower {
                nextVal = max(0, current - 1)
            } else if neighborsSum > safeLower && neighborsSum <= safeUpper {
                nextVal = min(3, current + 1)
            } else {
                nextVal = 0
            }
            
            if nextVal != current {
                if nextVal == 0 { nextWorld.removeValue(forKey: c) }
                else { nextWorld[c] = nextVal }
            }
        }
        worldData = nextWorld
    }
    
    private func setupCamera() {
        cameraNode = SKCameraNode()
        camera = cameraNode
        addChild(cameraNode)
    }
    
    private func setupGestures(in view: SKView) {
        let p1 = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        p1.delegate = self
        view.addGestureRecognizer(p1)
        pinchGesture = p1
        
        let p2 = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        p2.minimumNumberOfTouches = 1
        p2.delegate = self
        view.addGestureRecognizer(p2)
        panGesture = p2
        
        updateInputMode()
    }
    
    private func updateInputMode() {
        pinchGesture?.isEnabled = !isDrawMode
        panGesture?.isEnabled = !isDrawMode
    }
    
    @objc private func handlePinch(_ g: UIPinchGestureRecognizer) {
        guard let cam = cameraNode else { return }
        if g.state == .changed {
            let val = cam.xScale * (1.0 / g.scale)
            let clamped = max(0.5, min(val, 4.0))
            cam.setScale(clamped)
            g.scale = 1.0
        }
    }
    
    @objc private func handlePan(_ g: UIPanGestureRecognizer) {
        guard let cam = cameraNode else { return }
        if g.state == .changed {
            let t = g.translation(in: view)
            cam.position = CGPoint(
                x: cam.position.x - t.x * cam.xScale,
                y: cam.position.y + t.y * cam.yScale
            )
            g.setTranslation(.zero, in: view)
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { true }
    
    @objc private func onStart() { isRunning.toggle() }
    @objc private func onReset() { isRunning = false; worldData.removeAll(); visibleNodes.removeAll(); children.forEach { if $0 is HexNode { $0.removeFromParent() } } }
    @objc private func onRecenter() { cameraNode.run(SKAction.move(to: .zero, duration: 0.3)) }
    @objc private func onStep() { if !isRunning { stepSimulation() } }
    @objc private func onModeChange(_ n: Notification) {
        if let mode = n.userInfo?["isDrawMode"] as? Bool {
            isDrawMode = mode
            updateInputMode()
        }
    }
    @objc private func onRulesChanged() { updateSettings() }
    
    private func updateSettings() {
        let d = UserDefaults.standard
        limitLower = d.integer(forKey: "rule_limitLower"); if limitLower == 0 { limitLower = 5 }
        limitUpper = d.integer(forKey: "rule_limitUpper"); if limitUpper == 0 { limitUpper = 9 }
        let savedSpeed = d.double(forKey: "simulationSpeed")
        speedMultiplier = savedSpeed > 0 ? savedSpeed : 1.0
    }
}
