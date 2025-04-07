.PHONY: release help

# Release a new version of the Markdown Editor
# This will use the release.sh script to handle the release process
release:
	@./release.sh

# Show help
help:
	@echo "Markdown Editor Makefile Commands:"
	@echo "  make release    - Create a new version release with semantic versioning"
	@echo "  make help       - Show this help message"
