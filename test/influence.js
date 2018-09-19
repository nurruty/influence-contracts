
const InfluenceCampaignFactory = artifacts.require("./InfluenceCampaignFactory.sol");
const InfluenceCampaign = artifacts.require("./InfluenceCampaign.sol");

let factory;
let campaignAddress;
let influenceCampaign;


contract('InfluenceCampaignFactory', async (accounts) => {

  it("should deploy contract", async () => {
     let instance = await InfluenceCampaignFactory.deployed();
     assert.ok(instance.address);
  });

  it('should fail to create campaign if offer is 0', async () => {
      
    try {
      let instance = await InfluenceCampaignFactory.deployed();
      await instance.createCampaign('', 0 , 1 , 1);
      assert(false);
    } catch(err) {
      assert(err)
    }

  });

  it("should create a new campaign", async () => {
    let instance = await InfluenceCampaignFactory.deployed();
    await instance.createCampaign('', 1 , 1 , 1);
    let campaignAddress;
    [campaignAddress] = await instance.getDeployedCampaigns();
    assert.ok(campaignAddress);
  });


});



contract('InfluenceCampaign', async(accounts) => {

  beforeEach( async () => {
    factory = await InfluenceCampaignFactory.deployed();
    await factory.createCampaign('', 1 , 1 , 1);
    campaignAddress;
    [campaignAddress] = await factory.getDeployedCampaigns();
    influenceCampaign = InfluenceCampaign.at(campaignAddress);
  });

  describe('Test campaign creation and initalization', () => {

    it('campaign should start relcluting', async() => {
      let state = await influenceCampaign.state();
      assert.equal(state,'0');
    });

    it('sholud init campaign', async () => {
      await influenceCampaign.initCampaign();
      let state = await influenceCampaign.state();
      assert.equal(state,'1');
    });

  });

  describe('Tunning campaign', () => {


    it('sholud raise payment offer', async () => {
      const initialOffer = await influenceCampaign.paymentOffer();
      await influenceCampaign.raiseOffer(
        { 
          value: web3._extend.utils.toWei('.1', 'ether'),
          from: accounts[0]
        });
      const offer = await influenceCampaign.paymentOffer();
      assert.ok(offer > initialOffer);
    });


  })

 
})