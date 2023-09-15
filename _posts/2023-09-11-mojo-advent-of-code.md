---
layout: post
title: A first look at Mojo 🔥
categories: [mojo, coding]
excerpt: Taking a quick look at the new Mojo programming language. 
---

The [Mojo](https://www.modular.com/mojo) programming language was officially released in May, but could only be used through some notebooks in a sandbox.  

Last week, the [SDK](https://www.modular.com/blog/mojo-its-finally-here) (version 0.2.1) got released, so I decided to give it a look.  

Mojo's goal is to *"combine the usability of Python with the performance of C"*, and bills itself as *"the programming language for all AI developers"*.   

It's clear that Python is the dominant language when it comes to ML/AI, with great libraries like Pytorch and a few others being the main drivers of that. The problem comes with depth: all the fast libraries in Python are written in a performant language, usually C or C++, which means that if you want to dig into the internals of the tools you are using you have to switch languages, which greatly raises the barrier of entry for doing so.  

There are other languages that try to go for the usability of Python while retaining performance, and the first language that comes to mind for me in this respect is Julia. Julia is a pretty neat language, and writing math-heavy, fast code in it feels very elegant, while retaining a very Python like syntax. Julia is about twenty years younger than Python, and to me seems like they took the best aspects of Python and Fortran and rolled them into one language, allowing you to have performant and elegant code that is Julia all the way down. Given all this, in vacuum, Julia would seem like the obvious language to choose when it comes to ML/AI programming.  

The one major downside of Julia is that it doesn't have the robust ecosystem of libraries that Python has, and unless something major changes, it seems that Python will keep winning. 

Enter Mojo, a language that then (aspires to) keep interoperability with Python, while itself being very performant and allowing you to write code that is Mojo all the way down. Basically if Mojo achieves its goals then we get to have our cake and eat it: we can keep the great ecosystem of packages that Python brings with it, while getting to write new performant code in a single. My guess is if this works out that all the major packages will eventually get rewritten in Mojo, but we can have a transition period where we still get to keep the C/C++ version of them until this can be done.  

The people behind Mojo (mostly [Chris Lattner](https://en.wikipedia.org/wiki/Chris_Lattner)) seem to know what they are doing, so I wish them all the best. 


## A quick look

I wanted to start with something basic, so I thought I would have a look at the first puzzle from the [2022 advent of code](https://adventofcode.com/2022). Basically you are given a text file with a several lists of numbers representing the amount of calories some elves are carrying (go read up on the advent of code if you are unfamiliar, it will make sense then), and have to find which elves are carrying the most calories.  

So effectively a little bit of file parsing, with some basic arithmetic, i.e. a little puzzle to ease into Mojo. I won't share the input because the creator of the AoC has [explicitly asked people not to](https://x.com/ericwastl/status/1465805354214830081?s=20), but you can download your own and try the code below. 

At first glance, a lot of Python code will "just work": 


```python
for _ in range(10):
    print("Blah")
```

    Blah
    Blah
    Blah
    Blah
    Blah
    Blah
    Blah
    Blah
    Blah
    Blah


However, it's clear a lot is still missing, e.g. lambda functions don't work yet: 


```python
lambda x: x + 2
```

    error: [0;1;31m[1mExpression [2]:17:5: [0m[1munexpected token in expression
    [0m    lambda x: x + 2
    [0;1;32m    ^
    [0m[0m
    expression failed to parse (no further compiler diagnostics)

This is likely coming, but for now we have to live without it. 

So for the first step, let's parse some text files. 
The first thing I found was that Mojo doesn't have a native way to parse text yet. But luckily, you can just get Python to do it for you!
In this case, you have to import Python as a module and call the builtin Python open function.  

It's standard practice in Python to open text files with the `with open(filename) as f` incantation, but this doesn't work in Mojo, so have to open and close files manually. 


```python
from python import Python
from math import max
from utils.vector import DynamicVector
from algorithm.sort import sort

def read_file(file_name: String) -> DynamicVector[Int]:
    """ 
    There seems to be no native mojo way to read a file yet.

    There is an issue in the mojo github page that suggests the code below.
    https://github.com/modularml/mojo/issues/130

    I've tried to keep the Python code in this function, in order to keep the others
    as "pure" mojo
    """
    builtins = Python.import_module("builtins")
    in_file = builtins.open(file_name)

    file_contents = in_file.read()
    in_file.close()

    content_list = file_contents.split("\n")
    # There seems to be no way yet to go straight from python int to mojo Int,
    # so you have to go via float64: https://github.com/modularml/mojo/issues/657
    let list_len: Int = content_list.__len__().to_float64().to_int()

    item_list = DynamicVector[Int](list_len)
    
    for item in content_list:
        str_item = item.to_string()
        if str_item != "":
            item_list.push_back(atol(str_item))
        else:
            item_list.push_back(0)
        
    return item_list

```

All in all, it's relatively standard Python, with a couple of caveats. 

One of the big things is that there is a distinction between Python types and Mojo types, i.e. the Python `int` is not the same as Mojo's `Int`, so if you want to get the most out of Mojo, you need to cast from the one to the other. Right now, there seems to be no direct way to go from `int` to `Int`, so I had to take a detour via `float64`.   

I tried to keep the Python imports in the `read_file` function, so that the other functions can be in "pure" Mojo. 

The my first impulse was to create a Python-esque list, but the [builtin list in Mojo is immutable](https://mojodojo.dev/guides/builtins/BuiltinList.html), so I had to go for a DynamicVector, which had a strong C++ flavour to it. 

Once that was done I was done with Python for this program and could go forth in pure Mojo.   

Below you can see I declare functions with `fn` while above I used `def`. Both work in Mojo, but `fn` functions forces you to be [strongly typed and enfoces some memory safe behaviour](https://docs.modular.com/mojo/manual/basics/#functions).


```python
fn part_one(calorie_list: DynamicVector[Int]) -> Int:
    """ 
    Loop over a vector of Ints, and find the grouping (split by 0) with the highest sum. 
    """
    var max_calories: Int = 0
    var this_calories: Int = 0

    var entry = 0
    for index in range(len(calorie_list)):
        entry = calorie_list.data[index]
        if entry != 0:
            this_calories += entry
        else:
            max_calories = max(this_calories, max_calories)
            this_calories = 0

    return max_calories
```

You can see here the values are all declared as mutable (`var`). You can also declare immutables with `let`. This is enforced in `fn` functions. 

Other than that, a relatively standard loop over a container. 




```python
fn part_two(calorie_list: DynamicVector[Int]) -> Int:
    """
    Initialize a vector to keep track of the current top 3 elf calories. 
    Add a value to the container if is larger than the smallerst value, and sort. 
    """
    let k: Int = 3
    var max_k_calories: DynamicVector[Int] = DynamicVector[Int](k)
    for i in range(k):
        max_k_calories.push_back(0)

    var this_calories: Int = 0

    var entry = 0
    for index in range(len(calorie_list)):
        entry = calorie_list.data[index]
        if entry != 0:
            this_calories += entry
        else:
            if this_calories > max_k_calories[0]:
                max_k_calories[0] = this_calories
                sort(max_k_calories)

            this_calories = 0
            

    var max_calories: Int = 0
    for index in range(len(max_k_calories)):
        max_calories += max_k_calories.data[index]

    return max_calories
```

Again, relatively straightforward. 

I'm definitely missing Python niceties like being able to easily sum over a container (can't call `sum(max_k_calories)` in Mojo 😢). 

To put it all together we create a main `fn`, and notice that we need to indicate that it might raise errors as we are calling the unsafe `read_file`. 


```python
fn main() raises:
    let file_contents: DynamicVector[Int] = read_file(
        "input/input_1.txt"
    )

    let answer_1: Int = part_one(file_contents)
    print("The elf carrying the most calories is carrying:", answer_1, "calories")

    let answer_2: Int = part_two(file_contents)
    print("The three elves carrying the most calories are carrying:", answer_2, "calories")


main()
```

    The elf carrying the most calories is carrying: 72511 calories
    The three elves carrying the most calories are carrying: 212117 calories


## Conclusions

Mojo feels relatively familiar, but I will also say that when writing "pure" Mojo it feels like writing C++ with Python syntax. 
This makes sense given the goals of the language, but caught me a little off guard; I was expecting something a little closer to Julia, which still feels a lot like Python in most cases.   

This was not the greatest example to show Mojo off, as Mojo really shines in high performance environments, so the language didn't really get to stretch its legs here. You can find some more [performance oriented examples on the official Mojo website](https://docs.modular.com/mojo/notebooks/Matmul.html).   

I will probably give Mojo another look and try out something a bit more suited for the language in the future, maybe when the `0.3` version of the language drops.   

I think I've been spoiled by mostly writing in two well supported languages (Python and C++) for which there are countless reference examples or StackOverflow posts on how to do things. Due to the fact that Mojo is brand new, there are very few examples to look to about how to do even relatively basic things. 

For now if you want to get started, I recommend starting with the [exercises on mojodojo.dev](https://mojodojo.dev/guides/intro-to-mojo/basic-types.html#exercises). 

