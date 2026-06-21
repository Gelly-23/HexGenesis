import UIKit
import SpriteKit

final class GameViewController: UIViewController {

    override func loadView() {
        let skView = SKView(frame: .zero)
        // 🚨 核心检查点：这一行必须有，否则双指无法被识别
        skView.isMultipleTouchEnabled = true
        self.view = skView
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let skView = self.view as? SKView else { return }
        
        // 防止重复 Present
        if skView.scene == nil {
            let scene = GameScene(size: skView.bounds.size)
            scene.scaleMode = .resizeFill
            skView.presentScene(scene)
            skView.ignoresSiblingOrder = true
            // skView.showsFPS = true // 调试用，可不加
            // skView.showsNodeCount = true // 调试用
        }
    }

    override var prefersStatusBarHidden: Bool { true }
}
