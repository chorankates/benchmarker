# bnchmrkr

[![build status](https://travis-ci.org/chorankates/bnchmrkr.svg)](https://travis-ci.org/chorankates/bnchmrkr) [![Gem Version](https://badge.fury.io/rb/bnchmrkr.png)](https://rubygems.org/gems/bnchmrkr) [![Code Climate](https://codeclimate.com/github/chorankates/bnchmrkr/badges/gpa.svg)](https://codeclimate.com/github/chorankates/bnchmrkr)

Bnchmrkr (Benchmarker) is a tool to help benchmark different method implementations in Ruby

it is driven by [Benchmark](http://ruby-doc.org/stdlib-2.0.0/libdoc/benchmark/rdoc/Benchmark.html)

i hate the name too, [but..](https://github.com/chorankates/bnchmrkr/issues/1)

- [usage](#usage)
  - [pre-built gem installation (stable)](#pre-built-gem-installation-stable)
  - [from-source installation (latest)](#from-source-installation-latest)
- [examples](#examples)
  - [code](#code)
  - [output](#output)
  - [converting from < 0.1.1](#upgrading)
- [methods](#methods)
  - [Bnchmrkr](#bnchmrkr)
  - [Bnchmrkr::Mark](#bnchmrkrmark)

## usage

### pre-built gem installation (stable)

```sh
gem install bnchmrkr
irb
...
irb(main):001:0> require 'bnchmrkr'
=> true
```

### from-source installation (latest)

```sh
git clone https://github.com/chorankates/bnchmrkr.git
cd bnchmrkr
rake clean build
gem install pkg/bnchmrkr*.gem
irb
...
irb(main):001:0> require 'bnchmrkr'
=> true
```

## examples

### code

```rb
tester = Bnchmrkr.new({
  :count_to_1k   => lambda { 1.upto(1000).each   { |i| i } },
  :count_to_5k   => lambda { 1.upto(5000).each   { |i| i } },
  :count_to_10k  => lambda { 1.upto(10000).each  { |i| i } },
  :count_to_50k  => lambda { 1.upto(50000).each  { |i| i } },
  :count_to_100k => lambda { 1.upto(100000).each { |i| i } },
}, 1000)

tester.benchmark!

puts tester
```

### output

```
$ ruby examples/ls_vs_stat.rb
  fastest by type(ls) => 0.005704
  fastest overall => {:name=>:ls, :measure=>0.005704}
  slowest by type(stat) => 0.076243
  slowest_overall => {:name=>:stat, :measure=>0.076243}
  is_faster?(:ls, :stat) => true
  is_slower?(:ls, :stat) => false
ls:
          fastest => 0.005704
             mean => 0.008375
           median => 0.006715
          slowest => 0.024187
            total => 0.083754
stat:
          fastest => 0.061403
             mean => 0.069956
           median => 0.073952
          slowest => 0.076243
            total => 0.699563
overall:
          fastest => ls [0.005704]
          slowest => stat [0.076243]
```

### upgrading

`Bnchmrkr` follows semantic versioning, which allowed a breaking change from versions `0.1.1` to `0.2.0`

`0.2.0` significantly improves the API and implementation for `Bnchmrkr`, and while upgrading will require some client side changes, they shouldn't be too onerous:

for the most part, you should be able to update the Hash lookup key with a method call of the same name,

#### < 0.1.1
```rb
assert_equal(:iterative, tester.fastest_overall[:name])
assert_equal(:recursive, tester.slowest_overall[:name])
```

#### >= 0.2.0
```rb
assert_equal(:iterative, tester.fastest_overall.name)
assert_equal(:recursive, tester.slowest_overall.name)
```

## methods

### `Bnchmrkr`
```rb
attr_reader :executions, :marks, :fastest, :slowest
...
def initialize(lambdas, executions = 100)
def types
def benchmark!
def inspect
def to_s
def fastest_by_type(type, mode = :real)
def slowest_by_type(type, mode = :real)
def fastest_overall
def slowest_overall
def is_faster?(a, b, mode = :real)
def is_slower?(a, b, mode = :real)
def faster_by_result(a, b, percent = true, mode = :real)
def faster_by_type(a, b, percent = true, mode = :real)
def slower_by_type(a, b, percent = true)
def slower_by_result(a, b, percent = true)
def calculate_overall(mode = :real)
```

### `Bnchmrkr::Mark`
```rb
attr_reader :computed, :lambda, :name, :mode_precision
attr_reader :fastest, :slowest, :mean, :median, :mode, :total
...
def initialize(name, lambda, mode_precision = 0)
def add_measure(measure)
def each(&block)
def compute
def inspect
def reset_computations
```
```
