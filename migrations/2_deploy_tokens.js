var SparkToken = artifacts.require("./SparkToken.sol")

module.exports = function (deployer, network, accounts) {

  deployer.then(async () => {

    console.log('network: ' + network)
    console.log(accounts)
    const owner = accounts[0]
    console.log('owner: ' + owner)

    let token = await deployer.deploy(SparkToken, {from: owner})
  })

};