# reshape2l

`reshape2l` is a Stata program to quickly convert data from wide to long form. It is primarily used in situations where *stubnames* are followed by numeric parts, which is often the case for raw panel datasets.

`reshape2l` is similar to [`reshape long`](https://www.stata.com/help.cgi?reshape) but significantly faster, especially for large datasets where memory requirement gets very high and `reshape long` becomes very slow. It relies on secondary storage rather than memory. The speed gain of `reshape2l` over `reshape long` increases with size and width of the dataset as well as read and write speed of storage device where the STATATMP folder resides.

## Installation

To install directly within Stata, use the following command:
```stata
local github "https://raw.githubusercontent.com"
net install reshape2l, from(`github'/gaksaray/reshape2l/master)
```
