---
layout: post
title: Mojo 0.6.0, now with traits and better Python like string wrangling.
categories: [mojo]
excerpt: The (Legendary) 0.6.0 release of the Mojo programming language along with a quick look at the new headline feature, traits 
---

Another month, another Mojo release.  

I am busy doing the 2023 edition of the [Advent of Code](https://adventofcode.com/2023) (AoC) in Mojo, and had a few complaints 😅.  
If you not familiar with the AoC, it's basically a coding advent calendar that gives you a new coding challenge every day for the first 25 days of December.  

In a bit of foreshadowing, I used an AoC 2022 puzzle in my [first post on Mojo](https://fnands.com/mojo-advent-of-code/), which was using Mojo 0.2.1, and it is encouraging to see how far the language has come.  

The AoC puzzles are often pretty heavy in string wrangling, a task that Python is pretty strong in, and that Mojo is still somewhat lacking in. 
One of the features that I found was lacking in Mojo 0.5.0 was the ability to easily split a string as one does in Python.  

In the case of the first day, I found myself needing to split a string by newlines, something which you can do trivially in Python by calling `my_string.split('\n')`. In Mojo 0.5.0 this did not exist and I had to write a struct to implement this functionality. I ended up generalizing it a bit and putting it in a [library](https://github.com/fnands/advent_of_code_2023/blob/main/aoc_lib/string_utils.mojo) as it was super useful for the following days as well.  

And then on the fourth of December [Mojo 0.6.0 was released](https://docs.modular.com/mojo/changelog.html#v0.6.0-2023-12-04), which now includes the ability to call `.split()` on a string, as well as a bunch of useful Python methods (`rfind()`, `len()`, `str()`, `int()`). These will definitely help going forward with the AoC challenges. 

I'll write a rundown of my experience with the AoC in Mojo when I complete all the puzzles, so now on the the spotlighted feature from 0.6.0: traits

## Traits in Mojo

[Traits](https://en.wikipedia.org/wiki/Trait_(computer_programming)) are a fairly common concept in programming languages, and allow you to add required functionality to a struct if it conforms to this trait. 

As an example, take the `len()` function that we know and love from Python, and that is also now a part of Mojo. 
The trait associated with `len()` in Mojo is `Sized`, meaning that any struct conforming to the `Sized` trait is required to have a `__len__()` method that returns an integer size. When the function `len()` is applied to a struct that conforms to `Sized`, the `__len__()` function is called. 

An example of a struct that conforms to the `Sized` trait is the builtin `String`:


```python
example_string = "This is a String and it conforms to the Sized trait."

print(len(example_string))
```

    52


Additionally, we can then write our own struct that conforms to `Sized`, and as long as it has a method named `__len__()` it will conform to the `Sized` trait (the compiler will let you know if it doesn't): 


```python
@value
struct MySizedStruct(Sized):
    var size: Int

    fn __len__(self) -> Int:
        return self.size

```

If we now call `len()` on an instance of this struct it will return the size value: 


```python
sized_struct = MySizedStruct(10)
print(len(sized_struct))
```

    10


As a side note, I used the `@value` decorator above which hides a bit of boilerplate code for us. 
The above initialization is equivalent to: 


```python
struct MySizedStruct(Sized):
    var size: Int

    fn __len__(self) -> Int:
        return self.size

    fn __init__(inout self, size: Int):
        self.size = size

    fn __copyinit__(inout self, existing: Self):
        self.size = existing.size

    fn __moveinit__(inout self, owned existing: Self):
        self.size = existing.size
```

So `@value` is a pretty useful way to save us a few lines of boilerplate code. 

I'm still getting used to decorators in Mojo (maybe a good idea to do a post on them in the future). 

One question I had about traits is how difficult it is to chain them? 
E.g. what if I have a struct that I want to conform to both `Sized` and `Stringable`, which allows the function `str()` to apply to the struct, and makes it printable? 

It turns out this is easy; just pass them during as a comma 


```python
@value
struct MySizedAndStingableStruct(Sized, Stringable):
    var size: Int

    fn __len__(self) -> Int:
        return self.size

    fn __str__(self) -> String:
        return str(self.size)

sized_and_stringable = MySizedAndStingableStruct(11)
print(sized_and_stringable)
```

    11


So it is very simple to add multiple traits. 

To create our own trait, we only need to define it with a method that conforming structs need to inherit: 



```python
trait Jazzable:
    fn jazz(self): ...
```

Here the `...` indicates that nothing is specified yet (needs to be done per struct). 
It is not possible yet to define a default method, but is apparently coming in the future. 

Let's create a struct that conforms to Jazzable: 


```python
@value
struct JazzX(Jazzable):
    var jazz_level: Int
    
    fn jazz(self):
        for i in range(self.jazz_level):
            print("Jazzing at level", i + 1)

ten_jazz = JazzX(10)
ten_jazz.jazz()
```

    Jazzing at level 1
    Jazzing at level 2
    Jazzing at level 3
    Jazzing at level 4
    Jazzing at level 5
    Jazzing at level 6
    Jazzing at level 7
    Jazzing at level 8
    Jazzing at level 9
    Jazzing at level 10


We can also define a function that calls a specific method. An example of this is the `len()` function that calls `__len__()`, we can create our own function that will call `jazz()`:


```python
fn make_it_jazz[T: Jazzable](jazz_struct: T):
    jazz_struct.jazz()


make_it_jazz(ten_jazz)
```

    Jazzing at level 1
    Jazzing at level 2
    Jazzing at level 3
    Jazzing at level 4
    Jazzing at level 5
    Jazzing at level 6
    Jazzing at level 7
    Jazzing at level 8
    Jazzing at level 9
    Jazzing at level 10


Additionally, traits can inherit from other traits, and keep the functionality of the parent trait:  


```python
trait SuperJazzable(Jazzable):
    fn super_jazz(self): ...


@value 
struct SuperJazz(SuperJazzable):
    var jazz_level: Int

    fn jazz(self):
        for i in range(self.jazz_level):
            print("Jazzing at level", i + 1)

    fn super_jazz(self):
        for i in range(self.jazz_level):
            print("Super Jazzing at level", (i + 1)*10)
    
```

This new struct will have all the methods of `Jazzable`, so `make_it_jazz()` will work: 


```python
super_jazz_5 = SuperJazz(5)
make_it_jazz(super_jazz_5)
```

    Jazzing at level 1
    Jazzing at level 2
    Jazzing at level 3
    Jazzing at level 4
    Jazzing at level 5


And we can define additional functions that will activate the new methods as well: 


```python
fn make_it_super_jazz[T: SuperJazzable](superjazz_struct: T):
    superjazz_struct.super_jazz()

make_it_super_jazz(super_jazz_5)
```

    Super Jazzing at level 10
    Super Jazzing at level 20
    Super Jazzing at level 30
    Super Jazzing at level 40
    Super Jazzing at level 50


## Conclusions

Traits provide a convenient way of adding functionality to structs, and as you can see they are pretty simple to use. 

I've never used traits in any other language before, but it does work similarly to generic classes, and feels really familiar, except for the fact that you can't have default behaviour (yet). 

From what I've seen from Mojo so far, writing structs seems to be a pretty core part of how Mojo is supposed to be used, so I guess I better get used to it. 




