import json
import os

from dotenv import load_dotenv
from solcx import compile_standard, install_solc
from web3 import Web3

install_solc("0.8.0")

with open("contracts/TreasureChest.sol", "r", encoding="utf-8") as file:
    contract_source_code = file.read()

compiled_sol = compile_standard(
    {
        "language": "Solidity",
        "sources": {"TreasureChest.sol": {"content": contract_source_code}},
        "settings": {
            "outputSelection": {
                "*": {"*": ["abi", "evm.bytecode", "evm.bytecode.sourceMap"]}
            }
        },
    },
    solc_version="0.8.0",
)


bytecode = compiled_sol["contracts"]["TreasureChest.sol"]["TreasureChest"]["evm"][
    "bytecode"
]["object"]

abi = compiled_sol["contracts"]["TreasureChest.sol"]["TreasureChest"]["abi"]

api_dir = "contracts/abi"

if not os.path.exists(api_dir):
    os.makedirs(api_dir)

with open(os.path.join(api_dir, "TreasureChest_abi.json"), "w") as file:
    json.dump(abi, file)

load_dotenv()

infura_api_key = os.getenv("INFURA_API_KEY")
infura_net = os.getenv("INFURA_NET")
infura_url = f"https://{infura_net}.infura.io/v3/{infura_api_key}"

w3 = Web3(Web3.HTTPProvider(infura_url))

if w3.is_connected:
    print("Connected to testnet!")
else:
    print("Connection failed.")


private_key = "0x" + os.getenv("PRIVATE_KEY")

acc = w3.eth.account.from_key(private_key)

TreasureChest = w3.eth.contract(abi=abi, bytecode=bytecode)

transaction = TreasureChest.constructor().build_transaction(
    {
        "from": acc.address,
        "gasPrice": w3.eth.gas_price,
        "nonce": w3.eth.get_transaction_count(acc.address),
        "gas": 2000000,
    }
)

signed_txn = w3.eth.account.sign_transaction(transaction, private_key=private_key)


tx_hash = w3.eth.send_raw_transaction(signed_txn.raw_transaction)
print("Transaction sent, hash:", tx_hash.hex())


tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
print("Contract deployed at address:", tx_receipt.contractAddress)
