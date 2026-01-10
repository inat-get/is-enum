# is-enum

[![GitHub License](https://img.shields.io/github/license/inat-get/is-enum)](LICENSE)
[![Gem Version](https://badge.fury.io/rb/is-enum.svg?icon=si%3Arubygems&d=1)](https://badge.fury.io/rb/is-enum)
[![Ruby](https://github.com/inat-get/is-enum/actions/workflows/ruby.yml/badge.svg)](https://github.com/inat-get/is-enum/actions/workflows/ruby.yml) 
![Coverage](coverage-badge.svg)

Enum types for Ruby

## Usage

```ruby
require 'is-enum'

class MyEnum < IS::Enum

  define :alpha, 1
  define :beta,  2
  define :b, alias: :beta

end
```
