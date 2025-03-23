Osdag Localized Tex Engine

The attached files in the .zip will couple Osdag to the localized tex engine in osdag-latex-env, completely removing the step of installing a Tex distro for the user.

There are 3 files in the .zip file. Here's a list of what must be extracted where:

1) 'osdag-latex-env' must be extracted to osdag/data/ResourceFiles.

Full path differs user to user, but it generally is:
C:\Users\User_Name\miniconda3\envs\osdag-env\Lib\site-packages\osdag\data\ResourceFiles

2) SectionModeller_Latex.py must be replaced with the existing file with the same name in the osdag folder.

i.e C:\Users\User_Name\miniconda3\envs\osdag-env\Lib\site-packages\osdag

3) reportGenerator_latex.py must be replaced with the existing file with the same name in the osdag/design_report folder.

i.e C:\Users\User_Name\miniconda3\envs\osdag-env\Lib\site-packages\osdag\design_report  