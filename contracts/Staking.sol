pragma solidity ^0.8.1;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CEStaking is ReentrancyGuard, Ownable {
  IERC20 public CEG;
  IERC20 public CE;
  mapping(address => uint256) _dayStaked;
  event Staked(address indexed staker, uint256 amount, uint256 timeStaked);
  event Withdrawal(address owner, uint256 amount);
  bool open;

  modifier onlyOpen() {
    require(open, "Contract not open");
    _;
  }

  constructor(IERC20 _CEG, IERC20 _CE) {
    CE = _CE;
    CEG = _CEG;
    open = true;
  }

  function stake(uint256 _amountToStake) external nonReentrant onlyOpen {
    require(_amountToStake > 0, "Stake: must be greater than 0");
    require(
      CE.allowance(msg.sender, address(this)) > _amountToStake,
      "Stake: Allowance not enough"
    );
    require(CE.transferFrom(msg.sender, address(this), _amountToStake));
    require(CEG.transfer(msg.sender, _amountToStake));
    _dayStaked[msg.sender] = block.timestamp;

    emit Staked(msg.sender, _amountToStake, block.timestamp);
  }

  function withdraw(uint256 _amountToWithdraw) external nonReentrant onlyOpen {
    require(_amountToWithdraw > 0, "Withdraw: Amount should be greater than 0");

    require(
      ((block.timestamp - _dayStaked[msg.sender]) / 86400) >= 2,
      "Must have staked for 2days or more"
    );
    require(
      CE.allowance(msg.sender, address(this)) > _amountToWithdraw,
      "Stake: Allowance not enough"
    );
    require(CEG.transferFrom(msg.sender, address(this), _amountToWithdraw));
    uint256 bonus = ((((block.timestamp - _dayStaked[msg.sender]) / 86400) *
      10**3) / 365) * _amountToWithdraw;
    uint256 total = _amountToWithdraw + (bonus / 10**3);

    require(CE.balanceOf(address(this)) > total, "Contract not Funded");
    require(CE.transfer(msg.sender, total));
    emit Withdrawal(msg.sender, total);
  }

  function freezeStaking() public onlyOwner {
    open = false;
  }

  function openStaking() public onlyOwner {
    open = true;
  }
}
