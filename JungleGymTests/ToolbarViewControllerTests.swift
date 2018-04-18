import XCTest
@testable import JungleGym

class ToolbarViewControllerTests: XCTestCase {
    func testEmptySimulatorsAreShownCorrectly() {
        let viewController = NSStoryboard.main.instantiateController(withIdentifier: .toolbarViewController) as! ToolbarViewController
        _ = viewController.view // load the view

        viewController.state.simulators = []

        XCTAssert(viewController.simulatorPopupButton.menu!.items.isEmpty)
    }
}
