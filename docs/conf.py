project = 'Bookweald'
copyright = '2026, Vladimir Tsichevski'
author = 'Vladimir Tsichevski'

extensions = [
    'sphinx.ext.githubpages',  # adds .nojekyll for GitHub Pages
]

templates_path = ['_templates']
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store']
html_theme = 'alabaster'
html_static_path = ['_static']
