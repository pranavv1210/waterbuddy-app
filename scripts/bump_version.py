import sys
import os
import re

def main():
    pubspec_path = os.path.join(os.path.dirname(__file__), "..", "apps", "waterbuddy_superapp", "pubspec.yaml")
    if not os.path.exists(pubspec_path):
        print(f"Error: pubspec.yaml not found at {pubspec_path}")
        sys.exit(1)

    bump_type = "patch"
    if len(sys.argv) > 1:
        arg = sys.argv[1].lower()
        if arg in ["--major", "major"]:
            bump_type = "major"
        elif arg in ["--minor", "minor"]:
            bump_type = "minor"
        elif arg in ["--patch", "patch"]:
            bump_type = "patch"
        elif arg in ["--build", "build"]:
            bump_type = "build"

    with open(pubspec_path, 'r') as f:
        content = f.read()

    # Find version line: version: X.Y.Z+W
    match = re.search(r'^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)', content, re.MULTILINE)
    if not match:
        print("Error: Could not parse version in pubspec.yaml")
        sys.exit(1)

    major = int(match.group(1))
    minor = int(match.group(2))
    patch = int(match.group(3))
    build = int(match.group(4))

    print(f"Current version: {major}.{minor}.{patch}+{build}")

    if bump_type == "major":
        major += 1
        minor = 0
        patch = 0
        build += 1
    elif bump_type == "minor":
        minor += 1
        patch = 0
        build += 1
    elif bump_type == "patch":
        patch += 1
        build += 1
    elif bump_type == "build":
        build += 1

    new_version_str = f"version: {major}.{minor}.{patch}+{build}"
    updated_content = re.sub(r'^version:\s*\d+\.\d+\.\d+\+\d+', new_version_str, content, flags=re.MULTILINE)

    with open(pubspec_path, 'w') as f:
        f.write(updated_content)

    print(f"Bumped version to: {major}.{minor}.{patch}+{build}")

if __name__ == "__main__":
    main()
