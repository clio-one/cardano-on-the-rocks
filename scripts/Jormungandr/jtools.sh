#!/bin/bash

# jtools version 0.4 fixing breaking changes in Jormungandr 0.8 release
# - removed serial option for pool registration
#
# jtools version 0.3 fixing breaking changes in Jormungandr 0.7 release
# - paramaters for jcli new stake-delegation reordered
#
# jtools version 0.2 
# - fixing breaking changes in Jormungandr 0.7.0.RC5 
#  - switch from signcert to cert
#  - transaction athentication
# - added wallet list
#
# jtools version 0.1 initial release
# 
# inspired by scripts from @NicolasDP and @disassembler
# 
# Please donate some (real) ADA to"
# Ae2tdPwUPEZJy2DbueGwkLjCqNcypkj5Aa3waEZdvBKMsNqjNw2kTqPfyhe"
# Thanks in advance!"


############### script settings ###################################

NODE_REST_URL="http://127.0.0.1:8081/api"

BASE_FOLDER=~/jormungandr/
JCLI=${BASE_FOLDER}"jcli"

WALLET_FOLDER=$BASE_FOLDER"wallet"
POOL_FOLDER=$BASE_FOLDER"pool"


# log jtools activities (comment out for no logs)
JTOOLS_LOG=${BASE_FOLDER}jtools-history.log

# update from asset
#ASSET_PLATTFORM="x86_64-unknown-linux-gnu"		# Debian, Ubuntu, CentOS 8,...
#ASSET_PLATTFORM="x86_64-unknown-linux-musl"	# CentOS 7, ...
ASSET_PLATTFORM="aarch64-unknown-linux-gnu" 	# Armbian, Raspian, RockPi, ARM 64bit, ...

###################################################################


usage() {
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "Usage:"
    echo ""
    echo "   $0 update"
    echo ""
    echo "   $0 wallet new [WALLET_NAME]"
    echo "   $0 wallet list"
    echo "   $0 wallet show [WALLET_NAME]"
    echo "   $0 wallet remove [WALLET_NAME]"
    echo ""
    echo "   $0 funds send [SOURCE_WALLET] [AMOUNT] [DESTINATION_ADDRESS|WALLET]"
    echo "           Note: Amount is an Integer value in Lovelaces"
    echo ""
    echo "   $0 pool register [POOL_NAME] [WALLET_NAME]"
    echo "           Note: Wallet is only used to pay the registration fee"
    echo ""
    echo "   $0 stake delegate [WALLET_NAME] [POOL_NAME]"
    echo "           Note: Entire Wallet balance (minus Fee) is delegated"
    echo ""
    echo "   Please donate some real ADA to"
    echo "   Ae2tdPwUPEZJy2DbueGwkLjCqNcypkj5Aa3waEZdvBKMsNqjNw2kTqPfyhe"
    echo "   Thanks in advance!"
    echo ""
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
}


