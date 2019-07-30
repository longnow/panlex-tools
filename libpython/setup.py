import setuptools

with open("README.md", "r") as fh:
    long_description = fh.read()

setuptools.setup(
    name="panlex-tools",
    version="1.0.0",
    author="Ben Yang, Alex DelPriore, Gary Krug, David Kamholz",
    author_email="ben@panlex.org",
    description="Various tools for analyzing PanLex sources",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/longnow/panlex-tools",
    packages=setuptools.find_packages(),
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
        "Topic :: Text Processing :: Linguistic",
    ],
    include_package_data=True,
)