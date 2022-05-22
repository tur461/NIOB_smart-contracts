//SPDX-License-Idetifier: MIT
pragma solidity ^0.8.4;

// this contract is also called Yield Farm Contract
import './NiobToken.sol';
import './abstracts/Ownable.sol';
import './libraries/SafeMath.sol';
import './libraries/SafeBEP20.sol';
import './interfaces/INiobReferral.sol';
import './abstracts/ReentrancyGuard.sol';

// MasterChef is the master of Niob. He can make Niob and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once NIOB is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    uint256 constant public DAY_IN_SECONDS = 86400;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        uint256 rewardLockedUp;  // Reward locked up.
        uint256 nextHarvestUntil; // When can the user harvest again.
        uint256 lastCount;         // Count of the last niob withdraw
        //
        // We do some fancy math here. Basically, any point in time, the amount of NIOBs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accNiobPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accNiobPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. NIOBs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that NIOBs distribution occurs.
        uint256 accNiobPerShare;   // Accumulated NIOBs per share, times 1e12. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
        uint256 harvestInterval;  // Harvest interval in seconds
    }

    struct LockNiob{
        uint256 amount;
        uint256 time;
    }

    // The NIOB TOKEN!
    NiobToken public niob;
    // Dev address.
    address public devAddress;
    // Deposit Fee address
    
    address public feeAddress;
    // NIOB tokens created per block.
    uint256 public niobPerBlock;
    // Bonus muliplier for early Niob makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Max harvest interval: 14 days.
    uint256 public constant MAXIMUM_HARVEST_INTERVAL = 14 days;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Type of the pool , 1- farming & 2- pools
    mapping(address => uint) public poolType;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when NIOB mining starts.
    uint256 public startBlock;
    // Total locked up rewards
    uint256 public totalLockedUpRewards;
    //Max level to get the referral commission
    uint256 public maxLevel;

    // Niob referral contract address.
    INiobReferral public niobReferral;
    // Referral commission rate in basis points.
    mapping(uint256 => uint256) public referralCommissionRate;
    // Max referral commission rate: 10%.
    uint16 public constant MAXIMUM_REFERRAL_COMMISSION_RATE = 1000;
    uint256 public constant MAX_LEVEL = 10;

    uint256 public lockTime;
    uint256 public niobId;
    mapping(address => uint256) public lockCount; // count for each user
    mapping(address => mapping(uint256 => LockNiob)) public lock; // each locked amount for each user.

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmissionRateUpdated(address indexed caller, uint256 previousAmount, uint256 newAmount);
    event ReferralCommissionPaid(address indexed user, address indexed referrer, uint256 commissionAmount);
    event RewardLockedUp(address indexed user, uint256 indexed pid, uint256 amountLockedUp);

    constructor(
        NiobToken _niob,
        uint256 _startBlock,
        uint256 _niobPerBlock,
        uint256 _days
    ) {
        niob = _niob;
        startBlock = _startBlock;
        niobPerBlock = _niobPerBlock;
        lockTime = _days * DAY_IN_SECONDS;

        devAddress = msg.sender;
        feeAddress = msg.sender;
        
        maxLevel = 3;

        referralCommissionRate[1] = 100;
        referralCommissionRate[2] = 100;
        referralCommissionRate[3] = 100;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IBEP20 _lpToken, uint16 _depositFeeBP, uint256 _harvestInterval, bool _withUpdate, uint _type) public onlyOwner {
        require(_depositFeeBP <= 10000, "add: invalid deposit fee basis points");
        require(_harvestInterval <= MAXIMUM_HARVEST_INTERVAL, "add: invalid harvest interval");
        require(_type <= 2, "add: invalid type number");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accNiobPerShare: 0,
            depositFeeBP: _depositFeeBP,
            harvestInterval: _harvestInterval
        }));
        poolType[address(_lpToken)] = _type;
        if(address(_lpToken) == address(niob))
            niobId = poolInfo.length - 1;
    }

    // Update the given pool's NIOB allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, uint256 _harvestInterval, bool _withUpdate, uint _type) public onlyOwner {
        require(_depositFeeBP <= 10000, "set: invalid deposit fee basis points");
        require(_harvestInterval <= MAXIMUM_HARVEST_INTERVAL, "set: invalid harvest interval");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        poolInfo[_pid].harvestInterval = _harvestInterval;
        poolType[address(poolInfo[_pid].lpToken)] = _type;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending NIOBs on frontend.
    function pendingNiob(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accNiobPerShare = pool.accNiobPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 niobReward = multiplier.mul(niobPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accNiobPerShare = accNiobPerShare.add(niobReward.mul(1e12).div(lpSupply));
        }
        uint256 pending = user.amount.mul(accNiobPerShare).div(1e12).sub(user.rewardDebt);
        return pending.add(user.rewardLockedUp);
    }

    // View function to see if user can harvest NIOBs.
    function canHarvest(uint256 _pid, address _user) public view returns (bool) {
        UserInfo storage user = userInfo[_pid][_user];
        return block.timestamp >= user.nextHarvestUntil;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 niobReward = multiplier.mul(niobPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        niob.mint(devAddress, niobReward.div(10));
        niob.mint(address(this), niobReward);
        pool.accNiobPerShare = pool.accNiobPerShare.add(niobReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for NIOB allocation.
    function deposit(uint256 _pid, uint256 _amount, address _referrer) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (_amount > 0 && address(niobReferral) != address(0) && _referrer != address(0) && _referrer != msg.sender) {
            niobReferral.recordReferral(msg.sender, _referrer);
        }
        payOrLockupPendingNiob(_pid);
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            if (address(pool.lpToken) == address(niob)) {
                uint256 transferTax = _amount.mul(niob.transferTaxRate()).div(10000);
                _amount = _amount.sub(transferTax);
            }
            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
                if(_pid == niobId) {
                    setNiobAmount(msg.sender,_amount.sub(depositFee));
                }
            } else {
                user.amount = user.amount.add(_amount);
                if(_pid == niobId) {
                    setNiobAmount(msg.sender,_amount);
                }
            }
        }
        user.rewardDebt = user.amount.mul(pool.accNiobPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        require(_pid != niobId, "withdraw: niob id sent");
        updatePool(_pid);
        payOrLockupPendingNiob(_pid);
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            }
        user.rewardDebt = user.amount.mul(pool.accNiobPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    //withdraw niob token
    function withdrawNiob(uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[niobId];
        UserInfo storage user = userInfo[niobId][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(niobId);
        payOrLockupPendingNiob(niobId);
        if(_amount > 0) {
            uint256 check = 0;
            uint256 i = user.lastCount;
            (,uint256 _count) = getWithdrawableNiob(msg.sender);
            for(i; i<_count; i++) {
                check += lock[msg.sender][i].amount;
                if(check > _amount) 
                    break;
            }
            lock[msg.sender][i].amount = check.sub(_amount);
            user.lastCount = i.sub(1);
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accNiobPerShare).div(1e12);
        emit Withdraw(msg.sender, niobId, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        user.rewardLockedUp = 0;
        user.nextHarvestUntil = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Locking the amount till lockTime period
    function setNiobAmount(address _user, uint256 _amount) internal {
        LockNiob memory temp;
        temp.amount = _amount;
        temp.time = block.timestamp;
        lock[_user][lockCount[_user]] = temp;
        lockCount[_user]++;
    }

    // Pay or lockup pending Niobs.
    function payOrLockupPendingNiob(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.nextHarvestUntil == 0) {
            user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);
        }

        uint256 pending = user.amount.mul(pool.accNiobPerShare).div(1e12).sub(user.rewardDebt);
        if (canHarvest(_pid, msg.sender)) {
            if (pending > 0 || user.rewardLockedUp > 0) {
                uint256 totalRewards = pending.add(user.rewardLockedUp);

                // reset lockup
                totalLockedUpRewards = totalLockedUpRewards.sub(user.rewardLockedUp);
                user.rewardLockedUp = 0;
                user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);

                // send rewards
                safeNiobTransfer(msg.sender, totalRewards);
                payReferralCommission(msg.sender, totalRewards);
            }
        } else if (pending > 0) {
            user.rewardLockedUp = user.rewardLockedUp.add(pending);
            totalLockedUpRewards = totalLockedUpRewards.add(pending);
            emit RewardLockedUp(msg.sender, _pid, pending);
        }
    }

    // Safe niob transfer function, just in case if rounding error causes pool to not have enough NIOBs.
    function safeNiobTransfer(address _to, uint256 _amount) internal {
        uint256 niobBal = niob.balanceOf(address(this));
        if (_amount > niobBal) {
            niob.transfer(_to, niobBal);
        } else {
            niob.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function setDevAddress(address _devAddress) public {
        require(msg.sender == devAddress, "setDevAddress: FORBIDDEN");
        require(_devAddress != address(0), "setDevAddress: ZERO");
        devAddress = _devAddress;
    }

    function setFeeAddress(address _feeAddress) public {
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        require(_feeAddress != address(0), "setFeeAddress: ZERO");
        feeAddress = _feeAddress;
    }

    // Pancake has to add hidden dummy pools in order to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _niobPerBlock) public onlyOwner {
        massUpdatePools();
        emit EmissionRateUpdated(msg.sender, niobPerBlock, _niobPerBlock);
        niobPerBlock = _niobPerBlock;
    }

    // Update the niob referral contract address by the owner
    function setNiobReferral(INiobReferral _niobReferral) public onlyOwner {
        niobReferral = _niobReferral;
    }

    // Update referral commission rate by the owner
    function setReferralCommissionRate(uint16 _referralCommissionRate, uint256 level) public onlyOwner {
        require(_referralCommissionRate <= MAXIMUM_REFERRAL_COMMISSION_RATE, "setReferralCommissionRate: invalid referral commission rate basis points");
        require(level > 0 && level <= MAX_LEVEL, "setReferralCommissionRate: invalid level");
        
        referralCommissionRate[level] = _referralCommissionRate;
    }
    
    // Change the level till which commission will be sent
    function setMaxLevel(uint256 newMax) external onlyOwner {
        require(newMax > 0 && newMax <= MAX_LEVEL, "setMaxLevel: invalid level");
        require(newMax != maxLevel, "setMaxLevel: previous value");

        maxLevel = newMax;
    }

    // Change the lock period for niob pool
    function setLockTime(uint256 _time) external onlyOwner {
        require(_time <= 730, "setLockTime: time exceeds limit");
        
        lockTime = _time;
    }
    
    // To change the type for any token
    function setPoolType(IBEP20 _lpToken, uint8 _type) public onlyOwner {
        require(_type <= 2, "setPoolType : invalid type number");
        require(poolType[address(_lpToken)] != 0 ,"setPoolType: token pool not created");
        require(poolType[address(_lpToken)] != _type, "setPoolType: same type number sent");
        poolType[address(_lpToken)] = _type;
    }

    // Pay referral commission to the referrer who referred this user.
    function payReferralCommission(address _user, uint256 _pending) internal {
        if (address(niobReferral) != address(0)) {
            address referrer;
            uint256 commissionAmount;
            for (uint i = 1; i <= maxLevel; i++) {
            	referrer = niobReferral.getReferrer(_user);

                if (referrer == address(0)) {
                    return;
                }
                
                commissionAmount = (_pending.mul(referralCommissionRate[i])).div(10000);
                
                if (referrer != address(0) && commissionAmount > 0) {
                    niob.mint(referrer, commissionAmount);
                    niobReferral.recordReferralCommission(referrer, commissionAmount);
                    emit ReferralCommissionPaid(_user, referrer, commissionAmount);
                }

                _user = referrer;
            }
        }
    }

    function getWithdrawableNiob(address _user) public view returns(uint256, uint256) {
        uint256 totalAmount = 0;
        uint256 i = userInfo[niobId][_user].lastCount;
        for(i; i< lockCount[_user]; i++) {
            if(lock[_user][i].time + lockTime <= block.timestamp) {
                totalAmount += lock[_user][i].amount;
            } else 
                break;
        }
        return (totalAmount, i);
    }
}