//
//  Map.swift
//  Denrim
//
//  Created by Markus Moenig on 7/9/20.
//

import MetalKit

class Map
{
    // Resources
    var images              : [String:MapImage] = [:]
    var aliases             : [String:MapAlias] = [:]
    var sequences           : [String:MapSequence] = [:]
    var layers              : [String:MapLayer] = [:]
    var scenes              : [String:MapScene] = [:]
    var behavior            : [String:MapBehavior] = [:]
    var fixtures2D          : [String:MapFixture2D] = [:]
    var physics2D           : [String:MapPhysics2D] = [:]

    var shapes2D            : [String:MapShape2D] = [:]
    var shaders             : [String:MapShader] = [:]

    var commands            : [MapCommand] = []

    var lines               : [Int32:String] = [:]
    
    var resources           : [String:Any] = [:]

    // Rendering
    
    var globalAlpha         : Float = 1
    
    // Have to be set!
    var game                : Game!
    var texture             : Texture2D!
    var aspect              : Float3!
    var viewBorder          : Float2!

    deinit {
        clear()
        resources = [:]
    }
    
    func clear(_ releaseResources: Bool = false)
    {
        print("release map")
        images = [:]
        aliases = [:]
        sequences = [:]
        layers = [:]
        scenes = [:]
        behavior = [:]
        fixtures2D = [:]
        physics2D = [:]
        shapes2D = [:]
        shaders = [:]
        commands = []
        lines = [:]
        if releaseResources {
            resources = [:]
        }
    }
    
    func setup(game: Game)
    {
        self.game = game
        self.texture = game.texture
        
        let canvasSize = getCanvasSize()
        
        let scale: Float = min(texture.width / canvasSize.x, texture.height / canvasSize.y)
        let scaledWidth: Float = canvasSize.x * scale
        let scaledHeight: Float = canvasSize.y * scale

        viewBorder = Float2((texture.width - scaledWidth) / 2.0, (texture.height - scaledHeight) / 2.0)

        aspect = Float3(texture.width, texture.height, 0)
        aspect.x = (scaledWidth / 100.0)
        aspect.y = (scaledHeight / 100.0)
        aspect.z = min(aspect.x, aspect.y)
                
        game._Aspect.x = aspect.x
        game._Aspect.y = aspect.y
    }
    
