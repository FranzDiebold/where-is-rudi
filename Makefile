.PHONY: install
install:
	pip install -r requirements.txt

.PHONY: lint
lint:
	pylint --version
	pylint **/*.py --reports=yes
