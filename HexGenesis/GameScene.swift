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

// MARK: - 视觉节点类
class HexNode: SKShapeNode {
    let coord: HexCoord
    private var currentRenderVal: Int = -1 // 缓存当前渲染状态，避免重复触发动画
    
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
    
    func updateRenderState(val: Int, force: Bool = false) {
        if !force && currentRenderVal == val { return }
        currentRenderVal = val
        
        let targetColor: UIColor
        switch val {
        case 1:  targetColor = UIColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 0.7)
        case 2:  targetColor = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 0.7)
        case 3:  targetColor = UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 0.7)
        default: targetColor = .clear
        }
        
        animateToState(color: targetColor)
    }
    
    private func animateToState(color: UIColor) {
        self.removeAllActions() // 防止连续演化时动画叠加卡死
        
        if color == .clear {
            // 优雅淡出回背景状态
            let fadeColor = SKAction.run {
                self.fillColor = .clear
                self.strokeColor = .white.withAlphaComponent(0.4)
            }
            let scaleBack = SKAction.scale(to: 1.0, duration: 0.2)
            self.run(SKAction.group([fadeColor, scaleBack]))
            return
        }
        
        let scaleDown = SKAction.scale(to: 0.8, duration: 0.1)
        let changeColor = SKAction.run {
            self.fillColor = color
            var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
            if color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
                let lighterColor = UIColor(hue: hue, saturation: saturation, brightness: min(brightness * 1.3, 1.0), alpha: alpha)
                self.strokeColor = lighterColor.withAlphaComponent(0.8)
            } else {
                self.strokeColor = color.withAlphaComponent(0.8)
            }
        }
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.25)
        scaleUp.timingMode = .easeOut
        
        self.run(SKAction.sequence([scaleDown, changeColor, scaleUp]))
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
    private var activeBackgroundCoords = Set<HexCoord>()
    
    private var isDrawMode: Bool = false
    private var isDraggingToDraw: Bool = false
    private var lastAddedCoord: HexCoord?
    
    private var cameraNode: SKCameraNode!
    
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
        setupGestures(in: view)
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(onStart), name: .gameStart, object: nil)
        nc.addObserver(self, selector: #selector(onReset), name: .gameReset, object: nil)
        nc.addObserver(self, selector: #selector(onRecenter), name: .gameRecenter, object: nil)
        nc.addObserver(self, selector: #selector(onStep), name: .gameStep, object: nil)
        nc.addObserver(self, selector: #selector(onModeChange(_:)), name: .drawModeChanged, object: nil)
        nc.addObserver(self, selector: #selector(onRulesChanged), name: .rulesChanged, object: nil)
        nc.addObserver(self, selector: #selector(onRulesChanged), name: .speedChanged, object: nil)
        
        dynamicViewportLodLoading()
    }
    
    override func willMove(from view: SKView) {
        NotificationCenter.default.removeObserver(self)
        if let pinch = pinchGesture { view.removeGestureRecognizer(pinch) }
        if let pan = panGesture { view.removeGestureRecognizer(pan) }
        super.willMove(from: view)
    }
    
    /// 按需加载/卸载视口内的所有格子节点
    private func dynamicViewportLodLoading() {
        guard let view = self.view, let cam = cameraNode else { return }
        
        let viewSize = view.bounds.size
        let halfW = (viewSize.width / 2.0) * cam.xScale
        let halfH = (viewSize.height / 2.0) * cam.yScale
        
        let padding = hexRadius * 4.0
        let minX = cam.position.x - halfW - padding
        let maxX = cam.position.x + halfW + padding
        let minY = cam.position.y - halfH - padding
        let maxY = cam.position.y + halfH + padding
        
        let topLeftCoord = HexCoord.from(point: CGPoint(x: minX, y: maxY), size: hexRadius)
        let bottomRightCoord = HexCoord.from(point: CGPoint(x: maxX, y: minY), size: hexRadius)
        
        let minQ = min(topLeftCoord.q, bottomRightCoord.q) - 2
        let maxQ = max(topLeftCoord.q, bottomRightCoord.q) + 2
        let minR = min(topLeftCoord.r, bottomRightCoord.r) - 2
        let maxR = max(topLeftCoord.r, bottomRightCoord.r) + 2
        
        var currentVisibleCoords = Set<HexCoord>()
        
        for q in minQ...maxQ {
            for r in minR...maxR {
                let coord = HexCoord(q: q, r: r)
                let pt = coord.toPoint(size: hexRadius)
                if pt.x >= minX && pt.x <= maxX && pt.y >= minY && pt.y <= maxY {
                    currentVisibleCoords.insert(coord)
                }
            }
        }
        
        // 1. 动态回收移出视口的节点
        let toRemove = activeBackgroundCoords.subtracting(currentVisibleCoords)
        for coord in toRemove {
            if let node = visibleNodes[coord] {
                node.removeFromParent()
                visibleNodes.removeValue(forKey: coord)
            }
        }
        
        // 2. 动态实例化新进入视口的节点
        let toAdd = currentVisibleCoords.subtracting(activeBackgroundCoords)
        for coord in toAdd {
            if visibleNodes[coord] == nil {
                let node = HexNode(size: hexRadius, coord: coord)
                node.position = coord.toPoint(size: hexRadius)
                
                // 实例化时，直接根据当前真实数据渲染正确颜色（哪怕是0，也会被正确设为clear）
                let val = worldData[coord] ?? 0
                node.updateRenderState(val: val, force: true)
                
                addChild(node)
                visibleNodes[coord] = node
            }
        }
        activeBackgroundCoords = currentVisibleCoords
    }
    
    /// 事件驱动：刷新当前所有**可见节点**的色彩表现（再也不会漏掉数据为0的死细胞）
    private func renderVisibleTilesOnDemand() {
        for (coord, node) in visibleNodes {
            let val = worldData[coord] ?? 0
            node.updateRenderState(val: val)
        }
    }

    override func update(_ currentTime: TimeInterval) {
        let effectiveSpeed = max(0.1, speedMultiplier)
        let currentInterval = baseUpdateInterval / effectiveSpeed
        
        if isRunning && currentTime - lastUpdateTime > currentInterval {
            lastUpdateTime = currentTime
            stepSimulation()
            renderVisibleTilesOnDemand()
        }
        
        dynamicViewportLodLoading()
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
            worldData[coord] = 3
            lastAddedCoord = coord
            // 数据改变后即时渲染
            if let node = visibleNodes[coord] {
                node.updateRenderState(val: 3)
            } else {
                dynamicViewportLodLoading()
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { isDraggingToDraw = false }
    
    private func handleTap(_ coord: HexCoord) {
        let val = worldData[coord] ?? 0
        let newVal = (val == 0) ? 3 : val - 1
        
        if newVal == 0 {
            worldData.removeValue(forKey: coord)
        } else {
            worldData[coord] = newVal
        }
        
        if let node = visibleNodes[coord] {
            node.updateRenderState(val: newVal)
        } else {
            dynamicViewportLodLoading()
        }
    }
    
    /// 核心算法：严格对齐 UI 区间（≤5 衰减、6~9 成长、>9 过载）的纯数据演化
    private func stepSimulation() {
        var nextWorld = worldData
        var candidates = Set<HexCoord>()
        
        // 收集所有需要评估的格子：当前活着的格子，以及它们的所有邻居
        for (c, _) in worldData {
            candidates.insert(c)
            for n in c.neighbors { candidates.insert(n) }
        }
        
        let safeLower = min(limitLower, limitUpper) // 严格对应 UI 的 5
        let safeUpper = max(limitLower, limitUpper) // 严格对应 UI 的 9
        
        for c in candidates {
            let current = worldData[c] ?? 0
            var neighborsSum = 0
            for n in c.neighbors { neighborsSum += worldData[n] ?? 0 }
            
            var nextVal = current
            
            // ==========================================
            // 严格映射 UI 三段区间，绝无边界歧义
            // ==========================================
            if neighborsSum <= safeLower {
                // 【区间一：0 ~ 5】衰减
                // 活细胞能量递减，空格子（0-1=-1 -> max后保持0）继续保持空
                nextVal = max(0, current - 1)
                
            } else if neighborsSum <= safeUpper {
                // 【区间二：6 ~ 9】成长 / 诞生
                if current == 0 {
                    nextVal = 1 // 空地孵化诞生新元素
                } else {
                    nextVal = min(3, current + 1) // 活细胞能量递增，最高为 3
                }
                
            } else {
                // 【区间三：> 9】过载
                // 超过上限，能量饱和坍塌，直接灰飞烟灭
                nextVal = 0
            }
            
            // 将计算出的新状态安全写入下一帧的缓冲字典中
            if nextVal == 0 {
                nextWorld.removeValue(forKey: c)
            } else {
                nextWorld[c] = nextVal
            }
        }
        
        // 整个视口扫描完毕，一次性切回主缓冲
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
            dynamicViewportLodLoading()
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
            dynamicViewportLodLoading()
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { true }
    
    @objc private func onStart() { isRunning.toggle() }
    
    // 【核心修复】完美重置所有状态，防止视口缓存导致的全黑漏洞
    @objc private func onReset() {
        isRunning = false
        worldData.removeAll()
        visibleNodes.removeAll()
        activeBackgroundCoords.removeAll() // 必须清空，否则LOD认为节点还在屏幕上
        children.forEach { if $0 is HexNode { $0.removeFromParent() } }
        dynamicViewportLodLoading()        // 立即重新生成当前视口的空白网格背景
    }
    
    @objc private func onRecenter() { cameraNode.run(SKAction.move(to: .zero, duration: 0.3)); dynamicViewportLodLoading() }
    @objc private func onStep() { if !isRunning { stepSimulation(); renderVisibleTilesOnDemand() } }
    @objc private func onModeChange(_ n: Notification) {
        if let mode = n.userInfo?["isDrawMode"] as? Bool {
            isDrawMode = mode
            updateInputMode()
        }
    }
    @objc private func onRulesChanged() { updateSettings() }
    
    private func updateSettings() {
        let d = UserDefaults.standard
        
        // 1. 标准安全的默认值注册：只在 App 初次安装且未设置时生效，绝不覆盖用户的真实意图
        d.register(defaults: [
            "rule_limitLower": 5,
            "rule_limitUpper": 9,
            "simulationSpeed": 1.0
        ])
        
        // 2. 直接放心读取。此时如果读到 0，那就是用户在 UI 上真真切切拉到的 0
        limitLower = d.integer(forKey: "rule_limitLower")
        limitUpper = d.integer(forKey: "rule_limitUpper")
        
        // 速度也同理，直接读取注册好的安全值
        speedMultiplier = d.double(forKey: "simulationSpeed")
    }
}
