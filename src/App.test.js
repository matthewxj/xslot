import React from "react"
import ReactDOM from "react-dom"
import App from "./App"

it('renders without crashing', () => {
  const div = document.createElement('div')
  ReactDOM.render(<App />, div)
})

// @ponicode
describe("componentWillMount", () => {
    let inst

    beforeEach(() => {
        inst = new App.default()
    })

    test("0", () => {
        let callFunction = () => {
            inst.componentWillMount()
        }
    
        expect(callFunction).not.toThrow()
    })
})

// @ponicode
describe("instantiateContract", () => {
    let inst

    beforeEach(() => {
        inst = new App.default()
    })

    test("0", () => {
        let callFunction = () => {
            inst.instantiateContract()
        }
    
        expect(callFunction).not.toThrow()
    })
})
