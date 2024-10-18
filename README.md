## Petiverse-Foundry

### Deploy

Follow these steps to deploy the contract:
1. Securely store your private key:

    Run the following command to store your private kye in a secure place:
    
    ```cast wallet import One --interactive```

    This will store the key with the alias One and you’ll be prompted for your private key and password interactively.

2. Deploy the contract with Foundry:

    ```forge create --rpc-url $KAIA_RPC_URL --account One --constructor-args-path script/args src/PetNft.sol:PetNft```

### Test

Run the following command to test the contract:

```forge test```
