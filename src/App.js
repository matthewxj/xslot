import React, { Component } from 'react'
import XslotContract from '../build/contracts/Xslot.json'
import getWeb3 from './utils/getWeb3'

import './css/oswald.css'
import './css/open-sans.css'
import './css/pure-min.css'
import './App.css'


const contractAddress = "0x8D413F09De2Ccd4E12181Dc3bB64CeF4E0246eBC";
var xslotInstance;
var ethBetValue;
var spinEvt;
var self;
var curAnimId;

const contract = require('truffle-contract')
const xslot = contract(XslotContract)

class App extends Component {
  constructor(props) {
    super(props)
    self = this
    this.state = {
      web3: null
    }
  }

  componentWillMount() {
    // Get network provider and web3 instance.
    // See utils/getWeb3 for more info.

    getWeb3
    .then(results => {
      this.setState({
        web3: results.web3
      })

      // Instantiate contract once web3 provided.
      this.instantiateContract()
    })
    .catch(() => {
      console.log('Error finding web3.')
    })
  }

  instantiateContract() {
    /*
     * SMART CONTRACT EXAMPLE
     *
     * Normally these functions would be called in the context of a
     * state management library, but for convenience I've placed them here.
     */

    xslot.setProvider(this.state.web3.currentProvider)

    // Get accounts.
    this.state.web3.eth.getAccounts((error, accounts) => {
      xslot.at(contractAddress).then((instance) => {
      //xslot.deployed().then((instance) => {
        xslotInstance = instance
        this.setState({ spinNumber: "0 0 0" })
        this.setState({ spinResult: "" })

        spinEvt = xslotInstance.SlotSpin({player: accounts[0]})
        spinEvt.watch(this.spinEnd);

        return xslotInstance.getBalance({from: accounts[0]});
      }).then((result) => {
        console.log("balance: " + result.c[0])
        var balance = result.c[0] / 10000
        this.setState({ balanceValue: balance})
        return xslotInstance.spinBet({from: accounts[0]});
      }).then((result) => {
        // Update state with the result.
        console.log(result.c[0])
        ethBetValue = result.c[0] / 10000
        this.setState({ spinBetValue: ethBetValue})
        return;
      })
    })
  }

  spinStart = function() {
    console.log("spin starting");
    self.spinAnimationStart();

    xslotInstance.spin({
      from: self.state.web3.eth.accounts[0],
      value: self.state.web3.toWei(ethBetValue, 'ether')
    }).then(() => {
        xslotInstance.getBalance(self.state.web3.eth.accounts[0]).then((result) => {
          console.log("balance: " + result.c[0])
          var balance = result.c[0] / 10000
          self.setState({ balanceValue: balance})
        });
    })
  }

  spinEnd = function(error, result) {
    if (!error)
    {
      console.log("spinEnd called!");
      self.spinAnimationStop();

      var spinNumber = result.args.number.c[0]
      var spinResult = result.args.result.c[0]
      var spinPrize = result.args.prize.c[0]
      console.log("spinNumber: "+ spinNumber + "spinResult "+spinResult);

      self.setState({ spinNumber: self.spinFormat(spinNumber)})

      if(spinResult === 0) {
        var wonPrize = spinPrize / 10000
        self.setState({ spinResult:  "Player Won "+ wonPrize + " ETH"})
      } else if(spinResult === 1) {
        var drawPrize = spinPrize / 10000
        self.setState({ spinResult:  "Player Draw! Got Back "+ drawPrize + " ETH"})
      } else {
        self.setState({ spinResult:  "Player Lost"})
      }

    } else {
        console.log(error);
    }
  }

  spinFormat = function(spinNumber) {
    var firstNum = Math.floor(spinNumber / 100);
    var secondNum = Math.floor(spinNumber % 100 / 10);
    var thirdNum = Math.floor(spinNumber % 10);
    return firstNum + " " + secondNum + " " + thirdNum;
  }

  spinAnimationStart = function() {
    var btn = document.getElementById("spinBtn");
    btn.innerHTML = "Spinning";
    btn.disabled = true;

    var elem = document.getElementById("spinningNumbers");
    curAnimId = setInterval(frame, 100);
      function frame() {
        var num = Math.floor(Math.random() * 1000)
        elem.innerHTML = self.spinFormat(num)
      }
  }

  spinAnimationStop = function() {
    var btn = document.getElementById("spinBtn");
    btn.innerHTML = "Spin";
    btn.disabled = false;
    clearInterval(curAnimId);
  }

  render() {
    return (
      <div className="App">
        <nav className="navbar pure-menu pure-menu-horizontal">
            <a href="#" className="pure-menu-heading pure-menu-link">XSlot Machine Game</a>
        </nav>

        <main className="container">
          <div className="pure-g">
            <div className="pure-u-1-1">
              <h1 id="spinningNumbers">{this.state.spinNumber}</h1>
              <h2>Current Lottery:  {this.state.balanceValue} ETH</h2>
              <h2>Cost Per Spin:  {this.state.spinBetValue} ETH</h2>
            </div>
          </div>
        </main>

        <button
            id="spinBtn"
            onClick={this.spinStart}
            style={{height: 40,marginLeft: 50}}> Spin
        </button>
        <br /><br /><br />
        <h2>  Spin Result: {this.state.spinResult}</h2>
        <br />

        <div className="pure-g">
          <div className="pure-u-1-1">
            <h1>  Rewards: </h1>
            <h3> 7 7 7 Winner take whole Lottery !</h3>
            <h3> 8 8 8 Winner take 80% Lottery !</h3>
            <h3> 6 6 6 Winner take 60% Lottery !</h3>
            <h3> Other Number Winner take half Lottery !</h3>
            <h3> Two Same Number  = Draw Free Spin !</h3>
          </div>
        </div>

      </div>
    );
  }
}

export default App
