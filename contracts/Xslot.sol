pragma solidity ^0.4.19;

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */

  constructor() public {
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

    uint private columnCount = 5;

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

    constructor() public {
      owner = msg.sender;
    }

    function () external payable {

    }

    function getRandomNumTest() onlyOwner public returns (uint32) {
        uint32 ran = _getRandomNum(blockhash(block.number));
      return ran;
    }

    function _getRandomNum(bytes32 hash) onlyUser internal returns (uint32) {
      nonce++;
      seed = keccak256(now, nonce);
      return uint32(uint32(keccak256(hash, seed)) % (10 ** columnCount));
    }

    struct mapCountStruct {
        mapping (uint32 => uint8) numCountMap;
    }

    function _createNewGame() onlyUser internal returns (Game) {
      uint gameId = games.length;
      Game memory newGame;

      newGame.id = gameId;
      newGame.player = msg.sender;
      newGame.amount = msg.value;

      newGame.blockNumber = block.number;
      newGame.hash = blockhash(block.number);
      newGame.number = _getRandomNum(newGame.hash);


      mapCountStruct storage mapCount;
      uint32 iteratorNum = newGame.number;
      newGame.result = GameResult.LOST;
      for(uint16 i = 0; i < columnCount; ++i) {
        uint32 columnNum = iteratorNum % 10;
        mapCount.numCountMap[columnNum] += 1;
        iteratorNum = iteratorNum / 10;

        if(mapCount.numCountMap[columnNum] >= 3) {
          newGame.result = GameResult.WON;
          newGame.prize = getBalance();
        } else if(mapCount.numCountMap[columnNum] >= 2 && newGame.result != GameResult.WON) {
          newGame.result = GameResult.DRAW;
          newGame.prize = newGame.amount;
        } else {
          newGame.result = GameResult.LOST;
          newGame.prize = 0;
        }
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
