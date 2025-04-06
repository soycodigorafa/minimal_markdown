.PHONY: release

# Release a new version of the Markdown Editor
# This will:
# 1. Show the current version
# 2. Prompt for a new version
# 3. Check if the tag already exists
# 4. Update the version in pubspec.yaml
# 5. Commit the changes
# 6. Create a tag with a changelog
# 7. Push everything to the repository
release:
	@echo "=== Markdown Editor Release Tool ==="
	@echo ""
	@current_version=$$(grep -m 1 "version:" pubspec.yaml | awk '{print $$2}' | cut -d'+' -f1); \
	echo "Current version: $$current_version"; \
	echo ""; \
	read -p "Enter new version (e.g., 1.0.1): " new_version; \
	echo ""; \
	if [ -z "$$new_version" ]; then \
		echo "Error: Version cannot be empty."; \
		exit 1; \
	fi; \
	\
	# Check if tag already exists \
	if git rev-parse "v$$new_version" >/dev/null 2>&1; then \
		echo "Error: Tag v$$new_version already exists."; \
		exit 1; \
	fi; \
	\
	# Update version in pubspec.yaml \
	build_number=$$(grep -m 1 "version:" pubspec.yaml | awk '{print $$2}' | cut -d'+' -f2); \
	new_build_number=$$((build_number + 1)); \
	sed -i '' "s/version: .*$$/version: $$new_version+$$new_build_number/" pubspec.yaml; \
	\
	echo "Updated version to $$new_version+$$new_build_number in pubspec.yaml"; \
	echo ""; \
	\
	# Prompt for changelog \
	echo "Enter changelog (press Ctrl+D when finished):"; \
	changelog=$$(cat); \
	echo ""; \
	\
	# Commit changes \
	git add pubspec.yaml; \
	git commit -m "Bump version to $$new_version"; \
	\
	# Create tag with changelog \
	git tag -a "v$$new_version" -m "Version $$new_version\n\n$$changelog"; \
	\
	echo "Created tag v$$new_version"; \
	echo ""; \
	\
	# Confirm push \
	read -p "Push changes and tag to remote repository? (y/n): " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		git push origin master; \
		git push origin "v$$new_version"; \
		echo ""; \
		echo "Successfully pushed v$$new_version to remote repository."; \
	else \
		echo ""; \
		echo "Changes are committed locally but not pushed."; \
		echo "To push manually:"; \
		echo "  git push origin master"; \
		echo "  git push origin v$$new_version"; \
	fi

# Show help
help:
	@echo "Markdown Editor Makefile Commands:"
	@echo "  make release    - Create a new version release with semantic versioning"
	@echo "  make help       - Show this help message"
