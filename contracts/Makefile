.PHONY: install build test deploy

ifneq (,$(wildcard ./.env))
    include .env
    export
endif

install:
	foundry install

build:
	forge build

test:
	forge test

deploy:
	@forge script script/ZkSafe.s.sol --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY) --broadcast