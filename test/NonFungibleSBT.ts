import { loadFixture, time } from "@nomicfoundation/hardhat-network-helpers";
import { Signer } from "ethers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { MerkleTree } from "merkletreejs"
import { keccak256 } from "@ethersproject/keccak256"

const baseURI = "https://test/metadata/"

const deploy = async (owner: Signer) => {
  const SampleBasicNonFungibleSBT = await ethers.getContractFactory("SampleBasicNonFungibleSBT")
  const nsbt = await SampleBasicNonFungibleSBT.connect(owner).deploy()
  await nsbt.deployed()

  await nsbt.connect(owner).setBaseURI(baseURI)
  await nsbt.connect(owner).setMaxSupply(1000)
  await nsbt.connect(owner).setWithdrawAddress(await owner.getAddress())
  await nsbt.connect(owner).airdrop([await owner.getAddress()], [100])

  return { nsbt }
}

type Node = {
  userId: number,
  address: string,
  allowedAmount: number
}

const createTree = (allowList: Node[]) => {
  const leaves = allowList.map(node => ethers.utils.solidityKeccak256(['uint256', 'address', 'uint248'], [node.userId, node.address, node.allowedAmount]))
  return new MerkleTree(leaves, keccak256, { sortPairs: true })
}

const getHexProof = (tree: MerkleTree, userId: number, address: string, allowedAmount: number) => {
  return tree.getHexProof(ethers.utils.solidityKeccak256(['uint256', 'address', 'uint248'], [userId, address, allowedAmount]))
}

