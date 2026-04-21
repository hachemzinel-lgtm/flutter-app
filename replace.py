import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Replace .withOpacity(x) with .withValues(alpha: x)
    # The regex needs to handle .withOpacity(0.5) correctly.
    # Be careful with parentheses inside the opacity argument. Usually it's just a number or a simple variable.
    # A simple regex: \.withOpacity\(([^)]+)\) -> .withValues(alpha: \1)
    # Note: we should only do this if we are not inside a larger complex expression that breaks it, but since withOpacity just takes a double, it's fairly safe.
    new_content = re.sub(r'\.withOpacity\(([^)]+)\)', r'.withValues(alpha: \1)', content)

    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Fixed {filepath}")

def main():
    lib_dir = 'lib'
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                process_file(os.path.join(root, file))

if __name__ == '__main__':
    main()
