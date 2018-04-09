pragma solidity ^0.4.19;

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract Mortal is Ownable {
    function kill() public onlyOwner {
        selfdestruct(owner);
    }
}

contract Xslot is Mortal {
    enum GameResult {WON,DRAW,LOST}

    modifier onlyUser() {
        if (tx.origin == msg.sender) {
            _;
        } else {
            revert();
        }
    }

    Game[] public games;                                // games
    mapping (address => uint) private balances;         // balances per address

    uint public spinBet = 100 finney;

    bytes32 private seed;
    uint private nonce = 1;

    struct Game {
      address player;
      uint id;
      uint amount;
      GameResult result;
      uint32 number;
      uint prize;
      bytes32 hash;
      uint blockNumber;
    }

    event SlotSpin (
      address indexed player,
      uint indexed gameId,
      uint amount,
      uint32 number,
      uint prize,
      GameResult result
    );

    function Xslot() public {
      owner = msg.sender;
    }

    function () external payable {

    }

    function _getRandomNum(bytes32 hash) onlyUser internal returns (uint32) {
      nonce++;
      seed = keccak256(now, nonce);
      return uint32(keccak256(hash, seed)) % 1000;
    }

    function _createNewGame() onlyUser internal returns (Game) {
      uint gameId = games.length;
      Game memory newGame;

      newGame.id = gameId;
      newGame.player = msg.sender;
      newGame.amount = msg.value;

      newGame.blockNumber = block.number;
      newGame.hash = block.blockhash(block.number);
      newGame.number = _getRandomNum(newGame.hash);

      uint8 firstNum = uint8(newGame.number / 100);
      uint8 thirdNum = uint8(newGame.number % 10);
      uint8 secondNum = uint8(newGame.number % 100 / 10);

      if(firstNum == secondNum && firstNum == thirdNum) {
        newGame.result = GameResult.WON;
        newGame.prize = getBalance();
      } else if(firstNum == secondNum || secondNum == thirdNum || firstNum == thirdNum) {
        newGame.result = GameResult.DRAW;
        newGame.prize = newGame.amount;
      } else {
        newGame.result = GameResult.LOST;
        newGame.prize = 0;
      }
      games.push(newGame);
      return games[gameId];
    }

    function spin() onlyUser public payable returns (GameResult,uint32,uint) {
      require(msg.value >= spinBet);

      Game memory game = _createNewGame();

      if(game.prize > 0) {
        game.player.transfer(game.prize);
      }
      emit SlotSpin(game.player,game.id,game.amount,game.number,game.prize,game.result);
      return (game.result, game.number, game.prize);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function setSpinBet(uint newBet) onlyOwner public {
      spinBet = newBet * 1 finney;
    }

    function ownerDeposit() onlyOwner public payable {
      require(msg.value >= 0);
    }

    function ownerWithdraw(uint amount) onlyOwner public {
        require(amount <= address(this).balance);
        msg.sender.transfer(amount);
    }
}
