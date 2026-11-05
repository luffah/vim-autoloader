tags: docs
	vim -u NONE -c "helptags doc/ | qa!"

docs:
	vim -c "call genhelp#GenHelp('plugin/autoloader.vim') | qa!"
