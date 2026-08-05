#__init__.py marks tests/ as a package rather than a loose folder. 
# When pytest finds a package, it adds the parent directory (dashboard/) to Python's import path — and app.py lives right there, 
# so from app import app resolves.