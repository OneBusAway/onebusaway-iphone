@testable import Hue
import AppKit
import XCTest

class NSImageTests: XCTestCase {

  func testImageColors() {
    let accuracy: CGFloat = 0.4
    let bundle = Bundle(for: self.classForCoder)
    let path = bundle.path(forResource: "Random Access Memories", ofType: "png")!
    let image = NSImage(contentsOfFile: path)!

    XCTAssertNotNil(image)

    let colors = image.colors()
    
    var (red, green, blue): (CGFloat, CGFloat, CGFloat) = (0,0,0)
    
    colors.background.getRed(&red, green: &green, blue: &blue, alpha: nil)

    XCTAssertEqual(red, 0.035, accuracy: accuracy)
    XCTAssertEqual(green, 0.05, accuracy: accuracy)
    XCTAssertEqual(blue, 0.054, accuracy: accuracy)

    colors.primary.getRed(&red, green: &green, blue: &blue, alpha: nil)

    XCTAssertEqual(red, 0.563, accuracy: accuracy)
    XCTAssertEqual(green, 0.572, accuracy: accuracy)
    XCTAssertEqual(blue, 0.662, accuracy: accuracy)

    colors.secondary.getRed(&red, green: &green, blue: &blue, alpha: nil)

    XCTAssertEqual(red, 0.746, accuracy: accuracy)
    XCTAssertEqual(green, 0.831, accuracy: accuracy)
    XCTAssertEqual(blue, 0.878, accuracy: accuracy)

    colors.detail.getRed(&red, green: &green, blue: &blue, alpha: nil)

    XCTAssertEqual(red, 1.000, accuracy: accuracy)
    XCTAssertEqual(green, 1.000, accuracy: accuracy)
    XCTAssertEqual(blue, 0.85, accuracy: accuracy)
  }

}
