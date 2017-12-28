//
//  GameScene.swift
//  ChineseCheckers Shared
//
//  Created by Kacper Raczy on 25.12.2017.
//  Copyright © 2017 Kacper Raczy. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    
    
    fileprivate var label : SKLabelNode?
    fileprivate var spinnyNode : SKShapeNode?
    fileprivate var session: GameSession!
    
    fileprivate static let hexSize: CGFloat = 40
    fileprivate static let hexOffset: CGFloat = 5

    fileprivate var board: Board {
        return self.session.board
    }
    
    //temporary (until game logic is done)
    fileprivate var player: Player {
        return self.session.players.first!
    }
    
    class func newGameScene() -> GameScene {
        // Load 'GameScene.sks' as an SKScene.
        guard let scene = SKScene(fileNamed: "GameScene") as? GameScene else {
            print("Failed to load GameScene.sks")
            abort()
        }

        if let path = Bundle.main.path(forResource: "grid", ofType: "json") {
            let url = URL(fileURLWithPath: path)
            let data = try! Data(contentsOf: url)
            let json = try! JSONSerialization.jsonObject(with: data)
            if let item = json as? [String: Any] {
                var players = [Player]()
                if let playersJson = item["players"] as? [[String: Any]] {
                    for dict in playersJson {
                        if let player = Player(dict: dict){
                            players.append(player)
                        }
                    }
                    
                    if let boardInfo = BoardInfo(dict: item) {
                        scene.session = GameSession(binfo: boardInfo, players: players)
                    }
                }
            }
        }
        
        // Set the scale mode to scale to fit the window
        scene.scaleMode = .aspectFill
        
        return scene
    }
    
    func setUpScene() {
        setUpBoard()
    }
    
    func setUpBoard() {
        let startId = self.board.startID
        let startField = self.board.fields[startId]!
        
        let center = CGPoint(x: self.frame.midX,
                             y: self.frame.midY)
        let node = createFieldHex(id: hexName(id: startId))
        node.position = center
        self.addChild(node)
        
        createNeighbours(arr: [startField])
        createCheckers(fields: self.board.fields.map({$0.value}))
    }
    
    func createNeighbours(arr: [Field]) {
        if arr.count == 0 {
            return
        }
        
        var created: [Field] = []
        for field in arr {
            created.append(contentsOf: createNeighboursHex(field: field))
        }
        
        createNeighbours(arr: created)
    }
    
    func createNeighboursHex(field: Field) -> [Field] {
        var createdFields: [Field] = []
        
        let hexName: String = self.hexName(id: field.id)
        guard let hexNode = self.childNode(withName: hexName) as? HexagonNode
        else {return [] /*ERROR*/}
        
        var tempName: String
        
        for direction in Field.Direction.allValues {
            if let neighbour = field.getNeighbour(dir: direction) {
                tempName = self.hexName(id: neighbour.id)
                if self.childNode(withName: tempName) == nil {
                    let newNode = createFieldHex(id: tempName)
                    newNode.position = offsetPosition(hex: hexNode, dir: direction)
                    self.addChild(newNode)
                    
                    createdFields.append(neighbour)
                }
            }
        }
        
        return createdFields
    }
    
    func offsetPosition(hex: HexagonNode, dir: Field.Direction) -> CGPoint {
        let angleDeg: CGFloat = CGFloat(dir.rawValue) * 60
        let angleRad: CGFloat = CGFloat.pi * angleDeg / 180
        
        let result = CGPoint(x: 2 * hex.radius * cos(angleRad) + hex.position.x,
                             y: 2 * hex.radius * sin(angleRad) + hex.position.y )
        
        return result
    }
    
    func createCheckers(fields: [Field]) {
        for f in fields {
            if let player = f.player {
                let hexStr = hexName(id: f.id)
                if let hexNode = self.childNode(withName: hexStr) {
                    let checkerHex = createChecker(player: player)
                    checkerHex.position = hexNode.position
                    self.addChild(checkerHex)
                }
            }
        }
    }
    
    func createChecker(player: Player) -> HexagonNode {
        let node = HexagonNode(size: GameScene.hexSize)
        node.name = checkerName(player: player)
        node.fillColor = checkerColor(zone: player.zoneID)
        
        //only current player's checkers
        node.delegate = self
        
        return node
    }
    
    func hexName(id: Int) -> String {
        return "h_\(id)"
    }
    
    func checkerName(player: Player) -> String {
        return "ch_\(player.zoneID)" //TODO
    }
    
    func hexIndex(checkerName: String) -> Int? {
        let scanner = Scanner(string: checkerName)
        var result: Int? = nil
        var value: Int = 0
        
        scanner.scanUpToCharacters(from: CharacterSet.decimalDigits, into: nil)
        if scanner.scanInt(&value) {
            result = value
        }
        
        return result
    }
    
    func createFieldHex(id: String) -> HexagonNode{
        let node = HexagonNode(size: GameScene.hexSize)
        node.name = id
        node.fillColor = NSColor.blue
        
        return node
    }
    
    
    #if os(iOS)
    func checkerColor(zone: Int) -> UIColor{
        let colors = ["#00077A", "#03BD5B", "#BF0A46", "#FF9947", "#A939B9", "#000000"]
        let hexString = colors[zone % 6]
    
        return UIColor.hexStringToUIColor(hex: hexString)
    }
    #elseif os(OSX)
    func checkerColor(zone: Int) -> NSColor {
        let colors = ["#00077A", "#03BD5B", "#BF0A46", "#FF9947", "#A939B9", "#000000"]
        let hexString = colors[zone % 6]
        
        return NSColor.hexStringToNSColor(hex: hexString)
    }
    #endif
    
    
    #if os(watchOS)
    override func sceneDidLoad() {
        self.setUpScene()
    }
    #else
    override func didMove(to view: SKView) {
        self.setUpScene()
    }
    #endif
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}

extension GameScene: HexagonNodeDelegate {
    func hexNodeClicked(_ node: HexagonNode) {
        let nodes = self.nodes(at: node.position)
        var hex: HexagonNode? = nil
        for f in nodes {
            if let hexNode = f as? HexagonNode, let name = hexNode.name {
                if name.starts(with: "h_") {
                    hex = hexNode
                    break
                }
            }
        }
        
        guard let fieldHex = hex else {return}
        
        if let idx = hexIndex(checkerName: fieldHex.name!),
            let field = self.session.board.fields[idx] {
            let possible = self.session.possibleMoves(from: field)
            for p in possible {
                if let node = self.childNode(withName: hexName(id: p.id)) as? HexagonNode {
                    node.lineWidth = 4.0
                    node.strokeColor = NSColor.red
                }
            }
        }
        
    }
}

#if os(iOS) || os(tvOS)
// Touch-based event handling
extension GameScene {

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
   
}
#endif

#if os(OSX)
// Mouse-based event handling
extension GameScene {

    override func mouseDown(with event: NSEvent) {
        
    }
    
    override func mouseDragged(with event: NSEvent) {
     
    }
    
    override func mouseUp(with event: NSEvent) {
       
    }

}
#endif

