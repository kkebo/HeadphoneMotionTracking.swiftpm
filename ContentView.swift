import ARKit
import CoreMotion
import SceneKit
import SwiftUI

struct ContentView {
    @State private var manager = CMHeadphoneMotionManager()
    @State private var motion: CMDeviceMotion?
    @State private var attitudeOffset: CMAttitude?
    @State private var scene = SCNScene()
    @State private var faceNode = SCNNode()
    @State private var cameraNode = SCNNode()

    private func startUpdatingMotion() {
        guard manager.isDeviceMotionAvailable else { return }
        manager.startDeviceMotionUpdates(to: .main) { motion, error in
            if let error { fatalError("\(error.localizedDescription)") }
            guard let motion else { fatalError("no value") }
            self.motion = motion
            if attitudeOffset == nil {
                attitudeOffset = motion.attitude
            }

            updateFace(attitude: motion.attitude)
        }
    }

    private func updateFace(attitude: CMAttitude) {
        guard let attitudeOffset else { fatalError() }
        faceNode.eulerAngles.x = -Float(attitude.pitch - attitudeOffset.pitch)
        faceNode.eulerAngles.y = Float(attitude.yaw - attitudeOffset.yaw)
        faceNode.eulerAngles.z = Float(attitude.roll - attitudeOffset.roll)
    }

    private func initializeScene() {
        scene.background.contents = UIColor.black

        let geometry = ARSCNFaceGeometry(device: MTLCreateSystemDefaultDevice()!)!
        let material = SCNMaterial()
        material.fillMode = .lines
        geometry.firstMaterial = material
        faceNode.geometry = geometry
        scene.rootNode.addChildNode(faceNode)

        let camera = SCNCamera()
        camera.fieldOfView = 20.0
        cameraNode.camera = camera
        cameraNode.position = .init(0, 0, 1.1)
        scene.rootNode.addChildNode(cameraNode)
    }
}

extension ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "airpodspro").imageScale(.large)
            if !manager.isDeviceMotionAvailable {
                Text("Your device doesn't support headphone motion tracking.")
            } else if let motion {
                Group {
                    ProgressView("roll", value: (motion.attitude.roll + 1) / 2)
                    ProgressView("pitch", value: (motion.attitude.pitch + 1) / 2)
                    ProgressView("yaw", value: (motion.attitude.yaw + 1) / 2)
                }
                .progressViewStyle(.linear)
            } else {
                ProgressView()
            }
            SceneView(scene: scene, pointOfView: cameraNode)
        }
        .onAppear {
            startUpdatingMotion()
            initializeScene()
        }
    }
}
