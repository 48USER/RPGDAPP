// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TreasureChest {
    struct Item {
        uint64 generation;
        string typ;
        string rarity;
        string[] enchantments;
        uint256 createdAt;
    }

    struct Chance {
        uint128 chance;
    }

    uint256 public chestPrice = 0.0001 ether;
    address payable public owner;

    uint64 public numGenerations;
    mapping(uint64 => string[]) public types;
    string[] public rarities;
    string[] public enchantments;

    mapping(uint64 => Chance) public gensProbDist;
    mapping(uint64 => mapping(string => Chance)) public typesProbDist;
    mapping(string => Chance) public raritiesProbDist;
    mapping(string => Chance) public enchantmentsProbDist;

    mapping(address => Item[]) public users;

    event ChestOpened(address indexed user, Item item);
    event GenerationAdded(uint64 generation, uint128 genChance);

    uint256 private nonce;
    uint128 public constant baseGenChance = 10;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    constructor() {
        owner = payable(msg.sender);
        numGenerations = 3;
        types[0].push("Hammer");
        types[0].push("BattleAxe");
        types[0].push("Bow");
        types[0].push("HandCannon");
        types[1].push("GreatSword");
        types[1].push("Sabre");
        types[1].push("WarHammer");
        types[1].push("Spear");
        types[2].push("Rapier");
        types[2].push("DoubleSwords");
        types[2].push("Scythe");
        types[2].push("GiantSword");

        rarities.push("Common");
        rarities.push("Rare");
        rarities.push("Epic");
        rarities.push("Legendary");

        enchantments.push("Flicker of Fortune");
        enchantments.push("Wisp of Swiftness");
        enchantments.push("Boon of Resilience");
        enchantments.push("Glimmer of Precision");
        enchantments.push("Spark of Fury");
        enchantments.push("Echo of Valor");
        enchantments.push("Pulse of Vengeance");
        enchantments.push("Whisper of the Ancients");
        enchantments.push("Storm of Annihilation");
        enchantments.push("Celestial Ascendance");

        gensProbDist[0] = Chance({chance: 10});
        gensProbDist[1] = Chance({chance: 30});
        gensProbDist[2] = Chance({chance: 60});

        typesProbDist[0]["Hammer"] = Chance({chance: 25});
        typesProbDist[0]["BattleAxe"] = Chance({chance: 25});
        typesProbDist[0]["Bow"] = Chance({chance: 45});
        typesProbDist[0]["HandCannon"] = Chance({chance: 5});

        typesProbDist[1]["GreatSword"] = Chance({chance: 40});
        typesProbDist[1]["Sabre"] = Chance({chance: 30});
        typesProbDist[1]["WarHammer"] = Chance({chance: 20});
        typesProbDist[1]["Spear"] = Chance({chance: 10});

        typesProbDist[2]["Rapier"] = Chance({chance: 30});
        typesProbDist[2]["DoubleSwords"] = Chance({chance: 30});
        typesProbDist[2]["Scythe"] = Chance({chance: 25});
        typesProbDist[2]["GiantSword"] = Chance({chance: 15});

        raritiesProbDist["Common"] = Chance({chance: 70});
        raritiesProbDist["Rare"] = Chance({chance: 20});
        raritiesProbDist["Epic"] = Chance({chance: 9});
        raritiesProbDist["Legendary"] = Chance({chance: 1});

        enchantmentsProbDist["Flicker of Fortune"] = Chance({chance: 40});
        enchantmentsProbDist["Wisp of Swiftness"] = Chance({chance: 35});
        enchantmentsProbDist["Boon of Resilience"] = Chance({chance: 30});
        enchantmentsProbDist["Glimmer of Precision"] = Chance({chance: 25});
        enchantmentsProbDist["Spark of Fury"] = Chance({chance: 20});
        enchantmentsProbDist["Echo of Valor"] = Chance({chance: 15});
        enchantmentsProbDist["Pulse of Vengeance"] = Chance({chance: 10});
        enchantmentsProbDist["Whisper of the Ancients"] = Chance({chance: 7});
        enchantmentsProbDist["Storm of Annihilation"] = Chance({chance: 3});
        enchantmentsProbDist["Celestial Ascendance"] = Chance({chance: 1});
    }

    function _random(uint256 modulo) internal returns (uint256) {
        nonce++;
        return
            uint256(
                keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))
            ) % modulo;
    }

    function _selectString(
        string[] memory keys,
        mapping(string => Chance) storage chanceMapping,
        uint256 randomVal
    ) internal view returns (string memory) {
        uint256 cumulative = 0;
        for (uint256 i = 0; i < keys.length; i++) {
            cumulative += chanceMapping[keys[i]].chance;
            if (randomVal < cumulative) return keys[i];
        }
        return keys[keys.length - 1];
    }

    function _selectGeneration(
        uint256 randomVal
    ) internal view returns (uint64) {
        uint256 cumulative = 0;
        for (uint64 i = 0; i < numGenerations; i++) {
            cumulative += gensProbDist[i].chance;
            if (randomVal < cumulative) return i;
        }
        return numGenerations - 1;
    }

    function _getTypesForGeneration(
        uint64 generation
    ) internal view returns (string[] memory) {
        return types[generation];
    }

    function updateGensChances() public onlyOwner {
        for (uint64 i = 0; i < numGenerations; i++) {
            gensProbDist[i].chance = uint128(
                ((i + 1) * 200) / (numGenerations * (numGenerations + 1))
            );
        }
    }

    function openChest() public payable returns (Item memory) {
        require(msg.value >= chestPrice, "Insufficient payment for chest");
        if (msg.value > chestPrice) {
            payable(msg.sender).transfer(msg.value - chestPrice);
        }
        uint256 randGen = _random(100);
        uint64 chosenGen = _selectGeneration(randGen);
        string[] memory genTypes = _getTypesForGeneration(chosenGen);
        require(genTypes.length > 0, "No types defined for chosen generation");
        uint256 randType = _random(100);
        string memory chosenType = _selectString(
            genTypes,
            typesProbDist[chosenGen],
            randType
        );
        uint256 randRarity = _random(100);
        string memory chosenRarity = _selectString(
            rarities,
            raritiesProbDist,
            randRarity
        );
        uint256 randEnch = _random(186);
        string memory chosenEnchantment = _selectString(
            enchantments,
            enchantmentsProbDist,
            randEnch
        );
        string[] memory enchArr = new string[](1);
        enchArr[0] = chosenEnchantment;
        Item memory newItem = Item({
            generation: chosenGen,
            typ: chosenType,
            rarity: chosenRarity,
            enchantments: enchArr,
            createdAt: block.timestamp
        });
        users[msg.sender].push(newItem);
        emit ChestOpened(msg.sender, newItem);
        return newItem;
    }

    function getUserItemsCount(address user) public view returns (uint256) {
        return users[user].length;
    }

    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        owner.transfer(balance);
    }

    function addGeneration(
        string[4] memory newTypes,
        uint128[4] memory newTypesChances
    ) external onlyOwner {
        uint64 newGen = numGenerations;
        numGenerations++;
        for (uint256 i = 0; i < 4; i++) {
            types[newGen].push(newTypes[i]);
            typesProbDist[newGen][newTypes[i]] = Chance({
                chance: newTypesChances[i]
            });
        }
        updateGensChances();
        emit GenerationAdded(newGen, gensProbDist[newGen].chance);
    }
}
