//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract UPNFTStaking_SR is Ownable, ReentrancyGuard, ERC721Holder {
    using SafeERC20 for IERC20;

    event UPNFTStaked(uint256[] tokenIds, address indexed staker);
    event UPNFTUnstaked(uint256[] tokenIds, address indexed staker);
    event RewardClaimed(uint256 reward, address indexed staker);
    event RewardAdded(uint256 reward);

    mapping(uint256 => address) public stakers;
    mapping(address => uint256[]) public stakedNFTs;

    IERC20 public immutable rewardToken;

    IERC721 public immutable upNFT;
    uint256 public totalStaked;

    uint256 public constant DURATION = 40 days;
    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public lastUpdateTime;
    uint256 public rewardPerNFTStored;
    address public rewardDistributor;
    mapping(uint256 => uint256) public rewardPerNFTPaid;

    modifier onlyRewardDistributor() {
        require(msg.sender == rewardDistributor, "Staking: NON_DISTRIBUTOR");
        _;
    }

    constructor(IERC20 _rewardToken, IERC721 _upNFT) {
        rewardToken = _rewardToken;
        upNFT = _upNFT;
    }

    /// @dev validation reward period
    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    /// @dev reward rate per staked token
    function rewardPerNFT() public view returns (uint256) {
        if (totalStaked == 0) {
            return rewardPerNFTStored;
        }
        return
            rewardPerNFTStored +
            ((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18) /
            totalStaked;
    }

    /**
     * @dev stake status for token {id}
     * @param tokenId target tokenId
     */
    function isStaked(uint256 tokenId) external view returns (bool) {
        return stakers[tokenId] != address(0);
    }

    /**
     * @dev view total pending reward for token {id}
     * @param tokenId target tokenId
     */
    function earned(uint256 tokenId) public view returns (uint256) {
        return (rewardPerNFT() - rewardPerNFTPaid[tokenId]) / 1e18;
    }

    function earnedBatch(uint256[] memory tokenIds) external view returns (uint256[] memory) {
        uint256[] memory earneds = new uint256[](tokenIds.length);
        for (uint256 i; i < tokenIds.length; i += 1) {
            earneds[i] = earned(tokenIds[i]);
        }
        return earneds;
    }

    /**
     * @dev view total pending reward for user
     * @param account user address
     */
    function earnedByAccount(address account) public view returns (uint256 reward) {
        for (uint256 i; i < stakedNFTs[account].length; i += 1) {
            if (stakers[stakedNFTs[account][i]] == address(0)) continue;
            reward += earned(stakedNFTs[account][i]);
        }
    }

    /**
     * @dev stake multiple tokens at once.
     * transfer user owned multiple nfts to contract and start getting rewarded
     * @param tokenIds token ids to be staked
     */
    function stake(uint256[] calldata tokenIds) external nonReentrant {
        _updateRewardArguments();

        uint256 len = tokenIds.length;
        totalStaked += len;
        for (uint256 i; i < len; ++i) {
            require(
                upNFT.ownerOf(tokenIds[i]) == msg.sender,
                "Can't stake tokens you don't own!"
            );
            stakers[tokenIds[i]] = msg.sender;
            stakedNFTs[msg.sender].push(tokenIds[i]);
            rewardPerNFTPaid[tokenIds[i]] = rewardPerNFTStored;
            upNFT.safeTransferFrom(msg.sender, address(this), tokenIds[i]);
        }

        emit UPNFTStaked(tokenIds, msg.sender);
    }

    /**
     * @dev unstake multiple tokens at once.
     *  multiple nfts to caller and pending rewards as well.
     * @param tokenIds token ids to be unstaked
     */
    function unstake(uint256[] calldata tokenIds) external nonReentrant {
        _updateRewardArguments();

        uint256 len = tokenIds.length;
        totalStaked -= len;
        for (uint256 i; i < len; ++i) {
            delete stakers[tokenIds[i]];
            uint256 reward = earned(tokenIds[i]);
            if (reward > 0) {
                rewardToken.safeTransfer(msg.sender, reward);
            }
            upNFT.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
        }

        emit UPNFTUnstaked(tokenIds, msg.sender);
    }

    /**
     * @dev claim reward and update reward related arguments
     * @notice emit {RewardClaimed} event
     */
    function claimBatch(uint256[] memory tokenIds) public {
        _updateRewardArguments();

        uint256 reward;
        for (uint256 i; i < tokenIds.length; i += 1) {
            require(stakers[tokenIds[i]] == msg.sender, "Staking: NOT_STAKER");
            reward += earned(tokenIds[i]);
            rewardPerNFTPaid[tokenIds[i]] = rewardPerNFTStored;
        }
        if (reward > 0) {
            rewardToken.safeTransfer(msg.sender, reward);
            emit RewardClaimed(reward, msg.sender);
        }
    }

    function claim() external {
        uint256[] memory tokenIds = new uint256[](stakedNFTs[msg.sender].length);
        uint256 k;
        for (uint256 i; i < stakedNFTs[msg.sender].length; i += 1) {
            if (stakers[stakedNFTs[msg.sender][i]] == address(0)) continue;
            tokenIds[k++] = stakedNFTs[msg.sender][i];
        }
        claimBatch(tokenIds);
    }

    /**
     * @dev set reward distributor by owner
     * reward distributor is the moderator who calls {notifyRewardAmount} function
     * whenever periodic reward tokens transferred to this contract
     * @param distributor new distributor address
     */
    function setRewardDistributor(address distributor) external onlyOwner {
        require(distributor != address(0), "Staking: INVALID_DISTRIBUTOR");
        rewardDistributor = distributor;
    }

    /**
     * @dev update reward related arguments after reward token arrived
     * @param reward reward token amounts received
     * @notice emit {RewardAdded} event
     */
    function notifyRewardAmount(uint256 reward) external onlyRewardDistributor {
        _updateRewardArguments();

        rewardToken.safeTransferFrom(msg.sender, address(this), reward);
 
        if (block.timestamp >= periodFinish) {
            rewardRate = reward / DURATION;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (reward + leftover) / DURATION;
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + DURATION;
        emit RewardAdded(reward);
    }

    function _updateRewardArguments() internal virtual {
        rewardPerNFTStored = rewardPerNFT();
        lastUpdateTime = lastTimeRewardApplicable();
    }
}
