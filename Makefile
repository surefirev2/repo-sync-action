# Makefile

.PHONY: init
init:
	pre-commit install

.PHONY: run-pre-commit
run-pre-commit:
	pre-commit run --all-files

.PHONY: test-bash
test-bash:
	bash test/run-resolve-config-tests.sh
	bash test/run-build-file-list-tests.sh
	bash test/run-ga-build-file-list-tests.sh
	bash test/run-generate-diffs-tests.sh
	bash test/run-write-step-summary-tests.sh
	bash test/run-pr-comment-tests.sh
	bash test/run-push-pr-tests.sh

.PHONY: test-python
test-python:
	python -m venv .venv
	./.venv/bin/pip install -r requirements.txt
	./.venv/bin/pytest

.PHONY: test
test: test-bash test-python