function main {

if [ ${#} -lt 1 ]; then
    usage ${0}
    exit 1
fi


# check for required command line tools
need_cmd "curl"
need_cmd "jq"

OPERATION=${1}
case $OPERATION in

  update) 
	
	if [ ${#} -lt 2 ]; then
		DESIRED_RELEASE_JSON=$(curl --proto '=https' --tlsv1.2 -sSf https://api.github.com/repos/input-output-hk/jormungandr/releases/latest)
	else
		DESIRED_RELEASE_JSON=$(curl --proto '=https' --tlsv1.2 -sSf https://api.github.com/repos/input-output-hk/jormungandr/releases/tags/${2})
	fi	
	DESIRED_RELEASE=$(echo $DESIRED_RELEASE_JSON | jq -r .tag_name)
	DESIRED_RELEASE_PUBLISHED=$(echo $DESIRED_RELEASE_JSON | jq -r .published_at)
	DESIRED_RELEASE_CLEAN=$(echo ${DESIRED_RELEASE} | cut -c2-)

	if [ -f "${JCLI}" ]; then
		CURRENT_VERSION=$(${JCLI} --version | cut -c 6-)
		
		say "Currently installed: ${CURRENT_VERSION}"
		say "Desired release:      ${DESIRED_RELEASE_CLEAN} (${DESIRED_RELEASE_PUBLISHED})"
		if [ "${DESIRED_RELEASE_CLEAN}" != "${CURRENT_VERSION}" ]; then
			read -n 1 -p "Would you like to upgrade to this release? (y/N)? " answer
			case ${answer:0:1} in
				y|Y )
					FILE="jormungandr-"${DESIRED_RELEASE}"-"${ASSET_PLATTFORM}".tar.gz"
					URL="https://github.com/input-output-hk/jormungandr/releases/download/"${DESIRED_RELEASE}"/"${FILE}
					echo -e "\nDownload $FILE ..."
					curl --proto '=https' --tlsv1.2 -L -URL ${URL} -O ${BASE_FOLDER}${FILE}
					#mkdir -p bin/rollback
					#cp -f bin/* bin/rollback
					#rm -f bin/*
					#mkdir -p config/rollback
					#cp -f config/* config/rollback
					#rm -f config/*
					#tar -xzf $FILE -C bin
					tar -C ${BASE_FOLDER} -xzf $FILE
					rm $FILE
					say "updated Jormungandr from ${CURRENT_VERSION} to ${DESIRED_RELEASE_CLEAN}" "log"
				;;
			esac
			
		fi
	else # 
		say "No jcli binary found"
		say "Desired available release: ${DESIRED_RELEASE_CLEAN} (${DESIRED_RELEASE_PUBLISHED})"
		read -n 1 -p "Would you like to install this release? (Y/n)? " answer
		case ${answer:0:1} in
			n|N )
				say "Well, that was a pleasant but brief pleasure. Bye bye!"
			;;
			* )
				FILE="jormungandr-"${DESIRED_RELEASE}"-"${ASSET_PLATTFORM}".tar.gz"
				URL="https://github.com/input-output-hk/jormungandr/releases/download/"${DESIRED_RELEASE}"/"${FILE}
				echo -e "\nDownload $FILE ..."
				curl --proto '=https' --tlsv1.2 -L -URL ${URL} -O ${BASE_FOLDER}${FILE}
				mkdir -p ${BASE_FOLDER}
				#mkdir -p ${BASE_FOLDER}bin
				#mkdir -p ${BASE_FOLDER}config
				mkdir -p ${BASE_FOLDER}logs
				mkdir -p ${BASE_FOLDER}scripts
				#mkdir -p ${BASE_FOLDER}www/cgi-bin
				#tar -xzf $FILE -C bin
				tar -C ${BASE_FOLDER} -xzf $FILE
				rm $FILE
: '				my_public_ip=$(curl -4 ifconfig.co)
				cat > config/node-config.yaml <<- EOF
storage: "${BASE_FOLDER}storage"
log:
  format: "plain"
  level: "info"
  output: "stdout"
rest:
  listen: "127.0.0.1:8081"
p2p:
  trusted_peers:
    - address: "/ip4/3.115.194.22/tcp/3000"
      id: ed25519_pk1npsal4j9p9nlfs0fsmfjyga9uqk5gcslyuvxy6pexxr0j34j83rsf98wl2
    - address: "/ip4/13.113.10.64/tcp/3000"
      id: ed25519_pk16pw2st5wgx4558c6temj8tzv0pqc37qqjpy53fstdyzwxaypveys3qcpfl
    - address: /ip4/52.57.214.174/tcp/3000
      id: ed25519_pk1v4cj0edgmp8f2m5gex85jglrs2ruvu4z7xgy8fvhr0ma2lmyhtyszxtejz
    - address: /ip4/3.120.96.93/tcp/3000
      id: ed25519_pk10gmg0zkxpuzkghxc39n3a646pdru6xc24rch987cgw7zq5pmytmszjdmvh
    - address: /ip4/52.28.134.8/tcp/3000
      id: ed25519_pk1unu66eej6h6uxv4j4e9crfarnm6jknmtx9eknvq5vzsqpq6a9vxqr78xrw
    - address: /ip4/13.52.208.132/tcp/3000
      id: ed25519_pk15ppd5xlg6tylamskqkxh4rzum26w9acph8gzg86w4dd9a88qpjms26g5q9
    - address: /ip4/54.153.19.202/tcp/3000
      id: ed25519_pk1j9nj2u0amlg28k27pw24hre0vtyp3ge0xhq6h9mxwqeur48u463s0crpfk
  public_address: "/ip4/${my_public_ip}/tcp/8201"
  private_id: 
  topics_of_interest:
    messages: high
    blocks: high
EOF
				cat > config/genesis.hash <<- EOF
adbdd5ede31637f6c9bad5c271eec0bc3d0cb9efb86a5b913bb55cba549d0770
EOF
				cat > start-node.sh <<- EOF
#!/bin/bash
homeDir="~/jormungandr/"
${homeDir}bin/jormungandr --config ${homeDir}config/node-config.yaml --genesis-block-hash config/genesis.hash --secret ${homeDir}pool/Gamma/secret.yaml 2>&1 | tee -a ${homeDir}logs/jormungandr.log
EOF
				chmod +x start-node.sh
'
				say "installed Jormungandr ${DESIRED_RELEASE_CLEAN}" "log"
			;;
		esac
		
	fi


  ;; ###################################################################

  wallet) 

	SUBCOMMAND=${2}
	
	case $SUBCOMMAND in
	  new) # [WALLET_NAME]
	
		if [ ${#} -lt 3 ]; then
			usage ${0}
			exit 1
		fi

		WALLET_NAME=${3}
		mkdir -p "${WALLET_FOLDER}/${WALLET_NAME}"
		
		if [  -f "${WALLET_FOLDER}/${WALLET_NAME}/ed25519.key" ]; then
			say "WARN: A wallet $WALLET_NAME already exists"
			say "      Choose another name or delete the existing one"
			exit 1
		fi
		
		# create a personal wallet key
		${JCLI} key generate --type=Ed25519 > "${WALLET_FOLDER}/${WALLET_NAME}/ed25519.key"
		MY_ED25519_key=$(cat "${WALLET_FOLDER}/${WALLET_NAME}/ed25519.key")
		MY_ED25519_file="${WALLET_FOLDER}/${WALLET_NAME}/ed25519.key"
		echo "$MY_ED25519_key" | ${JCLI} key to-public > "${WALLET_FOLDER}/${WALLET_NAME}/ed25519.pub"
		MY_ED25519_pub=$(cat "${WALLET_FOLDER}/${WALLET_NAME}/ed25519.pub")

		# extract account address from wallet key
		${JCLI} address account ${MY_ED25519_pub} --testing > "${WALLET_FOLDER}/${WALLET_NAME}/ed25519.account"
		MY_ED25519_address=$(cat "${WALLET_FOLDER}/${WALLET_NAME}/ed25519.account")
		
		say "New wallet $WALLET_NAME" "log"
		say "  public key:  $MY_ED25519_pub" "log"
		say "  address:     $MY_ED25519_address" "log"
		say "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

	  ;; ###################################################################
	
	  list) # no parameters
	  
		for WALLET_FOLDER_NAME in ${WALLET_FOLDER}/*/     
		do
			WALLET_FOLDER_NAME=${WALLET_FOLDER_NAME%*/}      
			echo ${WALLET_FOLDER_NAME##*/}    
			if [ -f "${WALLET_FOLDER_NAME}/ed25519.account" ]; then
				WALLET_ADDRESS=$(cat "${WALLET_FOLDER_NAME}/ed25519.account")
				RESULT=$(${JCLI} rest v0 account get ${WALLET_ADDRESS} --host ${NODE_REST_URL} )
				WALLET_BALANCE=$(${JCLI} rest v0 account get ${WALLET_ADDRESS} --host ${NODE_REST_URL} | grep '^value:' | sed -e 's/value: //' )
				WALLET_BALANCE_NICE=$(printf "%'d Lovelaces" $WALLET_BALANCE)
				say "  Address: ${WALLET_ADDRESS}"
				say "  Balance: ${WALLET_BALANCE_NICE}"
			else
				say "Warn: missing wallet account file (${WALLET_FOLDER}/${WALLET_NAME}/ed25519.account)"
			fi
		done

		
	  ;; ###################################################################
	
	  show) # [WALLET_NAME]
		
		WALLET_NAME=${3}
		
		if [ ${#WALLET_NAME} == "62" ]; then # looks like a 62 char account address
			RESULT=$(${JCLI} rest v0 account get ${WALLET_NAME} --host ${NODE_REST_URL} )
			WALLET_BALANCE=$(${JCLI} rest v0 account get ${WALLET_NAME} --host ${NODE_REST_URL} | grep '^value:' | sed -e 's/value: //' )
			WALLET_BALANCE_NICE=$(printf "%'d Lovelaces" $WALLET_BALANCE)
			say "Address: ${WALLET_ADDRESS}" "log"
			say "  Balance: ${WALLET_BALANCE_NICE}" "log"
			printf "%b\n" "${RESULT}"
		else # look for a local wallet account address
			if [ -f "${WALLET_FOLDER}/${WALLET_NAME}/ed25519.account" ]; then
				WALLET_ADDRESS=$(cat "${WALLET_FOLDER}/${WALLET_NAME}/ed25519.account")
				RESULT=$(${JCLI} rest v0 account get ${WALLET_ADDRESS} --host ${NODE_REST_URL} )
				WALLET_BALANCE=$(${JCLI} rest v0 account get ${WALLET_ADDRESS} --host ${NODE_REST_URL} | grep '^value:' | sed -e 's/value: //' )
				WALLET_BALANCE_NICE=$(printf "%'d Lovelaces" $WALLET_BALANCE)
				say "Address: ${WALLET_ADDRESS}"
				say "  Balance:    ${WALLET_BALANCE_NICE}"
				printf "%b\n" "${RESULT}"
				
			else
				say "Error: no wallet $WALLET_NAME found (${WALLET_FOLDER}/${WALLET_NAME}/ed25519.account)"
			fi
		fi
		
	  ;; ###################################################################
	
	  remove) # [WALLET_NAME]
	
		if [ ${#} -lt 3 ]; then
			usage ${0}
			exit 1
		fi

		WALLET_NAME=${3}

		if [ -f "${WALLET_FOLDER}/${WALLET_NAME}/ed25519.account" ]; then
			WALLET_BALANCE=$(${JCLI} rest v0 account get $(cat "${WALLET_FOLDER}/${WALLET_NAME}/ed25519.account") --host "${NODE_REST_URL}" | grep '^value:' | sed -e 's/value: //' )
			WALLET_BALANCE_NICE=$(printf "%'d Lovelaces" ${WALLET_BALANCE})
			
			if [[ ${WALLET_BALANCE} == "" ]]; then
				say "INFO: found local wallet file but can't (yet) verify it's balance on blockchain"
				read -n 1 -p "Are you sure to delete secret/public key pairs (y/n)? " answer
				case ${answer:0:1} in
					y|Y )
						rm -rf "${WALLET_FOLDER}/${WALLET_NAME}"
						say "\nremoved ${WALLET_NAME}"
					;;
					* )
						echo -e "\nskipped removal process for $WALLET_NAME"
					;;
				esac
			else
				if [[ ${WALLET_BALANCE} == "0" ]]; then
					say "INFO: found local wallet file with current balance 0"
					rm -r "${WALLET_FOLDER}/${WALLET_NAME}"
					echo "removed ${WALLET_NAME}"
				else
					say "WARN: this wallet file has a balance of ${WALLET_BALANCE_NICE}"
					read -n 1 -p "      Are you sure to delete secret/public key pairs (y/n)? " answer
					case ${answer:0:1} in
						y|Y )
							rm -rf "${WALLET_FOLDER}/${WALLET_NAME}"
							echo -e "\nremoved ${WALLET_NAME}"
						;;
						* )
							echo -e "\nskipped removal process for $WALLET_NAME"
						;;
					esac
				fi
			fi
		else
			Say "INFO: no wallet $WALLET_NAME found"
			exit 1
		fi
		
	  ;; ###################################################################

	  *)
		usage ${0}
		exit 1
	  ;;

	esac
	  
  ;; ###################################################################

  funds)
  
	SUBCOMMAND=${2}

	case $SUBCOMMAND in
	  send) #[SOURCE_WALLET] [AMOUNT] [DESTINATION_WALLET|ADDRESS]

		if [ ${#} -lt 5 ]; then
			usage ${0}
			exit 1
		fi
		
		WALLET_NAME=${3}
		
		if [ -f "${WALLET_FOLDER}/${WALLET_NAME}/ed25519.account" ]; then
			SOURCE_ADDRESS=$(cat "${WALLET_FOLDER}/${WALLET_NAME}/ed25519.account")
			SOURCE_KEY=$(cat "${WALLET_FOLDER}/${WALLET_NAME}/ed25519.key")
		else
			echo "Error: no source wallet $WALLET_NAME found"
			usage ${0}
			exit 1
		fi
		
		if [ ${4} -eq ${4} 2>/dev/null ]; then 
			AMOUNT=${4}
			AMOUNT_NICE=$(printf "%'d Lovelaces" ${AMOUNT})
		else
			echo "ERROR: $(AMOUNT) is no valid (integer) amount"
			usage ${0}
			exit 1
		fi

		if [ ${#5} == "62" ]; then # looks like a 62 char account address
			DESTINATION_ADDRESS=${5}
		else # look for a local wallet account address
			if [ -f "$WALLET_FOLDER/${5}/ed25519.account" ]; then
				DESTINATION_ADDRESS=$(cat "$WALLET_FOLDER/${5}/ed25519.account")
			else
				echo "Error: no destination wallet ${5} found"
				usage ${0}
				exit 1
			fi
		fi
		
		# get the source wallet's state
		SOURCE_BALANCE=$(${JCLI} rest v0 account get "${SOURCE_ADDRESS}" --host "${NODE_REST_URL}" | grep '^value:' | sed -e 's/value: //' )
		if (( $SOURCE_BALANCE == 0 )); then
			echo "ERROR: source wallet balance is zero"
			exit 1
		fi
		SOURCE_BALANCE_NICE=$(printf "%'d Lovelaces" ${SOURCE_BALANCE})
		SOURCE_COUNTER=$(${JCLI} rest v0 account get "${SOURCE_ADDRESS}" --host "${NODE_REST_URL}" | grep '^counter:' | sed -e 's/counter: //' )
		
		# read the nodes blockchain settings (parameters are required for the next transactions)
		settings="$(curl -s ${NODE_REST_URL}/v0/settings)"
		FEE_CONSTANT=$(echo $settings | jq -r .fees.constant)
		FEE_COEFFICIENT=$(echo $settings | jq -r .fees.coefficient)
		FEE_CERTIFICATE=$(echo $settings | jq -r .fees.certificate)
		BLOCK0_HASH=$(echo $settings | jq -r .block0Hash)
		FEES=$((${FEE_CONSTANT} + 2 * ${FEE_COEFFICIENT}))
		FEES_NICE=$(printf "%'d Lovelaces" ${FEES})
		AMOUNT_WITH_FEES=$((${AMOUNT} + ${FEES}))

		if (( $AMOUNT_WITH_FEES >= $SOURCE_BALANCE )); then
			echo "ERROR: source wallet ($SOURCE_BALANCE) has not enough funds to send $AMOUNT and pay $((${FEE_CONSTANT} + 2 * ${FEE_COEFFICIENT})) in fees"
			exit 1
		fi

		TMPDIR=$(mktemp -d)
		STAGING_FILE="${TMPDIR}/staging.$$.transaction"
		${JCLI} transaction new --staging ${STAGING_FILE}
		${JCLI} transaction add-account "${SOURCE_ADDRESS}" "${AMOUNT_WITH_FEES}" --staging "${STAGING_FILE}"
		${JCLI} transaction add-output "${DESTINATION_ADDRESS}" "${AMOUNT}" --staging "${STAGING_FILE}"
		${JCLI} transaction finalize --staging ${STAGING_FILE}
		TRANSACTION_ID=$(${JCLI} transaction data-for-witness --staging ${STAGING_FILE})
		WITNESS_SECRET_FILE="${TMPDIR}/witness.secret.$$"
		WITNESS_OUTPUT_FILE="${TMPDIR}/witness.out.$$"

		printf "${SOURCE_KEY}" > ${WITNESS_SECRET_FILE}

		${JCLI} transaction make-witness ${TRANSACTION_ID} \
			--genesis-block-hash ${BLOCK0_HASH} \
			--type "account" --account-spending-counter "${SOURCE_COUNTER}" \
			${WITNESS_OUTPUT_FILE} ${WITNESS_SECRET_FILE}
		${JCLI} transaction add-witness ${WITNESS_OUTPUT_FILE} --staging "${STAGING_FILE}"

		# Finalize the transaction and send it
		${JCLI} transaction seal --staging "${STAGING_FILE}"
		TXID=$(${JCLI} transaction to-message --staging "${STAGING_FILE}" | ${JCLI} rest v0 message post --host "${NODE_REST_URL}")

		rm -r ${TMPDIR}

		say "Transaction ${WALLET_NAME} > ${DESTINATION_ADDRESS}" "log"
		say "  From:       ${SOURCE_ADDRESS}" "log"
		say "  Balance:    ${SOURCE_BALANCE_NICE}" "log"
		say "  Amount:     ${AMOUNT_NICE}" "log"
		say "  To:         ${DESTINATION_ADDRESS}" "log"
		say "  Fees:       ${FEES_NICE}" "log"
		say "  TX-ID:      ${TXID}" "log"
		say "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

	
	  ;; ###################################################################
	
	  *)
		usage ${0} #unknown sub command
		exit 1
	  ;;

	esac

  ;; ###################################################################

  pool)

	if [ ${#} -lt 3 ]; then
		usage ${0}
		exit 1
	fi

	SUBCOMMAND=${2}
	
	case $SUBCOMMAND in
	  register)  # [POOL_NAME] [WALLET_NAME]

		POOL_NAME=${3}
		WALLET_NAME=${4}

		if [ ${#} -lt 4 ]; then
			usage ${0}
			exit 1
		fi

		if [ -f "${POOL_FOLDER}/${POOL_NAME}/stake_pool.id" ]; then
			echo "Error: Pool $POOL_NAME already exists (${POOL_FOLDER}/${POOL_NAME}/stake_pool.id)"
			exit 1
		fi
		
		if [ -f "$WALLET_FOLDER/${WALLET_NAME}/ed25519.account" ]; then
			SOURCE_ADDRESS=$(cat "${WALLET_FOLDER}/${WALLET_NAME}/ed25519.account")
			SOURCE_KEY=$(cat "${WALLET_FOLDER}/${WALLET_NAME}/ed25519.key")
			SOURCE_PUB=$(cat "${WALLET_FOLDER}/${WALLET_NAME}/ed25519.pub")
			SOURCE_FILE="${WALLET_FOLDER}/${WALLET_NAME}/ed25519.key"
		else
			echo "Error: no wallet $WALLET_NAME found (${WALLET_FOLDER}/${WALLET_NAME}/ed25519.account)"
			exit 1
		fi
		
		SOURCE_BALANCE=$(${JCLI} rest v0 account get "${SOURCE_ADDRESS}" --host "${NODE_REST_URL}" | grep '^value:' | sed -e 's/value: //' )
		if (( $SOURCE_BALANCE == 0 )); then
			echo "ERROR: source wallet balance is zero"
			exit 1
		fi
		SOURCE_BALANCE_NICE=$(printf "%'d Lovelaces" ${SOURCE_BALANCE})
		SOURCE_COUNTER=$(${JCLI} rest v0 account get "${SOURCE_ADDRESS}" --host "${NODE_REST_URL}" | grep '^counter:' | sed -e 's/counter: //' )
		
		# read the nodes blockchain settings (parameters are required for the next transactions)
		settings="$(curl -s ${NODE_REST_URL}/v0/settings)"
		FEE_CONSTANT=$(echo $settings | jq -r .fees.constant)
		FEE_COEFFICIENT=$(echo $settings | jq -r .fees.coefficient)
		FEE_CERTIFICATE=$(echo $settings | jq -r .fees.certificate)
		BLOCK0_HASH=$(echo $settings | jq -r .block0Hash)
		AMOUNT_WITH_FEES=$((${FEE_CONSTANT} + ${FEE_COEFFICIENT} + ${FEE_CERTIFICATE}))
		AMOUNT_WITH_FEES_NICE=$(printf "%'d Lovelaces" ${AMOUNT_WITH_FEES})

		if (( $SOURCE_BALANCE <= AMOUNT_WITH_FEES )); then
			echo "ERROR: source wallet balance is not sufficient to pay the registration fee"
			exit 1
		fi

		mkdir -p "${POOL_FOLDER}/${POOL_NAME}"

		# generate pool owner wallet
		${JCLI} key generate --type=Ed25519 > "${POOL_FOLDER}/${POOL_NAME}/stake_pool_owner_wallet.key"
		cat "${POOL_FOLDER}/${POOL_NAME}/stake_pool_owner_wallet.key" | ${JCLI} key to-public > "${POOL_FOLDER}/${POOL_NAME}/stake_pool_owner_wallet.pub"
		${JCLI} address account "$(cat ${POOL_FOLDER}/${POOL_NAME}/stake_pool_owner_wallet.pub)" --testing > "${POOL_FOLDER}/${POOL_NAME}/stake_pool_owner_wallet.address"

		# generate pool KES and VRF certificates
		${JCLI} key generate --type=SumEd25519_12 > "${POOL_FOLDER}/${POOL_NAME}/stake_pool_kes.key"
		cat "${POOL_FOLDER}/${POOL_NAME}/stake_pool_kes.key" | ${JCLI} key to-public > "${POOL_FOLDER}/${POOL_NAME}/stake_pool_kes.pub"
		${JCLI} key generate --type=Curve25519_2HashDH > "${POOL_FOLDER}/${POOL_NAME}/stake_pool_vrf.key"
		cat "${POOL_FOLDER}/${POOL_NAME}/stake_pool_vrf.key" | ${JCLI} key to-public > "${POOL_FOLDER}/${POOL_NAME}/stake_pool_vrf.pub"

		# build stake pool certificate
		${JCLI} certificate new stake-pool-registration \
		--kes-key $(cat "${POOL_FOLDER}/${POOL_NAME}/stake_pool_kes.pub") \
		--vrf-key $(cat "${POOL_FOLDER}/${POOL_NAME}/stake_pool_vrf.pub") \
		--owner ${SOURCE_PUB} \
		--serial $(date +%Y%m%d)"01" \
		--management-threshold 1 \
		--start-validity 0 > "$POOL_FOLDER/${POOL_NAME}/stake_pool.cert"

		# get the stake pool ID
		cat "${POOL_FOLDER}/${POOL_NAME}/stake_pool.cert" | ${JCLI} certificate get-stake-pool-id > "${POOL_FOLDER}/${POOL_NAME}/stake_pool.id"
		POOLID=$(cat "${POOL_FOLDER}/${POOL_NAME}/stake_pool.id")

		# note pool-ID, vrf and KES keys into a secret file
		jq -n '.genesis.node_id = "'$POOLID'" | .genesis.vrf_key = "'$(cat "${POOL_FOLDER}/${POOL_NAME}/stake_pool_vrf.key")'" | .genesis.sig_key = "'$(cat "${POOL_FOLDER}/${POOL_NAME}/stake_pool_kes.key")'"' > "${POOL_FOLDER}/${POOL_NAME}/secret.yaml"
		
		TMPDIR=$(mktemp -d)
		STAGING_FILE="${TMPDIR}/staging.$$.transaction"
		${JCLI} transaction new --staging ${STAGING_FILE}
		${JCLI} transaction add-account "${SOURCE_ADDRESS}" "${AMOUNT_WITH_FEES}" --staging "${STAGING_FILE}"
		${JCLI} transaction add-certificate --staging ${STAGING_FILE} $(cat "${POOL_FOLDER}/${POOL_NAME}/stake_pool.cert")
		${JCLI} transaction finalize --staging ${STAGING_FILE}
		TRANSACTION_ID=$(${JCLI} transaction data-for-witness --staging ${STAGING_FILE})
		WITNESS_SECRET_FILE="${TMPDIR}/witness.secret.$$"
		WITNESS_OUTPUT_FILE="${TMPDIR}/witness.out.$$"

		printf "${SOURCE_KEY}" > ${WITNESS_SECRET_FILE}
		
		${JCLI} transaction make-witness ${TRANSACTION_ID} \
			--genesis-block-hash ${BLOCK0_HASH} \
			--type "account" --account-spending-counter "${SOURCE_COUNTER}" \
			${WITNESS_OUTPUT_FILE} ${WITNESS_SECRET_FILE}
		${JCLI} transaction add-witness ${WITNESS_OUTPUT_FILE} --staging "${STAGING_FILE}"

		# Finalize the transaction and send it
		${JCLI} transaction seal --staging "${STAGING_FILE}"
		${JCLI} transaction auth -k ${WITNESS_SECRET_FILE} --staging "${STAGING_FILE}"
		TXID=$(${JCLI} transaction to-message --staging "${STAGING_FILE}" | ${JCLI} rest v0 message post --host "${NODE_REST_URL}")

		rm -r ${TMPDIR}

		say "Registered new Pool ${POOL_NAME}" "log"
		say "  Pool-ID:    ${POOLID}" "log"
		say "  Fees:       ${AMOUNT_WITH_FEES_NICE}" "log"
		say "  TX-ID:      ${TXID}" "log"
		say "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

	  ;; ###################################################################

	  show)  # [POOL_ID]
		
		printf '%b\n' $(${JCLI} rest v0 stake-pools get --host "${NODE_REST_URL}" | grep ${3})
	
	  ;; ###################################################################

	  *)
		usage ${0} #unknown sub command
		exit 1
	  ;;

	esac
	
  ;; ###################################################################

  stake)

	if [ ${#} -lt 3 ]; then
		usage ${0}
		exit 1
	fi

	SUBCOMMAND=${2}
	
	case $SUBCOMMAND in
	  delegate)  # [WALLET_NAME] [POOL_NAME] 
		
		POOL_NAME=${4}
		WALLET_NAME=${3}
		
		if [ ${#} -lt 4 ]; then
			usage ${0}
			exit 1
		fi
		
		if [ -f "${POOL_FOLDER}/${POOL_NAME}/stake_pool.id" ]; then
			POOLID=$(cat "${POOL_FOLDER}/${POOL_NAME}/stake_pool.id")
		else
			echo "Error: no pool $POOL_NAME found"
			exit 1
		fi
		
		if [ -f "${WALLET_FOLDER}/${WALLET_NAME}/ed25519.account" ]; then
			SOURCE_ADDRESS=$(cat "${WALLET_FOLDER}/${WALLET_NAME}/ed25519.account")
			SOURCE_KEY=$(cat "${WALLET_FOLDER}/${WALLET_NAME}/ed25519.key")
			SOURCE_PUB=$(cat "${WALLET_FOLDER}/${WALLET_NAME}/ed25519.pub")
			SOURCE_FILE="${WALLET_FOLDER}/${WALLET_NAME}/ed25519.key"
		else
			echo "Error: no wallet $WALLET_NAME found"
			exit 1
		fi
		SOURCE_BALANCE=$(${JCLI} rest v0 account get "${SOURCE_ADDRESS}" --host "${NODE_REST_URL}" | grep '^value:' | sed -e 's/value: //' )
		if (( $SOURCE_BALANCE == 0 )); then
			echo "ERROR: source wallet balance is zero"
			exit 1
		fi
		SOURCE_BALANCE_NICE=$(printf "%'d Lovelaces" ${SOURCE_BALANCE})
		SOURCE_COUNTER=$(${JCLI} rest v0 account get "${SOURCE_ADDRESS}" --host "${NODE_REST_URL}" | grep '^counter:' | sed -e 's/counter: //' )

		# read the nodes blockchain settings (parameters are required for the next transactions)
		settings="$(curl -s ${NODE_REST_URL}/v0/settings)"
		FEE_CONSTANT=$(echo $settings | jq -r .fees.constant)
		FEE_COEFFICIENT=$(echo $settings | jq -r .fees.coefficient)
		FEE_CERTIFICATE=$(echo $settings | jq -r .fees.certificate)
		BLOCK0_HASH=$(echo $settings | jq -r .block0Hash)
		AMOUNT_WITH_FEES=$((${FEE_CONSTANT} + ${FEE_COEFFICIENT} + ${FEE_CERTIFICATE}))
		AMOUNT_WITH_FEES_NICE=$(printf "%'d Lovelaces" ${AMOUNT_WITH_FEES})
		
		if (( $SOURCE_BALANCE <= AMOUNT_WITH_FEES )); then
			echo "ERROR: source wallet balance is not sufficient to pay the registration fees"
			exit 1
		fi

		if [  -f "${WALLET_FOLDER}/${WALLET_NAME}/ed25519_stake.key" ]; then
			say "WARN: A stake key for wallet ${WALLET_NAME} already exists"
			exit 1
		fi
		
		# create a personal wallet key
		${JCLI} key generate --type=Ed25519 > "${WALLET_FOLDER}/${WALLET_NAME}/ed25519_stake.key"
		MY_ED25519_stake_key=$(cat "${WALLET_FOLDER}/${WALLET_NAME}/ed25519_stake.key")
		MY_ED25519_stake_file="${WALLET_FOLDER}/${WALLET_NAME}/ed25519_stake.key"
		echo "$MY_ED25519_stake_key" | ${JCLI} key to-public > "${WALLET_FOLDER}/${WALLET_NAME}/ed25519_stake.pub"
		MY_ED25519_stake_pub=$(cat "${WALLET_FOLDER}/${WALLET_NAME}/ed25519_stake.pub")

		# generate a delegation certificate (private wallet > stake pool)
		${JCLI} certificate new stake-delegation ${SOURCE_PUB} ${POOLID} > "${WALLET_FOLDER}/${WALLET_NAME}/${POOL_NAME}_stake_delegation.cert"
		
		TMPDIR=$(mktemp -d)
		STAGING_FILE="${TMPDIR}/staging.$$.transaction"
		${JCLI} transaction new --staging ${STAGING_FILE}
		${JCLI} transaction add-account "${SOURCE_ADDRESS}" "${AMOUNT_WITH_FEES}" --staging "${STAGING_FILE}"
		${JCLI} transaction add-certificate --staging ${STAGING_FILE} $(cat "${WALLET_FOLDER}/${WALLET_NAME}/${POOL_NAME}_stake_delegation.cert")
		${JCLI} transaction finalize --staging ${STAGING_FILE}
		TRANSACTION_ID=$(${JCLI} transaction data-for-witness --staging ${STAGING_FILE})
		WITNESS_SECRET_FILE="${TMPDIR}/witness.secret.$$"
		WITNESS_OUTPUT_FILE="${TMPDIR}/witness.out.$$"

		printf "${SOURCE_KEY}" > ${WITNESS_SECRET_FILE}
		
		${JCLI} transaction make-witness ${TRANSACTION_ID} \
			--genesis-block-hash ${BLOCK0_HASH} \
			--type "account" --account-spending-counter "${SOURCE_COUNTER}" \
			${WITNESS_OUTPUT_FILE} ${WITNESS_SECRET_FILE}
		${JCLI} transaction add-witness ${WITNESS_OUTPUT_FILE} --staging "${STAGING_FILE}"

		# Finalize the transaction and send it
		${JCLI} transaction seal --staging "${STAGING_FILE}"
		${JCLI} transaction auth -k ${WITNESS_SECRET_FILE} --staging "${STAGING_FILE}"
		TXID=$(${JCLI} transaction to-message --staging "${STAGING_FILE}" | ${JCLI} rest v0 message post --host "${NODE_REST_URL}")

		rm -r ${TMPDIR}

		say "Delegate wallet ${WALLET_NAME} to Pool ${POOL_NAME}" "log"
		say "  Pool-ID:    ${POOLID}" "log"
		say "  Stake:      ${SOURCE_BALANCE_NICE}" "log"
		say "  Fees:       ${AMOUNT_WITH_FEES_NICE}" "log"
		say "  TX-ID:      ${TXID}" "log"
		say "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
		
	  ;; ###################################################################
	
	  *)
		usage ${0} #unknown sub command
		exit 1
	  ;;

	esac
	
  ;; ###################################################################

  *)
	usage ${0} #unknown main command
	exit 1
  ;;

esac # main OPERATION
}


need_cmd() {
	if ! check_cmd "$1"; then
		echo "WARN: need '$1' (command not found)"
		echo "try 'sudo apt install $1'"
		exit 1
	fi
}

check_cmd() {
	command -v "$1" > /dev/null 2>&1
}

say() {
	echo $1
	if [[ $2 == "log" && "${JTOOLS_LOG}" != "" ]]; then 
		echo "$(date -Iseconds) - $1" >> ${JTOOLS_LOG}
	fi
}

##############################################################

main "$@"
