---
id: mvb0hfa50somdlala4fhj5a
title: Cuelang-Example
desc: ''
updated: 1656607143590
created: 1656607124788
jupyter:
  jupytext:
    formats: 'ipynb,md'
    text_representation:
      extension: .md
      format_name: markdown
      format_version: '1.3'
      jupytext_version: 1.13.8
  kernelspec:
    display_name: Python 3 (ipykernel)
    language: python
    name: python3
---

## Summary

A simple demonstration of [cuelang](https://cuelang.org/) within a notebook.

Note: presumes already installed cue commandline client. More information here: <https://cuelang.org/docs/install/>

<!-- #region -->
## Types are Values

Within cuelang, types are values. Duplicates are allowed so long as they don't conflict.

Consider the following valid example:

```cue
bigCity: {
  name:    "Aurora"
  pop:     386261
  capital: false
}
bigCity: {
  name:    string
  pop:     int
  capital: bool
}
bigCity: {
  name:    string
  pop:     >100000
  capital: bool
}
```

Whereas, the following would be invalid, throwing an error (capital as string and bool types are mismatched):

```cue
bigCity: {
  name:    "Aurora"
  pop:     386261
  capital: "false"
}
bigCity: {
  name:    string
  pop:     int
  capital: bool
}
bigCity: {
  name:    string
  pop:     >100000
  capital: bool
}
```

See the following documentation for more:
    - <https://cuelang.org/docs/tutorials/tour/intro/cue/>
    - <https://cuelang.org/docs/tutorials/tour/intro/duplicates/>
<!-- #endregion -->

```python
import os
```

```python
# demonstrate invalid
some_cue = """
bigCity: {
  name:    "Aurora"
  pop:     386261
  capital: "false"
}
bigCity: {
  name:    string
  pop:     int
  capital: bool
}
bigCity: {
  name:    string
  pop:     >100000
  capital: bool
}
"""

with open("./example.cue", "w") as f:
    f.write(some_cue)
```

```sh
# run as shell
# shows conflicting values error
cue eval example.cue
```

```python
# demonstrate valid
some_cue = """
bigCity: {
  name:    "Aurora"
  pop:     386261
  capital: false
}
bigCity: {
  name:    string
  pop:     int
  capital: bool
}
bigCity: {
  name:    string
  pop:     >100000
  capital: bool
}
"""

with open("./example.cue", "w") as f:
    f.write(some_cue)
```

```sh
# run as shell
# shows valid result
cue eval example.cue
```

```python
# remove example file
os.remove("./example.cue")
```
