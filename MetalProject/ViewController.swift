//
//  ViewController.swift
//  MetalProject
//
//  Created by Sina Dashtebozorgy on 22/12/2022.
//

import Cocoa
import Metal
import MetalKit


var mouse_x : Float?
var mouse_y : Float?

class ViewController: NSViewController {
    
    var cameraOrigin : simd_float3?
    var cameraDirection : simd_float3?
    
    var cameraState : Bool = false {
        didSet {
            
            if let origin = cameraOrigin, let direction = cameraDirection {
               // print(origin,direction)
                var camera = simd_float4x4(eye: origin, center: direction, up: simd_float3(0,1,0))
                //renderer.currentScene.updateCamera(with: camera)
//                self.renderer.currentScene.eye = origin
//                self.renderer.currentScene.direction = direction
            }

                cameraState = false
        }
    }
    
    @IBOutlet weak var xEye: NSTextField!
    @IBOutlet weak var yEye: NSTextField!
    @IBOutlet weak var zEye: NSTextField!
    
    @IBOutlet weak var testOrigin: NSTextField!
    
    @IBOutlet weak var testDirection: NSTextField!
    
    @IBAction func updateCamera(_ sender: NSTextField) {
        
        switch sender {
        case xEye:
            print(sender.doubleValue)
            return
        case yEye:
            print(sender.doubleValue)
            return
        case zEye:
            print(sender.doubleValue)
            return
        case testOrigin:
            let origin = sender.stringValue.split(separator: ",")
            cameraState = true
            cameraOrigin = simd_float3(Float(origin[0])!,Float(origin[1])!,Float(origin[2])!)
            return
        case testDirection:
            let direction = sender.stringValue.split(separator: ",")
            cameraDirection = simd_float3(Float(direction[0])!,Float(direction[1])!,Float(direction[2])!)
            cameraState = true
        default:
            return
        }
    }
    

    @IBOutlet weak var skybox1: NSButton!
    @IBOutlet weak var skybox0: NSButton!
    
   
    var mtkView: MTKView!
    var renderer: Renderer!
    
    override func mouseMoved(with event: NSEvent) {
//        if mouse_x == nil && mouse_y == nil {
//            mouse_x = Float(event.locationInWindow.x)
//            mouse_y = Float(event.locationInWindow.y)
//            renderer.testCamera.previous_x = mouse_x
//            renderer.testCamera.previous_y = mouse_y
//        }
//        else {
//            //print(event.locationInWindow.y,event.locationInWindow.x)
//            mouse_x = Float(event.locationInWindow.x)
//            mouse_y = Float(event.locationInWindow.y)
//            renderer.testCamera.update()
//        }
    }
    override func mouseUp(with event: NSEvent) {
        for camera in renderer.cameraLists{
            camera.reset_mouse()

        }
    }
    
   
    override func mouseDragged(with event: NSEvent) {
        let pos = simd_float2(Float(event.locationInWindow.x),Float(event.locationInWindow.y))
        for camera in renderer.cameraLists{
            camera.update_mouse(with: pos)

        }
    }
    
    func myKeyDownEvent(event: NSEvent) -> NSEvent
    {
        switch event.keyCode {
        case Keycode.l:
            if(renderer.shadowScene!.renderDepth ){
                renderer.shadowScene?.renderDepth = false
            }
            else{
                renderer.shadowScene?.renderDepth = true
            }
            break
        case Keycode.space:
            if(renderer.adjustSceneCamera){
                renderer.adjustSceneCamera = false
            }
            else {
                renderer.adjustSceneCamera = true
            }
            break
        case Keycode.w:
            if(renderer.adjustSceneCamera){
                for camera in renderer.cameraLists{
                    camera.update_eye(with: simd_float3(0,1,0))
                }
            }
            else {
                for camera in renderer.lightCameraLists {
                    camera.update_eye(with: simd_float3(0,1,0))
                }
            }
            break
        case Keycode.s:
            if(renderer.adjustSceneCamera){
                for camera in renderer.cameraLists{
                    camera.update_eye(with: simd_float3(0,-1,0))
                }
            }
            else {
                for camera in renderer.lightCameraLists {
                    camera.update_eye(with: simd_float3(0,-1,0))
                }
            }
            break
        case Keycode.a:
            if(renderer.adjustSceneCamera){
                for camera in renderer.cameraLists{
                    camera.update_eye(with: simd_float3(-1,0,0))
                }
            }
            else {
                for camera in renderer.lightCameraLists {
                    camera.update_eye(with: simd_float3(-1,0,0))
                }
            }
            break
        case Keycode.d:
            if(renderer.adjustSceneCamera){
                for camera in renderer.cameraLists{
                    camera.update_eye(with: simd_float3(1,0,0))
                }
            }
            else {
                for camera in renderer.lightCameraLists {
                    camera.update_eye(with: simd_float3(1,0,0))
                }
            }
            break
        case Keycode.q:
            if(renderer.adjustSceneCamera){
                for camera in renderer.cameraLists{
                    camera.update_eye(with: simd_float3(0,0,1))
                }
            }
            else {
                for camera in renderer.lightCameraLists {
                    camera.update_eye(with: simd_float3(0,0,1))
                }
            }
            break
        case Keycode.e:
            if(renderer.adjustSceneCamera){
                for camera in renderer.cameraLists{
                    camera.update_eye(with: simd_float3(0,0,-1))
                }
            }
            else {
                for camera in renderer.lightCameraLists {
                    camera.update_eye(with: simd_float3(0,0,-1))
                }
            }
            break
        default:
            break
        }
        
        return event
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask.keyDown, handler: myKeyDownEvent)
        let ta = NSTrackingArea(rect: CGRect.zero, options: [.activeAlways, .inVisibleRect, .mouseMoved], owner: self, userInfo: nil)
        self.view.addTrackingArea(ta)
        
        
        
        // First we save the MTKView to a convenient instance variable
        guard let mtkViewTemp = self.view as? MTKView else {
            print("View attached to ViewController is not an MTKView!")
            return
        }
        
        mtkView = mtkViewTemp
       
        

        // Then we create the default device, and configure mtkView with it
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported on this device")
            return
        }

        print("My GPU is: \(defaultDevice)")
        mtkView.device = defaultDevice

        // Lastly we create an instance of our Renderer object,
        // and set it as the delegate of mtkView
        guard let tempRenderer = Renderer(mtkView: mtkView) else {
            print("Renderer failed to initialize")
            return
        }
       renderer = tempRenderer
//
       mtkView.delegate = renderer


    }
}

