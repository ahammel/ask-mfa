PYTHON = python3.8
ACTIVATE = python/bin/activate
SITE_PACKAGES = python/lib/$(PYTHON)/site-packages/
PIP = $(SITE_PACKAGES)/pip
PYTHON_DEPENDENCIES = $(SITE_PACKAGES)/psycopg2 \
					  $(SITE_PACKAGES)/black
CONFIG = config.env

build: $(PYTHON_DEPENDENCIES)

run: $(PYTHON_DEPENDENCIES) $(CONFIG) $(ACTIVATE)
	source $(ACTIVATE) && source $(CONFIG) && python ask_mfa_api.py

venv: $(ACTIVATE)

clean:
	rm -fr python

black b: $(PYTHON_DEPENDENCIES) $(ACTIVATE)
	source $(ACTIVATE) && python -m black .

repl: $(PYTHON_DEPENDENCIES) $(ACTIVATE)
	source $(ACTIVATE) && python

$(ACTIVATE):
	python3 -m venv ./python

$(PIP): $(ACTIVATE)
	source $(ACTIVATE) && pip install --upgrade pip

$(PYTHON_DEPENDENCIES): $(PIP) $(ACTIVATE)
	source $(ACTIVATE) && pip install -r requirements.txt

