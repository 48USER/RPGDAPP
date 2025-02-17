import asyncio
import json
import os

from dotenv import load_dotenv
from web3 import AsyncHTTPProvider, AsyncWeb3


async def open_treasure_chest():
    load_dotenv("contracts/deployment/test/.env")

    with open("contracts/abi/TreasureChest_abi.json", "r") as abi_file:
        contract_abi = json.load(abi_file)

    contract_address = os.getenv("CONTRACT_ADDRESS")
    infura_api_key = os.getenv("INFURA_API_KEY")
    infura_net = os.getenv("INFURA_NET")
    infura_url = f"https://{infura_net}.infura.io/v3/{infura_api_key}"

    w3 = AsyncWeb3(AsyncHTTPProvider(infura_url))
    if await w3.is_connected():
        print("Connected to network!")
    else:
        print("Connection failed")
        return

    contract = w3.eth.contract(address=contract_address, abi=contract_abi)

    private_key = os.getenv("PRIVATE_KEY")
    account = w3.eth.account.from_key(private_key)
    nonce = await w3.eth.get_transaction_count(account.address)

    tx = await contract.functions.openChest().build_transaction(
        {
            "gas": 200000,
            "gasPrice": await w3.eth.gas_price,
            "nonce": nonce,
            "value": w3.to_wei(0.0001, "ether"),
        }
    )

    signed_tx = w3.eth.account.sign_transaction(tx, private_key=private_key)

    tx_hash = await w3.eth.send_raw_transaction(signed_tx.raw_transaction)
    print("Transaction sent, hash:", tx_hash.hex())

    receipt = await w3.eth.wait_for_transaction_receipt(tx_hash)
    print("Transaction receipt:", receipt)


if __name__ == "__main__":
    asyncio.run(open_treasure_chest())
