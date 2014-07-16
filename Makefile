PATH := ./node_modules/.bin:${PATH}

init:
	git submodule init && git submodule update && npm install

build:
	coffee --output lib --compile src

publish:
	npm publish
