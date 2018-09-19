var InfluenceCampaignFactory = artifacts.require("./InfluenceCampaignFactory.sol");
var InfluenceCampaign = artifacts.require("./InfluenceCampaign.sol");

module.exports = function(deployer) {
  //deployer.deploy(SafeMath);
  //deployer.link(SafeMath, InfluenceCampaign);
  deployer.deploy(InfluenceCampaignFactory);
  //deployer.deploy(InfluenceCampaign);
};