describe("nsbt", function () {
  async function fixture() {
    const [owner, otherAccount, allowed1_1, allowed1_2, allowed2, notAllowed1, withdrawAddress, ...others] = await ethers.getSigners()

    const tree = createTree([
      { userId: 1, address: allowed1_1.address, allowedAmount: 6 },
      { userId: 1, address: allowed1_2.address, allowedAmount: 6 },
      { userId: 2, address: allowed2.address, allowedAmount: 4 }
    ])

    const proof1_1 = getHexProof(tree, 1, allowed1_1.address, 6)
    const proof1_2 = getHexProof(tree, 1, allowed1_2.address, 6)
    const proof2 = getHexProof(tree, 2, allowed2.address, 4)

    const contracts = await deploy(owner)

    await contracts.nsbt.connect(owner)["setCurrentSale((uint8,uint248,uint248,uint8),bytes32)"]({
      id: 1,
      saleType: 0,
      mintCost: ethers.utils.parseEther("0.001"),
      maxSupply: 10
    }, tree.getHexRoot())

    return { ...contracts, owner, otherAccount, allowed1_1, allowed1_2, allowed2, notAllowed1, withdrawAddress, others, tree, proof1_1, proof1_2, proof2 };
  }

  describe("deploy", function () {
    it("デプロイ時にオーナーのもとにミントされること / 最大供給数を参照できること", async function () {
      const { nsbt, owner } = await loadFixture(fixture)

      expect(await nsbt.ownerOf(0)).to.equals(owner.address)
      expect(await nsbt.balanceOf(owner.address)).to.equals(100)
      expect(await nsbt.maxSupply()).to.equals(1000)
    })
  })

  describe("claim", function () {
    it("WL保有者がmintできること", async function () {
      const { nsbt, allowed1_1, allowed2, proof1_1, proof2 } = await loadFixture(fixture)

      await expect(nsbt.connect(allowed1_1).claim(1, 1, 6, proof1_1, { value: ethers.utils.parseEther("0.001") })).not.to.be.reverted
      expect(await nsbt.ownerOf(100)).to.equals(allowed1_1.address)
      expect(await nsbt.balanceOf(allowed1_1.address)).to.equals(1)

      await expect(nsbt.connect(allowed2).claim(2, 3, 4, proof2, { value: ethers.utils.parseEther("0.003") })).not.to.be.reverted
      expect(await nsbt.ownerOf(101)).to.equals(allowed2.address)
      expect(await nsbt.balanceOf(allowed2.address)).to.equals(3)
    })

    it("WL非保有者がmintできないこと", async function () {
      const { nsbt, notAllowed1, proof1_1 } = await loadFixture(fixture)

      await expect(nsbt.connect(notAllowed1).claim(1, 1, 6, proof1_1, { value: ethers.utils.parseEther("0.001") })).to.be.reverted
    })
  })

  describe("airdrop", function () {
    it("管理者がmintできること", async function () {
      const { nsbt, owner, allowed1_1 } = await loadFixture(fixture)

      await expect(nsbt.connect(owner).airdrop([allowed1_1.address], [10])).not.to.be.reverted
      expect(await nsbt.ownerOf(100)).to.equals(allowed1_1.address)
      expect(await nsbt.balanceOf(allowed1_1.address)).to.equals(10)
    })

    it("管理者以外はmintできないこと", async function () {
      const { nsbt, allowed1_1 } = await loadFixture(fixture)

      await expect(nsbt.connect(allowed1_1).airdrop([allowed1_1.address], [10])).to.be.reverted
    })
  })

  describe("approve", function () {
    it("approveできないこと", async function () {
      const { nsbt, owner, allowed1_1 } = await loadFixture(fixture)
      await expect(nsbt.connect(owner).approve(allowed1_1.address, 0)).to.be.revertedWith("This token is SBT.")
    })

    it("setApprovalForAllできないこと", async function () {
      const { nsbt, owner, allowed1_1 } = await loadFixture(fixture)
      await expect(nsbt.connect(owner).setApprovalForAll(allowed1_1.address, true)).to.be.revertedWith("This token is SBT.")
    })
  })

  describe("transfer", function () {
    it("transferできないこと", async function () {
      const { nsbt, owner, allowed1_1 } = await loadFixture(fixture)
      await expect(nsbt.connect(owner)["safeTransferFrom(address,address,uint256)"](owner.address, allowed1_1.address, 0))
        .to.be.revertedWith("This token is SBT, so this can not transfer.")
    })
  })

  describe("burn", function () {
    it("ホルダーならburnできること", async function () {
      const { nsbt, owner } = await loadFixture(fixture)
      await expect(nsbt.connect(owner).burn([0, 1, 2])).not.to.be.reverted
      expect(await nsbt.balanceOf(owner.address)).to.equals(97)
    })
  })

  describe("tokenURI", function () {
    it("tokenURIを参照できること", async function () {
      const { nsbt } = await loadFixture(fixture)
      expect(await nsbt.tokenURI(0)).to.equals(`${baseURI}0.json`)
      expect(await nsbt.tokenURI(99)).to.equals(`${baseURI}99.json`)
    })
  })

  describe("withdraw", function () {
    it("売り上げを引き出せること(寄付0%)", async function () {
      const { nsbt, owner, withdrawAddress, allowed1_1, allowed2, proof1_1, proof2 } = await loadFixture(fixture)

      await expect(nsbt.connect(owner).setDonationRate(0)).not.to.be.reverted

      await expect(nsbt.connect(allowed1_1).claim(1, 1, 6, proof1_1, { value: ethers.utils.parseEther("0.001") })).not.to.be.reverted
      await expect(nsbt.connect(allowed2).claim(2, 3, 4, proof2, { value: ethers.utils.parseEther("0.003") })).not.to.be.reverted

      await expect(nsbt.connect(owner).setWithdrawAddress(withdrawAddress.address)).not.to.be.reverted
      const beforeBalance = await withdrawAddress.getBalance()
      await expect(nsbt.connect(owner).withdraw()).not.to.be.reverted
      const afterBalance = await withdrawAddress.getBalance()

      expect(afterBalance.sub(beforeBalance)).to.equals(ethers.utils.parseEther("0.004"))
    })

    it("売り上げを引き出せること(寄付10%)", async function () {
      const { nsbt, owner, withdrawAddress, allowed1_1, allowed2, proof1_1, proof2 } = await loadFixture(fixture)
      const donationRecipient = await ethers.getSigner("0x98ad592418A2Bd5588FeE85734b15905c34e690A")

      await expect(nsbt.connect(owner).setDonationRate(1000)).not.to.be.reverted

      await expect(nsbt.connect(allowed1_1).claim(1, 1, 6, proof1_1, { value: ethers.utils.parseEther("0.001") })).not.to.be.reverted
      await expect(nsbt.connect(allowed2).claim(2, 3, 4, proof2, { value: ethers.utils.parseEther("0.003") })).not.to.be.reverted

      await expect(nsbt.connect(owner).setWithdrawAddress(withdrawAddress.address)).not.to.be.reverted
      const beforeWithdrawAddressBalance = await withdrawAddress.getBalance()
      const beforeDonationRecipientBalance = await donationRecipient.getBalance()
      await expect(nsbt.connect(owner).withdraw()).not.to.be.reverted
      const afterWithdrawAddressBalance = await withdrawAddress.getBalance()
      const afterDonationRecipientBalance = await donationRecipient.getBalance()

      const donateValue = ethers.utils.parseEther("0.0004")
      const withdrawValue = ethers.utils.parseEther("0.0036")

      expect(afterWithdrawAddressBalance.sub(beforeWithdrawAddressBalance)).to.equals(withdrawValue)
      expect(afterDonationRecipientBalance.sub(beforeDonationRecipientBalance)).to.equals(donateValue)
    })
  })

  describe("supportsInterfaces", () => {
    it("ERC721", async () => {
      const { nsbt } = await loadFixture(fixture)
      expect(await nsbt.supportsInterface("0x80ac58cd")).to.be.true
    })

    it("ERC721Metadata", async () => {
      const { nsbt } = await loadFixture(fixture)
      expect(await nsbt.supportsInterface("0x5b5e139f")).to.be.true
    })

    it("ERC165", async () => {
      const { nsbt } = await loadFixture(fixture)
      expect(await nsbt.supportsInterface("0x01ffc9a7")).to.be.true
    })
  })
})