# jtools for Jormungandr

jtools is a Linux shell wrapper for [Jormungandr](https://github.com/input-output-hk/jormungandr) and its jcli tool.
It allows the typical steps necessary to set up a Cardano Shelley Stake pool to be performed with a few simple commands.

You should have ready a Jormungandr installation as described [here](https://github.com/input-output-hk/shelley-testnet/wiki/How-to-setup-a-Jormungandr-Networking--node-(--v0.5.0))

## Settings

First take a look at the settings section at the top of the script. 

*NODE_REST_URL* is what you have set in your node-config.yaml file as *rest: listen:* 

you can execute this script right out from the cloned repository on your computer, to create the *BASE_FOLDER*.

*FALLET_FOLDER* and *POOL_FOLDER* subdirectories then will contain all the keys and certificates created by the tool.

If *JTOOLS_LOG* is set, the tool will keep an archive of all it's activities, which may help remembering when and what was done in the past.

Choose the right *ASSET_PLATTFORM* for your operating system by commenting out all others. It is already required for the first command.

## update

> ```bash
> ./jtools.sh update
> ```
>
> 

This will automatically determine the latest Jormungandr release version. In case there is a newer one it offers you to download and unpack it into the BASE_FOLDER. 

```
currently installer: 0.5.3
Latest available release: 0.5.5 (2019-10-01T21:04:02Z)
Would you like to install the latest release? (Y/n)? y
Download jormungandr-v0.5.5-x86_64-unknown-linux-gnu.tar.gz ...
installed Jormungandr 0.5.5
```



## wallet

### new

> ```bash
> ./jtools.sh wallet new Pluto
> ```
>
> 

will create a new wallet named "Pluto". All keys and files related to this wallet will be stored in a subfolder /Pluto inside WALLET_FOLDER

As a result you will see the wallets public UTXO key and the account address

> New wallet Pluto
> public key: ed25519_pk15azdzf8w80hck4cuk659va6wwz6sjzsrazds08aw4a9np90vg20qd86zv8
> address: ca1skn5f5fyaca7lz6hrjm2s4nhfect2zg2q05fkpul46h5kvy4a3pfulm738v

You can now copy the address (starting with ca...) navigate to the [Testnet faucet](https://testnet.iohkdev.io/shelley/tools/faucet/), paste it in, and request free testnet ADA's.

Tip: Already create a second wallet "Mars" for the next steps

### show

After some seconds you can verify the account balance with

> ```bash
> ./jtools.sh wallet show Pluto
> ```
>
> 

Note: it will show you a *404 not found* error, until your wallet received it first funds.

As soon as the transaction from the faucet arrive it should look like this

> Address: ca1skn5f5fyaca7lz6hrjm2s4nhfect2zg2q05fkpul46h5kvy4a3pfulm738v
> Balance: 10,000,000,000 Lovelaces

Note: 1,000,000 Lovelaces = 1 ADA

### remove

You can delete a wallet's public and secret key with

> ```bash
> ./jtools.sh wallet remove Pluto
> ```
>
> 

As this will irretrievably remove everything you need to access the funds inside this wallet, the jtools wrapper will warn you about not empty wallets. Take care and think twice! You may need this wallet and its funds soon.

## funds

### send

> ```bash
> ./jtools.sh funds send Pluto 200000 Mars
> ```
>
> 

will send 200,000 Lovelaces from your Pluto to your Mars wallet and show a result like

> ```
> Transaction Pluto > Mars
> From:     ca1skn5f5fyaca7lz6hrjm2s4nhfect2zg2q05fkpul46h5kvy4a3pfulm738v
> Balance:  10,000,000 Lovelaces
> Amount:   200,000 Lovelaces
> To:       ca1s4l2maalvhhpzr4khnpstjalt30y7rfzfzxzypux5jj7h4zhc2g0vuq8cy9
> Fees:     1,100 Lovelaces
> TX-ID:    73fb488e06e113a91f41f6d988d37cffa86257cedc29a37b1505600c7c963a5a
> ```

Note: all this is archived as activities with date-time stamps in the jtools' Logfile.



## pool

### register

Now it's getting serious.

```bash
./jtools.sh pool register Atlantis Pluto
```

will generate a series of keys and certificates for the Stake-Pool Atlantis. It will pay the fees to submit the new stake-pool registration to the blockchain with funds from wallet pluto.

```
Registered new Pool Atlantis
Pool-ID:    9b0c448ab1204bc55b6e1ff54437b1653926e69c99e291d93c187c1168239a3e
Fees:       11,050 Lovelaces
TX-ID:      5190b157a5142dbf11d4a4a2e49a88c087c9c40a32a2a0df07c6ad22855ec7d4
```

Note: No stake is delegated to this pool yet.

### show

After a short wait you can copy the above Pool-ID at the end of the show command

```
./jtools.sh pool show 9b0c448ab1204bc55b6e1ff54437b1653926e69c99e291d93c187c1168239a3e
```

and it should show you the same ID as a result. This is the confirmation that your Pool certificate became part of the testnet.

## stake

### delegate

In order to delegate your testnet ADA to the stake pool just execute

```bash
./jtools.sh stake delegate Mars Atlantis
```

You will see something like

```
Delegate wallet Mars to Pool Atlantis
Pool-ID:   9b0c448ab1204bc55b6e1ff54437b1653926e69c99e291d93c187c1168239a3e
Stake:     200,000 Lovelaces
Fees:      11,050 Lovelaces
TX-ID:     0ae692388df6e666ebb7948f76f27cbe650ae1819d0441b0639acbe9d5c9a0b1
```



For now that's it.

The epochs of this test network last exactly one day. According to the specification of Ouroboros Genesis the stake delegations are valid from the epoch after next. So it is now 1-2 days to wait. 



Hope you enjoyed jtools. 

Now perhaps you can send some real ADA's to the address Ae2tdPwUPEZJyJy2DbueGwkLjCqNcypkj5Aa3waEZdvBKMsNqjNw2kTqPfyhe. With 40 ADA, I get a coffee ;-)