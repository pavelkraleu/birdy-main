import codecs

import web3
from ethereum.transactions import Transaction
from rlp import encode
import json
from ethereum.tools.keys import decode_keystore_json
from secret_keys import SecretKeys

class CallSmartContract(object):

    web3 = web3.Web3(web3.HTTPProvider(SecretKeys.infura_node_url))

    key_file = "ethereum_key_file.json"
    key_pass = SecretKeys.ethereum_key_pass

    # Public address of Birdy
    from_addr = "0x006CAfcA933C32fF5d672085cd7C12dfe2ca891B"

    # Smart Contract
    to_addr = "0xe55E2c3A123dc770Af42eeDF8c2abDBF1B96b618"

    def iterate_birds(self, birds_count):

        data_value = "0x059e9bf1" + str(birds_count).zfill(64)

        return self._submit_transaction(data_value)

    def register_new_card(self, card_uid):

        data_value = "0x2783e330" + self.web3.toHex(card_uid).replace("0x", "").ljust(64, "0")

        print(data_value)

        return self._submit_transaction(data_value)

    def _submit_transaction(self, data_value):

        amount = 0

        tx_count = self.web3.eth.getTransactionCount(self.from_addr)

        tx_gasprice = self.web3.eth.gasPrice

        # tx_startgas = self.web3.eth.estimateGas({
        #     'to': self.to_addr,
        #     'from': self.from_addr,
        #     'value': amount,
        #     'data': data_value,
        # })

        tx_startgas = 90000

        tx = Transaction(
            nonce=tx_count,
            gasprice=tx_gasprice,
            startgas=tx_startgas,
            to=self.web3.toAscii(self.to_addr),
            value=amount,
            data=self.web3.toAscii(data_value)
        )

        key_file_json = json.loads(open(self.key_file).read())

        keys = decode_keystore_json(key_file_json, self.key_pass)

        tx.sign(keys)

        tx_hex_signed = self.web3.toHex(encode(tx))

        tx_id = self.web3.eth.sendRawTransaction(tx_hex_signed)
        print('Transaction Hash: ' + tx_id)

        return tx_id
