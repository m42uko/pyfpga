#!/usr/bin/make

.PHONY: docs

docs:
	cd docs; make html

lint:
	pycodestyle pyfpga examples tests
	pylint -s n pyfpga
	git diff --check --cached

test:
	pytest tests

clean:
	py3clean .
	cd docs; make clean
	rm -fr build .pytest_cache

submodule-init:
	git submodule update --init

submodule-update:
	cd resources; git checkout main; git pull
