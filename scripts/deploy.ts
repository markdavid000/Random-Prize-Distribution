import { ethers } from "hardhat";

async function main() {
  const initialAddress = "0x802Da5c76521317f2cC9d6eBad176e47A5F4205c";
  const tokenName = "MarkToken";
  const tokenSymbol = "MKT";

  const ERC20Token = await ethers.deployContract("ERC20Token", [
    initialAddress,
    tokenName,
    tokenSymbol,
  ]);

  await ERC20Token.waitForDeployment();

  console.log(`ERC20Token has been deployed to ${ERC20Token.target}`);

  const vrfCoordinator = "0x7a1bac17ccc5b313516c5e16fb24f7659aa5ebed";
  const linkTokenAddress = "0x326C977E6efc84E512bB9C30f76E30c160eD06FB";
  const keyHash =
    "0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f";
  const fee = 5;

  const RPD = await ethers.deployContract("RPD", [
    vrfCoordinator,
    linkTokenAddress,
    keyHash,
    fee,
    ERC20Token.target,
  ]);

  await RPD.waitForDeployment();

  console.log(`RPD has been deployed to ${RPD.target}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
