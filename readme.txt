Osdag Tex Environment

There are 2 files(SectionModeller_Latex.py and reportGenerator_latex.py) and a folder(osdag-latex-env) here which when extracted correctly will couple Osdag to its own Tex Environment in osdag-latex-env, completely removing the step of installing a Tex distro for the user.

Here's a list of what must be extracted where:

1) 'osdag-latex-env' as an entire folder must be copied & placed in osdag/data/ResourceFiles.

Full path differs user to user, but it generally is:
C:\Users\User_Name\miniconda3\envs\osdag-env\Lib\site-packages\osdag\data\ResourceFiles

2) SectionModeller_Latex.py must be replaced with the existing file with the same name in the osdag folder.

i.e C:\Users\User_Name\miniconda3\envs\osdag-env\Lib\site-packages\osdag

3) reportGenerator_latex.py must be replaced with the existing file with the same name in the osdag/design_report folder.

i.e C:\Users\User_Name\miniconda3\envs\osdag-env\Lib\site-packages\osdag\design_report  
