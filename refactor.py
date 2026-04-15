import os
import re
import shutil

lib_dir = os.path.join('c:\\', 'Users', 'chelb', 'StudioProjects', 'flutter-app', 'lib')

categories = ['models', 'views', 'services', 'routes', 'providers']
for c in categories:
    os.makedirs(os.path.join(lib_dir, c), exist_ok=True)

# 1. Build a map of filename -> new_path
file_map = {}
duplicates = []

for root, _, files in os.walk(lib_dir):
    for f in files:
        if not f.endswith('.dart'): continue
        if 'l10n' in root: continue
        if 'generated' in root: continue
        
        full_path = os.path.join(root, f)
        rel_path = os.path.relpath(full_path, lib_dir).replace('\\', '/')
        
        # Don't touch files already at root level (main.dart, app.dart)
        if rel_path == f and f != 'user_model.dart': 
            continue

        cat = 'views'
        if 'model' in f or 'entity' in rel_path.lower(): cat = 'models'
        elif 'service' in f or 'repository' in rel_path.lower() or 'source' in rel_path.lower(): cat = 'services'
        elif 'router' in f or 'route' in f: cat = 'routes'
        elif 'provider' in f or 'controller' in f or 'state' in f.lower(): cat = 'providers'
        elif 'screen' in f or 'page' in f or 'widget' in rel_path.lower() or 'components' in rel_path.lower(): cat = 'views'
        else: cat = 'core' # We'll put constants in models or views later if needed, let's keep core for now
        
        if cat == 'core':
            os.makedirs(os.path.join(lib_dir, 'core'), exist_ok=True)
            
        new_rel_path = f"{cat}/{f}"
        
        if f in file_map:
            duplicates.append((f, full_path))
        else:
            file_map[f] = new_rel_path

# To handle duplicates for now, let's just prefix their category from their old path
for dup_f, full_path in duplicates:
    parent = os.path.basename(os.path.dirname(full_path))
    new_f = f"{parent}_{dup_f}"
    rel_path = os.path.relpath(full_path, lib_dir).replace('\\', '/')
    cat = 'views'
    if 'model' in dup_f: cat = 'models'
    elif 'service' in dup_f: cat = 'services'
    elif 'router' in dup_f: cat = 'routes'
    elif 'provider' in dup_f: cat = 'providers'
    file_map[new_f] = f"{cat}/{new_f}"
    # Wait, we need to map the full path to the new path reliably
    
# Let's do a strict full_path -> new_full_path mapping
exact_map = {}
filename_to_new_package_path = {}

for root, _, files in os.walk(lib_dir):
    for f in files:
        if not f.endswith('.dart'): continue
        if 'l10n' in root: continue
        
        full_path = os.path.join(root, f)
        rel_path = os.path.relpath(full_path, lib_dir).replace('\\', '/')
        
        if rel_path == f: continue # ignore root files like main.dart

        cat = 'views'
        if 'model' in f or 'entity' in rel_path.lower(): cat = 'models'
        elif 'service' in f or 'repository' in rel_path.lower() or 'source' in rel_path.lower(): cat = 'services'
        elif 'router' in f or 'route' in f: cat = 'routes'
        elif 'provider' in f or 'controller' in f: cat = 'providers'
        else: cat = 'views'
        
        new_f = f
        # simple deduplication
        if any(new_f == os.path.basename(v) for v in exact_map.values()):
            parent = os.path.basename(os.path.dirname(full_path))
            new_f = f"{parent}_{f}"
            
        new_rel_path = f"{cat}/{new_f}"
        if rel_path != new_rel_path:
            exact_map[full_path] = os.path.join(lib_dir, cat, new_f)
            
        filename_to_new_package_path[f] = f"package:flutter_application_1/{cat}/{new_f}"

# Replace imports in memory first
import_pattern = re.compile(r"import\s+['\"](.*?)['\"];")

def get_new_import(match, current_dir):
    imp = match.group(1)
    if not imp.endswith('.dart'): return match.group(0)
    
    # if it's already a package import except ours, keep it
    if imp.startswith('package:') and not imp.startswith('package:flutter_application_1'):
        return match.group(0)
        
    filename = os.path.basename(imp)
    if filename in filename_to_new_package_path:
        return f"import '{filename_to_new_package_path[filename]}';"
        
    return match.group(0)
    
# 2. Modify files
for full_path in list(exact_map.keys()) + [os.path.join(lib_dir, 'main.dart'), os.path.join(lib_dir, 'app.dart')]:
    if not os.path.exists(full_path): continue
    with open(full_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    new_content = import_pattern.sub(lambda m: get_new_import(m, os.path.dirname(full_path)), content)
    
    with open(full_path, 'w', encoding='utf-8') as f:
        f.write(new_content)

# 3. Move files
for src, dst in exact_map.items():
    if not os.path.exists(src): continue
    if src == dst: continue
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    shutil.move(src, dst)

# 4. Clean up empty dirs
for root, dirs, files in os.walk(lib_dir, topdown=False):
    for d in dirs:
        dir_path = os.path.join(root, d)
        if not os.listdir(dir_path):
            os.rmdir(dir_path)

print("Refactoring complete.")
