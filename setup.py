from setuptools import setup, Extension
from Cython.Build import cythonize


extensions = [
    Extension(
        "engine.matching_engine",
        ["engine/matching_engine.pyx"],
        extra_compile_args=["-O3"],
    )
]


setup(
    name="chronosmatch",
    version="0.1.0",
    ext_modules=cythonize(
        extensions,
        compiler_directives={
            "language_level": 3,
            "boundscheck": False,
            "wraparound": False,
            "initializedcheck": False,
        },
    ),
)