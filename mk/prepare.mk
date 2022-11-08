
.PHONY: prepare
prepare:  ## Download all the external repositories
	[ -e "$(PROJECT_DIR)/external" ] || mkdir -p "$(PROJECT_DIR)/external"
	[ -e "$(PROJECT_DIR)/external/console.dot" ] || git clone -u downstream "https://github.com/cockpit-project/console.dot.git" external/console.dot
	[ -e .venv ] || python3 -m venv .venv
	source .venv/bin/activate && pip install -U pip
	source .venv/bin/activate && pip install "crc-bonfire>=4.10.2,<4.11.0"

