pragma solidity ^0.4.24;

import "node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/// @title InfluenceCampaign
/// @dev 
/// 
/// @author Nicolas Urruty

contract InfluenceCampaignFactory {

    event CreateCampaign(string _data, uint _paymentOffer, uint _minFollowers, uint _influencersLimit);
    
    address public owner;

    address[] public influenceCampaigns;
    
    function createCampaign(
        string _data,
        uint _paymentOffer,
        uint _minFollowers,
        uint _influencersLimit
        ) public {
        address newCampaign = new InfluenceCampaign(owner, msg.sender, _data, _paymentOffer, _minFollowers, _influencersLimit);
        influenceCampaigns.push(newCampaign);

        emit CreateCampaign(_data, _paymentOffer, _minFollowers, _influencersLimit);
    } 
    
    function getDeployedCampaigns() public view returns (address[]) {
        return influenceCampaigns;
    }
}

contract InfluenceCampaign {

    event InitCampaign();
    event EndCampaign();
    event CancelCampaign();
    event LockOffer();
    event UnlockOffer();
    event RaiseOffer();
    event ChangeMinFollowers(uint _newMax);
    event ExtendInfluencersLimit(uint _extrLimit);
    event AcceptInfluencer(address _address);
    event SubmitPost(string url, string account, uint date);
    event AcceptPost(address influencer);
    event Withdraw();
    

    struct Influencer {
        address influencerAddress;
        string account;
        uint postsCount;
        Post finalPost;
        bool payed;
    }

    struct Post {
        string url;
        uint date;
        bool accepted;
    }

    enum CampaignState {
      Recluting,
      Live,
      Ended
    }

    address public owner;
    address public campaign_creator;
    Influencer[] public influencers;
    string public data;
    CampaignState public state;
    uint public postsCount;
    uint public paymentOffer;
    uint public finalOffer;
    bool public offerLocked;
    uint public minFollowers;
    uint public influencersLimit;
    bool public successful;
    mapping(address => uint) influencerIndex;


    modifier amountNotZero(uint _amount) {
        require(_amount != 0);
        _;
    }

    modifier amountGraterThanZero(uint _amount) {
        require(_amount > 0);
        _;
    }

    modifier offerGraterThanZero() {
        require(paymentOffer > 0); 
        _;
    }

    modifier equalsOffer(uint _amount) {
        require(paymentOffer == _amount);
        _;
    }

    modifier isLive() {
        require(state == CampaignState.Live );
        _;
    }


    modifier isRecluting() {
        require(state == CampaignState.Recluting );
        _;
    }

    modifier isEnded() {
        require(state == CampaignState.Ended );
        _;
    }

    modifier isNotEnded() {
        require(state != CampaignState.Ended );
        _;
    }

    modifier offerIsUnlocked() {
        require(!offerLocked);
        _;
    }

    modifier onlyCampaignCreator(address _address) {
        require(msg.sender == _address);
        _;
    }

    modifier influencerAccepted(address _address) {
        require(influencerIndex[_address] != 0);
        _;
    }

    modifier postNotYetAccepted(address _address) {
        Post memory post = influencers[influencerIndex[_address]].finalPost;
        require(!post.accepted);
        _;
    }
    

    constructor(address _owner, address _campaign_creator, string _data, 
                uint _paymentOffer, uint _minFollowers, uint _influencersLimit) public
        amountGraterThanZero(_paymentOffer)
        {
        owner = _owner;
        campaign_creator = _campaign_creator;
        data = _data;
        paymentOffer = SafeMath.div(_paymentOffer,_influencersLimit);
        minFollowers = _minFollowers;
        influencersLimit = _influencersLimit;
    }

    function initCampaign() public isRecluting() offerGraterThanZero() {
        state = CampaignState.Live;

        emit InitCampaign();
    }

    function endCampaign() public isLive() {
        state = CampaignState.Ended;

        emit EndCampaign();
    }

    function lockOffer() public {
        finalOffer = paymentOffer;
        paymentOffer = 0;

        emit LockOffer();
    }

    function unlockOffer() public {
        paymentOffer = finalOffer;
        finalOffer = 0;

        emit UnlockOffer();
    }

    function raiseOffer() public payable 
        isNotEnded() offerIsUnlocked() amountGraterThanZero(msg.value) onlyCampaignCreator(msg.sender) 
        {
        
        uint extraPayment = SafeMath.div(msg.value,influencersLimit);
        paymentOffer = SafeMath.add(paymentOffer,extraPayment);

        emit RaiseOffer();
    }

    function changeMinFollowers(uint _amount) public 
        isRecluting() amountGraterThanZero(_amount) onlyCampaignCreator(msg.sender) 
        {

        minFollowers = _amount;

        emit ChangeMinFollowers(_amount);
    }

    function extendInfluencersLimit(uint _newLimit) public payable
        isNotEnded() amountGraterThanZero(_newLimit) amountGraterThanZero(msg.value) onlyCampaignCreator(msg.sender) 
        equalsOffer(msg.value)
        {
        
        influencersLimit = SafeMath.add(influencersLimit, _newLimit);
        
        emit ExtendInfluencersLimit(_newLimit);
    }

    function acceptInfluencer(address _address, string _account, uint followers) public isNotEnded() onlyCampaignCreator(msg.sender) {
        require(influencers.length < influencersLimit);
        require(followers >= minFollowers);

        Influencer memory influencer = Influencer({
            influencerAddress: _address,
            account: _account,
            postsCount: 0,
            finalPost: Post({url: "", date: 0, accepted: false}),
            payed: false
        });
        influencers.push(influencer);
        influencerIndex[_address] = influencers.length - 1;

        emit AcceptInfluencer(_address);
    }


    function submitPost(string _url, string _account, uint _date) public 
        isNotEnded() influencerAccepted(msg.sender) postNotYetAccepted(msg.sender)
        {

        Post memory post = Post({ url: _url, date: _date, accepted: false });
        Influencer storage influencer = influencers[influencerIndex[msg.sender]];
        influencer.finalPost = post;
        influencer.postsCount += 1;
        postsCount += 1;
       
        emit SubmitPost(_url, _account, _date);
    }

    function acceptPost(address _address) public 
        isNotEnded() onlyCampaignCreator(msg.sender)
        {
        
        Influencer storage influencer = influencers[influencerIndex[msg.sender]];
        require(influencer.postsCount > 0);

        Post storage post = influencer.finalPost;
        post.accepted = true;

        if(postsCount == influencers.length) {
            state = CampaignState.Ended;
            successful = true;
        }

        emit AcceptPost(_address);
    }

    function cancelCampaign() public onlyCampaignCreator(msg.sender) isNotEnded() {
        require(postsCount == 0);

        msg.sender.transfer(address(this).balance);
    }

    function withdraw() public isEnded() {

        Influencer storage influencer = influencers[influencerIndex[msg.sender]];
        require(!influencer.payed);
        Post storage post = influencer.finalPost;
        require(post.accepted);

        influencer.influencerAddress.transfer(finalOffer);
        influencer.payed = true;

        emit Withdraw();
    }


    
}
