import os
import re

lib_dir = os.path.join('c:\\', 'Users', 'chelb', 'StudioProjects', 'flutter-app', 'lib')

# Build map of filename -> new package path
file_destinations = {}
for root, _, files in os.walk(lib_dir):
    for f in files:
        if not f.endswith('.dart'): continue
        rel_path = os.path.relpath(os.path.join(root, f), lib_dir).replace('\\', '/')
        file_destinations[f] = f'package:flutter_application_1/{rel_path}'

import_pattern = re.compile(r"import\s+['\"](.*?)['\"];")

def replace_import(match):
    imp = match.group(1)
    if imp.startswith('dart:') or imp.startswith('package:firebase') or imp.startswith('package:flutter/') or imp.startswith('package:flutter_riverpod') or imp.startswith('package:go_router') or imp.startswith('package:flutter_localizations'):
        return match.group(0)
    
    filename = os.path.basename(imp)
    if filename in file_destinations:
        return f"import '{file_destinations[filename]}';"
    return match.group(0)

# Also fix the models override issue
overrides_fix = re.compile(r"final .*? (bio|yearsExperience);")

for root, _, files in os.walk(lib_dir):
    for f in files:
        if not f.endswith('.dart'): continue
        full_path = os.path.join(root, f)
        
        with open(full_path, 'r', encoding='utf-8') as file:
            content = file.read()
            
        new_content = import_pattern.sub(replace_import, content)
        
        if f == 'marketplace_model.dart':
            new_content = new_content.replace("final String? description;", "@override final String? description;")
        if f == 'work_provider_model.dart':
            new_content = new_content.replace("final int? yearsExperience;", "@override final int? yearsExperience;")
            new_content = new_content.replace("final String? bio;", "@override final String? bio;")
        
        if new_content != content:
            with open(full_path, 'w', encoding='utf-8') as file:
                file.write(new_content)

print('Imports updated based on filenames.')
