#!/bin/bash

set -xe

pushd /mnt/extracted
	if [ "${ENGLISH_COMPATIBLE}" = "1" ]; then
		OLD_LANG=${LANG}
		export LANG=it_IT.UTF-8
	fi;

	if [ ! -f "wiki_it_lower.txt" ]; then
		curl -sSL https://github.com/MozillaItalia/DeepSpeech-Italian-Model/releases/download/lm-0.1/wiki.txt.xz | pixz -d | tr '[:upper:]' '[:lower:]' > wiki_it_lower.txt
	fi;

	if [ "${ENGLISH_COMPATIBLE}" = "1" ]; then
		mv wiki_it_lower.txt wiki_it_lower_accents.txt
		# Locally force LANG= to make iconv happy and avoid errors like:
		# iconv: illegal input sequence at position 4468
		# Also required locales and locales-all to be installed
		head -n 5 wiki_it_lower_accents.txt
		iconv -f UTF-8 -t ASCII//TRANSLIT//IGNORE < wiki_it_lower_accents.txt > wiki_it_lower.txt
		head -n 5 wiki_it_lower.txt
		> wiki_it_lower_accents.txt
	fi;

	if [ ! -f "/mnt/lm/lm.binary" ]; then
		lmplz	--order 3 \
			--temp_prefix /mnt/tmp/ \
			--memory 80% \
			--text wiki_it_lower.txt \
			--arpa /mnt/lm/lm.arpa \
			--skip_symbols \
			--prune 0 1

		build_binary -a 255 \
			-q 8 \
			trie \
			/mnt/lm/lm.arpa \
			/mnt/lm/lm.binary

		rm /mnt/lm/lm.arpa
		> wiki_it_lower.txt
	fi;

	if [ ! -f "/mnt/lm/trie" ]; then
		curl -sSL https://index.taskcluster.net/v1/task/project.deepspeech.deepspeech.native_client.master.${DS_SHA1}.cpu/artifacts/public/native_client.tar.xz | pixz -d | tar -xf -
		./generate_trie /mnt/models/alphabet.txt /mnt/lm/lm.binary /mnt/lm/trie
	fi;

	if [ "${ENGLISH_COMPATIBLE}" = "1" ]; then
		export LANG=${OLD_LANG}
	fi;
popd