    func createPhysics()
    {
        // Create the Physics2D instances
        for (physicsName, physics) in physics2D {
            var gravity = b2Vec2(0.0, -10.0)
            if let gravityOption = physics.options["gravity"] as? Float2 {
                gravity.x = gravityOption.x
                gravity.y = gravityOption.y
            }
            gravity.y = -gravity.y
            physics2D[physicsName]!.world = b2World(gravity: gravity)
        }
        
        // Parse the 2D shapes and add them to the right physics world
        for cmd in commands {
            if cmd.command == "ApplyPhysics2D" {
                if let physicsName = cmd.options["physicsid"] as? String {
                    if let physics2D = physics2D[physicsName] {
                        if let shapeName = cmd.options["shapeid"] as? String {
                            if let shape2D = shapes2D[shapeName] {

                                let ppm = physics2D.ppm
                                // Define the dynamic body. We set its position and call the body factory.
                                let bodyDef = b2BodyDef()
                                bodyDef.angle = shape2D.options.rotation.x.degreesToRadians
                                bodyDef.type = b2BodyType.staticBody

                                let polyShape = b2PolygonShape()
                                polyShape.setAsBox(halfWidth: shape2D.options.size.x / ppm, halfHeight: shape2D.options.size.y / ppm)

                                let fixtureDef = b2FixtureDef()
                                fixtureDef.shape = polyShape
                                
                                if let body = cmd.options["body"] as? String {
                                    if body.lowercased() == "dynamic" {
                                        bodyDef.type = b2BodyType.dynamicBody
                                        fixtureDef.density = 1.0
                                        fixtureDef.restitution = 0.0
                                    }
                                }
                                
                                if let restitution = cmd.options["restitution"] as? Float1 {
                                    fixtureDef.restitution = restitution.x
                                } else {
                                    fixtureDef.restitution = 0.0
                                }
                                if let friction = cmd.options["friction"] as? Float1 {
                                    fixtureDef.friction = friction.x
                                } else {
                                    fixtureDef.friction = 0.3
                                }
                                if let density = cmd.options["density"] as? Float1 {
                                    fixtureDef.density = density.x
                                    if density.x == 0 {
                                        bodyDef.type = b2BodyType.staticBody
                                    }
                                }
                                
                                bodyDef.position.set(shape2D.options.position.x / ppm, shape2D.options.position.y / ppm)
                                
                                shapes2D[shapeName]?.body = physics2D.world!.createBody(bodyDef)
                                shapes2D[shapeName]?.body!.createFixture(fixtureDef)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func getImageResource(_ name: String) -> Texture2D?
    {
        if let texture = resources[name] as? Texture2D {
            return texture
        } else {
            let array = name.split(separator: ":")
            if array.count == 2 {
                if let asset = game?.assetFolder.getAssetById(UUID(uuidString: String(array[0]))!, .Image) {
                    if let index = Int(array[1]) {
                    
                        let data = asset.data[index]
                        
                        let texOptions: [MTKTextureLoader.Option : Any] = [.generateMipmaps: false, .SRGB: false]
                        if let texture  = try? game!.textureLoader.newTexture(data: data, options: texOptions) {
                            let texture2D = Texture2D(game!, texture: texture)
                            resources[name] = texture2D
                            return texture2D
                        }
                    }
                }
            }
        }
        return nil
    }

    @discardableResult func drawAlias(_ x: Float,_ y: Float,_ alias: MapAlias, scale: Float = 1) -> (Float, Float)
    {
        var object : [String:Any] = [:]
        var rc     : (Float, Float) = (0,0)

        if alias.type == .Image {
            if let image = images[alias.pointsTo] {
                
                if let texture2D = getImageResource(image.resourceName) {
                    var width = texture2D.width * scale
                    var height = texture2D.height * scale

                    object["x"] = x
                    object["y"] = y
                    object["width"] = width
                    object["height"] = height
                    object["texture"] = texture2D
                    
                    if let v = alias.options["rect"] as? Rect2D {
                        object["rect"] = v
                        width = v.width * scale
                        height = v.height * scale
                        
                        object["width"] = width
                        object["height"] = height
                    }
                
                    game?.texture?.drawTexture(object)

                    if let v = alias.options["repeatx"] as? Bool {
                        if v == true {
                            var posX : Float = x + width
                            while posX < game!.texture!.width {
                                object["x"] = posX
                                game?.texture?.drawTexture(object)
                                posX += width
                            }
                        }
                    }
                    
                    rc.0 = width
                    rc.1 = height
                }
            }
        }
        
        return rc
    }
    
    func drawShape(_ shape: MapShape2D)
    {
        if let grid = shape.grid {
            for s in grid.instances {
                let instShape = s.0
                                
                if instShape.options.visible.toSIMD() == false { continue }
                
                if instShape.shape == .Disk {
                    drawDisk(instShape.options)
                } else
                if instShape.shape == .Box {
                    drawBox(instShape.options)
                } else
                if instShape.shape == .Text {
                    drawText(instShape.options)
                }
            }
        } else {
            if shape.options.visible.toSIMD() == false { return }
            
            if shape.shape == .Disk {
                drawDisk(shape.options)
            } else
            if shape.shape == .Box {
                drawBox(shape.options)
            } else
            if shape.shape == .Text {
                drawText(shape.options)
            }
        }
    }
    
    func drawLayer(_ x: Float,_ y: Float,_ layer: MapLayer, scale: Float = 1)
    {
        var xPos = x
        var yPos = y
        
        if let shs = layer.options["shaders"] as? [String] {
            for shaderName in shs {
                if let sh = shaders[shaderName] {
                    if let shader = sh.shader {
                        drawShader(shader, MMRect(0,0,texture.width, texture.height))
                    }
                }
            }
        }
        
        if let shapes = layer.options["shapes"] as? [String] {
            for shape in shapes {
                if let sh = shapes2D[shape] {
                    drawShape(sh)
                }
            }
        }
        
        for line in layer.data {
            
            var index     : Int = 0
            var maxHeight : Float = 0
            
            while index < line.count - 1 {
                
                let a = String(line[line.index(line.startIndex, offsetBy: index)]) + String(line[line.index(line.startIndex, offsetBy: index+1)])
                if let alias = aliases[a] {
                    let advance = drawAlias(xPos, yPos, alias, scale: scale)
                    xPos += advance.0
                    if advance.1 > maxHeight {
                        maxHeight = advance.1
                    }
                }
                index += 2
            }
            
            yPos -= maxHeight
            xPos = x
        }
    }
    
    func drawScene(_ x: Float,_ y: Float,_ scene: MapScene, scale: Float = 1)
    {
        for (_, physics2D) in physics2D {
        
            let timeStep: b2Float = 1.0 / 60.0
            let velocityIterations = 6
            let positionIterations = 2
        
            physics2D.world!.step(timeStep: timeStep, velocityIterations: velocityIterations, positionIterations: positionIterations)
            
            let ppm = physics2D.ppm

            for (_, shape) in shapes2D {
                if let body = shape.body {
                    //print(shapeName, body.position.x, body.position.y)
                    shape.options.position.x = body.position.x * ppm// - shape.options.size.x / 2.0 * ppm// * game._Aspect.x
                    shape.options.position.y = body.position.y * ppm// - shape.options.size.y / 2.0 * ppm// * game._Aspect.y
                    shape.options.rotation.x = body.angle.radiansToDegrees
                    //object.positionValue?.value.setValue(body.position.x * ppm, forProperty: "x")
                    //object.positionValue?.value.setValue(body.position.y * ppm, forProperty: "y")
                }
            }
        }
        
        if let sceneLayers = scene.options["layers"] as? [String] {
            for l in sceneLayers {
                if let layer = layers[l] {
                    
                    var layerOffX : Float = 0
                    var layerOffY : Float = 0
                    
                    if let sOff = layer.options["sceneoffset"] as? Float2 {
                        layerOffX = sOff.x
                        layerOffY = sOff.y
                    }
                    drawLayer(x + layerOffX, y + layerOffY, layer, scale: scale)
                }
            }
        }
    }
    
    func getCanvasSize() -> Float2 {
        var size = Float2(texture.width, texture.height)

        var name = "Desktop"
        #if os(iOS)
        name = "Mobile"
        #endif
        
        for s in commands {
            if s.command == "CanvasSize" {
                if let platform = s.options["platform"] as? String {
                    if platform == name {
                        if let i = s.options["size"] as? Float2 {
                            size = i
                        }
                    }
                }
            }
        }
        
        return size
    }
    
    /// Draw a Disk
    func drawDisk(_ options: MapShapeData2D)
    {
        var position : SIMD2<Float> = float2(options.position.x * aspect.x, options.position.y * aspect.y)
        let radius : Float = options.radius.x * aspect.z
        let border : Float = options.border.x * aspect.z
        let onion : Float = options.onion.x * aspect.z
        let fillColor : SIMD4<Float> = options.color.toSIMD()
        let borderColor : SIMD4<Float> = options.borderColor.toSIMD()
        
        //position.y = -position.y
        position.x += viewBorder.x
        position.y += viewBorder.y

        position.x /= game.scaleFactor
        position.y /= game.scaleFactor
        
        var data = DiscUniform()
        data.borderSize = border / game.scaleFactor
        data.radius = radius / game.scaleFactor
        data.fillColor = fillColor
        data.borderColor = borderColor
        data.onion = onion / game.scaleFactor

        let rect = MMRect(position.x - data.borderSize / 2, position.y - data.borderSize / 2, data.radius * 2 + data.borderSize * 2, data.radius * 2 + data.borderSize * 2, scale: game.scaleFactor )
        let vertexData = game.createVertexData(texture: texture, rect: rect)
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = texture.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        
        let renderEncoder = game.gameCmdBuffer!.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
                
        renderEncoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
        renderEncoder.setVertexBytes(&game.viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)
        
        renderEncoder.setFragmentBytes(&data, length: MemoryLayout<DiscUniform>.stride, index: 0)
        renderEncoder.setRenderPipelineState(game.metalStates.getState(state: .DrawDisc))
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        renderEncoder.endEncoding()
    }
    
    /// Draw a Box
    func drawBox(_ options: MapShapeData2D)
    {
        var position : SIMD2<Float> = float2(options.position.x * aspect.x, options.position.y * aspect.y)
        let size : SIMD2<Float> = float2(options.size.x * aspect.x, options.size.y * aspect.y)
        let round : Float = options.round.x * aspect.z
        let border : Float = options.border.x * aspect.z
        let rotation : Float = options.rotation.x
        let onion : Float = options.onion.x * aspect.z
        let fillColor : SIMD4<Float> = options.color.toSIMD()
        let borderColor : SIMD4<Float> = options.borderColor.toSIMD()
        
        position.x += viewBorder.x
        position.y += viewBorder.y
        
        position.x /= game.scaleFactor
        position.y /= game.scaleFactor

        var data = BoxUniform()
        data.onion = onion / game.scaleFactor
        data.size = float2(size.x / game.scaleFactor, size.y / game.scaleFactor)
        data.round = round / game.scaleFactor
        data.borderSize = border / game.scaleFactor
        data.fillColor = fillColor
        data.borderColor = borderColor
                
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = texture.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        
        let renderEncoder = game.gameCmdBuffer!.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

        /*
        if rotation == 0 {
            let rect = MMRect(position.x, position.y, data.size.x, data.size.y, scale: game.scaleFactor)
            let vertexData = game.createVertexData(texture: texture, rect: rect)
            renderEncoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
            renderEncoder.setVertexBytes(&game.viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)

            renderEncoder.setFragmentBytes(&data, length: MemoryLayout<BoxUniform>.stride, index: 0)
            renderEncoder.setRenderPipelineState(game.metalStates.getState(state: .DrawBox))
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        } else {*/
            data.pos.x = position.x
            data.pos.y = position.y
            data.rotation = rotation.degreesToRadians
            data.screenSize = float2(texture.width / game.scaleFactor, texture.height / game.scaleFactor)

            let rect = MMRect(0, 0, texture.width / game.scaleFactor, texture.height / game.scaleFactor, scale: game.scaleFactor)
            let vertexData = game.createVertexData(texture: texture, rect: rect)
                                    
            renderEncoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
            renderEncoder.setVertexBytes(&game.viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)

            renderEncoder.setFragmentBytes(&data, length: MemoryLayout<BoxUniform>.stride, index: 0)
            renderEncoder.setRenderPipelineState(game.metalStates.getState(state: .DrawBoxExt))
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        //}
        renderEncoder.endEncoding()
    }
    
    /// Draws the given text
    func drawText(_ options: MapShapeData2D)
    {
        var position : SIMD2<Float> = float2(options.position.x * aspect.x, options.position.y * aspect.y)
        let size : Float = options.text.fontSize * aspect.z
        let font : Font? = options.text.font
        var text : String = ""
        let color : SIMD4<Float> = options.color.toSIMD()

        position.x += viewBorder.x
        position.y += viewBorder.y
        
        if let t = options.text.text {
            text = t
        } else
        if let f1 = options.text.f1 {
            if let digits = options.text.digits {
                text = String(format: "%.0\(digits.x)f", f1.x)
            } else {
                text = String(f1.x)
            }
        } else
        if let i1 = options.text.i1 {
            if let digits = options.text.digits {
                text = String(format: "%0\(digits.x)d", i1.x)
            } else {
                text = String(i1.x)
            }
        } else
        if let f2 = options.text.f2 {
            if let digits = options.text.digits {
                text = String(format: "%.0\(digits.x)f", f2.x) + " " + String(format: "%.0\(digits.x)f", f2.y)
            } else {
                text = String(f2.x) + " " + String(f2.y)
            }
        } else
        if let f3 = options.text.f3 {
            if let digits = options.text.digits {
                text = String(format: "%.0\(digits.x)f", f3.x) + " " + String(format: "%.0\(digits.x)f", f3.y) + " " + String(format: "%.0\(digits.x)f", f3.z)
            } else {
                text = String(f3.x) + " " + String(f3.y) + " " + String(f3.z)
            }
        } else
        if let f4 = options.text.f4 {
            if let digits = options.text.digits {
                text = String(format: "%.0\(digits.x)f", f4.x) + " " + String(format: "%.0\(digits.x)f", f4.y) + " " + String(format: "%.0\(digits.x)f", f4.z) + " " + String(format: "%.0\(digits.x)f", f4.w)
            } else {
                text = String(f4.x) + " " + String(f4.y) + " " + String(f4.z) + " " + String(f4.w)
            }
        }

        //position.y = -position.y;
        let scaleFactor : Float = game.scaleFactor
        
        func drawChar(char: BMChar, x: Float, y: Float, adjScale: Float)
        {
            var data = TextUniform()
            
            data.atlasSize.x = Float(font!.atlas!.width) * scaleFactor
            data.atlasSize.y = Float(font!.atlas!.height) * scaleFactor
            data.fontPos.x = char.x * scaleFactor
            data.fontPos.y = char.y * scaleFactor
            data.fontSize.x = char.width * scaleFactor
            data.fontSize.y = char.height * scaleFactor
            data.color = color

            let rect = MMRect(x, y, char.width * adjScale, char.height * adjScale, scale: scaleFactor)
            let vertexData = game.createVertexData(texture: texture, rect: rect)
            
            let renderPassDescriptor = MTLRenderPassDescriptor()
            renderPassDescriptor.colorAttachments[0].texture = texture.texture
            renderPassDescriptor.colorAttachments[0].loadAction = .load
            
            let renderEncoder = game.gameCmdBuffer!.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

            renderEncoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
            renderEncoder.setVertexBytes(&game.viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)

            renderEncoder.setFragmentBytes(&data, length: MemoryLayout<TextUniform>.stride, index: 0)
            renderEncoder.setFragmentTexture(font!.atlas, index: 1)

            renderEncoder.setRenderPipelineState(game.metalStates.getState(state: .DrawTextChar))
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            renderEncoder.endEncoding()
        }
        
        if let font = font {
         
            let scale : Float = (1.0 / font.bmFont!.common.lineHeight) * size
            let adjScale : Float = scale// / 2
            
            var posX = position.x / game.scaleFactor
            let posY = position.y / game.scaleFactor

            for c in text {
                let bmChar = font.getItemForChar( c )
                if bmChar != nil {
                    drawChar(char: bmChar!, x: posX + bmChar!.xoffset * adjScale, y: posY + bmChar!.yoffset * adjScale, adjScale: adjScale)
                    posX += bmChar!.xadvance * adjScale;
                }
            }
        }
    }
    
    /// Draws the given shader
    func drawShader(_ shader: Shader, _ rect: MMRect)
    {
        let vertexData = game.createVertexData(texture: texture, rect: rect)
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = texture.texture!
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        
        let renderEncoder = game.gameCmdBuffer!.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

        renderEncoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
        renderEncoder.setVertexBytes(&game.viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)

        var behaviorData = BehaviorData()
        
        if shader.hasBindings {            
            for (_, binding) in shader.intVar {
                if let value = binding.1 as? Int1 {
                    if binding.0 == 0 { behaviorData.intData.0 = Int32(value.x) }
                    else if binding.0 == 1 { behaviorData.intData.1 = Int32(value.x) }
                    else if binding.0 == 2 { behaviorData.intData.2 = Int32(value.x) }
                    else if binding.0 == 3 { behaviorData.intData.3 = Int32(value.x) }
                    else if binding.0 == 4 { behaviorData.intData.4 = Int32(value.x) }
                    else if binding.0 == 5 { behaviorData.intData.5 = Int32(value.x) }
                    else if binding.0 == 6 { behaviorData.intData.6 = Int32(value.x) }
                    else if binding.0 == 7 { behaviorData.intData.7 = Int32(value.x) }
                    else if binding.0 == 8 { behaviorData.intData.8 = Int32(value.x) }
                    else if binding.0 == 9 { behaviorData.intData.9 = Int32(value.x) }
                }
            }
            for (_, binding) in shader.floatVar {
                if let value = binding.1 as? Float1 {
                    if binding.0 == 0 { behaviorData.floatData.0 = value.x }
                    else if binding.0 == 1 { behaviorData.floatData.1 = value.x }
                    else if binding.0 == 2 { behaviorData.floatData.2 = value.x }
                    else if binding.0 == 3 { behaviorData.floatData.3 = value.x }
                    else if binding.0 == 4 { behaviorData.floatData.4 = value.x }
                    else if binding.0 == 5 { behaviorData.floatData.5 = value.x }
                    else if binding.0 == 6 { behaviorData.floatData.6 = value.x }
                    else if binding.0 == 7 { behaviorData.floatData.7 = value.x }
                    else if binding.0 == 8 { behaviorData.floatData.8 = value.x }
                    else if binding.0 == 9 { behaviorData.floatData.9 = value.x }
                }
            }
            for (_, binding) in shader.float2Var {
                if let value = binding.1 as? Float2 {
                    if binding.0 == 0 { behaviorData.float2Data.0 = value.toSIMD() }
                    else if binding.0 == 1 { behaviorData.float2Data.1 = value.toSIMD() }
                    else if binding.0 == 2 { behaviorData.float2Data.2 = value.toSIMD() }
                    else if binding.0 == 3 { behaviorData.float2Data.3 = value.toSIMD() }
                    else if binding.0 == 4 { behaviorData.float2Data.4 = value.toSIMD() }
                    else if binding.0 == 5 { behaviorData.float2Data.5 = value.toSIMD() }
                    else if binding.0 == 6 { behaviorData.float2Data.6 = value.toSIMD() }
                    else if binding.0 == 7 { behaviorData.float2Data.7 = value.toSIMD() }
                    else if binding.0 == 8 { behaviorData.float2Data.8 = value.toSIMD() }
                    else if binding.0 == 9 { behaviorData.float2Data.9 = value.toSIMD() }
                }
            }
            for (_, binding) in shader.float3Var {
                if let value = binding.1 as? Float3 {
                    if binding.0 == 0 { behaviorData.float3Data.0 = value.toSIMD() }
                    else if binding.0 == 1 { behaviorData.float3Data.1 = value.toSIMD() }
                    else if binding.0 == 2 { behaviorData.float3Data.2 = value.toSIMD() }
                    else if binding.0 == 3 { behaviorData.float3Data.3 = value.toSIMD() }
                    else if binding.0 == 4 { behaviorData.float3Data.4 = value.toSIMD() }
                    else if binding.0 == 5 { behaviorData.float3Data.5 = value.toSIMD() }
                    else if binding.0 == 6 { behaviorData.float3Data.6 = value.toSIMD() }
                    else if binding.0 == 7 { behaviorData.float3Data.7 = value.toSIMD() }
                    else if binding.0 == 8 { behaviorData.float3Data.8 = value.toSIMD() }
                    else if binding.0 == 9 { behaviorData.float3Data.9 = value.toSIMD() }
                }
            }
            for (_, binding) in shader.float4Var {
                if let value = binding.1 as? Float4 {
                    if binding.0 == 0 { behaviorData.float4Data.0 = value.toSIMD() }
                    else if binding.0 == 1 { behaviorData.float4Data.1 = value.toSIMD() }
                    else if binding.0 == 2 { behaviorData.float4Data.2 = value.toSIMD() }
                    else if binding.0 == 3 { behaviorData.float4Data.3 = value.toSIMD() }
                    else if binding.0 == 4 { behaviorData.float4Data.4 = value.toSIMD() }
                    else if binding.0 == 5 { behaviorData.float4Data.5 = value.toSIMD() }
                    else if binding.0 == 6 { behaviorData.float4Data.6 = value.toSIMD() }
                    else if binding.0 == 7 { behaviorData.float4Data.7 = value.toSIMD() }
                    else if binding.0 == 8 { behaviorData.float4Data.8 = value.toSIMD() }
                    else if binding.0 == 9 { behaviorData.float4Data.9 = value.toSIMD() }
                }
            }
        }
        
        renderEncoder.setFragmentBytes(&behaviorData, length: MemoryLayout<BehaviorData>.stride, index: 0)

        renderEncoder.setRenderPipelineState(shader.pipelineState)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        renderEncoder.endEncoding()
    }
}
