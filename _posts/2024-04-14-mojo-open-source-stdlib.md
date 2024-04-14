---
layout: post
title: Mojo's standard library goes open source
categories: [mojo]
excerpt: Modular open sources the Mojo stdlib, as well as changes from version 0.7 up to the current 24.2 (new numbering scheme). 
---

A lot has changed in Mojo land since I last had a look. The last time I wrote one of these Mojo was at version 0.6, and now it's at 24.2!  
This is just due to a change in version numbering, so they have basically still kept the pace of about one new version per month, so the releases (ignoring bugfix releases) goes 0.6 -> 0.7 -> 24.1 -> 24.2.  

Why 24.1/24.2? Modular have moved to a `YY.MAJOR.MINOR` numbering scheme, so 24.1 and 24.2 are the first and second releases (under this naming scheme) in 2024, respectively. The [reason this was done](https://www.modular.com/blog/max-is-here-what-does-that-mean-for-mojo) is to keep the Mojo versioning in sync with Max, Modular's other product. A minor worry I have about this is that unlike semantic versioning where you get a nice 1.0 release, it's a bit hard to know now what a stable release will look like.   

Another big piece of news is that the Mojo standard library is now open source, under the Apache 2.0 license (with LLVM exceptions). So far only the SDK has been available, but with the stdlib this is one step closer to the entire language being open source. Some people on HackerNews have grumbled about the language not being open source, but I do totally get why the developers want to reach some level of maturity before opening their language up to the peanut gallery.

In any case, I want to have a bit of a look at what has changed. 

## Release 0.7 

The one object I've severely missed in Mojo has been a dictionary type, and in 0.7 they finally added it. It's one of the most useful data structures in Python, and they have kept the implementation similar to the Python one (so a hash map under the hood). 

A slight difference is that for Mojo dicts the types must be statically specified, unlike Python where you can just kinda do whatever you want. 

So to define a dictionary: 


```python
from collections import Dict
var my_dict = Dict[String, String]()
my_dict["foo"] = "oof"
my_dict["bar"] = "rab"
print(len(my_dict))      
print(my_dict["foo"])      
print(my_dict.pop("bar"))  
print(len(my_dict))      
```

    2
    oof
    rab
    1


So pretty straightforward stuff. Nice!

Another profiling feature that I've never seen anywhere before is getting not just the number of cores on your system, but the types as well. 


```python
from sys import info

print(info.num_logical_cores())
print(info.num_physical_cores())
print(info.num_performance_cores())
```

    20
    14
    6


So you can see my machine has 20 total "cores", which I believe breaks down as 6 performance cores and 8 efficiency cores, for 6 + 8 = 14 physical cores, and the 6 performance cores each having two threads, so 2 * 6 + 8 = 20 threads. I've never really had to consider what kind of cores my program runs on, but this will probably become an increasingly important thing to consider going forward. 

Another interesting thing that caught my eye is the new `Reference` type, which is taking a page out of the Rust playbook. Checking the roadmap, they do state that a borrow checker is on the way. This does make a lot of sense: if you want to be able to give people access to low-level memory management, do it the Rust way. Right now you can mess around with raw pointers and the compiler will just let you, but it seems this will change in the future. 

I mentioned in an earlier post that Mojo felt like writing C++ with Python syntax, but maybe it will be more like writing Rust with Python syntax soon. 

Talking of comparing Mojo to Rust, [ThePrimeagen](https://twitter.com/ThePrimeagen) made a [video](https://www.youtube.com/watch?v=MDblUyz0PtQ) discussing the topic. Actually it's discussing a [blog post](https://www.modular.com/blog/mojo-vs-rust-is-mojo-faster-than-rust) by Modular that is discussing an earlier [video from him](https://www.youtube.com/watch?v=kmmqHV26Ukg) discussing a Mojo community [blog post](https://www.modular.com/blog/outperforming-rust-benchmarks-with-mojo). It's a whole thing. In any case, it's an interesting video going into a lot of the rationale behind how a lot of the design decisions about Mojo are being made.  

## Release 24.1

Another release, another useful data structure. This time it's Mojo's implementation of a set: 


```python
from collections import Set

var my_set = Set[String]()
my_set.add("foo")
my_set.add("bar")
print(len(my_set))

my_set.add("foo")
print(len(my_set))

if "foo" in my_set:
    print("foo is in the set")
```

    2
    2
    foo is in the set


So `Set` is a nice little addition, and works as you would expect. 
The `a in b` syntax from Python is also new, so every day we get a bit closer to Python. 


A feature I haven't appreciated before is unbound values and the `alias` declaration: so you can create an alias of an object, which is basically a partial initialization that can then be fully initialized later. 


```python
@value
struct StructWithDefault[a: Int, b: Int, c: Int = 8, d: Int = 9]: pass
alias end_unbound = StructWithDefault[3, 4, 5, _]

var my_instance_5 = end_unbound[5]()
var my_instance_10 = end_unbound[10]()
```

This reminds me a bit of `partial` in Python (however, this does happen at compile time), and might make sense if you are initializing multiple versions of large objects. On that note, the compile-time metaprogramming side of Mojo is something I still need to explore and something I haven't fully grasped yet.  

A new feature is that you can unbind any number of parameters with `*_`


```python
alias most_unbound = StructWithDefault[3, *_]

var my_instance_567 = most_unbound[5, 6, 7]()
var my_instance_8910 = most_unbound[8, 9, 10]()
```

An issue I ran into earlier was the lack of support for iteration in `DynamicVector`, which has now been rectified! 

Additionally (in v24.2), the `DynamicVector` been replaced with a `List`, which has a distinctly Pythonic feel to it: 


```python
var names =  List[String]("Alice", "Bob", "Charlie")
for x in names:
    x[] = str("Hello, ") + x[]
for x in names:
    print(x[])

```

    Hello, Alice
    Hello, Bob
    Hello, Charlie


Even negative indexing is now supported: 



```python
print(names[-1])
```

    Hello, Charlie


If you are wondering what the `[]` syntax in `print(x[])` is for is that the iterator over the list returns references, and `[]` is the dereference operator in Mojo. 

Additionally, file handling just became easier with the introduction of `pathlib.Path` and `os.listdir`, which should be familiar to anyone who uses Python. 


## Release 24.2

An interesting change is the removal of the `let` declaration, i.e. the way you declare immutable variables in Mojo. I thought this was a bit strange at first, but there has been a lot of thought put into the decision, see [this post](https://github.com/modularml/mojo/blob/main/proposals/remove-let-decls.md) by Chris Lattner. 

Partly it's due to simplicity, as Python has no concept of immutability, but the one interesting argument that stuck out to me was: 
> The immutability only applies to the local value
i.e. only the `Pointer` (or `Reference`) is immutable if you use `let`, not the value being pointed to, which was causing some confusion. It sounds like the concept is being re-evaluated and will likely make a comeback in some shape later. 


`print` in Mojo is now very close to the Python version, so you can specify the separator and end:  


```python
print("Hello", "Mojo", sep=", ", end="!!!\n") 
print("Hello", "Mojo", sep="~~~", end="\n~~~") 
```

    Hello, Mojo!!!
    Hello~~~Mojo
    ~~~

Other than that, there are a few changes that bring the language closer to Python, such as adding variadic keyword arguments (as `**kwargs`), but the biggest change in 24.2 is really the release of the `stdlib`. 

## Conclusions

Mojo is finally starting to look usable. Earlier this year there was still too much missing to do much more than a little sandboxed demo in Mojo, and it looks like this is starting to change. Someone is even starting building an ML framework (called [Basalt](https://github.com/basalt-org/basalt)) in Mojo, and I'm excited to see where that goes. On that note, I'm very curious to see when Mojo will finally support GPUs, as that will really be the point where it will start living up to it's promise of being the language of machine learning. 

So far I've basically just been writing these posts as an exercise to make myself really parse the Mojo changelog, but I'm tempted to actually start running some real world tests. 
